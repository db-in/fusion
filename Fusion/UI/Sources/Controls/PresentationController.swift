//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Definitions -

/// A presentation controller that has a dimming view and presents from the bottom, as a drawer behavior.
final public class PresentationController : UIPresentationController {
	
// MARK: - Properties
	
	private var isDismissing: Bool = false
	private var originalHeight: CGFloat = 0
	private var propertyAnimator: UIViewPropertyAnimator?
	private var nestedViewController: UIViewController? { (presentedViewController as? UINavigationController)?.viewControllers.last ?? presentedViewController }
	private var scrollView: UIScrollView? { nestedViewController?.view as? UIScrollView ?? nestedViewController?.view.firstSubviewOf() }
	private var topOffset: CGFloat { UIWindow.key?.safeAreaInsets.top ?? 0 }
	private var interactor: UIPercentDrivenInteractiveTransition? { allowsInteraction ? interactiveTransition : nil }
	private lazy var interactiveTransition: UIPercentDrivenInteractiveTransition = { .init() }()
	private lazy var grabberView: UIView = {
		.init(frame: .init(x: 0, y: 0, width: 36, height: 5), backgroundColor: .gray.withAlphaComponent(0.5), corner: 2.5)
	}()
	
	/// Indicates if a grabber will be visible for interaction. The default value is `false`.
	public var isGrabberVisible: Bool = false {
		didSet {
			grabberView.isHidden = !isGrabberVisible
		}
	}
	
	/// Indicates if the user is allowed to interactively move the presentation. The default value is `false`.
	public var allowsInteraction: Bool = false
	
	/// Indicates if the user is allowed to dismiss it manually. When set to `false` user won't be albe to tap to dismiss, however it still
	/// dismissable programatically. The default value is `true`.
	public var allowsDismiss: Bool = true
	
	/// The corner radius of the drawer frame.
	public var cornerRadius: CGFloat = 20
	
	/// A closure to be executed after the presentation is dismissed in the future.
	public var onDismissal: Callback?
	
	/// The dimming view. This property can be used to customize the dimming view.
	public private(set) lazy var dimmingView: UIView = { .init(backgroundColor: .black.withAlphaComponent(0.5)) }()
	
	public override var frameOfPresentedViewInContainerView: CGRect {
		let navigation = presentedViewController as? UINavigationController
		let header = (navigation?.navigationBar.frame.height ?? 0) + (navigation?.additionalSafeAreaInsets.top ?? 0)
		
		guard
			let containerBounds = containerView?.bounds,
			let controller = nestedViewController,
			let screenSafeArea = UIWindow.key?.safeAreaInsets
		else { return UIWindow.key?.bounds ?? .zero }

		let viewSafeArea = controller.additionalSafeAreaInsets
		let extraPadding = header + screenSafeArea.bottom + viewSafeArea.top + viewSafeArea.bottom
		
		var frame = containerBounds
		frame.size.height = min(controller.preferredHeight + extraPadding, containerBounds.height - topOffset)
		frame.origin.y = containerBounds.height - frame.size.height
		originalHeight = originalHeight > 0 ? originalHeight : controller.preferredHeight
		
		return frame
	}
	
// MARK: - Constructors
	
	override init(presentedViewController: UIViewController, presenting: UIViewController?) {
		super.init(presentedViewController: presentedViewController, presenting: presenting)
#if os(iOS)
		registerForKeyboardNotifications()
#endif
	}
	
// MARK: - Protected Methods
#if os(iOS)
	private func registerForKeyboardNotifications() {
		let center = NotificationCenter.default
		center.addObserver(self, selector: #selector(keyboardToggled(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
		center.addObserver(self, selector: #selector(keyboardToggled(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
	}
	
	@objc private func keyboardToggled(_ notification: NSNotification) {
		guard
			!isDismissing,
			scrollView?.findFirstResponder() != nil,
			let keyboard = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
			notification.name == UIResponder.keyboardWillShowNotification || notification.name == UIResponder.keyboardWillHideNotification
		else { return }
		
		let isShowing = notification.name == UIResponder.keyboardWillShowNotification
		let visibleFrame = (nestedViewController?.view.frame.height ?? 0) - (scrollView?.frame.maxY ?? 0)
		let extraHeight = keyboard.height - visibleFrame
		let height = isShowing ? originalHeight + extraHeight : originalHeight
		
		nestedViewController?.preferredContentSize.height = height
		nestedViewController?.navigationController?.preferredContentSize.height = height
	}
#endif
	@objc private func handleDismiss() {
		presentedView?.endEditing(true)
		if allowsDismiss {
			presentedViewController.dismiss(animated: true)
		}
	}
	
// MARK: - Exposed Methods

// MARK: - Overridden Methods
	
	public override func presentationTransitionWillBegin() {
		guard
			let containerBounds = containerView?.bounds,
			let targetView = presentedView
		else { return }
		
		containerView?.addSubview(targetView)
//		containerView?.addSubview(grabberView)
		containerView?.insertSubview(dimmingView, at: 0)
		
		targetView.layoutIfNeeded()
		targetView.frame = frameOfPresentedViewInContainerView
		targetView.frame.origin.y = containerBounds.height
		targetView.layer.masksToBounds = true
		targetView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
		targetView.setCornerRadius(at: [.topLeft, .topRight], radius: cornerRadius)
		
		dimmingView.frame = containerBounds
		dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		dimmingView.alpha = 0
		dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
		
		presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
			self?.dimmingView.alpha = 1
		})
	}
	
