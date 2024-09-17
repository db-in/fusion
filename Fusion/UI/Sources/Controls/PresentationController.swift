//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Definitions -

public extension UIRectEdge {
	
	/// Returns true when the edge is either `top` or `bottom`. Returns false for `all`.
	var isVertical: Bool { self == .top || self == .bottom }
	
	/// Returns true when the edge is either `left` or `right`. Returns false for `all`.
	var isHorizontal: Bool { self == .left || self == .right }
	
	/// Safer RTL compatible alignment.
	var rtlSafe: Self {
		let isRTL = Locale.preferredLocale.isRTL
		
		switch self {
		case .left:
			return isRTL ? .right : .left
		case .right:
			return isRTL ? .left : .right
		default:
			return self
		}
	}
}

/// A presentation controller that has a dimming view and presents from the bottom, as a drawer behavior.
public final class PresentationController : UIPresentationController {
	
	public struct Config {
		
		/// Defines the default initial ``cornerRadius`` for future ``PresentationController``.
		public static var cornerRadius: RectCorners = .init(all: 20)
		
		/// Defines the default initial ``topSafeArea`` for future ``PresentationController``.
		public static var extraSafeArea: CGFloat = 20
	}
	
// MARK: - Properties
	
	private weak var snapshotView: UIView?
	private var isDismissing: Bool = false
	private var isInteracting: Bool = false
	private var originalHeight: CGFloat = 0
	private var propertyAnimator: UIViewPropertyAnimator?
	private var nestedViewController: UIViewController? { (presentedViewController as? UINavigationController)?.viewControllers.last ?? presentedViewController }
	private var scrollView: UIScrollView? { nestedViewController?.view.firstOf() }
	private var topOffset: CGFloat { UIWindow.keySafeAreaInsets.top }
	private var interactor: UIPercentDrivenInteractiveTransition? { allowsInteractiveTransition && isInteracting ? interactiveTransition : nil }
	private lazy var interactiveTransition: UIPercentDrivenInteractiveTransition = { .init() }()
	
	/// Indicates if a grabber will be visible for interaction. The default value is `false`.
	public var isGrabberVisible: Bool = false {
		didSet { updateGrabber() }
	}
	
	/// Indicates if the user is allowed to interactively move the transition. The default value is `true`.
	public var allowsInteractiveTransition: Bool = false
	
	/// Indicates if the user is allowed to dismiss it manually. When set to `false` user won't be albe to tap to dismiss, however it still
	/// dismissable programatically. The default value is `true`.
	public var allowsDismiss: Bool = true
	
	/// The corner radius of the drawer frame.
	public var cornerRadius: RectCorners = Config.cornerRadius
	
	/// Defines a safe space at the top that will never be exceeded, this is in addition to any top existing window safe.
	public var extraSafeArea: CGFloat = Config.extraSafeArea
	
	/// Defines the presenting side of the new controller.
	public var presentingSide: UIRectEdge = .bottom
	
	/// Keeps the previous View Controller visible on top, the return navigation is done by tapping on it.
	public var picInPic: Bool = false
	
	/// A closure to be executed after the presentation is dismissed in the future.
	public var onDismissal: Callback?
	
	/// The dimming view. This property can be used to customize the dimming view.
	public private(set) lazy var dimmingView: UIView = { .init(background: .black.withAlphaComponent(0.5)) }()
	
	public override var frameOfPresentedViewInContainerView: CGRect {
		guard
			let containerBounds = containerView?.bounds,
			let controller = nestedViewController,
			let screenSafeArea = UIWindow.key?.safeAreaInsets
		else { return UIWindow.keyBounds }
		
		let navigation = presentedViewController as? UINavigationController
		let header = (navigation?.navigationBar.frame.height ?? 0) + (navigation?.additionalSafeAreaInsets.top ?? 0)
		let viewSafeArea = controller.additionalSafeAreaInsets
		let extraPadding = header + screenSafeArea.bottom + viewSafeArea.top + viewSafeArea.bottom
		var frame = containerBounds
		originalHeight = originalHeight > 0 ? originalHeight : controller.preferredSize.height
		
		switch presentingSide {
		case .left, .right:
//			frame.size.width = min(controller.preferredSize.width, containerBounds.width - extraSafeArea)
			frame.origin.x = containerBounds.width - frame.width
		case .top, .bottom:
			frame.size.height = min(controller.preferredSize.height + extraPadding, containerBounds.height - topOffset - extraSafeArea)
			frame.origin.y = containerBounds.height - frame.size.height
		default:
			break
		}
		
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
		guard allowsDismiss else { return }
		presentedViewController.dismiss(animated: true)
	}
	
