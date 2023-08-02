//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation

// MARK: - Type - Searcheable

public protocol Searcheable {
	
	var searchableText: String { get }
}

// MARK: - Type - TextConvertible

public protocol TextConvertible {
	
	var content: String { get }
	func render(target: Any?)
	func styled(_ attributes: [NSAttributedString.Key : Any], overriding: Bool) -> NSAttributedString
	func appending(_ rhs: TextConvertible) -> NSAttributedString
}

extension String : TextConvertible { }

extension NSAttributedString : TextConvertible { }

// MARK: - Extension - TextConvertible

public extension TextConvertible {
	
	var attributes: [NSAttributedString.Key : Any] {
		(self as? NSAttributedString)?.attributes(at: 0, effectiveRange: nil) ?? [:]
	}
	
	func boundingSize(width: CGFloat? = nil, height: CGFloat? = nil) -> CGSize {
		let constraintRect = CGSize(width: width ?? .greatestFiniteMagnitude, height: height ?? .greatestFiniteMagnitude)
		let box = styled(attributes, overriding: false).boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
		return box.size
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
	
// MARK: - Extension - [NSAttributedString.Key : Any]

public extension Dictionary where Key == NSAttributedString.Key, Value == Any {
	
	func attributed(_ attributes: [NSAttributedString.Key : Any]) -> Self {
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
	
	func styled(_ attributes: [NSAttributedString.Key : Any], overriding: Bool = true) -> NSAttributedString {
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

// MARK: - Extension - NSAttributedString

public extension NSAttributedString {
	
// MARK: - Properties
		
	var content: String { string }
	
// MARK: - Exposed Methods

	func styled(_ attributes: [NSAttributedString.Key : Any], overriding: Bool = true) -> NSAttributedString {
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

#if canImport(AppKit)
import AppKit

// MARK: - Extension - String

public extension String {

	// MARK: - Exposed Methods
	
	func render(target: Any?) {
		guard let view = target as? NSView else {
			return
		}
		
		switch view {
		case let label as NSTextField:
			label.stringValue = self
		case let button as NSButton:
			button.title = self
		case let textView as NSTextView:
			textView.string = self
		case let textField as NSTextField:
			textField.stringValue = self
		default:
			break
		}
		
		view.setAccessibilityIdentifier(originalKey)
	}
}

// MARK: - Extension - NSAttributedString

public extension NSAttributedString {
	
	// MARK: - Exposed Methods

	func render(target: Any?) {
		guard let view = target as? NSView else {
			return
		}
		
		switch view {
		case let label as NSTextField:
			label.attributedStringValue = self
		case let button as NSButton:
			button.attributedTitle = self
		case let textView as NSTextView:
			textView.textStorage?.setAttributedString(self)
		case let textField as NSTextField:
			textField.attributedStringValue = self
		default:
			break
		}
		
		view.setAccessibilityIdentifier(content.originalKey)
	}
}
#elseif canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Definitions -

public extension NSTextAlignment {
	
	/// Mirrors the alignment.
	var mirror: NSTextAlignment {
		switch self {
		case .left:
			return .right
		case .right:
			return .left
		default:
			return self
		}
	}
}

public extension Dictionary where Key == NSAttributedString.Key, Value == Any {
	
	static func attributed(font: UIFont? = nil,
						   color: UIColor? = nil,
						   lineSpacing: CGFloat? = nil,
						   lineHeight: CGFloat? = nil,
						   alignment: NSTextAlignment? = nil) -> Self {
		var attributes = Self()
		
		if let newFont = font {
			attributes[.font] = newFont
		}
		
		if let newColor = color {
			attributes[.foregroundColor] = newColor
		}
		
		if lineSpacing != nil || lineHeight != nil || alignment != nil {
			let paragraph = NSMutableParagraphStyle()
			paragraph.alignment = alignment ?? .natural
			paragraph.lineSpacing = lineSpacing ?? 0
			paragraph.lineHeightMultiple = lineHeight ?? 0
			paragraph.lineBreakMode = .byTruncatingTail
			attributes[.paragraphStyle] = paragraph
		}
		
		return attributes
	}
}

public extension TextConvertible {
	
	func styled(font: UIFont? = nil,
				color: UIColor? = nil,
				lineSpacing: CGFloat? = nil,
				lineHeight: CGFloat? = nil,
				alignment: NSTextAlignment? = nil,
				overriding: Bool = true) -> NSAttributedString {
		styled(.attributed(font: font, color: color, lineSpacing: lineSpacing, lineHeight: lineHeight, alignment: alignment),
			   overriding: overriding)
	}
}

// MARK: - Extension - String

public extension String {

// MARK: - Exposed Methods
	
	func render(target: Any?) {
		switch target {
		case let label as UILabel:
			label.text = self
		case let button as UIButton:
			button.setTitle(self, for: .normal)
		case let textView as UITextView:
			textView.text = self
		case let textField as UITextField:
			textField.text = self
		default:
			break
		}
		
		(target as? UIView)?.accessibilityIdentifier = originalKey
	}
	
	func sizeThatFits(font: UIFont,
					  width: CGFloat = .greatestFiniteMagnitude,
					  height: CGFloat = .greatestFiniteMagnitude) -> CGSize {
		let string = NSString(string: self)
		let rect = string.boundingRect(with: CGSize(width: width, height: height),
									   options: .usesLineFragmentOrigin,
									   attributes: [.font: font],
									   context: nil)
		return rect.size
	}
	
	@inlinable func appending(_ image: UIImage) -> NSAttributedString { appending(" ").appending(image.toText()) }
}

// MARK: - Extension - NSAttributedString

public extension NSAttributedString {
	
// MARK: - Exposed Methods

	func render(target: Any?) {
		switch target {
		case let label as UILabel:
			label.attributedText = self
		case let button as UIButton:
			button.setAttributedTitle(self, for: .normal)
		case let textView as UITextView:
			textView.attributedText = self
		case let textField as UITextField:
			textField.attributedText = self
		default:
			break
		}
		
		(target as? UIView)?.accessibilityIdentifier = content.originalKey
	}
	
	/// Appends an image to the string.
	///
	/// - Parameter image: The image to be appended.
	/// - Returns: The final concatenated result.
	@inlinable func appending(_ image: UIImage) -> NSAttributedString { appending(" ").appending(image.toText()) }
}

// MARK: - Extension - Optional TextConvertible

public extension Optional where Wrapped == TextConvertible {
	
	func render(target: Any?) {
		
		switch self {
		case let .some(value):
			value.render(target: target)
			return
		default:
			switch target {
			case let label as UILabel:
				label.text = nil
			case let button as UIButton:
				button.setTitle(nil, for: .normal)
			case let textView as UITextView:
				textView.text = nil
			case let textField as UITextField:
				textField.text = nil
			default:
				break
			}
		}
	}
}

// MARK: - Extension - UILabel

public extension UILabel {
	
	convenience init(text: TextConvertible?,
					 fitting: CGSize = .zero,
					 font aFont: UIFont = .body,
					 color: UIColor = .label,
					 aligment: NSTextAlignment = .natural,
					 minimumScale: CGFloat = 0.7,
					 lines: Int = 0) {
		let size = text?.content.sizeThatFits(font: aFont, width: fitting.width, height: fitting.height) ?? .zero
		self.init(frame: CGRect(origin: .zero, size: size))
		font = aFont
		textColor = color
		adjustsFontForContentSizeCategory = true
		adjustsFontSizeToFitWidth = true
		minimumScaleFactor = minimumScale
		numberOfLines = lines
		textAlignment = isRTL ? aligment.mirror : aligment
		text.render(target: self)
	}
	
	func sizeToFitContent(maxWidth: CGFloat = .greatestFiniteMagnitude) {
		guard
			let validText = text,
			let validFont = font
		else { return }
		
		let size = validText.sizeThatFits(font: validFont, width: maxWidth)
		var newFrame = frame
		newFrame.size = size + CGSize(width: 0, height: 20)
		
		frame = newFrame
	}
	
	/// Automatically aligns the text accordingly to the view direction. Either Left or Right. All the other alignment parameters
	/// remain unchanged.
	///
	/// - Parameter direction: The text alignment.
	func textAlignment(to direction: NSTextAlignment) {
		textAlignment = isRTL ? direction.mirror : direction
	}
}

// MARK: - Extension - UIImage

public extension UIImage {
	
	func toText(offset: CGPoint = .zero) -> NSAttributedString {
		
		let attachment = NSTextAttachment()
		attachment.image = self
		
		if let image = attachment.image {
			attachment.bounds = CGRect(origin: offset, size: image.size)
		}
		
		return NSAttributedString(attachment: attachment)
	}
}
#endif
