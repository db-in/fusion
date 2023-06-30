//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit)
import UIKit

// MARK: - Definitions -

private struct ObjcKeys {
	
	static var shadowKey: UInt8 = 1
	static var borderKey: UInt8 = 2
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
	
	var maskedCorners: CACornerMask {
		CACornerMask(rawValue: rawValue)
	}
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
	
	func setCornerRadius(at: UIRectCorner, radius: CGFloat) {
		cornerRadius = radius
		layer.maskedCorners = at.maskedCorners
	}
}

// MARK: - Extension - UIView Border

public extension UIView {
	
	private var borderLayer: CALayer? {
		get { objc_getAssociatedObject(self, &ObjcKeys.borderKey) as? CALayer }
		set { objc_setAssociatedObject(self, &ObjcKeys.borderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
	}
	
	@IBInspectable var borderWidth: CGFloat {
		get { layer.borderWidth }
		set { layer.borderWidth = newValue }
	}

	@IBInspectable var borderColor: UIColor? {
		get { layer.borderColor?.uiColor }
		set { layer.borderColor = newValue?.cgResolved(with: interfaceStyle) }
	}
	
	func makeRoundedBox(background: UIColor, radius: CGFloat = 8.0) {
		backgroundColor = background
		cornerRadius = radius
	}
	
	func makeOutlinedBox(border: UIColor?, thickness: CGFloat = 1.0) {
		borderColor = border
		borderWidth = thickness
	}
	
	func makeRoundedOutlinedBox(border: UIColor?, thickness: CGFloat = 1.0, radius: CGFloat = 8.0) {
		borderColor = border
		borderWidth = thickness
		cornerRadius = radius
	}
	
	func makeDashedBorder(_ pattern: [Int], border: UIColor?, thickness: CGFloat = 1.0, radius: CGFloat = 8.0) {
		borderLayer?.removeFromSuperlayer()
		guard !pattern.isEmpty else { return }
		let dashed = CAShapeLayer()
		dashed.strokeColor = border?.cgResolved(with: interfaceStyle)
		dashed.lineDashPattern = pattern as [NSNumber]
		dashed.lineWidth = thickness
		dashed.frame = bounds
		dashed.fillColor = nil
		dashed.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
		layer.addSublayer(dashed)
		borderLayer = dashed
	}
}

// MARK: - Extension - UIView Shadow

public extension UIView {
	
	private var shadowLayer: CALayer? {
		get { objc_getAssociatedObject(self, &ObjcKeys.shadowKey) as? CALayer }
		set { objc_setAssociatedObject(self, &ObjcKeys.shadowKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
	}

	var hasShadow: Bool { (shadowLayer?.shadowOpacity ?? 0) > 0 }
	
	func applyShadow(radius: CGFloat = 4.0,
					 fillColor: UIColor = .black,
					 shadowColor: UIColor = .black,
					 opacity: Float = 0.3,
					 offset: CGSize = .zero,
					 cornerRadius: CGFloat = 0.0) {
		
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
	
	static var interfaceStyle: UIUserInterfaceStyle { .light }//UIWindow.key?.interfaceStyle
	
	func embededInView(edges: UIEdgeInsets = .zero) -> UIView {
		let view = UIView(frame: bounds.expand(top: edges.top, left: edges.left, bottom: edges.bottom, right: edges.right))
		view.addSubview(self)
//		view.setConstraintsFitting(child: self, edges: edges)
		return view
	}
	
	static func spacer(width: CGFloat? = nil, height: CGFloat? = nil, backgroundColor: UIColor? = nil) -> UIView {
		let view = UIView(frame: .init(x: 0, y: 0, width: width ?? 0, height: height ?? 0))
		view.backgroundColor = backgroundColor
//		view.setConstraints(width: width, height: height)
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
