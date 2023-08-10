//  
//  Created by Diney Bomfim on 5/2/23.
//

import Foundation

// MARK: - Definitions -

/// Basic floating point data type.
public typealias FPoint = Double

public extension Constant {
	
	/// A single color unit from RGBA format in the range [0.0, 1.0].
	static let colorUnit: FPoint = 1.0 / 255.0
	
	/// The value of PI.
	static let pi: FPoint = 3.141592
	
	/// The value of 2 * PI.
	static let piDouble: FPoint = 6.283184
	
	/// The value of PI / 2.
	static let piHalf: FPoint = 1.570796
	
	/// Pre-calculated value of PI / 180. It's used to convert degrees to radians.
	static let piOver180: FPoint = 0.017453
	
	/// Pre-calculated value of 180 / PI. It's used to convert radians to degrees.
	static let piUnder180: FPoint = 57.295780
}

// MARK: - Extension - Float

public extension FPoint {
	
	/// Converts the current number to radians (N * pi / 180), assuming it's in degrees.
	var radians: Self { self * Constant.piOver180 }
	
	/// Converts the current number to degrees (N * 180 / pi), assuming it's in radians.
	var degrees: Self { self * Constant.piUnder180 }
	
	/// Finds and returns the closets element in an array to the original number.
	///
	/// - Parameter numbers: An array of numbers.
	/// - Returns: The closest element to the original number.
	func closest(to numbers: [Self]) -> Self {
		
		var closest = Self(0)
		var min = Self(Int.max)
			
		numbers.forEach { number in
			let distance = abs(distance(to: number))
			if distance < min {
				min = distance
				closest = number
			}
		}
		
		return closest
	}
}

// MARK: - Extension - ClosedRange

public extension ClosedRange {
	
	/// Clamps a value to the given range. Values above or bellow will be clamped to its bounds.
	/// The value itself if inside the range, or the lower bound if bellow the range, or the upper bound if above the range.
	///
	/// - Parameter value: A value to be clamped.
	/// - Returns: The final result.
	func clamped(_ value: Bound) -> Bound { Swift.min(upperBound, Swift.max(lowerBound, value)) }
	
	/// Loops a value inside a range with stops at the bounds.
	/// The value itself if inside the range, or the upper bound if bellow the range, or the lower bound if above the range.
	///
	/// - Parameter value: A value to be clamped.
	/// - Returns: The final result.
	func looped(_ value: Bound) -> Bound { value < lowerBound ? upperBound : (value > upperBound ? lowerBound : value) }
}

public extension ClosedRange where Bound == CGFloat {
	
	/// Converts a value within the range to a percentage based on its position relative to the lower and upper bounds.
	///
	/// - Parameters:
	///   - value: The value within the range.
	///   - normalizeBelow: A threshold value below which the result is considered as 0 (optional, default is 0.001).
	/// - Returns: The percentage value of the input value within the range.
	func percent(_ value: Bound, normalizeBelow: CGFloat = 0.001) -> Bound {
		let percent = (clamped(value) - lowerBound) / (upperBound - lowerBound)
		return percent > normalizeBelow ? percent : 0
	}
	
	/// Converts a percentage value to the corresponding value within the range.
	///
	/// - Parameter percent: The percentage value.
	/// - Returns: The value within the range corresponding to the given percentage.
	func value(from percent: CGFloat) -> Bound {
		lowerBound + ((upperBound - lowerBound) * percent)
	}
}

// MARK: - Extension - CGPoint

public extension CGPoint {
	static func + (lhs: Self, rhs: Self) -> Self { .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
	static func - (lhs: Self, rhs: Self) -> Self { .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
}

// MARK: - Extension - CGSize

public extension CGSize {
	
	/// The size where width and height are both set to the minimum of the original width and height.
	var squared: CGSize { .init(squared: min(width, height)) }
	
	/// The size where width and height are both set to the maximum of the original width and height.
	var squaredByMax: CGSize { .init(squared: max(width, height)) }
	
	/// The size halved by dividing both width and height by 2.
	var half: CGSize { self * 0.5 }
	
	/// The size represented as a `CGPoint` where `x` is the width and `y` is the height.
	var point: CGPoint { .init(x: width, y: height) }
	
	/// Initializes a square `CGSize` with equal width and height.
	///
	/// - Parameter squared: The length of the sides of the square.
	init(squared: CGFloat) { self.init(width: squared, height: squared) }
	
	static func + (lhs: Self, rhs: Self) -> Self { .init(width: lhs.width + rhs.width, height: lhs.height + rhs.height) }
	static func - (lhs: Self, rhs: Self) -> Self { .init(width: lhs.width - rhs.width, height: lhs.height - rhs.height) }
	static func * (lhs: Self, rhs: CGFloat) -> Self { .init(width: lhs.width * rhs, height: lhs.height * rhs) }
	static func / (lhs: Self, rhs: CGFloat) -> Self { .init(width: lhs.width / rhs, height: lhs.height / rhs) }
}

// MARK: - Extension - CGRect

public extension CGRect {
	
	init(size: CGSize) {
		self.init(origin: .zero, size: size)
	}
	
	init(width: CGFloat, height: CGFloat) {
		self.init(origin: .zero, size: .init(width: width, height: height))
	}
	
//	/// Similar to `insetBy` but safer, this function avoids resulting in negative size.
//	/// - Parameters:
//	///   - dx: The X axis insets on both sides.
//	///   - dy: The Y axis insets on both sides.
//	/// - Returns: A new `CGRect`.
//	func insetSafelyBy(dx: CGFloat, dy: CGFloat) -> CGRect {
//		let normalizedX = dx * 2 > size.width ? 0 : dx
//		let normalizedY = dy * 2 > size.height ? 0 : dy
//		return insetBy(dx: normalizedX, dy: normalizedY)
//	}
//	
//	/// Returns a new `CGRect` by expanding the edges of the current `CGRect` with a given criteria.
//	///
//	/// - Parameters:
//	///   - top: The top expansion.
//	///   - left: The left expansion.
//	///   - bottom: The bottom expansion.
//	///   - right: The right expansion.
//	/// - Returns: A new `CGRect`.
//	func expandBy(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) -> CGRect {
//		let newOrigin = CGPoint(x: origin.x - left, y: origin.y - top)
//		let newSize = CGSize(width: width + right + left, height: height + bottom + top)
//		return .init(origin: newOrigin, size: newSize)
//	}
}
