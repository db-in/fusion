//
//  Created by Diney Bomfim on 5/28/26.
//

import XCTest
@testable import Fusion

// MARK: - Type -

class TextFunctionsToStringTests: XCTestCase {

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

	func testToString_WithNegativeValue_ShouldPreserveSignAndGroup() {
		let locale = Locale(identifier: "en_US")
		XCTAssertEqual((-1234.5 as Double).toString(decimals: 2, locale: locale), "-1,234.50")
	}

// MARK: - No grouping

	func testToString_WithoutGrouping_ForSmallDecimalValues() {
		assertNoGroupingCases([
			.init(value: 42.5, decimals: 2, localeIdentifier: "en_US", expected: "42.50"),
			.init(value: 999.99, decimals: 2, localeIdentifier: "en_US", expected: "999.99"),
			.init(value: 42.5, decimals: 2, localeIdentifier: "it_IT", expected: "42,50"),
			.init(value: 999.99, decimals: 2, localeIdentifier: "it_IT", expected: "999,99"),
			.init(value: 999.99, decimals: 2, localeIdentifier: "es_ES", expected: "999,99"),
			.init(value: 999.99, decimals: 2, localeIdentifier: "de_DE", expected: "999,99"),
			.init(value: 999.99, decimals: 2, localeIdentifier: "fr_FR", expected: "999,99"),
			.init(value: 42.5, decimals: 2, localeIdentifier: "en_US", groupingSize: 3, expected: "42.50"),
			.init(value: 42.5, decimals: 2, localeIdentifier: "it_IT", groupingSize: 3, expected: "42,50"),
		])
	}

	func testToString_WithoutGrouping_ForLocaleDefaultFourDigitThreshold() {
		assertNoGroupingCases([
			.init(value: 1234.567, decimals: 2, localeIdentifier: "it_IT", expected: "1234,56"),
			.init(value: 1234.567, decimals: 2, localeIdentifier: "es_ES", expected: "1234,56"),
		])
	}

	func testToString_WithoutGrouping_ForIntegerAndZeroFractionDigits() {
		assertNoGroupingCases([
			.init(value: 42, decimals: 0, localeIdentifier: "en_US", expected: "42"),
			.init(value: 99.99, decimals: 0, localeIdentifier: "en_US", expected: "99"),
			.init(value: 9.99, decimals: 0, localeIdentifier: "en_US", expected: "9"),
			.init(value: 99.99, decimals: 0, localeIdentifier: "it_IT", expected: "99"),
		])
	}

	func testToString_WithoutGrouping_ForZeroAndSmallNegativeValues() {
		assertNoGroupingCases([
			.init(value: 0, decimals: 2, localeIdentifier: "en_US", expected: "0.00"),
			.init(value: -9.99, decimals: 2, localeIdentifier: "en_US", expected: "-9.99"),
			.init(value: -42.5, decimals: 2, localeIdentifier: "en_US", expected: "-42.50"),
		])
	}

	func testToString_WithoutGrouping_ForTrimTrailingZeros() {
		assertNoGroupingCases([
			.init(value: 100, decimals: 2, localeIdentifier: "en_US", trimTrailingZeros: true, expected: "100"),
			.init(value: 100, decimals: 2, localeIdentifier: "de_DE", trimTrailingZeros: true, expected: "100"),
			.init(value: 99.5, decimals: 2, localeIdentifier: "en_US", trimTrailingZeros: true, expected: "99.5"),
		])
	}

	func testToString_WithoutGrouping_ForMinimumDecimal() {
		assertNoGroupingCases([
			.init(value: 1.5, decimals: 2, localeIdentifier: "en_US", minimumDecimal: 0, expected: "1.5"),
			.init(value: 0.05, decimals: 2, localeIdentifier: "en_US", minimumDecimal: 0, expected: "0.05"),
		])
	}

	func testToString_WithoutGrouping_ForMultiplierBelowGroupingThreshold() {
		assertNoGroupingCases([
			.init(value: 0.5, decimals: 0, localeIdentifier: "en_US", multiplier: 100, expected: "50"),
			.init(value: 0.25, decimals: 0, localeIdentifier: "en_US", multiplier: 100, expected: "25"),
		])
	}

	func testToString_WithoutGrouping_ForPercentStyle() {
		assertNoGroupingCases([
			.init(value: 0.1234, decimals: 2, localeIdentifier: "en_US", style: .percent, expected: "0.12%"),
			.init(value: 0.1234, decimals: 2, localeIdentifier: "it_IT", style: .percent, expected: "0,12%"),
			.init(value: 0.5, decimals: 2, localeIdentifier: "en_US", style: .percent, expected: "0.50%"),
			.init(value: 12.34, decimals: 2, localeIdentifier: "en_US", style: .percent, expected: "12.34%"),
		])
	}

