//
//  Created by Diney Bomfim.
//

#if canImport(UIKit) && canImport(SwiftUI) && !os(watchOS)
import SwiftUI

// MARK: - Type - TextAnimationSegments

struct TextAnimationSegments {
	
	private static let numberRegex: NSRegularExpression? = try? NSRegularExpression(pattern: "[0-9][0-9.,]*", options: [])
	
	let template: NSAttributedString
	let numberRange: NSRange
	let number: String
	let decimals: Int
	let value: Double
	let full: AttributedString
	let prefix: AttributedString
	let suffix: AttributedString
	let numberAttributes: AttributeContainer
	
	var hasNumber: Bool { numberRange.location != NSNotFound }
	
	init(_ attributed: NSAttributedString = .init(), locale: Locale = .preferredLocale) {
		let string = attributed.string
		template = attributed
		full = AttributedString(attributed)
		
		guard let range = Self.firstNumberRange(in: string), let bounds = Range<AttributedString.Index>(range, in: full) else {
			numberRange = .init(location: NSNotFound, length: 0)
			number = ""
			decimals = 0
			value = 0
			prefix = full
			suffix = .init()
			numberAttributes = .init()
			return
		}
		
		let number = (string as NSString).substring(with: range)
		numberRange = range
		self.number = number
		decimals = Self.fractionDigits(in: number, locale: locale)
		value = Self.parse(number, locale: locale)
		prefix = AttributedString(full[..<bounds.lowerBound])
		suffix = AttributedString(full[bounds.upperBound...])
		numberAttributes = full[bounds].runs.first?.attributes ?? .init()
	}
	
	static func firstNumberRange(in string: String) -> NSRange? {
		let range = NSRange(location: 0, length: (string as NSString).length)
		return numberRegex?.firstMatch(in: string, options: [], range: range)?.range
	}
	
	private static func parse(_ string: String, locale: Locale) -> Double {
		let parts = string.decimalComponents(locale: locale)
		if parts.fraction.isEmpty { return Double(parts.integer) ?? 0 }
		return Double("\(parts.integer).\(parts.fraction)") ?? 0
	}
	
	private static func fractionDigits(in string: String, locale: Locale) -> Int {
		let decimal = locale.decimalSeparator ?? "."
		if let range = string.range(of: decimal) { return string[range.upperBound...].count }
		return 0
	}
	
	func composed(number replacement: String) -> AttributedString {
		guard hasNumber else { return full }
		var result = prefix
		result.append(AttributedString(replacement, attributes: numberAttributes))
		result.append(suffix)
		return result
	}
	
	func composed(value: Double, locale: Locale = .preferredLocale) -> AttributedString {
		composed(number: value.toString(decimals: decimals, locale: locale))
	}
}
#endif
