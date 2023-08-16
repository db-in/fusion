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
	
	var content: String { get }
	func render(target: Any?)
	func styled(_ attributes: TextAttributes, overriding: Bool) -> NSAttributedString
	func appending(_ rhs: TextConvertible) -> NSAttributedString
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
	
	func replacing(regex: String, withString: String) -> TextConvertible {
		guard let attributed = self as? NSAttributedString else { return content.replacing(regex: regex, with: withString) }
				
		if let range = content.range(of: regex, options: [.regularExpression, .caseInsensitive]) {
			let nsRange = NSRange(range, in: content)
			let mutableText = NSMutableAttributedString(attributedString: attributed)
			mutableText.replaceCharacters(in: nsRange, with: withString)
			return mutableText as NSAttributedString
		}
		
		return self
	}
	
	func render(target: Any?) { }
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
	
	/// Converts any numeral to Western Arabic Numerals (aka ASCII digits, Western digits, Latin digits, or European digits)
	var usingWesternArabicNumerals: String { convertedDigitsToLocale(.init(identifier: "EN")) }
	
	/// Tries to identify the decimal precision in a given string assuming it uses (.) as the decimal separator
	var inferredPrecision: Int? { components(separatedBy: ".").last?.count }
	
// MARK: - Protected Methods
	
	internal func decimalComponents(locale: Locale = .autoupdatingCurrent) -> (integer: String, fraction: String) {
		let decimalSeparator = locale.decimalSeparator ?? ""
		let components = components(separatedBy: decimalSeparator)
		let integer = components.first?.replacingOccurrences(of: "\\D", with: "", options: .regularExpression) ?? ""
		let fraction = components.last?.replacingOccurrences(of: "\\D", with: "", options: .regularExpression) ?? ""
		let value = Double(self) ?? 0
		let signedInteger = value < 0 ? "-\(integer)" : integer
		
		return components.count > 1 ? (signedInteger, fraction) : (signedInteger, "")
	}
	
// MARK: - Exposed Methods
	
	func styled(_ attributes: TextAttributes, overriding: Bool = true) -> NSAttributedString {
		NSAttributedString(string: self, attributes: attributes)
	}
	
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
	func convertedDigitsToLocale(_ locale: Locale = .autoupdatingCurrent) -> String {
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
		let criteria = isCaseSensitive ? text : text.lowercased()
		let query = isCaseSensitive ? self : lowercased()
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
		let criteria = isCaseSensitive ? text : text.lowercased()
		let query = isCaseSensitive ? self : lowercased()
		return query.contains(criteria)
	}
	
	@inlinable func appending(_ rhs: TextConvertible) -> NSAttributedString { NSAttributedString(string: self).appending(rhs) }
	
	@inlinable static func + (lhs: String, rhs: TextConvertible) -> NSAttributedString { NSAttributedString(string: lhs) + rhs }
	
	@inlinable static func + (lhs: TextConvertible, rhs: String) -> NSAttributedString { lhs + NSAttributedString(string: rhs) }
	
	@inlinable static func + (lhs: String, rhs: String) -> String {
		if Locale.autoupdatingCurrent.isRTL {
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
	
	func appending(_ rhs: TextConvertible) -> NSAttributedString { string.appending(rhs) }
	
	func styled(_ attributes: TextAttributes, overriding: Bool) -> NSAttributedString { string.styled(attributes) }
}

// MARK: - Extension - NSAttributedString

public extension NSAttributedString {
	
// MARK: - Properties
		
	var content: String { string }
	
// MARK: - Exposed Methods

	func styled(_ attributes: TextAttributes, overriding: Bool = true) -> NSAttributedString {
		guard overriding else { return self }
		let copy = NSMutableAttributedString(attributedString: self)
		copy.addAttributes(attributes, range: NSRange(location: 0, length: copy.length))
		return Self.init(attributedString: copy)
	}
	
	/// Places a new argument in the right always. Ignores the language direction.
	///
	/// - Parameter rhs: The right argument that will stay in the right, regardless the direction.
	/// - Returns: The final concatenated result.
	@inlinable func appending(_ rhs: TextConvertible) -> NSAttributedString {
		let copy = NSMutableAttributedString(attributedString: self)
		
		if let rhsAttr = rhs as? NSAttributedString {
			copy.append(rhsAttr)
		} else if let rhsString = rhs as? String {
			copy.append(NSAttributedString(string: rhsString))
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
		
		if Locale.autoupdatingCurrent.isRTL {
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
