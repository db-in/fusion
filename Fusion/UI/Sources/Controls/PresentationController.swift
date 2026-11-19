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

protocol PresentationSizing : UIViewController {
	
	func presentationHeight(fitting width: CGFloat, maxHeight: CGFloat) -> CGFloat
	
	func preparePresentationSizing() -> CGFloat?
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
	private var heightConstraint: NSLayoutConstraint?
	private var measuredWidth: CGFloat = 0
	private var propertyAnimator: UIViewPropertyAnimator?
	private let snapshotScale: CGFloat = 0.8
	private let snapshotInset: CGFloat = 40
	private var nestedViewController: UIViewController? { (presentedViewController as? UINavigationController)?.viewControllers.last ?? presentedViewController }
	private var scrollView: UIScrollView? { nestedViewController?.view.firstOf() }
	private var interactor: UIPercentDrivenInteractiveTransition? { allowsInteractiveTransition && isInteracting ? interactiveTransition : nil }
	private lazy var interactiveTransition: UIPercentDrivenInteractiveTransition = { .init() }()
	
	private var maximumHeight: CGFloat {
		guard let containerView else { return UIWindow.keyBounds.height }
		let insets = containerView.safeAreaInsets
		return max(0, containerView.bounds.height - insets.top - max(insets.bottom, keyboardOverlap) - extraSafeArea)
	}
	
	private var keyboardOverlap: CGFloat = 0
	
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
	
	public var fixedHeight: CGFloat?
	
	/// A closure to be executed after the presentation is dismissed in the future.
	public var onDismissal: Callback?
	
	/// The dimming view. This property can be used to customize the dimming view.
	public private(set) lazy var dimmingView: UIView = { .init(background: .black.withAlphaComponent(0.5)) }()
	
// MARK: - Constructors
	
	override init(presentedViewController: UIViewController, presenting: UIViewController?) {
		super.init(presentedViewController: presentedViewController, presenting: presenting)
	}
	
// MARK: - Protected Methods
	
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
		
		let translation = gesture.translation(in: containerView)
		let velocity = gesture.velocity(in: containerView).y
		let percent = max(0, min(1, translation.y / containerView.bounds.height))
		
