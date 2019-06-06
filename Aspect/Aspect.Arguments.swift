//
//  Aspect.Arguments.swift
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

public extension NSObject {

    func hook(
        selector: Selector,
        strategy: AspectStrategy = .before,
        block: @escaping(AspectInfo) -> Void) throws -> AspectToken
    {
        let wrappedBlock: @convention(block) (AspectInfo) -> Void = { aspectInfo in
            block(aspectInfo)
        }

        let wrappedObject: AnyObject = unsafeBitCast(wrappedBlock, to: AnyObject.self)
        return try hook(selector: selector, strategy: strategy, block: wrappedObject)
    }

    func hook<Arg1>(
        selector: Selector,
        strategy: AspectStrategy = .before,
        block: @escaping(AspectInfo, Arg1) -> Void) throws -> AspectToken
    {
        let wrappedBlock: @convention(block) (AspectInfo) -> Void = { aspectInfo in
            guard aspectInfo.arguments.count == 1,
                let arg1 = aspectInfo.arguments[0] as? Arg1 else { return }
            block(aspectInfo, arg1)
        }
        return try hook(selector: selector, strategy: strategy, block: wrappedBlock)
    }

    func hook<Arg1, Arg2>(
        selector: Selector,
        strategy: AspectStrategy = .before,
        block: @escaping(AspectInfo, Arg1, Arg2) -> Void) throws -> AspectToken
    {
        let wrappedBlock: @convention(block) (AspectInfo) -> Void = { aspectInfo in
            guard aspectInfo.arguments.count == 2,
                let arg1 = aspectInfo.arguments[0] as? Arg1,
                let arg2 = aspectInfo.arguments[1] as? Arg2 else { return }
            block(aspectInfo, arg1, arg2)
        }

        let wrappedObject: AnyObject = unsafeBitCast(wrappedBlock, to: AnyObject.self)
        return try hook(selector: selector, strategy: strategy, block: wrappedObject)
    }

    func hook<Arg1, Arg2, Arg3>(
        selector: Selector,
        strategy: AspectStrategy = .before,
        block: @escaping(AspectInfo, Arg1, Arg2, Arg3) -> Void) throws -> AspectToken
    {
        let wrappedBlock: @convention(block) (AspectInfo) -> Void = { aspectInfo in
            guard aspectInfo.arguments.count == 3,
                let arg1 = aspectInfo.arguments[0] as? Arg1,
                let arg2 = aspectInfo.arguments[1] as? Arg2,
                let arg3 = aspectInfo.arguments[2] as? Arg3 else { return }
            block(aspectInfo, arg1, arg2, arg3)
        }

        let wrappedObject: AnyObject = unsafeBitCast(wrappedBlock, to: AnyObject.self)
        return try hook(selector: selector, strategy: strategy, block: wrappedObject)
    }

    func hook<Arg1, Arg2, Arg3, Arg4>(
        selector: Selector,
        strategy: AspectStrategy = .before,
        block: @escaping(AspectInfo, Arg1, Arg2, Arg3, Arg4) -> Void) throws -> AspectToken
    {
        let wrappedBlock: @convention(block) (AspectInfo) -> Void = { aspectInfo in
            guard aspectInfo.arguments.count == 4,
                let arg1 = aspectInfo.arguments[0] as? Arg1,
                let arg2 = aspectInfo.arguments[1] as? Arg2,
                let arg3 = aspectInfo.arguments[2] as? Arg3,
                let arg4 = aspectInfo.arguments[3] as? Arg4 else { return }
            block(aspectInfo, arg1, arg2, arg3, arg4)
        }

        let wrappedObject: AnyObject = unsafeBitCast(wrappedBlock, to: AnyObject.self)
        return try hook(selector: selector, strategy: strategy, block: wrappedObject)
    }

    func hook<Arg1, Arg2, Arg3, Arg4, Arg5>(
        selector: Selector,
        strategy: AspectStrategy = .before,
        block: @escaping(AspectInfo, Arg1, Arg2, Arg3, Arg4, Arg5) -> Void) throws -> AspectToken
    {
        let wrappedBlock: @convention(block) (AspectInfo) -> Void = { aspectInfo in
            guard aspectInfo.arguments.count == 5,
                let arg1 = aspectInfo.arguments[0] as? Arg1,
                let arg2 = aspectInfo.arguments[1] as? Arg2,
                let arg3 = aspectInfo.arguments[2] as? Arg3,
                let arg4 = aspectInfo.arguments[3] as? Arg4,
                let arg5 = aspectInfo.arguments[4] as? Arg5 else {
                    return
            }
            block(aspectInfo, arg1, arg2, arg3, arg4, arg5)
        }

        let wrappedObject: AnyObject = unsafeBitCast(wrappedBlock, to: AnyObject.self)
        return try hook(selector: selector, strategy: strategy, block: wrappedObject)
    }

