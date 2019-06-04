//
//  AspectBlock.swift
//  Aspect
//
//  This is the original copyright notice:
//  Copyright © 2017 Brandon. All rights reserved.

import Foundation

// Block internals.
internal class AspectBlock {

    private let block: AnyObject

    init(_ block: AnyObject) {
        self.block = block
    }

    var blockSignature: AnyObject? {
        return self.signature != nil ? NSMethodSignature.signature(objCTypes: self.signature!) : nil
    }

    private var signature: String? {
        let block = unsafeBitCast(self.block, to: UnsafePointer<BlockInfo>.self).pointee
        let descriptor = block.descriptor.pointee

        let signatureFlag: UInt32 = 1 << 30

        if block.flags & signatureFlag != 0 {
            let signature = String(cString: descriptor.signature)
            return signature
        }
        return nil
    }

    private struct BlockInfo {
        var isa: UnsafeRawPointer
        var flags: UInt32
        var reserved: UInt32
        var invoke: UnsafeRawPointer
        var descriptor: UnsafePointer<BlockDescriptor>
    }

    private struct BlockDescriptor {
        var reserved: UInt
        var size: UInt

        var copy_helper: UnsafeRawPointer
        var dispose_helper: UnsafeRawPointer
        var signature: UnsafePointer<Int8>
    }
}
