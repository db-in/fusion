//
//  Created by Diney Bomfim on 5/27/23.
//

import Foundation
import Testing
@testable import Fusion

// MARK: - Definitions -

// MARK: - Type -

@Suite
struct MathTests {
	
// MARK: - Exposed Methods
	
	@Test
	func radians_WhenConvertingToRadians_ShouldReturnCorrectValue() {
		let degrees: FPoint = 90.0
		let radians = degrees.radians
		#expect(abs(radians - 1.5707963267948966) <= 0.0001)
	}
	
	@Test
	func degrees_WhenConvertingToDegrees_ShouldReturnCorrectValue() {
		let radians: FPoint = 1.5707963267948966
		let degrees = radians.degrees
		#expect(abs(degrees - 90.0) <= 0.00001)
	}
	
	@Test
	func closest_WhenFindingClosestNumberInArray_ShouldReturnClosestElement() {
		let numbers: [FPoint] = [10.0, 20.0, 30.0, 40.0, 50.0]
		let numberToFind: FPoint = 25.0
		let closest = numberToFind.closest(to: numbers)
		#expect(closest == 20.0)
	}
	
	@Test
	func clamped_WhenClampingValueToRange_ShouldReturnClampedValue() {
		let range: ClosedRange<FPoint> = 10.0...20.0
		let value: FPoint = 5.0
		let clampedValue = range.clamped(value)
		#expect(clampedValue == 10.0)
	}
	
	@Test
	func looped_WhenLoopingValueInRange_ShouldReturnLoopedValue() {
		let range: ClosedRange<FPoint> = 10.0...20.0
		let value: FPoint = 25.0
		let loopedValue = range.looped(value)
		#expect(loopedValue == 10.0)
	}
}
