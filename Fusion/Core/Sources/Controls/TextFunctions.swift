//
//  Created by Diney Bomfim on 8/2/23.
//

import Foundation

// MARK: - Type - Searcheable

public protocol Searcheable {
	
	var searchableText: String { get }
}

public typealias TextAttributes = [NSAttributedString.Key : Any]

// MARK: - Type - TextConvertible

public protocol TextConvertible {
	
	/// The raw content.
	var content: String { get }
	
	/// Renders the text on the given target.
	/// - Parameter target: The target to receive the text.
	func render(on target: Any?)
	
	/// Apply a given style to the current text. Multiple sequencial calls can be made.
	///
	/// - Parameter attributes: The ``TextAttributes`` to be applied.
	/// - Returns: The new attributed string.
	func styled(_ attributes: TextAttributes) -> NSAttributedString
	
	/// Apply a given style to the current text with option to override existing styles. Multiple sequencial calls can be made.
	///
	/// - Parameters:
	///   - attributes: The ``TextAttributes`` to be applied.
	///   - overriding: Defines if old styles will be overriden.
	/// - Returns: The new attributed string.
	func styled(_ attributes: TextAttributes, overriding: Bool) -> NSAttributedString
	
	/// Apply a given style to the current text over a given text string.
	///
	/// - Parameters:
	///   - attributes: The ``TextAttributes`` to be applied.
	///   - onText: The text string to be applied the new attributes on.
	/// - Returns: The new attributed string.
	func styled(_ attributes: TextAttributes, onText: String) -> NSAttributedString
	
	/// Applies HTML tag-based styling to specific tagged portions of text
	/// - Parameter tagStyles: Dictionary mapping HTML tags to their corresponding TextAttributes
	/// - Returns: Styled NSAttributedString with HTML tags removed
	func styledHTML(_ tags: [String: TextAttributes]) -> TextConvertible
	
	/// Appends multiple arguments to the current attributed string.
	/// Places each argument in the right, regardless of the language direction.
	///
	/// - Parameter rhs: A variable number of arguments to be appended, each of which can be a `TextConvertible`.
	/// - Returns: A new `NSAttributedString` with the concatenated result.
	func appending(_ rhs: TextConvertible...) -> NSAttributedString
}

extension String : TextConvertible { }

extension String.SubSequence : TextConvertible { }

extension NSAttributedString : TextConvertible { }

// MARK: - Extension - TextConvertible

public extension TextConvertible {
	
	var attributes: TextAttributes {
		guard let attributed = (self as? NSAttributedString), attributed.length > 0 else { return [:] }
		return attributed.attributes(at: 0, effectiveRange: nil)
	}
	
	/// Replaces the text matched by the specified regular expression with the provided text.
	///
	/// - Parameters:
	///   - regex: The regular expression pattern to search for.
	///   - withText: The text to replace the matched pattern.
	/// - Returns: A `TextConvertible` object with the replaced text.
	func replacing(regex: String, withText: TextConvertible) -> TextConvertible {
		if let range = content.range(of: regex, options: [.regularExpression, .caseInsensitive]) {
			let mutableText: NSMutableAttributedString
			let nsRange = NSRange(range, in: content)
			
			if let attributed = self as? NSAttributedString {
				mutableText = NSMutableAttributedString(attributedString: attributed)
			} else {
				mutableText = NSMutableAttributedString(string: content)
			}
			
			let preText = mutableText.attributedSubstring(from: NSRange(location: 0, length: nsRange.lowerBound))
			let postText = mutableText.attributedSubstring(from: NSRange(location: nsRange.upperBound, length: mutableText.length - nsRange.upperBound))
			
			return preText.appending(withText).appending(postText)
		}
		
		return self
	}
	
	/// This function will find and replace placeholders inside a string with other values, the placeholders can be named of unnamed.
	///
	/// ```
	/// "{KG}kg is equal {gr}g".replace(["5", "5000"]) // results in "5kg is equal 5000g"
	/// ```
	///
	/// ```
	/// let string = "{KG}kg is equal {gr}g"
	/// string.replace(["5000", "5"], placeholders: ["{KG}", "{gr}"]) // results in "5kg is equal 5000g"
	/// ```
	///
	/// - Parameters:
	///   - template: An array containing the actual values to be replaced
	///   - placeholders: An array containing the named placeholders. Ommiting this parameter takes advantage of default placeholders.
	/// - Returns: A string with placeholders being replaced.
	///
	func replacing(with template: [TextConvertible], placeholders: [String]? = nil) -> TextConvertible {
		let elements = placeholders ?? Array(repeating: "{.*?}", count: template.count)
		let pattern = elements.map { $0.replacingOccurrences(of: "{", with: "\\{").replacingOccurrences(of: "}", with: "\\}") }
		var result: TextConvertible = self
		zip(pattern, template).forEach { result = result.replacing(regex: $0, withText: $1) }
		return result
	}
	
	/// Replaces the default placeholders in a given string with the new values.
	///
	/// - Parameter template: The new values.
	/// - Returns: A string with the replaces values.
	func replacing(_ template: TextConvertible...) -> TextConvertible {
		replacing(with: template)
	}
	