    func hook<Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(
        selector: Selector,
        strategy: AspectStrategy = .before,
        block: @escaping(AspectInfo, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) -> Void) throws -> AspectToken
    {
        let wrappedBlock: @convention(block) (AspectInfo) -> Void = { aspectInfo in
            guard aspectInfo.arguments.count == 6,
                let arg1 = aspectInfo.arguments[0] as? Arg1,
                let arg2 = aspectInfo.arguments[1] as? Arg2,
                let arg3 = aspectInfo.arguments[2] as? Arg3,
                let arg4 = aspectInfo.arguments[3] as? Arg4,
                let arg5 = aspectInfo.arguments[4] as? Arg5,
                let arg6 = aspectInfo.arguments[5] as? Arg6 else {
                    return
            }
            block(aspectInfo, arg1, arg2, arg3, arg4, arg5, arg6)
        }

        let wrappedObject: AnyObject = unsafeBitCast(wrappedBlock, to: AnyObject.self)
        return try hook(selector: selector, strategy: strategy, block: wrappedObject)
    }

    func hook<Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7>(
        selector: Selector,
        strategy: AspectStrategy = .before,
        block: @escaping(AspectInfo, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7) -> Void) throws -> AspectToken
    {
        let wrappedBlock: @convention(block) (AspectInfo) -> Void = { aspectInfo in
            guard aspectInfo.arguments.count == 7,
                let arg1 = aspectInfo.arguments[0] as? Arg1,
                let arg2 = aspectInfo.arguments[1] as? Arg2,
                let arg3 = aspectInfo.arguments[2] as? Arg3,
                let arg4 = aspectInfo.arguments[3] as? Arg4,
                let arg5 = aspectInfo.arguments[4] as? Arg5,
                let arg6 = aspectInfo.arguments[5] as? Arg6,
                let arg7 = aspectInfo.arguments[6] as? Arg7 else {
                    return
            }
            block(aspectInfo, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
        }

        let wrappedObject: AnyObject = unsafeBitCast(wrappedBlock, to: AnyObject.self)
        return try hook(selector: selector, strategy: strategy, block: wrappedObject)
    }
}

public extension NSObject {

    class func hook(
        selector: Selector,
        strategy: AspectStrategy = .before,
        block: @escaping(AspectInfo) -> Void) throws -> AspectToken
    {
        let wrappedBlock: @convention(block) (AspectInfo) -> Void = { aspectInfo in
            block(aspectInfo)
        }

        let wrappedObject: AnyObject = unsafeBitCast(wrappedBlock, to: AnyObject.self)
        return try hook(selector: selector, strategy: strategy, block: wrappedObject)
    }

    class func hook<Arg1>(
        selector: Selector,
        strategy: AspectStrategy = .before,
        block: @escaping(AspectInfo, Arg1) -> Void) throws -> AspectToken
    {
        let wrappedBlock: @convention(block) (AspectInfo) -> Void = { aspectInfo in
            guard aspectInfo.arguments.count == 1,
                let arg1 = aspectInfo.arguments[0] as? Arg1 else { return }
            block(aspectInfo, arg1)
        }

        let wrappedObject: AnyObject = unsafeBitCast(wrappedBlock, to: AnyObject.self)
        return try hook(selector: selector, strategy: strategy, block: wrappedObject)
    }

    class func hook<Arg1, Arg2>(
        selector: Selector,
        strategy: AspectStrategy = .before,
        block: @escaping(AspectInfo, Arg1, Arg2) -> Void) throws -> AspectToken
    {
        let wrappedBlock: @convention(block) (AspectInfo) -> Void = { aspectInfo in
            guard aspectInfo.arguments.count == 2,
                let arg1 = aspectInfo.arguments[0] as? Arg1,
                let arg2 = aspectInfo.arguments[1] as? Arg2 else { return }
            block(aspectInfo, arg1, arg2)
        }

        let wrappedObject: AnyObject = unsafeBitCast(wrappedBlock, to: AnyObject.self)
        return try hook(selector: selector, strategy: strategy, block: wrappedObject)
    }

    class func hook<Arg1, Arg2, Arg3>(
        selector: Selector,
        strategy: AspectStrategy = .before,
        block: @escaping(AspectInfo, Arg1, Arg2, Arg3) -> Void) throws -> AspectToken
    {
        let wrappedBlock: @convention(block) (AspectInfo) -> Void = { aspectInfo in
            guard aspectInfo.arguments.count == 3,
                let arg1 = aspectInfo.arguments[0] as? Arg1,
                let arg2 = aspectInfo.arguments[1] as? Arg2,
                let arg3 = aspectInfo.arguments[2] as? Arg3 else { return }
            block(aspectInfo, arg1, arg2, arg3)
        }

        let wrappedObject: AnyObject = unsafeBitCast(wrappedBlock, to: AnyObject.self)
        return try hook(selector: selector, strategy: strategy, block: wrappedObject)
    }

