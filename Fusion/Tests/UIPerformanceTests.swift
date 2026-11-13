//
//  Created by Diney Bomfim on 11/13/26.
//

#if canImport(UIKit) && !os(watchOS)
import XCTest
import UIKit
@testable import Fusion

// MARK: - Type -

final class UIPerformanceTests : PerformanceTestCase {
	
// MARK: - Properties
	
	private let base = UIImage.solid(color: .systemBlue, size: .init(width: 128, height: 128))
	
	private let font = UIFont.systemFont(ofSize: 15)
	
// MARK: - Colors
	
	func testColorInterpolation() {
		measureLoop { _ = UIColor.red.interpolated(toColor: .blue, percentage: CGFloat($0 % 100) / 100) }
	}
	
	func testColorDarker() {
		measureLoop { _ = UIColor.systemTeal.darker(by: CGFloat($0 % 50) / 100) }
	}
	
// MARK: - Images
	
	func testSolidImage32() {
		measureLoop(iterations: 200) { _ in _ = UIImage.solid(color: .systemRed, size: .init(width: 32, height: 32)) }
	}
	
	func testTintedImage128() {
		let image = base
		measureLoop(iterations: 200) { _ in _ = image.tinted(.systemGreen) }
	}
	
	func testResizedImage128To64() {
		let image = base
		measureLoop(iterations: 200) { _ in _ = image.resized(to: .init(width: 64, height: 64)) }
	}
	
// MARK: - Text
	
	func testStyledText() {
		let font = font
		measureLoop { _ = "Price \($0)".styled(font: font, color: .label) }
	}
	
	func testTextBoundingSize() {
		let font = font
		measureLoop(iterations: 500) { _ = "Apple Inc. closed at \($0).25 USD".styled(font: font).boundingSize(width: 200) }
	}
	
	func testSizeThatFits() {
		let font = font
		measureLoop(iterations: 500) { _ = "Apple Inc. closed at \($0).25 USD".sizeThatFits(font: font, width: 200) }
	}
}
#endif
