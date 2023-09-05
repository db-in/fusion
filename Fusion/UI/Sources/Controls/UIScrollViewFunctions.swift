//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Definitions -

public extension UIEdgeInsets {
	
	var flipped: UIEdgeInsets { UIEdgeInsets(top: bottom, left: right, bottom: top, right: left) }
	
	var finite: UIEdgeInsets { .init(top: top.finite, left: left.finite, bottom: bottom.finite, right: right.finite) }
	
	init(by: CGFloat) { self.init(top: by, left: by, bottom: by, right: by) }
	
	init(horizontal: CGFloat) { self.init(top: 0, left: horizontal, bottom: 0, right: horizontal) }
	
	init(vertical: CGFloat) { self.init(top: vertical, left: 0, bottom: vertical, right: 0) }
	
	static func + (lhs: Self, rhs: Self) -> Self {
		.init(top: lhs.top + rhs.top, left: lhs.left + rhs.left, bottom: lhs.bottom + rhs.bottom, right: lhs.right + rhs.right)
	}
}

// MARK: - Extension - UIScrollView Overflow

extension UIScrollView {
	
	public enum Overflow {
		case none
		case fade(inset: CGFloat = 0)
		case line(view: UIView = UIView(frame: .init(x: 0, y: 0, width: 1, height: 1), background: .lightGray))
		
		func update(_ scrollView: UIScrollView, at: UIRectEdge) {
			let offset = scrollView.contentOffset.y
			let width = scrollView.bounds.width
			let safeArea = scrollView.safeAreaInsets.bottom
			let bottomY = offset + scrollView.bounds.height - safeArea
			
			switch self {
			case let .line(line):
				switch at {
				case .bottom:
					line.frame = CGRect(x: 0, y: bottomY + safeArea - 0.5, width: width, height: 0.5)
					
					if bottomY < scrollView.contentSize.height {
						scrollView.addSubview(line)
					} else {
						line.removeFromSuperview()
					}
				default:
					line.frame = CGRect(x: 0, y: offset, width: width, height: 0.5)
					
					if offset > 0 {
						scrollView.addSubview(line)
					} else {
						line.removeFromSuperview()
					}
				}
			case let .fade(inset):
				let black = CGColor.black
				let gradient = (scrollView.layer.mask?.sublayers?.first as? CAGradientLayer) ?? CAGradientLayer(variations: 4)
				let contentHeight = scrollView.contentSize.height
				let gradientLocation = Float(64.0 / contentHeight)
				let offsetLocation = Float(inset / contentHeight)
				let viewSize = scrollView.bounds.size
				let offsetY = scrollView.contentOffset.y
				var contentInset = scrollView.contentInset
				var scrollInset = scrollView.indicatorInsets
				
				gradient.frame = CGRect(origin: .zero, size: viewSize)
				
				switch at {
				case .bottom:
					let alpha: CGFloat = (offsetY - contentInset.bottom + viewSize.height >= contentHeight) ? 1 : 0
					let color = UIColor(white: 0, alpha: alpha)
					gradient.locations = [gradient.locations?[0] ?? 0,
										  gradient.locations?[1] ?? 0,
										  NSNumber(value: 1 - gradientLocation - offsetLocation),
										  NSNumber(value: 1 - offsetLocation)]
					gradient.colors = [gradient.colors?.first ?? black, black, black, color.cgColor]
					contentInset.bottom = inset
					scrollInset.bottom = inset
				default:
					let alpha: CGFloat = (offsetY + contentInset.top <= 0) ? 1 : 0
					let color = UIColor(white: 0, alpha: alpha)
					gradient.locations = [NSNumber(value: offsetLocation),
										  NSNumber(value: offsetLocation + gradientLocation),
										  gradient.locations?[2] ?? 0,
										  gradient.locations?[3] ?? 0]
					gradient.colors = [color.cgColor, black, black, gradient.colors?.last ?? black]
					contentInset.top = inset
					scrollInset.top = inset
				}

				let maskLayer = CALayer()
				maskLayer.frame = scrollView.bounds
				maskLayer.addSublayer(gradient)
				scrollView.layer.mask = maskLayer
				scrollView.contentInset = contentInset.finite
				scrollView.indicatorInsets = scrollInset.finite
			case .none:
				break
			}
		}
		
		func clear(_ scrollView: UIScrollView) {
			switch self {
			case let .line(line):
				line.removeFromSuperview()
			case .fade:
				scrollView.layer.mask = nil
			case .none:
				break
			}
		}
	}
	
// MARK: - Properties
	
	private static var topKey: UInt8 = 1
	private static var bottomKey: UInt8 = 2
	
	private var top: Overflow? {
		get { objc_getAssociatedObject(self, &Self.topKey) as? Overflow }
		set { objc_setAssociatedObject(self, &Self.topKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
	}
	
	private var bottom: Overflow? {
		get { objc_getAssociatedObject(self, &Self.bottomKey) as? Overflow }
		set { objc_setAssociatedObject(self, &Self.bottomKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
	}
	
	public var indicatorInsets: UIEdgeInsets {
		get { verticalScrollIndicatorInsets + horizontalScrollIndicatorInsets }
		set {
			verticalScrollIndicatorInsets = newValue
			horizontalScrollIndicatorInsets = newValue
		}
	}
	
// MARK: - Constructors

// MARK: - Protected Methods
	
	@objc open func updateOnScroll() {
		top?.update(self, at: .top)
		bottom?.update(self, at: .bottom)
	}
	
// MARK: - Exposed Methods

	public func setupOverflow(top: Overflow = .line(), bottom: Overflow = .fade()) {
		self.top?.clear(self)
		self.bottom?.clear(self)
		self.top = top
		self.bottom = bottom
		addObserverOnce(forKeyPath: KeyPathName.scrollOffset)
		asyncMain { self.flashScrollIndicators() }
	}
	
// MARK: - Overridden Methods
	
	open override func observeValue(forKeyPath keyPath: String?,
									of object: Any?,
									change: [NSKeyValueChangeKey : Any]?,
									context: UnsafeMutableRawPointer?) {
		updateOnScroll()
	}
}
#endif