	func render(on: Any?) { }
	
	func styled(_ attributes: TextAttributes) -> NSAttributedString { styled(attributes, overriding: true) }
	
	func styled(_ attributes: TextAttributes, onText: String) -> NSAttributedString {
		let attributedString = NSMutableAttributedString(attributedString: styled(self.attributes))
		let range = (content as NSString).range(of: onText)
		
		if range.location != NSNotFound {
			attributedString.addAttributes(attributes, range: range)
		}
		
		return attributedString
	}
	
	func styledHTML(_ tags: [String: TextAttributes]) -> TextConvertible {
		var result: TextConvertible = self
		
		tags.forEach { tag, style in
			let pattern = "<\(tag).*?>(.*?)</\(tag).*?>"
			while result.content.hasMatch(regex: pattern) {
				let styled = result.content.replacing(regex: ".*?\(pattern).*", with: "$1").styled(style)
				result = result.replacing(regex: pattern, withText: styled)
			}
		}
		
		return result
	}
}

// MARK: - Extension - TextStyle

public extension TextAttributes {
	
	func attributed(_ attributes: TextAttributes) -> Self {
		merging(attributes) { $1 }
	}
}

// MARK: - Extension - String

public extension String {
	
// MARK: - Properties
	
	var content: String { self }
	
	/// Filters the whole string keeping only the digits `usingWesternArabicNumerals`
	var digits: String { filter("0123456789".contains) }
	
	/// Ignores diacritic marks. é = e, ë = e, õ = o, etc.
	var noDiacritic: String { folding(options: .diacriticInsensitive, locale: nil) }
	
	/// Converts any numeral to Western Arabic Numerals (aka ASCII digits, Western digits, Latin digits, or European digits)
	var usingWesternArabicNumerals: String { convertedDigitsToLocale(.init(identifier: "EN")) }
	
	/// Tries to identify the decimal precision in a given string assuming it uses (.) as the decimal separator
	var inferredPrecision: Int? { components(separatedBy: ".").last?.count }
	
// MARK: - Protected Methods
	
	internal func decimalComponents(locale: Locale = .preferredLocale) -> (integer: String, fraction: String) {
		let decimalSeparator = locale.decimalSeparator ?? ""
		let components = components(separatedBy: decimalSeparator)
		let integer = components.first?.replacingOccurrences(of: "\\D", with: "", options: .regularExpression) ?? ""
		let fraction = components.last?.replacingOccurrences(of: "\\D", with: "", options: .regularExpression) ?? ""
		let value = Double(self) ?? 0
		let signedInteger = value < 0 ? "-\(integer)" : integer
		
		return components.count > 1 ? (signedInteger, fraction) : (signedInteger, "")
	}
	
// MARK: - Exposed Methods
	
	func styled(_ attributes: TextAttributes, overriding: Bool) -> NSAttributedString { .init(string: self, attributes: attributes) }
	
	/// Cleans up precisely what is a thousand formatted and a decimal formatted string in a given locale.
	///
	/// - Parameters:
	///   - decimals: The number of decimal places for the returning double.
	///   - locale: The given locale.
	/// - Returns: The resulting `Double`
	func toDouble(decimals: Int, with locale: Locale) -> Double {
		let components = decimalComponents(locale: locale)
		guard !components.fraction.isEmpty else { return Double(components.integer) ?? 0 }
		return Double("\(components.integer).\(components.fraction.prefix(decimals))") ?? 0
	}
	
	/// Converts any numeral in the string to a given locale, preserving all non-numeral character as is.
	///
	/// - Parameter locale: The target locale of the new numerals.
	/// - Returns: The new string with the converted numerals.
	func convertedDigitsToLocale(_ locale: Locale = .preferredLocale) -> String {
		let digitsOnly = components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
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

		return maps.reduce(self) { converted, map in
			converted.replacingOccurrences(of: map.original, with: map.converted)
		}
	}
	
	/// Searches for any character match in the given order inside the string.
	///
	/// - Parameters:
	///   - text: The sequence of character to search for.
	///   - isCaseSensitive: Defines if the algorithm will consider the character case. Default is `false`.
	/// - Returns: A `Bool` indicating if the search was successful.
	func containsCharacters(_ text: String, isCaseSensitive: Bool = false) -> Bool {
		let criteria = (isCaseSensitive ? text : text.lowercased()).noDiacritic
		let query = (isCaseSensitive ? self : lowercased()).noDiacritic
		let searchCount = criteria.count
		var pointer = 0
		
		for character in query {
			guard pointer < searchCount else { break }
			let index = criteria.index(criteria.startIndex, offsetBy: pointer)
			
			if character == criteria[index] {
				pointer += 1
			}
		}
		
		return pointer >= searchCount
	}
	