		switch gesture.state {
		case .began:
			isInteracting = true
			interactiveTransition = .init()
			if !presentedViewController.isBeingDismissed && scrollView?.contentOffset.y ?? 0 <= 0 {
				presentedViewController.dismiss(animated: true)
			}
		case .changed:
			limitScrollView(gesture)
			interactor?.update(percent)
		case .cancelled, .ended:
			interactor?.completionSpeed = 0.9
			if percent > 0.3 || velocity > 1600 {
				interactor?.finish()
			} else {
				interactor?.cancel()
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
	
	private func layout(_ targetView: UIView, in containerView: UIView) {
		let height = targetView.safeAreaLayoutGuide.heightAnchor.constraint(equalToConstant: measureHeight()).priority(new: .init(999))
		heightConstraint = height
		
		switch presentingSide {
		case .bottom:
			trackKeyboard()
			containerView.setConstraintsFitting(child: targetView, leading: 0, bottom: 0, trailing: 0)
			containerView.setConstraints([
				targetView.topAnchor.constraint(greaterThanOrEqualTo: containerView.safeAreaLayoutGuide.topAnchor, constant: extraSafeArea),
				height
			])
		case .top:
			containerView.setConstraintsFitting(child: targetView, top: 0, leading: 0, trailing: 0)
			containerView.setConstraints([
				targetView.bottomAnchor.constraint(lessThanOrEqualTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -extraSafeArea),
				height
			])
		default:
			let edge = presentingSide == .left ?
				targetView.leftAnchor.constraint(equalTo: containerView.leftAnchor) :
				targetView.rightAnchor.constraint(equalTo: containerView.rightAnchor)
			let visibleWidth = (1 + snapshotScale) * 0.5
			containerView.setConstraintsFitting(child: targetView, top: 0, bottom: 0)
			containerView.setConstraints([
				edge,
				targetView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: visibleWidth, constant: -snapshotInset * snapshotScale)
			])
		}
		
		targetView.make(radius: cornerRadius.topLeft)
	}
	
	private func trackKeyboard() {
#if !os(tvOS)
		let center = NotificationCenter.default
		[UIResponder.keyboardWillShowNotification, UIResponder.keyboardWillChangeFrameNotification, UIResponder.keyboardWillHideNotification].forEach {
			center.removeObserver(self, name: $0, object: nil)
			center.addObserver(self, selector: #selector(keyboardChanged(notification:)), name: $0, object: nil)
		}
#endif
	}
	
#if !os(tvOS)
	@objc private func keyboardChanged(notification: Notification) {
		guard
			let containerView,
			let userInfo = notification.userInfo,
			let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
		else { return }
		
		let isHiding = notification.name == UIResponder.keyboardWillHideNotification
		let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? Constant.duration
		let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int ?? 0
		
		keyboardOverlap = isHiding ? 0 : max(0, containerView.bounds.maxY - containerView.convert(frame, from: nil).minY)
		
		UIView.animate(withDuration: duration, delay: 0, options: .init(rawValue: UInt(curve << 16))) {
			self.updateKeyboardInset()
			containerView.layoutIfNeeded()
		}
	}
#endif
	
	private func updateKeyboardInset() {
		let inset = max(0, keyboardOverlap - (containerView?.safeAreaInsets.bottom ?? 0))
		guard abs(presentedViewController.additionalSafeAreaInsets.bottom - inset) > 0.5 else { return }
		presentedViewController.additionalSafeAreaInsets.bottom = inset
		updateHeight(animated: false)
	}
	
	private func measureHeight() -> CGFloat {
		measuredWidth = containerView?.bounds.width ?? UIWindow.keyBounds.width
		return min(fixedHeight ?? presentedViewController.fittingPresentationHeight(width: measuredWidth, maxHeight: maximumHeight), maximumHeight)
	}
	
	private func updateHeight(animated: Bool) {
		guard !isDismissing, let heightConstraint else { return }
		let height = measureHeight()
		guard abs(heightConstraint.constant - height) > 0.5 else { return }
		heightConstraint.constant = height
		
		guard animated, propertyAnimator?.isRunning != true else { return }
		UIView.animate(springDuration: Constant.duration, bounce: 0, options: .beginFromCurrentState) {
			self.containerView?.layoutIfNeeded()
		}
	}
	
// MARK: - Exposed Methods
	
	public func prepareInitialLayout(closing: Bool = false) {
		guard
			let containerBounds = containerView?.bounds,
			let targetView = presentedView
		else { return }
		
		snapshotView?.transform = .identity
		if closing {
			CATransaction.setCompletionBlock { [weak self] in self?.snapshotView?.removeFromSuperview() }
		}
		
		let frame = targetView.frame
		
		switch presentingSide {
		case .top:
			targetView.transform = .init(translationX: 0, y: -frame.maxY)
		case .bottom:
			targetView.transform = .init(translationX: 0, y: containerBounds.height - frame.minY)
		default:
			break
		}
	}
	
	public func prepareFinalLayout(source: UIViewController?) {
		guard let targetView = presentedView else { return }
		
		targetView.transform = .identity
		
		if presentingSide.isHorizontal {
			let delta: CGFloat = presentingSide == .right ? 1 : -1
			let posX = -(UIWindow.keyBounds.width * delta) + (snapshotInset * delta)
			let imageView = UIImageView(image: source?.view.superview?.snapshot)
			containerView?.addSubview(imageView)
			imageView.make(radius: 50).transform = .identity.scaledBy(x: snapshotScale, y: snapshotScale).translatedBy(x: posX, y: 0)
			UITapGestureRecognizer.set(on: imageView) { [weak self] _ in self?.handleDismiss() }
			UIPanGestureRecognizer.set(on: imageView) { [weak self] _ in self?.handleDismiss() }
			snapshotView = imageView
		}
	}
	
// MARK: - Overridden Methods
	
	public override func presentationTransitionWillBegin() {
		guard
			let containerView,
			let targetView = presentedView
		else { return }
		
		let explicitHeight = (nestedViewController as? PresentationSizing)?.preparePresentationSizing()
		fixedHeight = fixedHeight ?? explicitHeight
		
		containerView.insertSubview(dimmingView, at: 0)
		containerView.addSubview(targetView)
		layout(targetView, in: containerView)
		containerView.layoutIfNeeded()
		updateGrabber()
		prepareInitialLayout()
		
		dimmingView.frame = containerView.bounds
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
	
	public override func containerViewWillLayoutSubviews() {
		super.containerViewWillLayoutSubviews()
		updateKeyboardInset()
		guard let width = containerView?.bounds.width, width != measuredWidth else { return }
		updateHeight(animated: false)
	}
	
	public override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
		super.preferredContentSizeDidChange(forChildContentContainer: container)
		updateHeight(animated: true)
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
	
	fileprivate func fittingPresentationHeight(width: CGFloat, maxHeight: CGFloat) -> CGFloat {
		if let navigation = self as? UINavigationController, let top = navigation.topViewController {
			let bar = navigation.isNavigationBarHidden ? 0 : navigation.navigationBar.frame.height
			return top.fittingPresentationHeight(width: width, maxHeight: max(0, maxHeight - bar)) + bar
		}
		
		if let sizing = self as? PresentationSizing {
			return sizing.presentationHeight(fitting: width, maxHeight: maxHeight)
		}
		
		if preferredContentSize.height > 0 {
			return preferredContentSize.height
		}
		
		let target = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
		let size = view.systemLayoutSizeFitting(target, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
		return max(0, size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)
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
		let isModal = style.isModal
#if os(iOS) && !os(visionOS)
		if style == .pageSheet || style == .formSheet {
			target.modalPresentationStyle = style
			target.transitioningDelegate = nil
			let sheet = target.sheetPresentationController
			let detent = UISheetPresentationController.Detent.custom(identifier: .init("dent")) { context in
				let width = UIWindow.keyBounds.width
				return target.presentation.fixedHeight ?? target.fittingPresentationHeight(width: width, maxHeight: context.maximumDetentValue)
			}
			sheet?.detents = [detent]
			
			if isModal {
				sheet?.preferredCornerRadius = target.presentation.cornerRadius.topLeft
				sheet?.prefersGrabberVisible = target.presentation.isGrabberVisible
			}
			
			sheet?.prefersEdgeAttachedInCompactHeight = true
			sheet?.prefersScrollingExpandsWhenScrolledToEdge = true
		} else {
			if isModal {
				target.presentation.presentingSide = side
			}
			target.modalPresentationStyle = isModal ? .custom : style
			target.transitioningDelegate = isModal ? target.presentation : target.transitioningDelegate
		}
#else
		target.modalPresentationStyle = isModal ? .custom : style
		target.transitioningDelegate = isModal ? target.presentationController as? UIViewControllerTransitioningDelegate : target.transitioningDelegate
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
	/// - Parameter style: Defines the `UIModalPresentationStyle` in which it will be presented. Default is `.none`.
	/// - Parameter side: The screen edge from which the presentation should originate.
	/// - Parameter preferredHeight: If provided, fixes the content height of the presentation instead of measuring it.
	func presentOverWindow(style: UIModalPresentationStyle = .none, from side: UIRectEdge = .bottom, preferredHeight: CGFloat? = nil) {
		if let height = preferredHeight {
			presentation.fixedHeight = height
		}
		UIWindow.topViewController?.presentOver(self, style: style, from: side)
	}
}
#endif
