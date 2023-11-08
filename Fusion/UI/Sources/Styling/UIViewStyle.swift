//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Definitions -

public extension CALayer {
	
	var maskPath: CGPath? { (mask as? CAShapeLayer)?.path?.copy() }
	
	func sublayers(named: String) -> [CALayer] { sublayers?.filter(\.name == named) ?? [] }
}

public extension Array where Element == CALayer {
	
	func removeAllFromSuperLayer() { forEach { $0.removeFromSuperlayer() } }
}

// MARK: - Extension - CAGradientLayer

/// Extends `CAGradientLayer` to provide convenience initializers for creating gradient layers with various styles.
public extension CAGradientLayer {
	
	/// Represents the different styles for gradient layers.
	enum Style {
		
		/// Radial gradient style.
		case radial
		
		/// Vertical linear gradient style.
		case vertical
		
		/// Horizontal linear gradient style.
		case horizontal
		
		/// Custom gradient style.
		case custom(start: CGPoint, end: CGPoint, type: CAGradientLayerType)
		
		/// Configures the given gradient layer according to the style.
		/// - Parameter layer: The gradient layer to be configured.
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
			case let .custom(start, end, type):
				layer.type = type
				layer.startPoint = start
				layer.endPoint = end
			}
		}
	}
	
	/// Creates a gradient layer with a specified pattern of colors, size, and style.
	/// - Parameters:
	///   - colors: An array of UIColor objects representing the gradient colors.
	///   - frame: The gradient layer's frame.
	///   - style: The style of the gradient layer. Default is `.radial`.
	convenience init(colors: [UIColor], frame: CGRect, style: Style = .radial) {
		self.init()
		self.colors = colors.map { $0.cgResolved() }
		self.frame = frame
		style.configure(self)
	}
	
	/// Creates a gradient layer with variations in color stops.
	/// - Parameter variations: The number of color variations.
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
	
	var hasTopCorners: Bool { contains(.topLeft) || contains(.topRight) }
	
	var hasBottomCorners: Bool { contains(.bottomLeft) || contains(.bottomRight) }
	
	var hasRoundedTop: Bool { contains(.topLeft) && contains(.topRight) }
	
	var hasRoundedBottom: Bool { contains(.bottomLeft) && contains(.bottomRight) }
	
	static var topCorners: Self { [.topLeft, .topRight] }
	
	static var bottomCorners: Self { [.bottomLeft, .bottomRight] }
	
	static var leadingCorners: Self { UIWindow.key?.isRTL == true ? [.topRight, .bottomRight] : [.topLeft, .bottomLeft] }
	
	static var trailingCorners: Self { UIWindow.key?.isRTL == true ? [.topLeft, .bottomLeft] : [.topRight, .bottomRight] }
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
			cornerRadius = newValue.size.squared.half.width
		}
	}
	
	var cornerCurve: CALayerCornerCurve {
		get { layer.cornerCurve }
		set { layer.cornerCurve = newValue }
	}
	
// MARK: - Constructor
	
	convenience init(circular: CGRect, background: UIColor? = nil, useConstraints: Bool = false, mode: ContentMode? = nil) {
		self.init(frame: circular, background: background, useConstraints: useConstraints, mode: mode)
		make(radius: circular.size.squared.half.width)
	}
	