    class func hook<Arg1, Arg2, Arg3, Arg4>(
        selector: Selector,
        strategy: AspectStrategy = .before,
        block: @escaping(AspectInfo, Arg1, Arg2, Arg3, Arg4) -> Void) throws -> AspectToken
    {
        let wrappedBlock: @convention(block) (AspectInfo) -> Void = { aspectInfo in
            guard aspectInfo.arguments.count == 4,
                let arg1 = aspectInfo.arguments[0] as? Arg1,
                let arg2 = aspectInfo.arguments[1] as? Arg2,
                let arg3 = aspectInfo.arguments[2] as? Arg3,
                let arg4 = aspectInfo.arguments[3] as? Arg4 else { return }
            block(aspectInfo, arg1, arg2, arg3, arg4)
        }

        let wrappedObject: AnyObject = unsafeBitCast(wrappedBlock, to: AnyObject.self)
        return try hook(selector: selector, strategy: strategy, block: wrappedObject)
    }

    class func hook<Arg1, Arg2, Arg3, Arg4, Arg5>(
        selector: Selector,
        strategy: AspectStrategy = .before,
        block: @escaping(AspectInfo, Arg1, Arg2, Arg3, Arg4, Arg5) -> Void) throws -> AspectToken
    {
        let wrappedBlock: @convention(block) (AspectInfo) -> Void = { aspectInfo in
            guard aspectInfo.arguments.count == 5,
                let arg1 = aspectInfo.arguments[0] as? Arg1,
                let arg2 = aspectInfo.arguments[1] as? Arg2,
                let arg3 = aspectInfo.arguments[2] as? Arg3,
                let arg4 = aspectInfo.arguments[3] as? Arg4,
                let arg5 = aspectInfo.arguments[4] as? Arg5 else {
                    return
            }
            block(aspectInfo, arg1, arg2, arg3, arg4, arg5)
        }

        let wrappedObject: AnyObject = unsafeBitCast(wrappedBlock, to: AnyObject.self)
        return try hook(selector: selector, strategy: strategy, block: wrappedObject)
    }

    class func hook<Arg1, Arg2, Arg3, Arg4, Arg5, Arg6>(
        selector: Selector,
        strategy: AspectStrategy = .before,
        block: @escaping(AspectInfo, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) -> Void) throws -> AspectToken
    {
        let wrappedBlock: @convention(block) (AspectInfo) -> Void = { aspectInfo in
            guard aspectInfo.arguments.count == 6,
                let arg1 = aspectInfo.arguments[0] as? Arg1,
                let arg2 = aspectInfo.arguments[1] as? Arg2,
                let arg3 = aspectInfo.arguments[2] as? Arg3,
                let arg4 = aspectInfo.arguments[3] as? Arg4,
                let arg5 = aspectInfo.arguments[4] as? Arg5,
                let arg6 = aspectInfo.arguments[5] as? Arg6 else {
                    return
            }
            block(aspectInfo, arg1, arg2, arg3, arg4, arg5, arg6)
        }

        let wrappedObject: AnyObject = unsafeBitCast(wrappedBlock, to: AnyObject.self)
        return try hook(selector: selector, strategy: strategy, block: wrappedObject)
    }

    class func hook<Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7>(
        selector: Selector,
        strategy: AspectStrategy = .before,
        block: @escaping(AspectInfo, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7) -> Void) throws -> AspectToken
    {
        let wrappedBlock: @convention(block) (AspectInfo) -> Void = { aspectInfo in
            guard aspectInfo.arguments.count == 7,
                let arg1 = aspectInfo.arguments[0] as? Arg1,
                let arg2 = aspectInfo.arguments[1] as? Arg2,
                let arg3 = aspectInfo.arguments[2] as? Arg3,
                let arg4 = aspectInfo.arguments[3] as? Arg4,
                let arg5 = aspectInfo.arguments[4] as? Arg5,
                let arg6 = aspectInfo.arguments[5] as? Arg6,
                let arg7 = aspectInfo.arguments[6] as? Arg7 else {
                    return
            }
            block(aspectInfo, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
        }

        let wrappedObject: AnyObject = unsafeBitCast(wrappedBlock, to: AnyObject.self)
        return try hook(selector: selector, strategy: strategy, block: wrappedObject)
    }
}
