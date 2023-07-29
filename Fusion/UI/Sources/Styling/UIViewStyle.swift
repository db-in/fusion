//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Definitions -

private struct ObjcKeys {
	
	static var shadowKey: UInt8 = 1
	static var borderKey: UInt8 = 2
	static var gradientKey: UInt8 = 3
}

// MARK: - Extension - UIRectCorner

public extension CAGradientLayer {
	
	enum Style {
		case radial
		case vertical
		case horizontal
		
		func configure(_ layer: CAGradientLayer) {
			switch self {
			case .radial:
				layer.type = .radial
				layer.startPoint = CGPoint(x: 0.5, y: 0.5)
				layer.endPoint = CGPoint(x: 1.0, y: 1.0)
			case .vertical:
				layer.type = .axial
				layer.startPoint = CGPoint(x: 0, y: 0)
				layer.endPoint = CGPoint(x: 0, y: 1.0)
			case .horizontal:
				layer.type = .axial
				layer.startPoint = CGPoint(x: 0, y: 0)
				layer.endPoint = CGPoint(x: 1.0, y: 0)
			}
		}
	}

	convenience init(pattern: [UIColor], size: CGSize, style: Style = .radial) {
		self.init()
		colors = pattern.map(\.cgColor)
		frame = CGRect(origin: .zero, size: size)
		style.configure(self)
	}
	
	convenience init(variations: Int) {
		self.init()
		guard variations > 1 else { return }
		colors = [CGColor](repeating: .black, count: variations)
		locations = [NSNumber](repeating: 0, count: variations - 1) + [1]
	}
}

// MARK: - Extension - UIUserInterfaceStyle

public extension UIUserInterfaceStyle {
	
	var opposite: Self {
		switch self {
		case .light:
			return .dark
		case .dark:
			return .light
		default:
			return self
		}
	}
}

// MARK: - Extension - UIRectCorner

public extension UIRectCorner {
	
	var maskedCorners: CACornerMask { .init(rawValue: rawValue) }
}

public extension CACornerMask {
	var rectCorners: UIRectCorner { .init(rawValue: rawValue) }
}
// MARK: - Extension - UIView Corner

public extension UIView {

// MARK: - Properties
	
	@IBInspectable var cornerRadius: CGFloat {
		get { layer.cornerRadius }
		set {
			layer.cornerRadius = newValue
			layer.masksToBounds = hasShadow ? false : newValue > 0.0
		}
	}
	
	@IBInspectable var circularFrame: CGRect {
		get { bounds }
		set {
			frame = newValue
			cornerRadius = CGFloat.minimum(newValue.width, newValue.height) * 0.5
		}
	}
	
// MARK: - Constructor
	
	convenience init(circular: CGRect, backgroundColor color: UIColor = .clear) {
		self.init()
		circularFrame = circular
		backgroundColor = color
	}
	
// MARK: - Protected Methods
	
	@discardableResult func makeCornerRadius(at: UIRectCorner, radius: CGFloat) -> Self {
		cornerRadius = radius
		layer.maskedCorners = at.maskedCorners
		return self
	}
}

// MARK: - Extension - UIView Border

public extension UIView {
	
	typealias Border = (color: UIColor, width: CGFloat)
	
