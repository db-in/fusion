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
