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
	var rgb: RGB { RGB(ciColor: CIColor(color: self)) }
	
	/// Returns the hexadecimal string for this color.
	var hexString: String {
		let values = RGB(ciColor: CIColor(color: self))
		return String(format: "#%02lX%02lX%02lX", values.r, values.g, values.b)
	}
	
	/// Returns the alpha for this color
	var alpha: CGFloat {
		return CIColor(color: self).alpha
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
