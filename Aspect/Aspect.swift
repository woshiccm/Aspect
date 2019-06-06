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
    func remove(_ aspect: AspectIdentifier) {

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
    ///
    ///   - returns: AspectToken, you can use it to remove hook.
    public func hook(selector: Selector, strategy: AspectStrategy = .before, block: AnyObject) throws -> AspectToken {
        return try ahook(object: self, selector: selector, strategy: strategy, block: block)
    }
}

extension NSObject {

    /// Hook an object selector.
    ///
    /// - Parameters:
    ///   - selector: The selector need to hook.
    ///   - strategy: The hook strategy, `.before` by default.
    ///   - block: The hook block.
    ///   - returns: AspectToken, you can use it to remove hook.
    public class func hook(selector: Selector, strategy: AspectStrategy, block: AnyObject) throws -> AspectToken {
        return try ahook(object: self, selector: selector, strategy: strategy, block: block)
    }
}

func ahook(object: AnyObject, selector: Selector, strategy: AspectStrategy, block: AnyObject) throws -> AspectToken {
    return try lock.performLocked {
        let identifier = try AspectIdentifier.identifier(with: selector, object: object, strategy: strategy, block: block)

        let cache = getAspectCache(for: object, selector: selector)
        cache.add(identifier, option: strategy)

        let subclass: AnyClass = try hookClass(object: object, selector: selector)
        let method = class_getInstanceMethod(subclass, selector) ?? class_getClassMethod(subclass, selector)

        guard let impl = method.map(method_getImplementation), let typeEncoding = method.flatMap(method_getTypeEncoding) else {
            throw AspectError.unrecognizedSelector
        }

        assert(checkTypeEncoding(typeEncoding))

        let aliasSelector = selector.alias

        if !subclass.instancesRespond(to: aliasSelector) {
            let succeeds = class_addMethod(subclass, aliasSelector, impl, typeEncoding)
            precondition(succeeds, "Aspect attempts to swizzle a selector that has message forwarding enabled with a runtime injected implementation. This is unsupported in the current version.")
        }

        class_addMethod(subclass, aliasSelector, impl, typeEncoding)
        class_replaceMethod(subclass, selector, _aspect_objc_msgForward, typeEncoding)
        return identifier
    }
}

private func hookClass(object: AnyObject, selector: Selector) throws -> AnyClass {
    let perceivedClass: AnyClass = object.objcClass
    let realClass: AnyClass = object_getClass(object)!
    let className = String(cString: class_getName(realClass))

    if className.hasPrefix(Constants.subclassSuffix) {
        return realClass
    } else if class_isMetaClass(realClass) {
        if class_getInstanceMethod(perceivedClass, selector) != nil {
            swizzleForwardInvocation(perceivedClass)
            return perceivedClass
        } else {
            swizzleForwardInvocation(realClass)
            return realClass
        }
    }

    let subclassName = Constants.subclassSuffix+className
    let subclass: AnyClass? = subclassName.withCString { cString in
        if let existingClass = objc_getClass(cString) as! AnyClass? {
            return existingClass
        } else {
            if let subclass: AnyClass = objc_allocateClassPair(perceivedClass, cString, 0) {
                swizzleForwardInvocation(subclass)
                replaceGetClass(in: subclass, decoy: perceivedClass)
                objc_registerClassPair(subclass)
                return subclass
            } else {
                return nil
            }
        }
    }

    guard let nonnullSubclass = subclass else {
        throw AspectError.failedToAllocateClassPair
    }

    object_setClass(object, nonnullSubclass)
    return nonnullSubclass
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
    let object = objectRef.takeUnretainedValue() as AnyObject
    let selector = invocation.selector!

    var aliasSelector = selector.alias
    var aliasSelectorKey = AssociationKey<AspectsCache?>(aliasSelector)

    let selectorKey = AssociationKey<AspectsCache?>(selector)
    let associations = Associations(object.objcClass as AnyObject)

    let aspectCache: AspectsCache

    if let cache = associations.value(forKey: selectorKey) {
        aspectCache = cache
    } else if let cache = (objectRef.takeUnretainedValue() as NSObject).associations.value(forKey: aliasSelectorKey) {
        aspectCache = cache
    } else {
        return
    }

    var info = AspectInfo(instance: object, invocation: invocation)

    // Before hooks.
    aspectCache.beforeAspects.invoke(with: &info)

    if !aspectCache.insteadAspects.isEmpty {
        // Instead hooks
        aspectCache.insteadAspects.invoke(with: &info)
    } else {
        invocation.setSelector(aliasSelector)
        invocation.invoke()
    }

    // After hooks.
    aspectCache.afterAspects.invoke(with: &info)
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

func getAspectCache(for object: AnyObject, selector: Selector) -> AspectsCache {
    let realClass: AnyClass = object_getClass(object)!
    let selectorKey: AssociationKey<AspectsCache?>

    if class_isMetaClass(realClass) {
        selectorKey = AssociationKey<AspectsCache?>(selector)
    } else {
        let aliasSelector = selector.alias
        selectorKey = AssociationKey<AspectsCache?>(aliasSelector)
    }
    var aspectCache = (object as! NSObject).associations.value(forKey: selectorKey)

    if aspectCache == nil {
        aspectCache = AspectsCache()
        (object as! NSObject).associations.setValue(aspectCache, forKey: selectorKey)
    }

    return aspectCache!
}

// TODO: remove aspect.
func remove(_ aspect: AspectIdentifier) {
    return lock.performLocked {
        guard let object = aspect.object else { return }

        let aspectCache = getAspectCache(for: object, selector: aspect.selector)
        aspectCache.remove(aspect)
    }
}

extension Collection where Iterator.Element == AspectIdentifier {

    func invoke(with info: inout AspectInfo) {
        self.forEach { $0.invoke(with: &info) }
    }
}