	private var borderLayer: CALayer? {
		get { objc_getAssociatedObject(self, &ObjcKeys.borderKey) as? CALayer }
		set { objc_setAssociatedObject(self, &ObjcKeys.borderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
	}
	
	/// The current border width.
	@IBInspectable var borderWidth: CGFloat {
		get { layer.borderWidth }
		set { layer.borderWidth = newValue }
	}
	
	/// The current border color.
	@IBInspectable var borderColor: UIColor? {
		get { layer.borderColor?.uiColor }
		set { layer.borderColor = newValue?.cgResolved(with: interfaceStyle) }
	}
	
	/// Makes a regular border on the current view.
	///
	/// - Parameter border: The border settings.
	/// - Returns: Returns self same instance for convenience.
	@discardableResult func make(border: Border?) -> Self{
		borderColor = border?.color
		borderWidth = border?.width ?? 0
		return self
	}
	
	/// Makes a regular border on the current view and sets its corner radius as half of the current height.
	///
	/// - Parameter border: The border settings.
	/// - Returns: Returns self same instance for convenience.
	@discardableResult func makeCapsule(border: Border?) -> Self {
		borderColor = border?.color
		borderWidth = border?.width ?? 0
		cornerRadius = frame.height * 0.5
		return self
	}
	
	/// Makes a dashed border on the current view following the current corners.
	///
	/// - Parameters:
	///   - pattern: The solid and spacing pattern ratio. [1,1] means solid and spaces happens 1 to 1 ratio.
	///   - border: The border settings.
	/// - Returns: Returns self same instance for convenience.
	@discardableResult func makeDashedBorder(_ pattern: [Int], border: Border?) -> Self {
		borderLayer?.removeFromSuperlayer()
		guard !pattern.isEmpty else { return self }
		let dashed = CAShapeLayer()
		dashed.strokeColor = border?.color.cgResolved(with: interfaceStyle)
		dashed.lineDashPattern = pattern as [NSNumber]
		dashed.lineWidth = border?.width ?? 0
		dashed.frame = bounds
		dashed.fillColor = nil
		dashed.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
		layer.addSublayer(dashed)
		borderLayer = dashed
		return self
	}
	
	/// Makes concentric borders following the current corner configuration. This method does not automatically redraws.
	///
	/// - Parameter borders: The array of concentrict borders.
	/// - Returns: Returns self same instance for convenience.
	@discardableResult func make(borders: [Border]) -> Self {
		let name = "MultiBorder"
		let radius = cornerRadius
		var totalWidth: CGFloat = 0
		var previous: CGFloat = 0
		
		layer.sublayers?.filter(\.name == name).forEach { $0.removeFromSuperlayer() }
		borders.forEach { border in
			totalWidth += border.width * 0.5
			let shape = CAShapeLayer()
			let shapeFrame = bounds.integral.insetBy(dx: totalWidth, dy: totalWidth)
			shape.strokeColor = border.color.cgColor
			shape.lineWidth = border.width
			shape.frame = bounds
			shape.fillColor = .clear
			
			if radius == 0 {
				shape.path = UIBezierPath(rect: shapeFrame).cgPath
			} else {
				let corners = layer.maskedCorners.rectCorners
				let size = CGSize(squared: radius - previous - (border.width * 0.5))
				shape.path = UIBezierPath(roundedRect: shapeFrame, byRoundingCorners: corners, cornerRadii: size).cgPath
			}
			
			shape.name = name
			layer.addSublayer(shape)
			totalWidth += border.width * 0.5
			previous = border.width
		}
		
		return self
	}
}

// MARK: - Extension - UIView Shadow

public extension UIView {
	
	private var shadowLayer: CALayer? {
		get { objc_getAssociatedObject(self, &ObjcKeys.shadowKey) as? CALayer }
		set { objc_setAssociatedObject(self, &ObjcKeys.shadowKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
	}

	/// Returns true if there is an existing gradient created by using ``makeShadow(radius:fillColor:shadowColor:opacity:offset:cornerRadius:)``
	var hasShadow: Bool { (shadowLayer?.shadowOpacity ?? 0) > 0 }
	
	/// Makes a shadow in the background of the view.
	///
	/// - Returns: Returns self for nested calls purpose.
	/// - Important: This routine uses layers to create its effect, changing layers after calling this method may produce undesired effects.
	/// - Parameters:
	///   - radius: The shadow radius. The default is `4`.
	///   - fillColor: The new fill color of the view. The default is `black`.
	///   - shadowColor: The shadow color. The default is `black`.
	///   - opacity: The shadow opacity. The default is `0.3.
	///   - offset: The shadow offset. The default is `zero.
	///   - cornerRadius: The corner radius of the view. The default is `0.
	@discardableResult func makeShadow(radius: CGFloat = 4.0,
									   fillColor: UIColor = .black,
									   shadowColor: UIColor = .black,
									   opacity: Float = 0.3,
									   offset: CGSize = .zero,
									   cornerRadius: CGFloat = 0.0) -> Self {
		asyncMain {
			self.cornerRadius = 0
			let shadow = self.shadowLayer ?? CALayer()
			let interface = self.interfaceStyle
			
			shadow.frame = self.bounds
			shadow.cornerRadius = cornerRadius
			shadow.backgroundColor = fillColor.cgResolved(with: interface)
			shadow.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius).cgPath
			shadow.shadowColor = shadowColor.cgResolved(with: interface)
			shadow.shadowOpacity = opacity
			shadow.shadowOffset = offset
			shadow.shadowRadius = radius
			self.layer.insertSublayer(shadow, at: 0)
			self.layer.cornerRadius = cornerRadius
			self.shadowLayer = shadow
		}
		return self
	}
}

// MARK: - Extension - UIView Gradient

public extension UIView {
	
	private var gradientLayer: CAGradientLayer? {
		get { objc_getAssociatedObject(self, &ObjcKeys.gradientKey) as? CAGradientLayer }
		set { objc_setAssociatedObject(self, &ObjcKeys.gradientKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
	}
	
	/// Returns true if there is an existing gradient created by using ``makeGradient(colors:start:end:type:)``
	var hasGradient: Bool { gradientLayer != nil }
	
	/// Makes a gradient in the background of the view. Call the method once at every redraw.
	///
	/// - Parameters:
	///   - colors: An array of colors. If empty ([]) any existing gradient is removed.
	///   - start: The percentual starting point [0-1]. The default is `(x:0,y:0)`.
	///   - end: The percentual ending point [0-1]. The default is `(x:0,y:1)`.
	///   - type: The type of gradient. The default is `axial`.
	/// - Returns: Returns self for nested calls purpose.
	/// - Important: This routine uses layers to create its effect, changing layers after calling this method may produce undesired effects.
	@discardableResult func makeGradient(colors: [UIColor],
										 start: CGPoint = .init(x: 0, y: 0),
										 end: CGPoint = .init(x: 0, y: 1),
										 type: CAGradientLayerType = .axial) -> Self {
		
		guard !colors.isEmpty else {
			gradientLayer?.removeFromSuperlayer()
			gradientLayer = nil
			return self
		}
		
		let newLayer = gradientLayer ?? CAGradientLayer()
		newLayer.frame = CGRect(origin: .zero, size: bounds.size)
		newLayer.colors = colors.map(\.cgColor)
		newLayer.startPoint = start
		newLayer.endPoint = end
		newLayer.type = type
		newLayer.zPosition = -1000
		layer.insertSublayer(newLayer, at: 0)
		gradientLayer = newLayer
		
		return self
	}
}

// MARK: - Extension - UIView Others

public extension UIView {
	
	/// Returns true if the given view is being rendered as right to left layout direction.
	var isRTL: Bool { traitCollection.layoutDirection == .rightToLeft }
	
	var hasSuperview: Bool { superview != nil }
	
	var visibility: CGFloat {
		get { alpha }
		set {
			let delta = frame.height * 0.25
			let change = delta - (newValue * delta)
			subviews.forEach {
				$0.transform = CGAffineTransform(translationX: 0, y: change)
				$0.alpha = newValue
			}
		}
	}
	
	var snapshot: UIImage {
		let renderer = UIGraphicsImageRenderer(bounds: bounds)
		return renderer.image { rendererContext in
			layer.render(in: rendererContext.cgContext)
		}
	}
	
	var interfaceStyle: UIUserInterfaceStyle {
		get { traitCollection.userInterfaceStyle }
		set {
			if #available(iOS 13.0, *) {
				overrideUserInterfaceStyle = newValue
			}
		}
	}
	
	static var interfaceStyle: UIUserInterfaceStyle { UIWindow.key?.interfaceStyle ?? .light }
	
	func embededInView(edges: UIEdgeInsets = .zero) -> UIView {
		let origin = CGPoint(x: edges.left, y: edges.top)
		let size = CGSize(width: bounds.width - (edges.left + edges.right), height: bounds.height - (edges.top + edges.bottom))
		let view = UIView(frame: .init(origin: origin, size: size))
		view.addSubview(self)
		view.setConstraintsFitting(child: self, edges: edges)
		return view
	}
	
	static func spacer(width: CGFloat? = nil, height: CGFloat? = nil, backgroundColor: UIColor? = nil) -> UIView {
		let view = UIView(frame: .init(x: 0, y: 0, width: width ?? 0, height: height ?? 0))
		view.backgroundColor = backgroundColor
		view.setConstraints(width: width, height: height)
		return view
	}
}

// MARK: - Extension - UIVisualEffectView

public extension UIVisualEffectView {
	
	convenience init(frame: CGRect, blur: UIBlurEffect.Style) {
		self.init(effect: UIBlurEffect(style: blur))
		self.frame = frame
		self.autoresizingMask = [.flexibleWidth, .flexibleHeight]
	}
}
#endif