// MARK: - Exposed Methods
	
	/// Applies a corner radius to specific corners of the current view's layer.
	/// - Parameters:
	///   - at: The corners to apply the corner radius to.
	///   - radius: The radius value for the corners.
	///   - curve: The corner curve style to use. Default is `.continuous`.
	/// - Returns: The modified view with the applied corner radius.
	@discardableResult func make(radius: CGFloat, corners: UIRectCorner = .allCorners, curve: CALayerCornerCurve = .continuous) -> Self {
		cornerRadius = radius
		layer.maskedCorners = corners.maskedCorners
		layer.cornerCurve = curve
		return self
	}
	
	/// Sets its corner radius as half of the current height.
	///
	/// - Returns: Returns self same instance for convenience.
	@discardableResult func makeCapsule() -> Self {
		make(radius: frame.height * 0.5)
	}
	
	/// Applies a soft curve rounded corners with options to expand and distort the rect by its edges.
	///
	/// - Parameters:
	///   - bezierCorners: The radii for each corner of the view.
	///   - edges: The offsets for each edge of the view. Default is `.zero`.
	///   - aspectToFit: Defines if the aspect will set to fit inside the given rect. The default is `true`.
	/// - Returns: Returns self same instance for convenience.
	@discardableResult func make(bezierCorners: RectCorners, edges: RectEdges = .zero, aspectToFit: Bool = true) -> Self {
		let path = UIBezierPath(smooth: bounds, corners: bezierCorners, edges: edges, aspectToFit: aspectToFit)
		let maskLayer = CAShapeLayer()
		maskLayer.path = path.cgPath
		layer.mask = maskLayer
		return self
	}
	
	/// Removes previously applied bezier corners.
	/// - Returns: Returns self same instance for convenience.
	@discardableResult func removeBezierCorners() -> Self {
		layer.mask = nil
		return self
	}
}

// MARK: - Extension - UIView Border

public extension UIView {
	
	struct Border : Equatable {
		
		public let color: UIColor?
		public let width: CGFloat
		public let dashed: [Int]
		
		public var shapeLayer: CAShapeLayer {
			let shape = CAShapeLayer()
			shape.fillColor = .clear
			shape.strokeColor = color?.cgResolved()
			shape.lineWidth = width
			if !dashed.isEmpty {
				shape.lineDashPattern = dashed as [NSNumber]
			}
			return shape
		}
		
		public static var none: Self = .init()
		
		/// Defines a border construction style.
		///
		/// - Parameters:
		///   - color: The border's color. The default value is `nil`.
		///   - width: The border's thickness. The default value is 0.
		///   - dashed: The border's dashed pattern. If empty, it means solid line. The default value is `[]`.
		public init(color: UIColor? = nil, width: CGFloat = 0, dashed: [Int] = []) {
			self.color = color
			self.width = width
			self.dashed = dashed
		}
	}
	
	private var borderKey: String { "viewBorderKey" }
	
	private var borderLayer: CAShapeLayer? { layer.sublayers(named: borderKey).firstMap { $0 as? CAShapeLayer } }
	
	/// The current border width.
	@IBInspectable var borderWidth: CGFloat {
		get { borderLayer?.lineWidth ?? 0 }
		set { borderLayer?.lineWidth = newValue }
	}
	
	/// The current border color.
	@IBInspectable var borderColor: UIColor? {
		get { borderLayer?.strokeColor?.uiColor }
		set { borderLayer?.strokeColor = newValue?.cgResolved(with: interfaceStyle) }
	}
	
	private func buildBorders(_ borders: [Border]) {
		let radius = cornerRadius
		var totalWidth: CGFloat = 0
		var previous: CGFloat = 0
		
		layer.sublayers(named: borderKey).removeAllFromSuperLayer()
		layer.sublayers?.filter(\.name == borderKey).forEach { $0.removeFromSuperlayer() }
		borders.forEach { border in
			totalWidth += border.width * 0.5
			let shape = border.shapeLayer
			let shapeFrame = bounds.insetBy(dx: totalWidth, dy: totalWidth).finite
			shape.frame = bounds
			shape.name = borderKey
			
			if let mask = layer.maskPath {
				shape.path = UIBezierPath(cgPath: mask).fit(into: mask.boundingBox.insetBy(dx: totalWidth, dy: totalWidth)).cgPath
			} else if radius > 0 {
				let corners = layer.maskedCorners.rectCorners
				let size = CGSize(squared: radius - previous - (border.width * 0.5))
				shape.path = UIBezierPath(roundedRect: shapeFrame, byRoundingCorners: corners, cornerRadii: size).cgPath
			} else {
				shape.path = UIBezierPath(rect: shapeFrame).cgPath
			}
			
			layer.addSublayer(shape)
			totalWidth += border.width * 0.5
			previous = border.width
		}
	}
	
