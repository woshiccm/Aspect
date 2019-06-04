//
//  Lock.swift
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

internal protocol Lock {
    func lock()
    func unlock()
}

@available(iOS 10.0, OSX 10.12, watchOS 3.0, tvOS 10.0, *)
internal class UnfairLock: Lock {
    private var unfairLock = os_unfair_lock_s()

    func lock() {
        os_unfair_lock_lock(&unfairLock)
    }

    func unlock() {
        os_unfair_lock_unlock(&unfairLock)
    }
}

internal class MutexLock: Lock {
    private var mutex = NSLock()

    func lock() {
        mutex.lock()
    }

    func unlock() {
        mutex.unlock()
    }
}

internal class SpinLock: Lock {
    private let locker: Lock

    init() {
        if #available(iOS 10.0, macOS 10.12, watchOS 3.0, tvOS 10.0, *) {
            locker = UnfairLock()
        } else {
            locker = MutexLock()
        }
    }

    func lock() {
        locker.lock()
    }

    func unlock() {
        locker.unlock()
    }
}

internal extension SpinLock {

    @inline(__always)
    final func performLocked(_ action: () -> Void) {
        lock(); defer { unlock() }
        action()
    }
}
