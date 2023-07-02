//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Definitions -

// MARK: - Extension - UIFont.TextStyle

public extension UIFont.TextStyle {
	
	var font: UIFont {
		let loader = UIFont.customFont[self]?.font
		let finalFont = loader ?? UIFont.preferredFont(forTextStyle: self)
		let metrics = UIFontMetrics(forTextStyle: self)
		let scaledFont = metrics.scaledFont(for: finalFont)
		
		return scaledFont
	}
}

// MARK: - Extension - UIFont

public extension UIFont {
	
// MARK: - Properties
	
	var style: String { (fontDescriptor.object(forKey: .textStyle) as? String) ?? fontDescriptor.postscriptName }
	
#if os(iOS)
	static var largeTitle: UIFont = .TextStyle.largeTitle.font
#endif
	static var title1: UIFont = .TextStyle.title1.font
	static var title2: UIFont = .TextStyle.title2.font
	static var title3: UIFont = .TextStyle.title3.font
	static var headline: UIFont = .TextStyle.headline.font
	static var subheadline: UIFont = .TextStyle.subheadline.font
	static var body: UIFont = .TextStyle.body.font
	static var callout: UIFont = .TextStyle.callout.font
	static var footnote: UIFont = .TextStyle.footnote.font
	static var caption1: UIFont = .TextStyle.caption1.font
	static var caption2: UIFont = .TextStyle.caption2.font
	
	/// Defines custom fonts loaders for each style.
	static var customFont: [UIFont.TextStyle : FontLoader] = [:] {
		didSet {
#if os(iOS)
			largeTitle = .TextStyle.largeTitle.font
#endif
			title1 = .TextStyle.title1.font
			title2 = .TextStyle.title2.font
			title3 = .TextStyle.title3.font
			headline = .TextStyle.headline.font
			subheadline = .TextStyle.subheadline.font
			body = .TextStyle.body.font
			callout = .TextStyle.callout.font
			footnote = .TextStyle.footnote.font
			caption1 = .TextStyle.caption1.font
			caption2 = .TextStyle.caption2.font
		}
	}
}

// MARK: - Type - FontLoader

/// Loads the font inside the compiled collection of bundles.
public struct FontLoader {
	
// MARK: - Properties
	
	private static var inMemory: [String : String] = [:]
	
	public let file: String
	public let size: CGFloat
	
	/// The font name if it's found, otherwise empty string.
	public var fontName: String { Self.inMemory[file] ?? generateName() }
	
	/// The font if it's found, otherwise return ``systemFont``.
	public var font: UIFont { .init(name: fontName, size: size) ?? UIFont.systemFont(ofSize: size) }

// MARK: - Constructors

	public init(file: String, size: CGFloat) {
		self.file = file
		self.size = size
	}
	
// MARK: - Protected Methods
	
	private func generateName() -> String {
		
		guard
			let url = Bundle.allAvailable.firstMap({ $0.url(forResource: file, withExtension: "") }),
			let data = try? Data(contentsOf: url),
			let provider = CGDataProvider(data: data as CFData),
			let font = CGFont(provider),
			CTFontManagerRegisterGraphicsFont(font, nil),
			let fontName = font.postScriptName as? String
		else { return "" }

		Self.inMemory[file] = fontName
		
		return fontName
	}
}
#endif
