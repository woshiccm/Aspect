//
//  Runtime.swift
//  Aspect
//
//  This is the original copyright notice:
//  Copyright ReactiveCocoa. All rights reserved.

import Foundation

// Unavailable selectors in Swift.
internal enum ObjCSelector {
    static let forwardInvocation = Selector((("forwardInvocation:")))
    static let methodSignatureForSelector = Selector((("methodSignatureForSelector:")))
    static let getClass = Selector((("class")))
}

// Method encoding of the unavailable selectors.
internal enum ObjCMethodEncoding {
    static let forwardInvocation = extract("v@:@")
    static let methodSignatureForSelector = extract("v@::")
    static let getClass = extract("#@:")

    private static func extract(_ string: StaticString) -> UnsafePointer<CChar> {
        return UnsafeRawPointer(string.utf8Start).assumingMemoryBound(to: CChar.self)
    }
}

internal let NSInvocation: AnyClass = NSClassFromString("NSInvocation")!
internal let NSMethodSignature: AnyClass = NSClassFromString("NSMethodSignature")!

// Signatures defined in `@objc` protocols would be available for ObjC message, sending via `AnyObject`.
@objc internal protocol ObjCClassReporting {
    // An alias for `-class`, which is unavailable in Swift.
    @objc(class)
    var objcClass: AnyClass! { get }

    @objc(methodSignatureForSelector:)
    func objcMethodSignature(for selector: Selector) -> AnyObject
}

// Methods of `NSInvocation`.
@objc internal protocol ObjCInvocation {
    @objc(setSelector:)
    func setSelector(_ selector: Selector)

    @objc(target)
    var objcTarget: AnyObject { get }

    @objc(methodSignature)
    var objcMethodSignature: AnyObject { get }

    @objc(getArgument:atIndex:)
    func getArgument(_ argumentLocation: UnsafeMutableRawPointer, atIndex idx: Int)

    @objc(setArgument:atIndex:)
    func setArgument(_ argumentLocation: UnsafeMutableRawPointer, atIndex idx: Int)

    @objc(invoke)
    func invoke()

    @objc(invokeWithTarget:)
    func invoke(target: AnyObject)

    @objc(invocationWithMethodSignature:)
    static func invocation(methodSignature: AnyObject) -> AnyObject
}

// Methods of `NSMethodSignature`.
@objc internal protocol ObjCMethodSignature {
    @objc(numberOfArguments)
    var objcNumberOfArguments: UInt { get }

    @objc(getArgumentTypeAtIndex:)
    func getArgumentType(at index: UInt) -> UnsafePointer<CChar>

    @objc(signatureWithObjCTypes:)
    static func signature(objCTypes: UnsafePointer<CChar>) -> AnyObject
}

/// Objective-C type encoding.
///
/// The enum does not cover all options, but only those that are expressive in
/// Swift.
internal enum ObjCTypeEncoding: Int8 {
    case char = 99
    case int = 105
    case short = 115
    case long = 108
    case longLong = 113

    case unsignedChar = 67
    case unsignedInt = 73
    case unsignedShort = 83
    case unsignedLong = 76
    case unsignedLongLong = 81

    case float = 102
    case double = 100

    case bool = 66

    case object = 64
    case type = 35
    case selector = 58

    case undefined = -1
}

