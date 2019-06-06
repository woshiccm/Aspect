//
//  AspectIdentifier.swift
//  Aspect
//
//  Created by roy.cao on 2019/5/26.
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

public protocol AspectToken {
    func remove()
}

extension AspectIdentifier: AspectToken {

    public func remove() {
        Aspect.remove(self)
    }
}

internal struct AspectIdentifier {

    let selector: Selector
    weak var object: AnyObject?
    let strategy: AspectStrategy
    let block: AnyObject
    var blockSignature: AnyObject?

    init(selector: Selector, object: AnyObject, strategy: AspectStrategy, block: AnyObject) {
        self.selector = selector
        self.object = object
        self.strategy = strategy
        self.block = block
    }

    func invoke(with info: inout AspectInfo) {
        guard let signature = blockSignature, let numberOfArguments = signature.objcNumberOfArguments  else { return }
        let invocation = NSInvocation.invocation(methodSignature: signature)

        if numberOfArguments > 1 {
            invocation.setArgument(&info, at: 1)
        }
        invocation.invoke(withTarget: self.block)
    }

    /// Create a AspectIdentifier
    ///
    /// - Parameters:
    ///   - selector: The selector need to hook.
    ///   - object: The object/class.
    ///   - strategy: The hook strategy.
    ///   - block: The hook strategy.
    static func identifier(with selector: Selector, object: AnyObject, strategy: AspectStrategy, block: AnyObject) throws -> AspectIdentifier {
        guard let blockSignature = AspectBlock(block).blockSignature else {
            throw AspectError.missingBlockSignature
        }

        do {
            try isCompatibleBlockSignature(blockSignature: blockSignature, object: object, selector: selector)
            var aspectIdentifier = AspectIdentifier(selector: selector, object: object, strategy: strategy, block: block)
            aspectIdentifier.blockSignature = blockSignature
            return aspectIdentifier
        } catch {
            throw error
        }
    }

    /// Compare block Signature and object method Signature are the same
    ///
    /// - Parameters:
    ///   - blockSignature: The block Signature.
    ///   - object: The object/class.
    ///   - selector: The selector need to hook.
    static func isCompatibleBlockSignature(blockSignature: AnyObject, object: AnyObject, selector: Selector) throws {
        let perceivedClass: AnyClass = object.objcClass
        let realClass: AnyClass = object_getClass(object)!
        let method = class_getInstanceMethod(perceivedClass, selector) ?? class_getClassMethod(realClass, selector)

        guard let nonnullMethod = method, let typeEncoding = method_getTypeEncoding(nonnullMethod) else {
            object.doesNotRecognizeSelector?(selector)
            throw AspectError.unrecognizedSelector
        }

        let signature = NSMethodSignature.signature(objCTypes: typeEncoding)
        var signaturesMatch = true

        if blockSignature.objcNumberOfArguments > signature.objcNumberOfArguments {
            signaturesMatch = false
        } else {
            if blockSignature.objcNumberOfArguments > 1 {
                let rawEncoding = blockSignature.getArgumentType(at: UInt(1))
                let encoding = ObjCTypeEncoding(rawValue: rawEncoding.pointee) ?? .undefined
                if encoding != .object {
                    signaturesMatch = false
                }
            }

            if signaturesMatch {
                for index in 2 ..< blockSignature.objcNumberOfArguments {
                    let methodRawEncoding = signature.getArgumentType(at: index)
                    let blockRawEncoding = blockSignature.getArgumentType(at: index)

                    let methodEncoding = ObjCTypeEncoding(rawValue: methodRawEncoding.pointee) ?? .undefined
                    let blockEncoding = ObjCTypeEncoding(rawValue: blockRawEncoding.pointee) ?? .undefined

                    if methodEncoding != blockEncoding {
                        signaturesMatch = false
                        break
                    }
                }
            }
        }

        if !signaturesMatch {
            throw AspectError.blockSignatureNotMatch
        }
    }
}
