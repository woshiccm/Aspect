//
//  Aspect.swift
//  Aspect
//
//  Created by roy.cao on 2019/5/18.
//  Copyright © 2019 roy. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

let lock = SpinLock()

//@_silgen_name ("_objc_msgForward")
//public func _as_objc_msgForward() -> IMP

private enum Constants {
    static let subclassSuffix = "_Aspect_"
    static let forwardInvocationSelectorName = "__aspect_forwardInvocation:"
}

public enum AspectStrategy {
    case after            /// Called after the original implementation (default)
    case instead          /// Will replace the original implementation.
    case before           /// Called before the original implementation.
}

public class AspectInfo: NSObject {

    let instance: AnyObject
    let originalInvocation: AnyObject
    var arguments: [Any?] { return unpackInvocation(originalInvocation) }

    init(instance: AnyObject, invocation: AnyObject) {
        self.instance = instance
        self.originalInvocation = invocation
    }
}

internal class AspectsCache {

    var beforeAspects: [AspectIdentifier] = []
    var insteadAspects: [AspectIdentifier] = []
    var afterAspects: [AspectIdentifier] = []

    func add(_ aspect: AspectIdentifier, option: AspectStrategy) {
        switch option {
        case .before:
            beforeAspects.append(aspect)
        case .instead:
            insteadAspects.append(aspect)
        case .after:
            afterAspects.append(aspect)
        }
    }

    // TODO: remove aspect.
    func remove(_ aspect: AspectIdentifier) -> Bool {
        return true
    }

    func hasAspects() -> Bool {
        return !(beforeAspects.isEmpty && insteadAspects.isEmpty && afterAspects.isEmpty)
    }
}

extension NSObject {

    /// Hook an object selector.
    ///
    /// - Parameters:
    ///   - selector: The selector need to hook.
    ///   - strategy: The hook strategy, `.before` by default.
    ///   - block: The hook block.
    public func hook(selector: Selector, strategy: AspectStrategy = .before, block: AnyObject) {
        ahook(object: self, selector: selector, strategy: strategy, block: block)
    }
}

extension NSObject {

    // TODO: Hook class selector.
    public class func hook(selector: Selector, strategy: AspectStrategy, block: AnyObject) {
        ahook(object: self, selector: selector, strategy: strategy, block: block)
    }
}

func ahook(object: AnyObject, selector: Selector, strategy: AspectStrategy, block: AnyObject) {
    lock.performLocked {
        guard let identifier = AspectIdentifier.identifier(with: selector, object: object, strategy: strategy, block: block) else { return }

        let aspectCache = getContainerForObject(object: object, selector: selector)
        aspectCache.add(identifier, option: strategy)

        let subclass: AnyClass = hookClass(object: object)
        let method = class_getInstanceMethod(subclass, selector)
        let impl: IMP = method.map(method_getImplementation) ?? _aspect_objc_msgForward

        guard impl != _aspect_objc_msgForward else { return }

        guard let typeEncoding = method.flatMap(method_getTypeEncoding) else { return }
        assert(checkTypeEncoding(typeEncoding))

        let aliasSelector = selector.alias

        if !subclass.instancesRespond(to: aliasSelector) {
            let succeeds = class_addMethod(subclass, aliasSelector, impl, typeEncoding)
            precondition(succeeds, "Aspect attempts to swizzle a selector that has message forwarding enabled with a runtime injected implementation. This is unsupported in the current version.")
        }

        class_replaceMethod(subclass, selector, _aspect_objc_msgForward, typeEncoding)
    }
}

private func hookClass(object: AnyObject) -> AnyClass {
    let perceivedClass: AnyClass = object.objcClass
    let realClass: AnyClass = object_getClass(object)!

    let className = String(cString: class_getName(realClass))

    if className.hasPrefix(Constants.subclassSuffix) {
        return realClass
    } else if class_isMetaClass(realClass) {
        // TODO:
    } else if perceivedClass != realClass {
        // TODO:
    }

    let subclassName = Constants.subclassSuffix+className

    let subclass: AnyClass = subclassName.withCString { cString in
        if let existingClass = objc_getClass(cString) as! AnyClass? {
            return existingClass
        } else {
            let subclass: AnyClass = objc_allocateClassPair(perceivedClass, cString, 0)!
            swizzleForwardInvocation(subclass)
            replaceGetClass(in: subclass, decoy: perceivedClass)
            objc_registerClassPair(subclass)
            return subclass
        }
    }

    object_setClass(object, subclass)
    return subclass
}

private func swizzleForwardInvocation(_ realClass: AnyClass) {
    guard let originalImplementation = class_replaceMethod(realClass,
                                                     ObjCSelector.forwardInvocation,
                                                     imp_implementationWithBlock(aspectForwardInvocation as Any),
                                                     ObjCMethodEncoding.forwardInvocation) else {
                                                        return
    }
    class_addMethod(realClass, NSSelectorFromString(Constants.forwardInvocationSelectorName), originalImplementation, ObjCMethodEncoding.forwardInvocation)
}

private let aspectForwardInvocation: @convention(block) (Unmanaged<NSObject>, AnyObject) -> Void = { objectRef, invocation in
    let selector = invocation.selector!
    var aliasSelector = invocation.selector!.alias
    var aliasSelectorKey = AssociationKey<AspectsCache?>(aliasSelector)

    guard let aspectCache = (objectRef.takeUnretainedValue() as NSObject).associations.value(forKey: aliasSelectorKey) else {
        return
    }

    var info = AspectInfo(instance: objectRef.takeUnretainedValue() as AnyObject, invocation: invocation)

    // Before hooks.
    for aspect in aspectCache.beforeAspects {
        aspect.invoke(with: &info)
    }

    var respondsToAlias = true

    if !aspectCache.insteadAspects.isEmpty {
        for aspect in aspectCache.insteadAspects {
            aspect.invoke(with: &info)
        }
    } else {
        if let target = invocation.objcTarget, let klass = object_getClass(target) {
            repeat
            {
                if true == klass.instancesRespond(to: aliasSelector) {
                    invocation.setSelector(aliasSelector)
                    invocation.invoke()
                    break
                } else {
                    respondsToAlias = false
                }
            } while !respondsToAlias && klass == class_getSuperclass(klass)
        } else {
            respondsToAlias = false
        }
    }

    // After hooks.
    for aspect in aspectCache.afterAspects {
        aspect.invoke(with: &info)
    }
}

private func replaceGetClass(in class: AnyClass, decoy perceivedClass: AnyClass) {
    let getClass: @convention(block) (UnsafeRawPointer?) -> AnyClass = { _ in
        perceivedClass
    }

    let impl = imp_implementationWithBlock(getClass as Any)

    _ = class_replaceMethod(`class`,
                            ObjCSelector.getClass,
                            impl,
                            ObjCMethodEncoding.getClass)

    _ = class_replaceMethod(object_getClass(`class`),
                            ObjCSelector.getClass,
                            impl,
                            ObjCMethodEncoding.getClass)
}

func getContainerForObject(object: AnyObject, selector: Selector) -> AspectsCache {
    let aliasSelector = selector.alias
    let aliasSelectorKey = AssociationKey<AspectsCache?>(aliasSelector)
    var aspectCache = (object as! NSObject).associations.value(forKey: aliasSelectorKey)

    if aspectCache == nil {
        aspectCache = AspectsCache()
        (object as! NSObject).associations.setValue(aspectCache, forKey: aliasSelectorKey)
    }

    return aspectCache!
}