internal func unpackInvocation(_ invocation: AnyObject) -> [Any?] {
    let invocation = invocation as AnyObject
    let methodSignature = invocation.objcMethodSignature!
    let count = methodSignature.objcNumberOfArguments!

    var bridged = [Any?]()
    bridged.reserveCapacity(Int(count - 2))

    // Ignore `self` and `_cmd` at index 0 and 1.
    for position in 2 ..< count {
        let rawEncoding = methodSignature.getArgumentType(at: position)
        let encoding = ObjCTypeEncoding(rawValue: rawEncoding.pointee) ?? .undefined

        func extract<U>(_ type: U.Type) -> U {
            let pointer = UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<U>.size,
                                                           alignment: MemoryLayout<U>.alignment)
            defer {
                pointer.deallocate()
            }

            invocation.getArgument(pointer, atIndex: Int(position))
            return pointer.assumingMemoryBound(to: type).pointee
        }

        let value: Any?

        switch encoding {
        case .char:
            value = NSNumber(value: extract(CChar.self))
        case .int:
            value = NSNumber(value: extract(CInt.self))
        case .short:
            value = NSNumber(value: extract(CShort.self))
        case .long:
            value = NSNumber(value: extract(CLong.self))
        case .longLong:
            value = NSNumber(value: extract(CLongLong.self))
        case .unsignedChar:
            value = NSNumber(value: extract(CUnsignedChar.self))
        case .unsignedInt:
            value = NSNumber(value: extract(CUnsignedInt.self))
        case .unsignedShort:
            value = NSNumber(value: extract(CUnsignedShort.self))
        case .unsignedLong:
            value = NSNumber(value: extract(CUnsignedLong.self))
        case .unsignedLongLong:
            value = NSNumber(value: extract(CUnsignedLongLong.self))
        case .float:
            value = NSNumber(value: extract(CFloat.self))
        case .double:
            value = NSNumber(value: extract(CDouble.self))
        case .bool:
            value = NSNumber(value: extract(CBool.self))
        case .object:
            value = extract((AnyObject?).self)
        case .type:
            value = extract((AnyClass?).self)
        case .selector:
            value = extract((Selector?).self)
        case .undefined:
            var size = 0, alignment = 0
            NSGetSizeAndAlignment(rawEncoding, &size, &alignment)
            let buffer = UnsafeMutableRawPointer.allocate(byteCount: size, alignment: alignment)
            defer { buffer.deallocate() }

            invocation.getArgument(buffer, atIndex: Int(position))
            value = NSValue(bytes: buffer, objCType: rawEncoding)
        }

        bridged.append(value)
    }

    return bridged
}

extension Selector {

    internal var utf8Start: UnsafePointer<Int8> {
        return unsafeBitCast(self, to: UnsafePointer<Int8>.self)
    }

    /// An alias of `self`, used in method interception.
    internal var alias: Selector {
        return prefixing("aspect_")
    }

    internal func prefixing(_ prefix: StaticString) -> Selector {
        let length = Int(strlen(utf8Start))
        let prefixedLength = length + prefix.utf8CodeUnitCount

        let asciiPrefix = UnsafeRawPointer(prefix.utf8Start).assumingMemoryBound(to: Int8.self)

        let cString = UnsafeMutablePointer<Int8>.allocate(capacity: prefixedLength + 1)
        defer {
            cString.deinitialize(count: prefixedLength + 1)
            cString.deallocate()
        }

        cString.initialize(from: asciiPrefix, count: prefix.utf8CodeUnitCount)
        (cString + prefix.utf8CodeUnitCount).initialize(from: utf8Start, count: length)
        (cString + prefixedLength).initialize(to: Int8(UInt8(ascii: "\0")))

        return sel_registerName(cString)
    }
}

internal func checkTypeEncoding(_ types: UnsafePointer<CChar>) -> Bool {
    // Some types, including vector types, are not encoded. In these cases the
    // signature starts with the size of the argument frame.
    assert(types.pointee < Int8(UInt8(ascii: "1")) || types.pointee > Int8(UInt8(ascii: "9")),
           "unknown method return type not supported in type encoding: \(String(cString: types))")

    assert(types.pointee != Int8(UInt8(ascii: "(")), "union method return type not supported")
    assert(types.pointee != Int8(UInt8(ascii: "{")), "struct method return type not supported")
    assert(types.pointee != Int8(UInt8(ascii: "[")), "array method return type not supported")

    assert(types.pointee != Int8(UInt8(ascii: "j")), "complex method return type not supported")

    return true
}
