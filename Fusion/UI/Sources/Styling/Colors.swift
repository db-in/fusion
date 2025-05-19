//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Definitions -

fileprivate extension CGFloat {
	
	var normalized: Int { lroundf(Float(self * 255)) }
}

public struct RGB {
	
	public let r: Int
	public let g: Int
	public let b: Int
	
	fileprivate init(ciColor: CIColor) {
		r = ciColor.red.normalized
		g = ciColor.green.normalized
		b = ciColor.blue.normalized
	}
}

// MARK: - Extension -

public extension UIColor {
	
// MARK: - Properties
	
	/// Returns the RGB object for this color.
	var rgb: RGB { RGB(ciColor: CIColor(color: resolved())) }
	
	/// Returns the hexadecimal string for this color.
	var hexString: String {
		let values = RGB(ciColor: CIColor(color: resolved()))
		return String(format: "#%02lX%02lX%02lX", values.r, values.g, values.b)
	}
	
	/// Returns the alpha for this color
	var alpha: CGFloat {
		return CIColor(color: resolved()).alpha
	}
	
	/// Returns the color in its opposite style mode from the current one used by the device settigns.
	var oppositeStyleMode: UIColor {
		resolved(with: UIView.interfaceStyle == .dark ? .light : .dark)
	}
	
// MARK: - Initializers
	
	convenience init(hex: String) {
		var normalized = hex.replacingOccurrences(of: "0x", with: "").replacingOccurrences(of: "#", with: "")
		
		if normalized.count < 6 {
			normalized = normalized.reduce("", { "\($0)\($1)\($1)" })
		}
		
		let hexValue = UInt32(normalized, radix: 16) ?? 0
		let red = CGFloat((hexValue & 0xFF0000) >> 16) / 255.0
		let green = CGFloat((hexValue & 0x00FF00) >> 8) / 255.0
		let blue = CGFloat(hexValue & 0x0000FF) / 255.0
		
		self.init(red: red, green: green, blue: blue, alpha: 1.0)
	}
	
// MARK: - Protected Methods
	
	private static func inAnyBundle(_ named: String, trait: UITraitCollection?) -> UIColor? {
		Bundle.allAvailable.firstMap { .init(named: named, in: $0, compatibleWith: trait) } ?? .init(named: named)
	}
	
	private static func color(named: String, bundle: Bundle, trait: UITraitCollection?) -> UIColor? {
		.init(named: named, in: bundle, compatibleWith: trait) ?? inAnyBundle(named, trait: trait)
	}

// MARK: - Exposed Methods
	
