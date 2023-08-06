//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

#if os(iOS)
// MARK: - Extension - [UIActivity.ActivityType]

public extension Array where Element == UIActivity.ActivityType {
	
	static var nonStandard: Self { [.assignToContact, .addToReadingList, .markupAsPDF, .openInIBooks, .print] }
}

// MARK: - Extension - Array

public extension Array {
	
	func shareAction(completion: UIActivityViewController.CompletionWithItemsHandler? = nil) {
		guard let target = UIWindow.topViewController else { return }
		
		let activity = UIActivityViewController(activityItems: self, applicationActivities: nil)
		let frame = target.view.frame
		
		activity.popoverPresentationController?.sourceView = target.view
		activity.popoverPresentationController?.sourceRect = frame
		activity.excludedActivityTypes = .nonStandard
		activity.completionWithItemsHandler = completion
		target.present(activity, animated: true)
	}
}
#endif
// MARK: - Type -

public typealias ControlHandler = (ControlAction) -> Void

public struct ControlAction {
	
// MARK: - Properties
	
	public let title: TextConvertible?
	public let image: UIImage?
	public let isEnabled: Bool
	public let isSelected: Bool
	public let action: ControlHandler?
	
// MARK: - Constructors
	
	public init(title: TextConvertible? = nil, image: UIImage? = nil, enabled: Bool = true, selected: Bool = false, action: ControlHandler? = nil) {
		self.title = title
		self.image = image
		self.action = action
		self.isEnabled = enabled
		self.isSelected = selected
	}
	
// MARK: - Exposed Methods
	
	public func execute() {
		action?(self)
	}
}

// MARK: - Extension - UIButton ControlAction

//public extension UIButton {
//	
//	var spacing: CGFloat {
//		get { contentEdgeInsets.left * 3 }
//		set {
//			let inset: CGFloat = (isRTL ? -newValue : newValue) / 3
//			imageEdgeInsets = .init(top: 0, left: -inset, bottom: 0, right: inset)
//			titleEdgeInsets = .init(top: 0, left: inset, bottom: 0, right: -inset)
//			contentEdgeInsets = .init(top: 0, left: inset, bottom: 0, right: inset)
//		}
//	}
//	
//	convenience init(frame: CGRect, image: UIImage) {
//		self.init(frame: frame)
//		self.setImage(image, for: .normal)
//	}
//	
//	convenience init(action newAction: ControlAction) {
//		self.init(frame: .init(origin: .zero, size: .init(squared: 44)))
//		contentEdgeInsets = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
//		setTitleColor(.label, for: .selected)
//		setTitleColor(.secondaryLabel, for: .normal)
//		tintColor = .secondaryLabel
//		titleLabel?.font = traitCollection.layoutDirection == .rightToLeft ? .footnote : .body
//		titleLabel?.textAlignment = .center
//		titleLabel?.lineBreakMode = .byTruncatingTail
//		titleLabel?.minimumScaleFactor = 0.6
//		setAction(newAction)
//	}
//	
//	func setAction(_ action: ControlAction?, in inAn: Animation? = nil, out outAn: Animation? = nil) {
//		
//		let define = { [weak self] in
//			if let validAction = action {
//				action?.title.render(target: self)
//				self?.setImage(action?.image, for: .normal)
//				self?.setAction { validAction.action?(validAction) }
//				self?.isEnabled = validAction.isEnabled
//			} else {
//				self?.setAction(nil)
//			}
//		}
//		
//		if let outAnimation = outAn {
//			animate(with: outAnimation)
//			asyncMain(after: .osDefault) { [weak self] in
//				define()
//				if let inAnimation = inAn {
//					self?.animate(with: inAnimation)
//				}
//			}
//		} else {
//			define()
//			if let inAnimation = inAn {
//				animate(with: inAnimation)
//			}
//		}
//	}
//}
#endif