	public override func dismissalTransitionWillBegin() {
		presentedViewController.transitionCoordinator?.animate(alongsideTransition: { [weak self] _ in
			self?.dimmingView.alpha = 0
		})
	}
	
	public override func dismissalTransitionDidEnd(_ completed: Bool) {
		propertyAnimator = nil
		isDismissing = false
		asyncMain {
			self.onDismissal?()
			self.presentedViewController.flushPresentationController()
		}
	}
	
	public override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
		super.preferredContentSizeDidChange(forChildContentContainer: container)
		
		if propertyAnimator == nil || propertyAnimator?.isRunning == false {
			asyncMain {
				self.presentedView?.frame = self.frameOfPresentedViewInContainerView
				self.presentedView?.layoutIfNeeded()
			}
		}
	}
}

// MARK: - Extension - PresentationController

extension PresentationController : UIViewControllerAnimatedTransitioning {
	
	public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { Constant.duration }
	
	public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
		interruptibleAnimator(using: transitionContext).startAnimation()
	}
	
	public func interruptibleAnimator(using transitionContext: UIViewControllerContextTransitioning) -> UIViewImplicitlyAnimating {
		propertyAnimator = .init(duration: Constant.duration, timingParameters: UICubicTimingParameters(animationCurve: .easeOut))

		let isPresenting = presentedViewController.isBeingPresented
		let original = transitionContext.viewController(forKey: isPresenting ? .from : .to)?.view
		let modal = transitionContext.view(forKey: isPresenting ? .to : .from)
		
		propertyAnimator?.addAnimations { [weak self] in
			if isPresenting {
				modal?.frame = self?.frameOfPresentedViewInContainerView ?? .zero
			} else {
				original?.transform = .identity
				modal?.frame.origin.y = transitionContext.containerView.frame.maxY
			}
		}
		
		propertyAnimator?.addCompletion { _ in
			transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
		}
		
		return propertyAnimator ?? UIViewPropertyAnimator()
	}
}

// MARK: - Extension - AlertPresentationController

extension PresentationController : UIViewControllerTransitioningDelegate {
	
	public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		isDismissing = true
		return self
	}
	
	public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? { self }
	
	public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? { self }
	
	public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? { interactor }
}

private struct Keys {
	static var presentationKey: UInt8 = 0
}

public extension UIViewController {
	
	fileprivate var preferredHeight: CGFloat { preferredContentSize.height > 0 ? preferredContentSize.height : calculatePreferredHeight() }
	
	/// Automatically creates and returns the ``PresentationController`` that will be used on the next ``presentOver(_:style:)`` action.
	/// - Important: This instance will be valid only for one round of presentation. Any changes will be discarded after the presentation is over.
	var presentationController: PresentationController {
		guard let sheet = objc_getAssociatedObject(self, &Keys.presentationKey) as? PresentationController else {
			let newSheet = PresentationController(presentedViewController: self, presenting: nil)
			objc_setAssociatedObject(self, &Keys.presentationKey, newSheet, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			return newSheet
		}
		
		return sheet
	}
	
	fileprivate func flushPresentationController() {
		objc_setAssociatedObject(self, &Keys.presentationKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	}
	
	fileprivate func calculatePreferredHeight() -> CGFloat {
		let insets = view.safeAreaInsets.top + view.safeAreaInsets.bottom
		var height = max(0, view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height - insets)
		
		if let tableView = view as? UITableView {
			height += tableView.contentSize.height + tableView.contentInset.top + tableView.contentInset.bottom
			return height
		}
		
		let scrollViews = view.subviews.compactMap { $0 as? UIScrollView }
		
		height += scrollViews.reduce(CGFloat(0), { result, scrollView in
			if scrollView.intrinsicContentSize.height <= 0 {
				return result + scrollView.contentSize.height + scrollView.contentInset.top + scrollView.contentInset.bottom
			} else {
				return result
			}
		})
		
		return height
	}
	
	/// Presents a new view controller on top of this instance.
	///
	/// - Parameters:
	///   - target: The new view controller to be presented on top.
	///   - style: Defines the `UIModalPresentationStyle` in which it will be presented. Default is `none`.
	func presentOver(_ target: UIViewController, style: UIModalPresentationStyle = .none) {
		target.modalPresentationStyle = style.isModal ? .custom : style
		target.transitioningDelegate = target.modalPresentationStyle.isModal ? target.presentationController : target.transitioningDelegate
		
		guard let current = presentedViewController else {
			present(target, animated: true)
			return
		}
		
		current.dismiss(animated: true) {
			asyncMain { self.present(target, animated: true) }
		}
	}
	
	/// Presents this instance over the key window's top view.
	///
	/// - Parameter style: Defines the `UIModalPresentationStyle` in which it will be presented. Default is `none`.
	func presentOverWindow(style: UIModalPresentationStyle = .none) {
		UIWindow.topViewController?.presentOver(self, style: style)
	}
}
#endif
