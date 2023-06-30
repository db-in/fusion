//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit)
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
	
	func cgResolved(with style: UIUserInterfaceStyle? = UIView.interfaceStyle) -> CGColor {
		guard let validStyle = style else { return cgColor }
		return resolved(with: validStyle).cgColor
	}
	
	/// Returns a random color with a given alpha.
	/// - Parameter alpha: The alpha between [0.0, 1.0], the default value is 1.0.
	/// - Returns: A random generated UIColor.
	static func random(alpha: CGFloat = 1.0) -> UIColor {
		.init(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), alpha: alpha)
	}
}

public extension CGColor {
	
	var uiColor: UIColor { .init(cgColor: self) }
	
	static var clear: CGColor { UIColor.clear.cgColor }
	
	static var white: CGColor { UIColor.white.cgColor }
	
	static var black: CGColor { UIColor.black.cgColor }
}
#endif
