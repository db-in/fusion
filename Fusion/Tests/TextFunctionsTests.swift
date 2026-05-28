//
//  Created by Diney Bomfim on 5/28/26.
//

import XCTest
@testable import Fusion

// MARK: - Type -

class TextFunctionsToStringTests: XCTestCase {

// MARK: - Locale formatting

	func testToString_WithEnglishUSLocale_ShouldFormatWithCommaGroupingAndDotDecimal() {
		let locale = Locale(identifier: "en_US")
		XCTAssertEqual(1234.567.toString(decimals: 2, locale: locale), "1,234.56")
	}

	func testToString_WithEnglishGBLocale_ShouldFormatLikeUS() {
		let locale = Locale(identifier: "en_GB")
		XCTAssertEqual(1234.567.toString(decimals: 2, locale: locale), "1,234.56")
	}

	func testToString_WithItalianLocale_ShouldUseLocaleDefaultGroupingForFourDigits() {
		let locale = Locale(identifier: "it_IT")
		XCTAssertEqual(1234.567.toString(decimals: 2, locale: locale), "1234,56")
		XCTAssertEqual(1234.567.toString(decimals: 2, locale: locale, groupingSize: 3), "1.234,56")
	}

	func testToString_WithItalianLocale_ShouldGroupLargeNumbersWithDot() {
		let locale = Locale(identifier: "it_IT")
		XCTAssertEqual(1234567.567.toString(decimals: 2, locale: locale), "1.234.567,56")
		XCTAssertEqual(1234567.567.toString(decimals: 2, locale: locale, groupingSize: 3), "1.234.567,56")
	}

	func testToString_WithSpanishLocale_ShouldUseLocaleDefaultGroupingForFourDigits() {
		let locale = Locale(identifier: "es_ES")
		XCTAssertEqual(1234.567.toString(decimals: 2, locale: locale), "1234,56")
		XCTAssertEqual(1234.567.toString(decimals: 2, locale: locale, groupingSize: 3), "1.234,56")
	}

	func testToString_WithSpanishLocale_ShouldGroupLargeNumbersWithDot() {
		let locale = Locale(identifier: "es_ES")
		XCTAssertEqual(1234567.567.toString(decimals: 2, locale: locale), "1.234.567,56")
	}

	func testToString_WithGermanLocale_ShouldUseDotGroupingAndCommaDecimal() {
		let locale = Locale(identifier: "de_DE")
		XCTAssertEqual(1234.567.toString(decimals: 2, locale: locale), "1.234,56")
	}

	func testToString_WithBrazilianPortugueseLocale_ShouldMatchEuropeanStyle() {
		let locale = Locale(identifier: "pt_BR")
		XCTAssertEqual(1234.567.toString(decimals: 2, locale: locale), "1.234,56")
	}

	func testToString_WithFrenchLocale_ShouldUseNarrowNoBreakSpaceGrouping() {
		let locale = Locale(identifier: "fr_FR")
		XCTAssertEqual(1234.567.toString(decimals: 2, locale: locale), "1\u{202F}234,56")
	}

	func testToString_WithIntegerValue_ShouldFormatWithoutFraction() {
		let locale = Locale(identifier: "en_US")
		XCTAssertEqual((42 as Int).toString(decimals: 0, locale: locale), "42")
	}

	func testToString_WithNegativeValue_ShouldPreserveSign() {
		let locale = Locale(identifier: "en_US")
		XCTAssertEqual((-1234.5 as Double).toString(decimals: 2, locale: locale), "-1,234.50")
	}

	func testToString_WithZeroDecimals_ShouldRoundDownToIntegerPart() {
		let locale = Locale(identifier: "en_US")
		XCTAssertEqual(99.99.toString(decimals: 0, locale: locale), "99")
	}

	func testToString_WithRoundingDown_ShouldTruncateInsteadOfRoundUp() {
		let locale = Locale(identifier: "en_US")
		XCTAssertEqual(1.999.toString(decimals: 2, locale: locale), "1.99")
	}

	func testToString_WithTrimTrailingZeros_ShouldOmitFractionWhenWhole() {
		let locale = Locale(identifier: "en_US")
		XCTAssertEqual(100.0.toString(decimals: 2, locale: locale, trimTrailingZeros: true), "100")
	}

	func testToString_WithTrimTrailingZeros_InGermanLocale_ShouldOmitFractionWhenWhole() {
		let locale = Locale(identifier: "de_DE")
		XCTAssertEqual(100.0.toString(decimals: 2, locale: locale, trimTrailingZeros: true), "100")
	}

	func testToString_WithMinimumDecimal_ShouldAllowFewerFractionDigits() {
		let locale = Locale(identifier: "en_US")
		XCTAssertEqual(1.5.toString(decimals: 2, locale: locale, minimumDecimal: 0), "1.5")
	}

	func testToString_WithCurrencyStyle_ShouldIncludeSymbol() {
		let locale = Locale(identifier: "en_US")
		XCTAssertEqual(99.9.toString(decimals: 2, locale: locale, style: .currency, currencySymbol: "$"), "$99.90")
	}

	func testToString_WithMultiplier_ShouldScaleBeforeFormatting() {
		let locale = Locale(identifier: "en_US")
		XCTAssertEqual(0.5.toString(decimals: 0, locale: locale, multiplier: 100), "50")
	}
}
