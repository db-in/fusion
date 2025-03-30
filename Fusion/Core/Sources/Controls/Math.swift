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

// MARK: - Extension - FloatingPoint

public extension FloatingPoint {
	
	/// Returns 0 if the value is not a number.
	var zeroIfNaN: Self { isNaN ? 0 : self }
	
	/// Returns the number securely inside the range of finite numbers.
	var finite: Self { isFinite ? self : min(max(zeroIfNaN, .leastNormalMagnitude), .greatestFiniteMagnitude) }
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

@available(macOS 11, iOS 13, watchOS 7, tvOS 13, *)
public extension CGPoint {
	
	/// Calculates the cross product of two points.
	static func * (lhs: Self, rhs: Self) -> CGFloat { lhs.x * rhs.y - lhs.y * rhs.x }
	
	/// Adds two points component-wise.
	static func + (lhs: Self, rhs: Self) -> Self { .init(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
	
	/// Subtracts two points component-wise.
	static func - (lhs: Self, rhs: Self) -> Self { .init(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
}

// MARK: - Extension - CGSize

public extension CGSize {
	
	/// The size where width and height are both set to the minimum of the original width and height.
	var squared: CGSize { .init(squared: min(width, height)) }
	
	/// The size where width and height are both set to the maximum of the original width and height.
	var squaredByMax: CGSize { .init(squared: max(width, height)) }
	
	/// Returns a new size where the curernt height is the minimum value for the width as well. Use for horizontal capsule/pill shapes.
	var heightAsMinimum: CGSize { width < height ? CGSize(width: height, height: height) : self }
	
	/// Returns a new size where the curernt width is the minimum value for the height as well. Use for vertical capsule/pill shapes.
	var widthAsMinimum: CGSize { height < width ? CGSize(width: width, height: width) : self }
	
	/// The size halved by dividing both width and height by 2.
	var half: CGSize { self * 0.5 }
	
	/// The size represented as a `CGPoint` where `x` is the width and `y` is the height.
	var point: CGPoint { .init(x: width, y: height) }
	
	/// Initializes a square `CGSize` with equal width and height.
	///
	/// - Parameter squared: The length of the sides of the square.
	init(squared: CGFloat) { self.init(width: squared, height: squared) }
	
	/// Scales the size proportionally based on the specified width or height.
	///
	/// - Parameters:
	///   - width: The target width. If provided without `height`, the height is scaled proportionally.
	///   - height: The target height. If provided without `width`, the width is scaled proportionally.
	/// - Returns: A new `CGSize` with the adjusted dimensions.
	func rescaled(width: CGFloat? = nil, height: CGFloat? = nil) -> CGSize {
		if let w = width { return .init(width: w, height: height ?? self.height * (w / self.width)) }
		if let h = height { return .init(width: self.width * (h / self.height), height: h) }
		return self
	}
	
	/// Returns a new size by expanding the current size.
	///
	/// - Parameters:
	///   - width: The delta width.
	///   - height: The delta height.
	/// - Returns: The new size.
	func expanded(width: CGFloat = 0, height: CGFloat = 0) -> CGSize { self + .init(width: width, height: height) }
	
	/// Expands the current size by a given width and height.
	///
	/// - Parameters:
	///   - width: The delta expansion.
	///   - height: The delta height.
	mutating func expand(width: CGFloat = 0, height: CGFloat = 0) {
		self.width += width
		self.height += height
	}
	
	static func + (lhs: Self, rhs: Self) -> Self { .init(width: lhs.width + rhs.width, height: lhs.height + rhs.height) }
	static func - (lhs: Self, rhs: Self) -> Self { .init(width: lhs.width - rhs.width, height: lhs.height - rhs.height) }
	static func * (lhs: Self, rhs: CGFloat) -> Self { .init(width: lhs.width * rhs, height: lhs.height * rhs) }
	static func / (lhs: Self, rhs: CGFloat) -> Self { .init(width: lhs.width / rhs, height: lhs.height / rhs) }
}

// MARK: - Extension - CGRect

public extension CGRect {
	
	var finite: Self {
		.init(origin: .init(x: origin.x.finite, y: origin.y.finite), size: .init(width: size.width.finite, height: size.height.finite))
	}
	
	init(size: CGSize) {
		self.init(origin: .init(x: 0, y: 0), size: size)
	}
	
	init(width: CGFloat, height: CGFloat) {
		self.init(origin: .init(x: 0, y: 0), size: .init(width: width, height: height))
	}
	
	/// Scales the rectangle proportionally based on the specified width or height.
	///
	/// - Parameters:
	///   - width: The target width. If provided without `height`, the height is scaled proportionally.
	///   - height: The target height. If provided without `width`, the width is scaled proportionally.
	/// - Returns: A new `CGRect` with the scaled size while maintaining the original origin.
	func rescaled(width: CGFloat? = nil, height: CGFloat? = nil) -> CGRect {
		.init(origin: origin, size: size.rescaled(width: width, height: height))
	}
}