	/// Makes a border on the current view following the current corners.
	///
	/// - Parameters:
	///   - border: The border settings.
	///   - immediately: A bool indicating if the border will be rendered immediately.
	/// - Returns: Returns self same instance for convenience.
	@discardableResult func make(border: Border, immediately: Bool = false) -> Self {
		guard !immediately else {
			buildBorders([border])
			return self
		}
		asyncMain { self.buildBorders([border]) }
		return self
	}
	
	/// Makes concentric borders following the current corner configuration. This method does not automatically redraws.
	///
	/// - Parameters:
	///   - borders: The array of concentrict borders.
	///   - immediately: A bool indicating if the border will be rendered immediately.
	/// - Returns: Returns self same instance for convenience.
	@discardableResult func make(borders: [Border], immediately: Bool = false) -> Self {
		guard !immediately else {
			buildBorders(borders)
			return self
		}
		asyncMain { self.buildBorders(borders) }
		return self
	}
}

// MARK: - Extension - UIView Shadow

public extension UIView {
	
	private var shadowKey: String { "viewShadowKey" }

	/// Returns true if there is an existing gradient created by using ``make(shadowRadius:fillColor:shadowColor:opacity:offset:cornerRadius:)``
	var hasShadow: Bool { (layer.sublayers(named: shadowKey).first?.shadowOpacity ?? 0) > 0 }
	
	/// Makes a shadow in the background of the view. Re-call this method once at every redraw to resize or re-color the effect.
	///
	/// - Returns: Returns self for nested calls purpose.
	/// - Important: This routine uses layers to create its effect, changing layers after calling this method may produce undesired effects.
	/// - Parameters:
	///   - shadowRadius: The shadow radius.
	///   - shadowColor: The shadow color. The default is `black`.
	///   - opacity: The shadow opacity. The default is `0.3.
	///   - offset: The shadow offset. The default is `zero.
	///   - cornerRadius: The corner radius of the view. The default is `0.
	@discardableResult func make(shadowRadius: CGFloat,
								 shadowColor: UIColor = .black,
								 opacity: Float = 0.3,
								 offset: CGSize = .zero,
								 cornerRadius: CGFloat = 0.0) -> Self {
		asyncMain {
			self.cornerRadius = 0
			self.layer.sublayers(named: self.shadowKey).removeAllFromSuperLayer()
			let shadow = CALayer()
			let interface = self.interfaceStyle
			
			shadow.name = self.shadowKey
			shadow.frame = self.bounds
			shadow.cornerRadius = cornerRadius
			shadow.shadowPath = self.layer.maskPath ?? UIBezierPath(roundedRect: self.bounds, cornerRadius: cornerRadius).cgPath
			shadow.shadowColor = shadowColor.cgResolved(with: interface)
			shadow.shadowOpacity = opacity
			shadow.shadowOffset = offset
			shadow.shadowRadius = shadowRadius
			
			let shape = CAShapeLayer()
			shape.name = self.shadowKey
			shape.path = shadow.shadowPath
			shape.fillColor = self.backgroundColor?.cgResolved(with: interface) ?? .clear
			
			self.backgroundColor = .clear
			self.layer.mask = nil
			self.layer.insertSublayer(shape, at: 0)
			self.layer.insertSublayer(shadow, at: 0)
			self.layer.cornerRadius = cornerRadius
		}
		return self
	}
}

// MARK: - Extension - UIView Gradient

public extension UIView {
	
	private var gradientKey: String { "viewGradientKey" }
	
	/// Returns true if there is an existing gradient created by using ``make(gradient:start:end:type:)``
	var hasGradient: Bool { !layer.sublayers(named: gradientKey).isEmpty }
	