	/// Resolves and return a color based on a specified user interface style
	///
	/// - Parameter style: The `UIUserInterfaceStyle` to resolve against.
	/// - Returns: A new `UIColor`.
	func resolved(with style: UIUserInterfaceStyle? = UIView.interfaceStyle) -> UIColor {
		if #available(iOS 13.0, *) {
			guard let validStyle = style else { return self }
			return resolvedColor(with: UITraitCollection(userInterfaceStyle: validStyle))
		} else {
			return self
		}
	}
	
	/// Returns the resulted CGColor with a given style.
	///
	/// - Parameter style: A given style. By default its value is ``UIView.interfaceStyle``
	/// - Returns: The resulting CGColor.
	func cgResolved(with style: UIUserInterfaceStyle? = UIView.interfaceStyle) -> CGColor {
		guard let validStyle = style else { return cgColor }
		return resolved(with: validStyle).cgColor
	}
	
	/// Creates an interpolation/transition between 2 colors given a percentage.
	///
	/// - Parameters:
	///   - toColor: The color to transition to.
	///   - percentage: The percentage in the range of [0-1].
	/// - Returns: The resulting interpolation.
	func interpolated(toColor: UIColor, percentage: CGFloat) -> UIColor {
		let fromRGB = rgb
		let toRGB = toColor.rgb
		
		return .init(
			red: (CGFloat(fromRGB.r) + CGFloat(toRGB.r - fromRGB.r) * percentage) / 255,
			green: (CGFloat(fromRGB.g) + CGFloat(toRGB.g - fromRGB.g) * percentage) / 255,
			blue: (CGFloat(fromRGB.b) + CGFloat(toRGB.b - fromRGB.b) * percentage) / 255,
			alpha: alpha + (toColor.alpha - alpha) * percentage
		)
	}
	
	/// Adjusts the color by making it darker. A value of 0.0 leaves the color unchanged, while a value of 1.0 results in full darkness.
	///
	/// - Parameter factor: A CGFloat value representing the amount by which to darken the color.
	/// - Returns: A darker version of the original color.
	func darker(by factor: CGFloat) -> UIColor {
		var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
		guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return self }
		
		let newRed = max(red - factor, 0)
		let newGreen = max(green - factor, 0)
		let newBlue = max(blue - factor, 0)
		
		return UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: alpha)
	}
	
	/// Adjusts the color by modifying its saturation and brightness. Positive values increase, while negative values decrease.
	/// Value of 0.0 keeps it unchanged.
	///
	/// - Parameters:
	///   - saturation: A CGFloat value representing the change in HUE. Default is 0.0, which means no change. Values can be between [-1.0, 1.0].
	///   - saturation: A CGFloat value representing the change in saturation. Default is 0.0.
	///   - brightness: A CGFloat value representing the change in brightness. Default is 0.0.
	/// - Returns: An adjusted version of the original color.
	func adjust(hue: CGFloat = 0.0, saturation: CGFloat = 0.0, brightness: CGFloat = 0.0) -> UIColor {
		var currentHue: CGFloat = 0, currentSaturation: CGFloat = 0, currentBrightness: CGFloat = 0, alpha: CGFloat = 0
		guard getHue(&currentHue, saturation: &currentSaturation, brightness: &currentBrightness, alpha: &alpha) else { return self }

		let newHue = (currentHue + hue).truncatingRemainder(dividingBy: 1)
		let newSaturation = min(max(currentSaturation + saturation, 0), 1)
		let newBrightness = min(max(currentBrightness + brightness, 0), 1)

		return UIColor(hue: newHue, saturation: newSaturation, brightness: newBrightness, alpha: alpha)
	}
	
	/// Retrieves a `UIColor` by name, with optional caching and bundle hinting.
	///
	/// This function attempts to load a color resource by its name from a specified bundle,
	/// with the option to cache the result for future use. If the color is not found in the
	/// specified bundle, it falls back to searching all available bundles.
	///
	/// - Parameters:
	///   - named: The name of the color resource to load.
	///   - allowCache: A Boolean value indicating whether to cache the color once found. Defaults to `true`.
	///   - bundleHint: The initial bundle to search for the color resource. Defaults to `.main`.
	///   - trait: The `UITraitCollection` to use when loading the color, allowing for dynamic color variants. Defaults to `.current`.
	///
	/// - Returns: The `UIColor` corresponding to the specified name, or a default color if not found.
	///            If caching is enabled, the color is stored in an in-memory cache for faster future retrievals.
	static func anyColor(named: String, allowCache: Bool = true, bundleHint: Bundle = .main, trait: UITraitCollection? = .current) -> UIColor {
		guard allowCache else { return color(named: named, bundle: bundleHint, trait: trait) ?? .black }
		return InMemoryCache.getOrSet(key: "\(Self.self)-\(named)", newValue: color(named: named, bundle: bundleHint, trait: trait)) ?? .black
	}
	
	/// Returns a random color with a given alpha.
	/// - Parameter alpha: The alpha between [0.0, 1.0], the default value is 1.0.
	/// - Returns: A random generated UIColor.
	static func random(alpha: CGFloat = 1.0) -> UIColor {
		.init(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: alpha)
	}
	
	/// Returns a gradient color using a gradient image pattern. It's important to be aware of the size of the generated gradient,
	/// it has direct relation with the resulting effect.
	///
	/// - Parameters:
	///   - colors: The gradient of colors to be used.
	///   - size: The pattern size. The default is `(width:10,height:10)`.
	///   - start: The percentual starting point [0-1]. The default is `(x:0,y:0)`.
	///   - end: The percentual ending point [0-1]. The default is `(x:0,y:1)`.
	///   - type: The type of gradient. The default is `axial`.
	/// - Returns: The resulting gradient color.
	static func gradient(_ colors: [UIColor],
						 size: CGSize = .init(width: 10, height: 10),
						 start: CGPoint = .init(x: 0, y: 0),
						 end: CGPoint = .init(x: 0, y: 1),
						 type: CAGradientLayerType = .axial) -> UIColor {
		.init(patternImage: UIView(frame: .init(size: size)).make(gradient: colors, start: start, end: end, type: type).snapshot)
	}
}

public extension CGColor {
	
	var uiColor: UIColor { .init(cgColor: self) }
	
	static var clear: CGColor { UIColor.clear.cgColor }
	
	static var white: CGColor { UIColor.white.cgColor }
	
	static var black: CGColor { UIColor.black.cgColor }
}
#endif

#if canImport(SwiftUI)
import SwiftUI

public extension Color {
	
// MARK: - Protected Methods
	
	private var nilIfClear: Self? {
		let color: CGColor
		
		if #available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *) {
			color = resolve(in: .init()).cgColor
		} else {
			color = cgColor ?? {
				#if canImport(AppKit)
				return NSColor(self).cgColor
				#else
				return .init(gray: 0, alpha: 0)
				#endif
			}()
		}
		
		return color.alpha == 0 ? nil : self
	}
	
	private static func inAnyBundle(_ named: String) -> Color? {
		Bundle.allAvailable.firstMap { .init(named, bundle: $0).nilIfClear } ?? .init(named)
	}
	
	private static func color(named: String, bundle: Bundle) -> Color? {
		.init(named, bundle: bundle).nilIfClear ?? inAnyBundle(named)
	}

// MARK: - Exposed Methods
	
	/// Retrieves a `UIColor` by name, with optional caching and bundle hinting.
	///
	/// This function attempts to load a color resource by its name from a specified bundle,
	/// with the option to cache the result for future use. If the color is not found in the
	/// specified bundle, it falls back to searching all available bundles.
	///
	/// - Parameters:
	///   - named: The name of the color resource to load.
	///   - allowCache: A Boolean value indicating whether to cache the color once found. Defaults to `true`.
	///   - bundleHint: The initial bundle to search for the color resource. Defaults to `.main`.
	///
	/// - Returns: The `UIColor` corresponding to the specified name, or a default color if not found.
	///            If caching is enabled, the color is stored in an in-memory cache for faster future retrievals.
	static func anyColor(named: String, allowCache: Bool = true, bundleHint: Bundle = .main) -> Color {
#if canImport(UIKit) && !os(watchOS)
		return Color(uiColor: .anyColor(named: named, allowCache: allowCache, bundleHint: bundleHint))
#else
		guard allowCache else { return color(named: named, bundle: bundleHint) ?? .black }
		return InMemoryCache.getOrSet(key: "\(Self.self)-\(named)", newValue: color(named: named, bundle: bundleHint)) ?? .black
#endif
	}
}
#endif