	@objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
		guard
			allowsInteractiveTransition,
			let containerView = containerView
		else { return }
		
		limitScrollView(gesture)
		let percent = gesture.translation(in: containerView).y / containerView.bounds.height
		
		switch gesture.state {
		case .began:
			if !presentedViewController.isBeingDismissed && scrollView?.contentOffset.y ?? 0 <= 0 {
				isInteracting = true
				presentedViewController.dismiss(animated: true)
			}
		case .changed:
			interactiveTransition.update(percent)
		case .cancelled:
			interactiveTransition.cancel()
			isInteracting = false
		case .ended:
			let velocity = gesture.velocity(in: containerView).y
			interactiveTransition.completionSpeed = 0.9
			if percent > 0.3 || velocity > 1600 {
				interactiveTransition.finish()
			} else {
				interactiveTransition.cancel()
			}
			isInteracting = false
		default:
			break
		}
	}
	
	private func limitScrollView(_ gesture: UIPanGestureRecognizer) {
		guard interactiveTransition.percentComplete > 0 else { return }
		scrollView?.contentOffset.y = -(scrollView?.adjustedContentInset.top ?? 0)
	}
	
	private func updateGrabber() {
		if isGrabberVisible {
			presentedView?.makeGrabber()
		} else {
			presentedView?.removeGrabber()
		}
	}
	
// MARK: - Exposed Methods
	
	public func prepareInitialLayout(closing: Bool = false) {
		guard
			let containerBounds = containerView?.bounds,
			let targetView = presentedView
		else { return }
		
		targetView.layoutIfNeeded()
		targetView.frame = frameOfPresentedViewInContainerView
		targetView.layer.masksToBounds = true
		targetView.make(bezierCorners: cornerRadius)
		
		snapshotView?.transform = .identity
		if closing {
			CATransaction.setCompletionBlock { [weak self] in self?.snapshotView?.removeFromSuperview() }
		}
		
		switch presentingSide {
		case .left:
			targetView.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
//			targetView.frame.origin.x = -containerBounds.width
		case .right:
			targetView.autoresizingMask = [.flexibleHeight, .flexibleLeftMargin]
//			targetView.frame.origin.x = containerBounds.width
		case .top:
			targetView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
			targetView.frame.origin.y = -containerBounds.height
		case .bottom:
			targetView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
			targetView.frame.origin.y = containerBounds.height
		default:
			break
		}
	}
	
	public func prepareFinalLayout(source: UIViewController?) {
		guard let targetView = presentedView else { return }
		
		targetView.frame = frameOfPresentedViewInContainerView
		
		if presentingSide.isHorizontal {
			let delta: CGFloat = presentingSide == .right ? 1 : -1
			let posX = -(UIWindow.keyBounds.width * delta) + (40 * delta)
			let imageView = UIImageView(image: source?.view.superview?.snapshot)
			nestedViewController?.view.addSubview(imageView)
			imageView.make(radius: 50).transform = .identity.scaledBy(x: 0.8, y: 0.8).translatedBy(x: posX, y: 0)
			UITapGestureRecognizer.set(on: imageView) { [weak self] _ in self?.handleDismiss() }
			UIPanGestureRecognizer.set(on: imageView) { [weak self] _ in self?.handleDismiss() }
			snapshotView = imageView
		}
	}
	
