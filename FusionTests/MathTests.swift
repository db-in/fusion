//
//  Created by Diney Bomfim on 5/27/23.
//

import XCTest
@testable import Fusion

// MARK: - Definitions -

// MARK: - Type -

class MathTests: XCTestCase {

// MARK: - Properties

// MARK: - Constructors

// MARK: - Protected Methods

// MARK: - Exposed Methods
	
	func testRadians_WhenConvertingToRadians_ShouldReturnCorrectValue() {
		let degrees: FPoint = 90.0
		let radians = degrees.radians
		XCTAssertEqual(radians, 1.5707963267948966, accuracy: 0.0001)
	}
	
	func testDegrees_WhenConvertingToDegrees_ShouldReturnCorrectValue() {
		let radians: FPoint = 1.5707963267948966
		let degrees = radians.degrees
		XCTAssertEqual(degrees, 90.0, accuracy: 0.00001)
	}
	
	func testClosest_WhenFindingClosestNumberInArray_ShouldReturnClosestElement() {
		let numbers: [FPoint] = [10.0, 20.0, 30.0, 40.0, 50.0]
		let numberToFind: FPoint = 25.0
		let closest = numberToFind.closest(to: numbers)
		XCTAssertEqual(closest, 20.0)
	}
	
	func testClamped_WhenClampingValueToRange_ShouldReturnClampedValue() {
		let range: ClosedRange<FPoint> = 10.0...20.0
		let value: FPoint = 5.0
		let clampedValue = range.clamped(value)
		XCTAssertEqual(clampedValue, 10.0)
	}
	
	func testLooped_WhenLoopingValueInRange_ShouldReturnLoopedValue() {
		let range: ClosedRange<FPoint> = 10.0...20.0
		let value: FPoint = 25.0
		let loopedValue = range.looped(value)
		XCTAssertEqual(loopedValue, 10.0)
	}
}
