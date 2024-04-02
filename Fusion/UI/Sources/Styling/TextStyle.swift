//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(AppKit)
import AppKit

// MARK: - Extension - String

public extension String {

	// MARK: - Exposed Methods
	
	func render(on target: Any?) {
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

// MARK: - Extension - String.SubSequence

public extension String.SubSequence {

	// MARK: - Exposed Methods
	
	func render(on target: Any?) { string.render(on: target) }
}

// MARK: - Extension - NSAttributedString

public extension NSAttributedString {
	
	// MARK: - Exposed Methods

	func render(on target: Any?) {
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

// MARK: - Extension - TextConvertible

public extension TextConvertible {
	
	func boundingSize(width: CGFloat? = nil, height: CGFloat? = nil) -> CGSize {
		let constraintRect = CGSize(width: width ?? .greatestFiniteMagnitude, height: height ?? .greatestFiniteMagnitude)
		let box = styled(attributes, overriding: false).boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
		return box.size
	}
}
#elseif canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Definitions -

public extension NSTextAlignment {
	
	/// Safer RTL compatible alignment.
	var rtlSafe: NSTextAlignment {
		let isRTL = Locale.preferredLocale.isRTL
		
		switch self {
		case .left, .natural:
			return isRTL ? .right : .left
		case .right:
			return isRTL ? .left : .right
		default:
			return self
		}
	}
}

public extension TextAttributes {
	
	static func attributed(font: UIFont? = nil,
						   color: UIColor? = nil,
						   lineSpacing: CGFloat? = nil,
						   lineHeight: CGFloat? = nil,
						   linebreak: NSLineBreakMode? = nil,
						   alignment: NSTextAlignment? = nil) -> Self {
		var attributes = Self()
		
		if let newFont = font {
			attributes[.font] = newFont
		}
		
		if let newColor = color {
			attributes[.foregroundColor] = newColor
		}
		
		if lineSpacing != nil || lineHeight != nil || linebreak != nil || alignment != nil {
			let paragraph = NSMutableParagraphStyle()
			paragraph.alignment = (alignment ?? .natural).rtlSafe
			paragraph.lineSpacing = lineSpacing ?? 0
			paragraph.lineHeightMultiple = lineHeight ?? 0
			paragraph.lineBreakMode = linebreak ?? .byTruncatingTail
			attributes[.paragraphStyle] = paragraph
		}
		
		return attributes
	}
}

public extension TextConvertible {
	
	func boundingSize(width: CGFloat? = nil, height: CGFloat? = nil) -> CGSize {
		let constraintRect = CGSize(width: width ?? .greatestFiniteMagnitude, height: height ?? .greatestFiniteMagnitude)
		let box = styled(attributes, overriding: false).boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
		return box.size
	}
	
	func styled(font: UIFont? = nil,
				color: UIColor? = nil,
				lineSpacing: CGFloat? = nil,
				lineHeight: CGFloat? = nil,
				linebreak: NSLineBreakMode? = nil,
				alignment: NSTextAlignment? = nil,
				overriding: Bool = true) -> NSAttributedString {
		styled(.attributed(font: font, color: color, lineSpacing: lineSpacing, lineHeight: lineHeight, linebreak: linebreak, alignment: alignment),
			   overriding: overriding)
	}
}

// MARK: - Extension - String

public extension String {

// MARK: - Exposed Methods
	
	func render(on target: Any?) {
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
	
	func sizeThatFits(font: UIFont, width: CGFloat = .greatestFiniteMagnitude, height: CGFloat = .greatestFiniteMagnitude) -> CGSize {
		let string = NSString(string: self)
		let rect = string.boundingRect(with: CGSize(width: width, height: height),
									   options: .usesLineFragmentOrigin,
									   attributes: [.font: font],
									   context: nil)
		return rect.size
	}
	
	@inlinable func appending(_ image: UIImage) -> NSAttributedString { appending(" ").appending(image.toText()) }
}

// MARK: - Extension - String.SubSequence

public extension String.SubSequence {

// MARK: - Exposed Methods
	
	func render(on target: Any?) { string.render(on: target) }
	
	func sizeThatFits(font: UIFont, width: CGFloat = .greatestFiniteMagnitude, height: CGFloat = .greatestFiniteMagnitude) -> CGSize {
		string.sizeThatFits(font: font, width: width, height: height)
	}
	
	@inlinable func appending(_ image: UIImage) -> NSAttributedString { string.appending(image) }
}

// MARK: - Extension - NSAttributedString

public extension NSAttributedString {
	
// MARK: - Exposed Methods

	func render(on target: Any?) {
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
	
	func render(on target: Any?) {
		
		switch self {
		case let .some(value):
			value.render(on: target)
			return
		default:
			switch target {
			case let label as UILabel:
				label.text = nil
			case let button as UIButton:
				button.setTitle("", for: .normal)
				button.setAttributedTitle(nil, for: .normal)
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
		textAlignment = aligment.rtlSafe
		text.render(on: self)
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