// MARK: - Overridden Methods
	
	public override func presentationTransitionWillBegin() {
		guard
			let containerBounds = containerView?.bounds,
			let targetView = presentedView
		else { return }
		
		containerView?.addSubview(targetView)
		containerView?.insertSubview(dimmingView, at: 0)
		updateGrabber()
		prepareInitialLayout()
		
		dimmingView.frame = containerBounds
		dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
		dimmingView.alpha = 0
		dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleDismiss)))
		targetView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:))))
		scrollView?.panGestureRecognizer.addTarget(self, action: #selector(handlePan(_:)))
		
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
		let duration = transitionDuration(using: transitionContext)
		propertyAnimator = .init(duration: duration, timingParameters: UICubicTimingParameters(animationCurve: .easeOut))

		let isPresenting = presentedViewController.isBeingPresented
		let sourceController = transitionContext.viewController(forKey: isPresenting ? .from : .to)
		let targetController = transitionContext.viewController(forKey: isPresenting ? .to : .from)
		
		propertyAnimator?.addAnimations {
			if isPresenting {
				targetController?.presentation.prepareFinalLayout(source: sourceController)
			} else {
				targetController?.presentation.prepareInitialLayout(closing: true)
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
	
	fileprivate var preferredSize: CGSize {
		let target = (self as? UINavigationController)?.topViewController ?? self
		let size = target.preferredContentSize
		guard size == .zero else { return size }

		let verticalInsets = target.view.safeAreaInsets.top + target.view.safeAreaInsets.bottom
		let horizontalInsets = target.view.safeAreaInsets.left + target.view.safeAreaInsets.right
		var height = max(0, target.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height - verticalInsets)
		var width = max(0, target.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).width - horizontalInsets)

		if let mainScroll = target.view as? UIScrollView {
			height += mainScroll.contentSize.height + mainScroll.contentInset.top + mainScroll.contentInset.bottom
			width += mainScroll.contentSize.width + mainScroll.contentInset.left + mainScroll.contentInset.right
			return CGSize(width: width, height: height)
		}

		let scrollViews: [UIScrollView] = target.view.allSubviewOf()
		target.view.layoutIfNeeded()

		height += scrollViews.reduce(CGFloat(0), { result, scrollView in
			if scrollView.intrinsicContentSize.height <= 0 {
				return result + scrollView.contentSize.height + scrollView.contentInset.top + scrollView.contentInset.bottom
			} else {
				return result
			}
		})

		width += scrollViews.reduce(CGFloat(0), { result, scrollView in
			if scrollView.intrinsicContentSize.width <= 0 {
				return result + scrollView.contentSize.width + scrollView.contentInset.left + scrollView.contentInset.right
			} else {
				return result
			}
		})

		return CGSize(width: width, height: height)
	}
	
	/// Automatically creates and returns the ``PresentationController`` that will be used on the next ``presentOver(_:style:)`` action.
	/// - Important: This instance will be valid only for one round of presentation. Any changes will be discarded after the presentation is over.
	var presentation: PresentationController {
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
	
	/// Presents a new view controller on top of this instance.
	///
	/// - Parameters:
	///   - target: The new view controller to be presented on top.
	///   - style: Defines the `UIModalPresentationStyle` in which it will be presented. Default is `none`.
	func presentOver(_ target: UIViewController, style: UIModalPresentationStyle = .none, from side: UIRectEdge = .bottom) {
		target.presentation.presentingSide = side
#if os(iOS) && !os(visionOS)
		if #available(iOS 15.0, *), style == .pageSheet || style == .formSheet {
			target.modalPresentationStyle = style
			target.transitioningDelegate = nil
			let sheet = target.sheetPresentationController
			if #available(iOS 16.0, *) {
				let detent = UISheetPresentationController.Detent.custom(identifier: .init("dent")) { _ in target.preferredSize.height }
				sheet?.detents = [detent]
			} else {
				sheet?.detents = [.large()]
			}
			
			sheet?.preferredCornerRadius = target.presentation.cornerRadius.topLeft
			sheet?.prefersGrabberVisible = target.presentation.isGrabberVisible
			sheet?.prefersEdgeAttachedInCompactHeight = true
			sheet?.prefersScrollingExpandsWhenScrolledToEdge = true
		} else {
			target.modalPresentationStyle = style.isModal ? .custom : style
			target.transitioningDelegate = target.modalPresentationStyle.isModal ? target.presentation : target.transitioningDelegate
		}
#else
		target.modalPresentationStyle = style.isModal ? .custom : style
		target.transitioningDelegate = target.modalPresentationStyle.isModal ? target.presentationController as? UIViewControllerTransitioningDelegate : target.transitioningDelegate
#endif
		
		guard let current = presentedViewController else {
			present(target as UIViewController, animated: true)
			return
		}
		
		current.dismiss(animated: true) {
			asyncMain { self.present(target, animated: true) }
		}
	}
	
	/// Presents this instance over the key window's top view.
	///
	/// - Parameter style: Defines the `UIModalPresentationStyle` in which it will be presented. Default is `none`.
	func presentOverWindow(style: UIModalPresentationStyle = .none, from side: UIRectEdge = .bottom) {
		UIWindow.topViewController?.presentOver(self, style: style, from: side)
	}
}
#endif
