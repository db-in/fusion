//
//  Created by Diney Bomfim.
//

import Foundation
import Testing
@testable import Fusion
#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Definitions -

private struct SeededGenerator: RandomNumberGenerator {
	
	var state: UInt64
	
	mutating func next() -> UInt64 {
		state &+= 0x9E3779B97F4A7C15
		var z = state
		z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
		z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
		return z ^ (z >> 31)
	}
}

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct TextAnimationTests {
		
		@Test
		func scrambled_WhenProgressIsComplete_ShouldReturnTheTarget() {
			var generator = SeededGenerator(state: 7)
			#expect(TextUpdateModifier.scrambled("1,234.56", progress: 1, using: &generator) == "1,234.56")
		}
		
		@Test
		func scrambled_AtAnyProgress_ShouldKeepSeparatorsAndLength() {
			var generator = SeededGenerator(state: 42)
			for step in 0...10 {
				let result = TextUpdateModifier.scrambled("12,345.67", progress: Double(step) / 10, using: &generator)
				#expect(result.count == 9)
				#expect(Array(result)[2] == ",")
				#expect(Array(result)[6] == ".")
				#expect(result.allSatisfy { $0.isWholeNumber || $0 == "," || $0 == "." })
			}
		}
		
		@Test
		func scrambled_AtHalfProgress_ShouldSettleTheLeadingHalfOfTheDigits() {
			var generator = SeededGenerator(state: 3)
			let result = TextUpdateModifier.scrambled("9876", progress: 0.5, using: &generator)
			#expect(result.hasPrefix("98"))
		}
		
		@Test
		func scrambled_AtZeroProgress_ShouldRandomizeEveryDigit() {
			var generator = SeededGenerator(state: 11)
			let results = (0..<20).map { _ in TextUpdateModifier.scrambled("0000", progress: 0, using: &generator) }
			#expect(results.contains { $0 != "0000" })
		}
		
		@Test
		func scrambled_WithoutDigits_ShouldReturnTheSameText() {
			var generator = SeededGenerator(state: 1)
			#expect(TextUpdateModifier.scrambled("abc", progress: 0, using: &generator) == "abc")
		}
		
		@Test
		func segments_ShouldParseTheFirstNumberOnce() {
			let segments = TextAnimationSegments(NSAttributedString(string: "Balance $ 1,234.56 today"), locale: Locale(identifier: "en_US"))
			#expect(segments.hasNumber)
			#expect(segments.number == "1,234.56")
			#expect(segments.decimals == 2)
			#expect(segments.value == 1_234.56)
		}
		
		@Test
		func segmentsComposed_ShouldReplaceOnlyTheNumberAndKeepItsStyle() {
			let bold = UIFont.boldSystemFont(ofSize: 20)
			let template = "Balance $ 1,234.56 today"
				.styled([.font: UIFont.systemFont(ofSize: 12)])
				.styled([.font: bold], onText: "1,234.56")
			let composed = TextAnimationSegments(template, locale: Locale(identifier: "en_US")).composed(number: "9.00")
			#expect(String(composed.characters) == "Balance $ 9.00 today")
			#expect(composed.runs.count == 3)
			#expect(AttributedString(template).runs.count == 3)
		}
		
		@Test
		func segmentsComposed_WithoutNumber_ShouldReturnTheFullText() {
			let segments = TextAnimationSegments(NSAttributedString(string: "No digits here"))
			#expect(!segments.hasNumber)
			#expect(String(segments.composed(number: "1").characters) == "No digits here")
		}
		
		@Test
		func odometerGlyphs_ShouldBeKeyedByTheirTrailingPosition() {
			let glyphs = OdometerGlyph.glyphs(for: "1,024")
			#expect(glyphs.map(\.id) == [4, 3, 2, 1, 0])
			#expect(glyphs.map(\.digit) == [1, nil, 0, 2, 4])
		}
		
		@Test
		func odometerGlyphs_WhenTheDigitCountGrows_ShouldKeepTheUnitsIdentity() {
			let before = OdometerGlyph.glyphs(for: "999")
			let after = OdometerGlyph.glyphs(for: "1,000")
			#expect(before.last?.id == after.last?.id)
			#expect(before.last?.id == 0)
		}
		
		@Test
		func segments_ShouldPrecomputeGlyphsAndDigitRuns() {
			let segments = TextAnimationSegments(NSAttributedString(string: "1,024"), locale: Locale(identifier: "en_US"), includeDigitRuns: true)
			#expect(segments.glyphs.map(\.id) == [4, 3, 2, 1, 0])
			#expect(segments.digitRuns.count == 10)
			#expect(segments.digitCount == 4)
			#expect(String(segments.digitRuns[7].characters) == "7")
		}
		
		@Test
		func segments_WithoutDigitRuns_ShouldSkipTheDigitTable() {
			let segments = TextAnimationSegments(NSAttributedString(string: "1,024"), locale: Locale(identifier: "en_US"))
			#expect(segments.digitRuns.isEmpty)
			#expect(segments.glyphs.count == 5)
		}
		
		@Test
		func formatted_ShouldMatchComposedNumber() {
			let segments = TextAnimationSegments(NSAttributedString(string: "Balance $ 1,234.50"), locale: Locale(identifier: "en_US"))
			let formatted = segments.formatted(value: 9)
			#expect(String(segments.composed(number: formatted).characters) == "Balance $ \(formatted)")
		}
		
		@Test
		func quantized_ShouldMatchNumberFormatterTruncation() {
			#expect(TextUpdateModifier.quantized(1_250.129, decimals: 2) == 125_012)
			#expect(TextUpdateModifier.quantized(1_250.129, decimals: 0) == 1_250)
			#expect(TextUpdateModifier.quantized(1_250.9, decimals: 0) == 1_250)
			#expect(TextUpdateModifier.quantized(1_250.129, decimals: 2) == TextUpdateModifier.quantized(1_250.124, decimals: 2))
		}
	}
}
#endif
