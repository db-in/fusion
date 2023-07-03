//  
//  Created by Diney Bomfim on 5/1/23.
//

import Foundation

// MARK: - Definitions -

public struct Constant { }

// MARK: - Extension - Constant DataType

public extension Constant {
	
	static let null: UInt32 = 0x00
	static let float: UInt32 = 0x01
	static let int: UInt32 = 0x02
	static let bool: UInt32 = 0x03
	static let vec2: UInt32 = 0x04
	static let vec3: UInt32 = 0x05
	static let vec4: UInt32 = 0x06
	static let ivec2: UInt32 = 0x07
	static let ivec3: UInt32 = 0x08
	static let ivec4: UInt32 = 0x09
	static let bvec2: UInt32 = 0x0A
	static let bvec3: UInt32 = 0x0B
	static let bvec4: UInt32 = 0x0C
	static let mat2: UInt32 = 0x0D
	static let mat3: UInt32 = 0x0E
	static let mat4: UInt32 = 0x0F
	static let sampler2D: UInt32 = 0x10
	static let samplerCube: UInt32 = 0x11
	static let blankChar: Character = " "
}

// MARK: - Extension - Constant Size

public extension Constant {
	
	static let sizePointer: Int = MemoryLayout<UnsafeRawPointer>.size
	static let sizeFloat: Int = MemoryLayout<Float>.size
	static let sizeInt: Int = MemoryLayout<Int32>.size
	static let sizeUInt: Int = MemoryLayout<UInt32>.size
	static let sizeShort: Int = MemoryLayout<Int16>.size
	static let sizeUShort: Int = MemoryLayout<UInt16>.size
	static let sizeChar: Int = MemoryLayout<Int8>.size
	static let sizeUChar: Int = MemoryLayout<UInt8>.size
	static let sizeBool: Int = MemoryLayout<Bool>.size
	static let sizeVec2: Int = sizeFloat * 2
	static let sizeVec3: Int = sizeFloat * 3
	static let sizeVec4: Int = sizeFloat * 4
	static let sizeIVec2: Int = sizeInt * 2
	static let sizeIVec3: Int = sizeInt * 3
	static let sizeIVec4: Int = sizeInt * 4
	static let sizeBVec2: Int = sizeBool * 2
	static let sizeBVec3: Int = sizeBool * 3
	static let sizeBVec4: Int = sizeBool * 4
	static let sizeMat2: Int = sizeFloat * 4
	static let sizeMat3: Int = sizeFloat * 9
	static let sizeMat4: Int = sizeFloat * 16
	static let sizeBox: Int = sizeVec3 * 8
}

// MARK: - Extension - Constant Limits

public extension Constant {
	
	static let max8: UInt = UInt(UInt8.max)
	static let max16: UInt = UInt(UInt16.max)
	static let max32: UInt = UInt(UInt32.max)
	static let max64: UInt = UInt(UInt64.max)
	static let notFound: UInt = max32
}

// MARK: - Extension - Constant Timing

public extension Constant {
	
	static let duration: TimeInterval = 0.33
	static let maxFps: FPoint = 60.0
	static let cycle: FPoint = 1.0 / maxFps
	static let cycleUsec: UInt64 = UInt64(cycle * 1000000.0)
	static let cycleNsec: UInt64 = UInt64(cycle * 1000000000.0)
}

// MARK: - Extension - Constant Mode

public extension Constant {
#if DEBUG
	static let isDebug: Bool = true
#else
	static let isDebug: Bool = false
#endif
}
