//
//  Created by Diney Bomfim on 11/12/26.
//

import Foundation
import Testing
@testable import Fusion

// MARK: - Type -

@Suite
struct NumberFormatterCacheTests {
	
	private static let locales = ["en_US", "ar_AE", "ar", "de_DE", "fr_FR", "it_IT", "hi_IN"].map(Locale.init(identifier:))
	private static let styles: [NumberFormatter.Style] = [.decimal, .percent, .currency]
	private static let roundingModes: [NumberFormatter.RoundingMode] = [.down, .halfEven, .up, .floor]
	private static let values: [Double] = [0, 1, -1, 0.5, 1234.5678, -98765.4321, 1_234_567.891_234, 0.000_123_45]
	
	private func freshString(_ value: Double,
							 decimals: Int,
							 locale: Locale,
							 style: NumberFormatter.Style = .decimal,
							 multiplier: NSNumber? = 1,
							 minimumDecimal: Int? = nil,
							 currencySymbol: String? = nil,
							 roundingMode: NumberFormatter.RoundingMode = .down,
							 trimTrailingZeros: Bool = false,
							 groupingSize: Int? = nil) -> String {
		let formatter = NumberFormatter()
		formatter.locale = locale
		formatter.numberStyle = style
		formatter.multiplier = multiplier
		formatter.allowsFloats = true
		formatter.currencySymbol = currencySymbol
		formatter.roundingMode = roundingMode
		
		if let groupingSize {
			if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
				formatter.minimumGroupingDigits = 1
			} else {
				formatter.groupingSize = groupingSize
				formatter.secondaryGroupingSize = groupingSize
				formatter.usesGroupingSeparator = true
			}
		}
		
		if trimTrailingZeros {
			formatter.minimumFractionDigits = 0
			formatter.maximumFractionDigits = decimals
		} else {
			formatter.minimumFractionDigits = minimumDecimal ?? decimals
			formatter.maximumFractionDigits = decimals
		}
		return formatter.string(for: value) ?? ""
	}
	
	private func freshDigits(_ string: String, locale: Locale) -> String {
		let digitsOnly = string.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
		let formatter = NumberFormatter()
		formatter.locale = locale
		let maps: [(original: String, converted: String)] = digitsOnly.map {
			let original = String($0)
			guard
				let digit = formatter.number(from: original),
				let localized = formatter.string(from: digit)
			else { return ("", "") }
			return (original, localized)
		}
		return maps.reduce(string) { $0.replacingOccurrences(of: $1.original, with: $1.converted) }
	}
	
	@Test
	func toString_AcrossLocalesStylesAndRoundingModes_ShouldMatchAFreshFormatter() {
		for locale in Self.locales {
			for style in Self.styles {
				for roundingMode in Self.roundingModes {
					for value in Self.values {
						for decimals in [0, 2, 8] {
							let cached = value.toString(decimals: decimals, locale: locale, style: style, roundingMode: roundingMode)
							let fresh = freshString(value, decimals: decimals, locale: locale, style: style, roundingMode: roundingMode)
							#expect(cached == fresh, "\(locale.identifier) \(style.rawValue) \(roundingMode.rawValue) \(value) \(decimals)")
						}
					}
				}
			}
		}
	}
	
	@Test
	func toString_WithOptionalArguments_ShouldMatchAFreshFormatter() {
		for locale in Self.locales {
			for value in Self.values {
				#expect(value.toString(decimals: 4, locale: locale, trimTrailingZeros: true) == freshString(value, decimals: 4, locale: locale, trimTrailingZeros: true))
				#expect(value.toString(decimals: 6, locale: locale, minimumDecimal: 2) == freshString(value, decimals: 6, locale: locale, minimumDecimal: 2))
				#expect(value.toString(decimals: 2, locale: locale, groupingSize: 3) == freshString(value, decimals: 2, locale: locale, groupingSize: 3))
				#expect(value.toString(decimals: 2, locale: locale, multiplier: 100) == freshString(value, decimals: 2, locale: locale, multiplier: 100))
				#expect(value.toString(decimals: 2, locale: locale, multiplier: nil) == freshString(value, decimals: 2, locale: locale, multiplier: nil))
				#expect(value.toString(decimals: 2, locale: locale, style: .currency, currencySymbol: "AED ") == freshString(value, decimals: 2, locale: locale, style: .currency, currencySymbol: "AED "))
			}
		}
	}
	
	@Test
	func toString_WithIntegerAndDecimalTypes_ShouldMatchAFreshFormatter() {
		let locale = Locale(identifier: "en_US")
		#expect(42.toString(decimals: 2, locale: locale) == "42.00")
		#expect(Decimal(string: "1234.5678")?.toString(decimals: 2, locale: locale) == "1,234.56")
	}
	
	@Test
	func toString_WhenCalledConcurrently_ShouldProduceStableResults() {
		let locales = Self.locales
		let expected = locales.map { freshString(1234.5678, decimals: 2, locale: $0) }
		let mismatches = ThreadSafe(wrappedValue: 0)
		
		DispatchQueue.concurrentPerform(iterations: 2_000) { index in
			let position = index % locales.count
			if 1234.5678.toString(decimals: 2, locale: locales[position]) != expected[position] {
				mismatches.mutate { $0 += 1 }
			}
		}
		
		#expect(mismatches.wrappedValue == 0)
	}
	
	@Test
	func toString_WithTheSameConfiguration_ShouldReuseTheFormatter() {
		let key = NumberFormatterCache.Key(locale: .init(identifier: "en_US"), style: .decimal, multiplier: 1, minimumFractionDigits: 2, maximumFractionDigits: 2, currencySymbol: nil, roundingMode: .down, groupingSize: nil)
		#expect(NumberFormatterCache.formatter(for: key) === NumberFormatterCache.formatter(for: key))
	}
	
	@Test
	func convertedDigitsToLocale_ShouldMatchAFreshFormatter() {
		let samples = ["0123456789", "Price 1,234.50 AED", "٠١٢٣٤٥٦٧٨٩", "abc", "", "12:30 - 45%"]
		for locale in Self.locales + [Locale(identifier: "EN"), Locale(identifier: "ar_EG")] {
			for sample in samples {
				#expect(sample.convertedDigitsToLocale(locale) == freshDigits(sample, locale: locale), "\(locale.identifier) \(sample)")
			}
		}
	}
	
	@Test
	func toDouble_WithNonDigitCharacters_ShouldStripThemLikeBefore() {
		let locale = Locale(identifier: "en_US")
		#expect("1,234.56".toDouble(locale: locale) == 1234.56)
		#expect("-1234.56".toDouble(locale: locale) == -1234.56)
		#expect("AED 12.3456".toDouble(decimals: 2, locale: locale) == 12.34)
		#expect("1.234,56".toDouble(locale: Locale(identifier: "de_DE")) == 1234.56)
	}
}