	/// Makes a gradient in the background of the view. Re-call this method once at every redraw to resize or re-color the effect.
	///
	/// - Parameters:
	///   - gradient: An array of colors. If empty ([]) any existing gradient is removed.
	///   - start: The percentual starting point [0-1]. The default is `(x:0,y:0)`.
	///   - end: The percentual ending point [0-1]. The default is `(x:0,y:1)`.
	///   - type: The type of gradient. The default is `axial`.
	/// - Returns: Returns self for nested calls purpose.
	/// - Important: This routine uses layers to create its effect, changing layers after calling this method may produce undesired effects.
	@discardableResult func make(gradient: [UIColor],
								 start: CGPoint = .init(x: 0, y: 0),
								 end: CGPoint = .init(x: 0, y: 1),
								 type: CAGradientLayerType = .axial) -> Self {
		
		layer.sublayers(named: gradientKey).removeAllFromSuperLayer()
		guard !gradient.isEmpty else { return self }
		let rect = layer.maskPath?.boundingBox ?? bounds
		let gradient = CAGradientLayer(colors: gradient, frame: rect, style: .custom(start: start, end: end, type: type))
		gradient.zPosition = -1000
		gradient.name = gradientKey
		layer.insertSublayer(gradient, at: 0)
		asyncMain { gradient.frame = self.layer.maskPath?.boundingBox ?? self.bounds }
		return self
	}
}

// MARK: - Extension - UIView Grabber

public extension UIView {
	
	private struct Keys {
		static var grabberKey: UInt8 = 1
	}
	
	private var grabber: UIView? {
		get { objc_getAssociatedObject(self, &Keys.grabberKey) as? UIView }
		set { objc_setAssociatedObject(self, &Keys.grabberKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
	}
	
	/// Makes a single grabber like view at the top of the view.
	///
	/// - Parameters:
	///   - color: The color of the grabber. The default value is black color 20% alpha.
	///   - size: The size of the grabber. The default vlaue is [36, 5].
	///   - padding: The padding distance from the top. The default vlaue is 8.
	@discardableResult func makeGrabber(color: UIColor = .black.withAlphaComponent(0.2),
										size: CGSize = .init(width: 36, height: 5),
										padding: CGFloat = 8) -> Self {
		let view = grabber ?? .init(frame: .init(origin: .zero, size: size), background: color)
		addSubview(view)
		view.cornerRadius = size.height * 0.5
		view.center = .init(x: center.x, y: center.y - (frame.height * 0.5) + padding)
		view.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleBottomMargin]
		grabber = view
		return self
	}
	
	/// Removes the grabber added via ``makeGrabber(color:size:)``.
	@discardableResult func removeGrabber() -> Self {
		grabber?.removeFromSuperview()
		return self
	}
}

// MARK: - Extension - UIView Visual

public extension UIView {
	
	/// Returns true if the given view is being rendered as right to left layout direction.
	var isRTL: Bool { effectiveUserInterfaceLayoutDirection == .rightToLeft }
	
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
	
	/// Resizes the view with a new CGSize. Returns itself for concatenation.
	///
	/// - Parameter size: The new size.
	/// - Returns: The same instance after changes.
	@discardableResult func resize(_ size: CGSize) -> Self {
		frame = .init(origin: frame.origin, size: size)
		return self
	}
	
	/// Resizes the view with a new CGRect. Returns itself for concatenation.
	///
	/// - Parameter size: The new rect.
	/// - Returns: The same instance after changes.
	@discardableResult func resize(_ rect: CGRect) -> Self {
		frame = rect
		return self
	}
	
	func embededInView(edges: UIEdgeInsets = .zero) -> UIView {
		let view = UIView(frame: .init(origin: .zero, size: frame.size))
		view.addSubview(self)
		view.setConstraintsFitting(child: self, edges: edges)
		return view
	}
	
	func embededInScrollView(edges: UIEdgeInsets = .zero) -> UIScrollView {
		let view = UIScrollView(frame: .init(origin: .zero, size: frame.size))
		view.showsHorizontalScrollIndicator = false
		view.showsVerticalScrollIndicator = false
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