	/// Searches for an exact sequence match in the given order inside the string.
	///
	/// - Parameters:
	///   - text: The sequence of character to search for.
	///   - isCaseSensitive: Defines if the algorithm will consider the character case. Default is `false`.
	/// - Returns: A `Bool` indicating if the search was successful.
	func containsSequence(_ text: String, isCaseSensitive: Bool = false) -> Bool {
		let criteria = (isCaseSensitive ? text : text.lowercased()).noDiacritic
		let query = (isCaseSensitive ? self : lowercased()).noDiacritic
		return query.contains(criteria)
	}
	
	@inlinable func appending(_ rhs: TextConvertible...) -> NSAttributedString { rhs.reduce(NSAttributedString(string: self)) { $0.appending($1) } }
	
	@inlinable static func + (lhs: String, rhs: TextConvertible) -> NSAttributedString { NSAttributedString(string: lhs) + rhs }
	
	@inlinable static func + (lhs: TextConvertible, rhs: String) -> NSAttributedString { lhs + NSAttributedString(string: rhs) }
	
	@inlinable static func + (lhs: String, rhs: String) -> String {
		if Locale.preferredLocale.isRTL {
			return "\(rhs)\(lhs)"
		} else {
			return "\(lhs)\(rhs)"
		}
	}
}

// MARK: - Extension - String.SubSequence

public extension String.SubSequence {
	
	var string: String { .init(self) }
	
	var content: String { string }
	
	func appending(_ rhs: TextConvertible...) -> NSAttributedString { rhs.reduce(NSAttributedString(string: string)) { $0.appending($1) } }
	
	func styled(_ attributes: TextAttributes, overriding: Bool) -> NSAttributedString { string.styled(attributes) }
}

// MARK: - Extension - NSAttributedString

public extension NSAttributedString {
	
// MARK: - Properties
		
	var content: String { string }
	
// MARK: - Exposed Methods

	func styled(_ attributes: TextAttributes, overriding: Bool) -> NSAttributedString {
		guard overriding else { return self }
		let copy = NSMutableAttributedString(attributedString: self)
		copy.addAttributes(attributes, range: NSRange(location: 0, length: copy.length))
		return Self.init(attributedString: copy)
	}
	
	@inlinable func appending(_ rhs: TextConvertible...) -> NSAttributedString {
		let copy = NSMutableAttributedString(attributedString: self)
		
		rhs.forEach { arg in
			if let attr = arg as? NSAttributedString {
				copy.append(attr)
			} else if let string = arg as? String {
				copy.append(NSAttributedString(string: string))
			}
		}
		
		return NSAttributedString(attributedString: copy)
	}
	
	/// Rightfully concatenating string. Respecting RTL.
	///
	/// - Parameters:
	///   - lhs: Left hand argument in standard LTR.
	///   - rhs: Right hand argument in standard LTR.
	/// - Returns: The final concatenated result.
	@inlinable static func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
		let copy = NSMutableAttributedString(attributedString: lhs)
		
		if Locale.preferredLocale.isRTL {
			copy.insert(rhs, at: 0)
		} else {
			copy.append(rhs)
		}
		
		return NSAttributedString(attributedString: copy)
	}
	
	@inlinable static func + (lhs: NSAttributedString, rhs: String) -> NSAttributedString {
		lhs + NSAttributedString(string: rhs)
	}
	
	@inlinable static func + (lhs: String, rhs: NSAttributedString) -> NSAttributedString {
		NSAttributedString(string: lhs) + rhs
	}
	
	@inlinable static func + (lhs: NSAttributedString, rhs: TextConvertible) -> NSAttributedString {
		if let rhsAttr = rhs as? NSAttributedString {
			return lhs + rhsAttr
		} else if let rhsString = rhs as? String {
			return lhs + rhsString
		}
		
		return lhs
	}
	
	@inlinable static func + (lhs: TextConvertible, rhs: NSAttributedString) -> NSAttributedString {
		if let lhsAttr = lhs as? NSAttributedString {
			return lhsAttr + rhs
		} else if let lhsString = lhs as? String {
			return lhsString + rhs
		}
		
		return rhs
	}
}

// MARK: - Extension - Numeric

public extension Numeric {
	
	/// Converts a numeric value to a formatted string, respecting locale and other standards.
	///
	/// - Parameters:
	///   - decimals: The number of decimal places (or fraction) in the result.
	///   - locale: The locale defines the group and decimal separator.
	///   - style: The style of the formatted string. Default is `.decimal`.
	///   - multiplier: A given multiplier to apply before the final string. Default is 1.
	///   - minimumDecimal: When defined, if sets the minimum fraction digits differently than the decimals.
	///   When `nil`, the `decimals` is used. Default is `nil`
	/// - Returns: The formatted value string.
	func toString(decimals: Int,
				  locale: Locale,
				  style: NumberFormatter.Style = .decimal,
				  multiplier: NSNumber? = 1,
				  minimumDecimal: Int? = nil) -> String {
		let formatter = NumberFormatter()
		formatter.locale = locale
		formatter.numberStyle = style
		formatter.multiplier = multiplier
		formatter.allowsFloats = true
		formatter.minimumFractionDigits = minimumDecimal ?? decimals
		formatter.maximumFractionDigits = decimals
		return formatter.string(for: self) ?? ""
	}
}