	func testToString_WithGrouping_ForPercentStyleOnLargeValues() {
		let locale = Locale(identifier: "en_US")
		XCTAssertEqual(1234.56.toString(decimals: 2, locale: locale, style: .percent), "1,234.56%")
	}

	func testToString_WithoutGrouping_ForScientificStyle() {
		assertNoGroupingCases([
			.init(value: 999.99, decimals: 2, localeIdentifier: "en_US", style: .scientific, expected: "9.9E2"),
			.init(value: 42.5, decimals: 2, localeIdentifier: "en_US", style: .scientific, expected: "4.2E1"),
			.init(value: 1234.56, decimals: 2, localeIdentifier: "it_IT", style: .scientific, expected: "1,2E3"),
		])
	}

	func testToString_WithoutGrouping_ForNoneStyle() {
		assertNoGroupingCases([
			.init(value: 1234.567, decimals: 2, localeIdentifier: "en_US", style: .none, expected: "1234.56"),
			.init(value: 1234.567, decimals: 2, localeIdentifier: "it_IT", style: .none, expected: "1234,56"),
		])
	}

	func testToString_WithoutGrouping_ForSpellOutStyle() {
		assertNoGroupingCases([
			.init(value: 42, decimals: 0, localeIdentifier: "en_US", style: .spellOut, expected: "forty-two", omitGroupingAssertion: true),
			.init(value: 999, decimals: 0, localeIdentifier: "en_US", style: .spellOut, expected: "nine hundred ninety-nine", omitGroupingAssertion: true),
		])
	}

	func testToString_WithoutGrouping_ForOrdinalStyle() {
		assertNoGroupingCases([
			.init(value: 42, decimals: 0, localeIdentifier: "en_US", style: .ordinal, expected: "42nd", omitGroupingAssertion: true),
			.init(value: 3, decimals: 0, localeIdentifier: "en_US", style: .ordinal, expected: "3rd", omitGroupingAssertion: true),
		])
	}

	func testToString_WithoutGrouping_ForSmallCurrencyAmounts() {
		assertNoGroupingCases([
			.init(value: 99.9, decimals: 2, localeIdentifier: "en_US", style: .currency, currencySymbol: "$", expected: "$99.90"),
			.init(value: 99.9, decimals: 2, localeIdentifier: "it_IT", style: .currency, expected: "99,90 €"),
			.init(value: 12.5, decimals: 2, localeIdentifier: "en_US", style: .currency, currencySymbol: "$", expected: "$12.50"),
		])
	}

	func testToString_WithoutGrouping_ForCurrencyAccountingStyle() {
		assertNoGroupingCases([
			.init(value: 99.9, decimals: 2, localeIdentifier: "en_US", style: .currencyAccounting, currencySymbol: "$", expected: "$99.90"),
		])
	}

// MARK: - Other formatting

	func testToString_WithRoundingDown_ShouldTruncateInsteadOfRoundUp() {
		let locale = Locale(identifier: "en_US")
		XCTAssertEqual(1.999.toString(decimals: 2, locale: locale), "1.99")
	}

	func testToString_WithCurrencyStyle_ShouldGroupLargeAmounts() {
		let locale = Locale(identifier: "en_US")
		XCTAssertEqual(1234.56.toString(decimals: 2, locale: locale, style: .currency, currencySymbol: "$"), "$1,234.56")
	}

	func testToString_WithMultiplier_ShouldScaleBeforeFormatting() {
		let locale = Locale(identifier: "en_US")
		XCTAssertEqual(12.34.toString(decimals: 0, locale: locale, multiplier: 100), "1,234")
	}
}

// MARK: - Test case

private extension TextFunctionsToStringTests {

	struct ToStringCase {
		let value: Double
		let decimals: Int
		let localeIdentifier: String
		var style: NumberFormatter.Style = .decimal
		var groupingSize: Int? = nil
		var multiplier: NSNumber? = 1
		var minimumDecimal: Int? = nil
		var currencySymbol: String? = nil
		var trimTrailingZeros: Bool = false
		let expected: String
		var omitGroupingAssertion: Bool = false
	}

	func assertNoGroupingCases(_ cases: [ToStringCase], file: StaticString = #file, line: UInt = #line) {
		cases.forEach { testCase in
			let locale = Locale(identifier: testCase.localeIdentifier)
			let result = testCase.value.toString(
				decimals: testCase.decimals,
				locale: locale,
				style: testCase.style,
				multiplier: testCase.multiplier,
				minimumDecimal: testCase.minimumDecimal,
				currencySymbol: testCase.currencySymbol,
				trimTrailingZeros: testCase.trimTrailingZeros,
				groupingSize: testCase.groupingSize
			)
			XCTAssertEqual(result, testCase.expected, file: file, line: line)
			guard !testCase.omitGroupingAssertion else { return }
			guard let separator = locale.groupingSeparator, !separator.isEmpty else { return }
			XCTAssertFalse(result.contains(separator), "Unexpected grouping in \"\(result)\"", file: file, line: line)
		}
	}
}
