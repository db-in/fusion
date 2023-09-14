//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Extension - CGSize

public extension CGSize {
	
	/// Squared 36.67 x 36.67. The size of the dynamic island at its launch.
	static var dynamicSquare: CGSize { .init(squared: 36.67) }
}

// MARK: - Type - StatusBarViewController

private class StatusBarViewController : UIViewController {
	
	private static var window: UIWindow?
	
#if os(iOS)
	override var prefersStatusBarHidden: Bool { true }
#endif
	
	private static func generateWindow() -> UIWindow {
		let topWindow = UIWindow.createWindowOverScene()
		topWindow.frame = UIWindow.keyBounds
		topWindow.backgroundColor = .clear
		topWindow.isUserInteractionEnabled = false
		topWindow.rootViewController = StatusBarViewController()
		return topWindow
	}
	
	static func setStatusBarHidden(_ hidden: Bool, animated: Bool) {
		if hidden {
			UIView.animate(withDuration: animated ? Constant.duration : 0) { window = generateWindow() }
		} else {
			UIView.animate(withDuration: animated ? Constant.duration : 0) {
				window?.isHidden = true
			} completion: { _ in
				window = hidden ? generateWindow() : nil
			}
		}
	}
}

// MARK: - Extension - NSLayoutConstraint

public extension NSLayoutConstraint {
	
	func isLike(_ other: NSLayoutConstraint) -> Bool {
		firstItem === other.firstItem &&
		secondItem === other.secondItem &&
		firstAnchor === other.firstAnchor &&
		secondAnchor === other.secondAnchor &&
		relation == other.relation
	}
}

// MARK: - Extension - NSLayoutConstraint.Relation

public extension NSLayoutConstraint.Relation {
	
	func constraint(_ dimension: NSLayoutDimension, constant: CGFloat) -> NSLayoutConstraint {
		switch self {
		case .greaterThanOrEqual:
			return dimension.constraint(greaterThanOrEqualToConstant: constant)
		case .lessThanOrEqual:
			return dimension.constraint(lessThanOrEqualToConstant: constant)
		default:
			return dimension.constraint(equalToConstant: constant)
		}
	}
}

// MARK: - Extension - NSObject

public extension NSObject {
	
	static var name: String { "\(self)" }
}

// MARK: - Extension - UIApplication

public extension UIApplication {
	
	static var main: UIApplication? { UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication }
	
	static func setStatusBarHidden(_ hidden: Bool, animated: Bool) {
		StatusBarViewController.setStatusBarHidden(hidden, animated: animated)
	}
}

// MARK: - Extension - [UIView]

public extension Array where Element == UIView {
	
	func removeAllFromSuperview() { forEach { $0.removeFromSuperview() } }
}

// MARK: - Extension - UIView

public extension UIView {

// MARK: - Constructors
	
	convenience init(width: CGFloat? = nil,
					 height: CGFloat? = nil,
					 relation: NSLayoutConstraint.Relation,
					 background: UIColor? = nil) {
		self.init(frame: .init(width: width ?? 0, height: height ?? 0))
		self.backgroundColor = background
		setConstraints(width: width, height: height, relation: relation)
	}
	
	convenience init(frame: CGRect = .zero, background: UIColor? = nil, useConstraints: Bool = false, mode: ContentMode? = nil) {
		self.init(frame: frame)
		self.backgroundColor = background
		
		if let newMode = mode {
			self.contentMode = newMode
		}
		
		if useConstraints {
			setConstraints(width: frame.width, height: frame.height)
		}
	}
	
// MARK: - Exposed Methods
	
	/// Returns an array of all subviews that satisfy the given condition.
	///
	/// - Parameter isIncluded: A closure that determines whether a subview should be included in the resulting array.
	/// - Returns: An array of subviews that satisfy the given condition.
	func allSubviews(where isIncluded: (UIView) -> Bool) -> [UIView] {
		var views = [UIView]()
		
		views += subviews.filter(isIncluded)

		subviews.forEach { subview in
			views += subview.allSubviews(where: isIncluded)
		}
		
		return views
	}
	
	/// Returns an array of all subviews with the specified name.
	///
	/// - Parameter named: The name to search for in the subviews.
	/// - Returns: An array of subviews with the specified name.
	func allSubviews(named: String) -> [UIView] {
		allSubviews { NSStringFromClass($0.classForCoder).contains(named) }
	}
	
	/// Returns the first subview with the specified name.
	///
	/// - Parameter named: The name to search for in the subviews.
	/// - Returns: The first subview with the specified name, or `nil` if not found.
	func firstSubview(named: String) -> UIView? {
		(allSubviews(named: named)).first
	}
	
	/// Returns an array of all subviews of the specified type.
	///
	/// - Returns: An array of subviews of the specified type.
	func allSubviewOf<T>() -> [T] {
		var views = [T]()
		
		views += subviews.compactMap { $0 as? T }

		subviews.forEach { subview in
			views += subview.allSubviewOf() as [T]
		}
		
		return views
	}
	
	/// Returns the first subview of the specified type.
	///
	/// - Returns: The first subview of the specified type, or `nil` if not found.
	func firstSubviewOf<T>() -> T? {
		(allSubviewOf() as [T]).first
	}
	
	/// Returns the first object of the specified type in the view hierarchy.
	///
	/// - Returns: The first object of the specified type, or `nil` if not found.
	func firstOf<T>() -> T? {
		self as? T ?? firstSubviewOf()
	}
	
	/// Finds and returns the first responder in the view hierarchy.
	///
	/// - Returns: The first responder view, or `nil` if not found.
	func findFirstResponder() -> UIView? {
		for subview in subviews {
			if subview.isFirstResponder {
				return subview
			}
			
			if let recursiveSubView = subview.findFirstResponder() {
				return recursiveSubView
			}
		}

		return nil
	}
	
	/// Finds and returns the possible associated view controller with this view.
	///
	/// - Returns: Returns the view controller if found or nil.
	func findViewController() -> UIViewController? {
		var responder: UIResponder? = self
		
		while responder != nil {
			responder = responder?.next
			guard let viewController = responder as? UIViewController else { continue }
			return viewController
		}

		return nil
	}
	
	/// Removes all gesture recognizers of the specified type from the view.
	///
	/// - Parameter kind: The type of gesture recognizer to remove.
	func removeAllGesture<T : UIGestureRecognizer>(of kind: T.Type) {
		gestureRecognizers?.forEach { gesture in
			guard gesture is T else { return }
			removeGestureRecognizer(gesture)
		}
	}
	
	/// Remove constraints like the ones in the list.
	/// It uses the ``NSLayoutConstraint/isLike(_:)`` in order to define if a constraint is like.
	///
	/// - Parameter list: A list of constraints to be removed when similar.
	func removeConstraintsLike(_ list: [NSLayoutConstraint]) {
		constraints.forEach { item in
			guard list.filter(item.isLike).first != nil else { return }
			removeConstraint(item)
		}
	}
	
	/// Activates a new set of constraints by removing an old list of constraints. The constraints to be removed can be defined or
	/// the ones in the new list will be overriding the old ones.
	/// Using this method does not affect `translatesAutoresizingMaskIntoConstraints`.
	///
	/// - Parameters:
	///   - list: The list of new constraints to be set.
	///   - removing: A list of old constraints to be removed before. The default value is `nil`, which means the new ones will override.
	func setConstraints(_ list: [NSLayoutConstraint], removing: [NSLayoutConstraint]? = nil) {
		removeConstraintsLike(removing ?? list)
		addConstraints(list)
	}
	
	/// Activates constraints for the width and height optionally, while having option to keep `translatesAutoresizingMaskIntoConstraints`.
	///
	/// - Parameters:
	///   - width: The width constant. If `nil`, the existing width constraint will be remove.
	///   - height: The height constant. If `nil`, the existing height constraint will be remove.
	///   - relation: The relation of the value with the constraints. The default is `equal`.
	///   - allowAutoresizing: Indicates the value to be set at `translatesAutoresizingMaskIntoConstraints`. The default is `false`.
	func setConstraints(width: CGFloat?, height: CGFloat?, relation: NSLayoutConstraint.Relation = .equal, allowAutoresizing: Bool = false) {
		let items = [
			relation.constraint(widthAnchor, constant: width ?? 0.0),
			relation.constraint(heightAnchor, constant: height ?? 0.0)
		]
		
		let validItems = zip([width, height], items).compactMap { $0 != nil ? $1 : nil }
		
		translatesAutoresizingMaskIntoConstraints = allowAutoresizing
		setConstraints(validItems, removing: items)
	}
	
	/// Activates constraints that will fit the child to this view directly.
	///
	/// Using this method does affect `translatesAutoresizingMaskIntoConstraints`, it's automatically set to `false`.
	///
	/// - Parameters:
	///   - child: The child view.
	///   - edges: The edges values, where `left` represents `leading` and `right` is `trailing`. The default is `zero`.
	func setConstraintsFitting(child: UIView, edges: UIEdgeInsets = .zero) {
		let views = ["c" : child]
		let hQuery = "H:|-(\(edges.left))-[c]-(\(edges.right))-|"
		let vQuery = "V:|-(\(edges.top))-[c]-(\(edges.bottom))-|"
		let items = NSLayoutConstraint.constraints(withVisualFormat: hQuery, metrics: nil, views: views) +
			NSLayoutConstraint.constraints(withVisualFormat: vQuery, metrics: nil, views: views)
		
		child.translatesAutoresizingMaskIntoConstraints = false
		setConstraints(items)
	}
	
	/// Activates constraints that will fit the child to this view safe area.
	///
	/// Using this method does affect `translatesAutoresizingMaskIntoConstraints`, it's automatically set to `false`.
	///
	/// - Parameters:
	///   - child: The child view.
	///   - edges: The edges values, where `left` represents `leading` and `right` is `trailing`. The default is `zero`.
	func setConstraintsToSafeAreaFitting(child: UIView, edges: UIEdgeInsets = .zero) {
		let items = [
			child.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: edges.top),
			child.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: edges.left),
			child.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -edges.bottom),
			child.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -edges.right)
		]
		
		child.translatesAutoresizingMaskIntoConstraints = false
		setConstraints(items)
	}
	
	/// Activates a series of conditional constraints, upong providing a value, from a child to this view.
	/// When `nil` is provided, no constraint is set for it.
	///
	/// Using this method does affect `translatesAutoresizingMaskIntoConstraints`, it's automatically set to `false`.
	///
	/// - Parameters:
	///   - child: The child view.
	///   - width: The width constant of the child. The default is `nil`.
	///   - height: The height constant of the child. The default is `CGSize.standardSquare.height`.
	///   - top: The top constant of the child. The default is `nil`.
	///   - leading: The leading constant of the child. The default is `nil`.
	///   - bottom: The bottom constant of the child. The default is `nil`.
	///   - trailing: The trailing constant of the child. The default is `nil`.
	///   - centerX: The centerX constant of the child. The default is `nil`.
	///   - centerY: The centerY constant of the child. The default is `nil`.
	func setConstraintsFitting(child: UIView,
							   width: CGFloat? = nil,
							   height: CGFloat? = nil,
							   top: CGFloat? = nil,
							   leading: CGFloat? = nil,
							   bottom: CGFloat? = nil,
							   trailing: CGFloat? = nil,
							   centerX: CGFloat? = nil,
							   centerY: CGFloat? = nil) {
		var items: [NSLayoutConstraint] = []
		
		if let value = top { items.append(child.topAnchor.constraint(equalTo: topAnchor, constant: value)) }
		if let value = leading { items.append(child.leadingAnchor.constraint(equalTo: leadingAnchor, constant: value)) }
		if let value = bottom { items.append(child.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -value)) }
		if let value = trailing { items.append(child.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -value)) }
		if let value = centerX { items.append(child.centerXAnchor.constraint(equalTo: centerXAnchor, constant: value)) }
		if let value = centerY { items.append(child.centerYAnchor.constraint(equalTo: centerYAnchor, constant: value)) }
		if let value = width { items.append(child.widthAnchor.constraint(equalToConstant: value)) }
		if let value = height { items.append(child.heightAnchor.constraint(equalToConstant: value)) }
		
		child.translatesAutoresizingMaskIntoConstraints = false
		setConstraints(items)
	}
	
	/// Scales the current view to fit its frame into its superview.
	func scaleToFitInSuperview() {
		guard frame.width > 0 else { return }
		transform = .identity
		let width = superview?.frame.width ?? 0
		let scale = width / frame.width
		transform = .init(scaleX: scale, y: scale)
		frame = .init(origin: .zero, size: frame.size)
	}
}

// MARK: - Extension - UIStackView

public extension UIStackView {
	
	convenience init(_ subviews: [UIView],
					 axis: NSLayoutConstraint.Axis,
					 spacing: CGFloat = 16,
					 distribution: UIStackView.Distribution = .equalSpacing,
					 alignment: UIStackView.Alignment = .fill) {
		self.init(arrangedSubviews: subviews)
		self.spacing = spacing
		self.axis = axis
		self.distribution = distribution
		self.alignment = alignment
	}
}

// MARK: - Extension - UIModalPresentationStyle

public extension UIModalPresentationStyle {
	
	/// Returns `true` if the current presentation is set to `custom` or `none` or `automatic`.
	var isModal: Bool {
		var oldModal = self == .custom || self == .none
		
		if #available(iOS 13.0, *) {
			oldModal = oldModal || self == .automatic
		}
		
		return oldModal
	}
}

// MARK: - Extension - UIWindow

public extension UIWindow {
	
#if os(iOS) && !os(xrOS)
	/// The frame of the status bar.
	var statusBarFrame: CGRect {
		guard #available(iOS 13.0, *) else { return UIApplication.main?.statusBarFrame ?? .zero }
		return windowScene?.statusBarManager?.statusBarFrame ?? .zero
	}
#endif
	
	/// The frame of the dynamic island, if it exists.
	var dynamicIslandFrame: CGRect? {
		guard safeAreaInsets.top >= 59 else { return nil }
		let height: CGFloat = CGSize.dynamicSquare.height
		let width: CGFloat
		
		switch bounds.size {
		case CGSize(width: 430, height: 932):
			width = 125
		case CGSize(width: 393, height: 852):
			width = 115
		default:
			width = 125
		}
		
		return .init(x: (bounds.width * 0.5) - (width * 0.5), y: safeAreaInsets.top - height - 11, width: width, height: height)
	}
	
	/// Indicates whether the view controller has a dynamic island.
	var hasDynamicIsland: Bool { dynamicIslandFrame != nil }
	
	/// Returns an array of all windows in the application.
	static var all: [UIWindow] {
		guard #available(iOS 13.0, *) else { return UIApplication.main?.windows ?? [] }
		return UIApplication.main?.connectedScenes.compactMap({ $0 as? UIWindowScene }).first?.windows ?? []
	}
	
	/// The first windown of the scene that is considered key.
	static var key: UIWindow? { all.first { $0.isKeyWindow } }
	
	/// Equivalent to the `topMost` controller of the `rootViewController` or the root itself.
	static var topViewController: UIViewController? { key?.rootViewController?.topMost ?? key?.rootViewController }
	
	/// The first tabbar that exists in the key hierarchy or nil if none is found.
	static var topTabBar: UITabBar? { key?.firstSubviewOf() }
	
	/// The frame of the key window. It can return zero if the key window isn't defined.
	static var keyFrame: CGRect { key?.frame ?? .zero }
	
	/// The bounds of the key window. It can return zero if the key window isn't defined.
	static var keyBounds: CGRect { key?.bounds ?? .zero }
	
	/// Removes the window from its scene and hides it.
	func removeFromScene() {
		isHidden = true

		if #available(iOS 13, *) {
			windowScene = nil
		}
	}
	
	/// Creates a new window over the current scene and makes it key and visible.
	///
	/// - Returns: The newly created UIWindow object.
	static func createWindowOverScene() -> UIWindow {
		guard
			#available(iOS 13.0, *),
			let scene = UIApplication.main?.connectedScenes.first as? UIWindowScene
		else { return .init() }
		
		let window = UIWindow(windowScene: scene)
		window.rootViewController = UIViewController()
		window.makeKeyAndVisible()
		return window
	}
	
	/// Sets the status bar state.
	///
	/// - Parameters:
	///   - hidden: A `bool` indicating if the bar will hide or show.
	///   - animated: A `bool` indicating if the transition will be animated.
	static func setStatusBarHidden(_ hidden: Bool, animated: Bool) {
		StatusBarViewController.setStatusBarHidden(hidden, animated: animated)
	}
}

// MARK: - Extension - UIViewController

public extension UIViewController {
	
// MARK: - Properties
	
	/// Returns the current top most view controller. When presenting modals and secondary navigation controllers
	/// this will return the top most.
	var topMost: UIViewController? {
		switch self {
		case let navigation as UINavigationController:
			return navigation.visibleViewController?.topMost
		case let presented where presentedViewController != nil:
			return presented.presentedViewController?.topMost
		case let tabbar as UITabBarController:
			return tabbar.selectedViewController?.topMost
		default:
			return self
		}
	}
	
	/// Returns the modal presentation style of the current navigation or view controller.
	var modalStyle: UIModalPresentationStyle { navigationController?.modalPresentationStyle ?? modalPresentationStyle }
	
	/// Identifies if the current ViewController is being presented inside a Modal.
	var isPresentingAsModal: Bool {
		let hasCustomStyle = modalStyle.isModal
		return hasCustomStyle ? true : navigationController?.presentingViewController != nil
	}
	
	/// Returns true if there are other controllers on the current navigation stack, otherwise false.
	var hasNavigationStack: Bool { (navigationController?.viewControllers.count ?? 0) > 1 }
	
// MARK: - Protected Methods
	
// MARK: - Exposed Methods
	
	/// Forces a given user interface style.
	///
	/// - Parameter with: The `UIUserInterfaceStyle` to be used.
	func overrideUserInterfaceStyle(with: UIUserInterfaceStyle) {
		if #available(iOS 13.0, *) {
			overrideUserInterfaceStyle = with
		}
	}
	
	/// Dinamically dismisses or pops the current view controller. Depending on the current navigation stack.
	func dismissOrPop() {
		if isPresentingAsModal && !hasNavigationStack {
			dismiss(animated: true)
		} else {
			navigationController?.popViewController(animated: true)
		}
	}
	
	/// Navigates back to the root view controller in the navigation stack.
	///
	/// - Parameter completion: An optional closure to be executed when the navigation operation completes.
	func backToRootViewController(completion: (() -> Void)? = nil) {
		if let callback = completion {
			CATransaction.setCompletionBlock { callback() }
		}
		
		CATransaction.begin()
		dismissOrPop()
		
		guard let rootController = view.window?.rootViewController else { return }
		rootController.dismiss(animated: false)
		
		if let tabBarController = rootController as? UITabBarController {
			(tabBarController.selectedViewController as? UINavigationController)?.popToRootViewController(animated: true)
		} else if let navigationController = rootController as? UINavigationController {
			navigationController.popToRootViewController(animated: true)
		} else {
			rootController.navigationController?.popToRootViewController(animated: true)
		}
		
		CATransaction.commit()
	}
	
	/// Adds a child view controller to the current view controller following the correct sequence of calls from `willMove` and `didMove`.
	///
	/// - Parameter child: The child view controller to be added.
	func add(child: UIViewController) {
		child.willMove(toParent: self)
		addChild(child)
		view.addSubview(child.view)
		child.didMove(toParent: self)
	}
	
	/// Removes the current view controller from its parent view controller following the correct sequence of calls from `willMove`.
	/// The `didMove` is also called, but it's done automatically by the deeper `removeFromParent`.
	func remove() {
		guard parent != nil else { return }
		willMove(toParent: nil)
		removeFromParent()
		view.removeFromSuperview()
	}
	
	/// Embeds the current view controller into a navigation controller if it is not already embedded.
	///
	/// - Returns: A navigation controller containing the current view controller.
	func embededInNavigation() -> UINavigationController {
		self as? UINavigationController ?? UINavigationController(rootViewController: self)
	}
	
	/// Instantiates the view controller from a storyboard with the specified name.
	///
	/// - Parameter storyboardName: The name of the storyboard.
	/// - Returns: The instantiated view controller.
	class func instantiate(storyboardName: String) -> Self? {
		let bundle: Bundle = Bundle(for: self)
		let storybaord = UIStoryboard(name: storyboardName, bundle: bundle)
		return storybaord.instantiateViewController(withIdentifier: name) as? Self
	}
	
#if os(iOS)
	private struct ObjcKeys {
		static var keyboard: UInt8 = 1
		static var originalInset: UInt8 = 2
	}
	
	private var keyboardInsetY: CGFloat {
		get { (objc_getAssociatedObject(self, &ObjcKeys.keyboard) as? CGFloat) ?? 0 }
		set { objc_setAssociatedObject(self, &ObjcKeys.keyboard, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
	}
	
	private var originalBottom: CGFloat {
		get { objc_getAssociatedObject(self, &ObjcKeys.originalInset) as? CGFloat ?? 0 }
		set { objc_setAssociatedObject(self, &ObjcKeys.originalInset, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
	}
	
	/// Registers the current view controller for keyboard show and hide notifications.
	func registerForKeyboardNotifications(insetY: CGFloat = 0) {
		keyboardInsetY = insetY
		originalBottom = additionalSafeAreaInsets.bottom
		
		let center = NotificationCenter.default
		let keyboardShow = UIResponder.keyboardWillShowNotification
		let keyboardHide = UIResponder.keyboardWillHideNotification
		center.removeObserver(self, name: keyboardShow, object: nil)
		center.removeObserver(self, name: keyboardHide, object: nil)
		center.addObserver(self, selector: #selector(keyboard(notification:)), name: keyboardShow, object: nil)
		center.addObserver(self, selector: #selector(keyboard(notification:)), name: keyboardHide, object: nil)
	}
	
	/// Handles the keyboard notifications and adjusts the additional safe area insets of the view controller's view.
	///
	/// - Parameter notification: The keyboard notification.
	@objc func keyboard(notification: Notification) {
		guard
			let userInfo = notification.userInfo,
			let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
			let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
			let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int
		else { return }
		
		let isShowing = notification.name == UIResponder.keyboardWillShowNotification
		
		UIView.animate(withDuration: duration, delay: 0, options: UIView.AnimationOptions(rawValue: UInt(curve << 16)), animations: {
			if isShowing {
				let existingInsets = self.additionalSafeAreaInsets
				let newBottomInset = max(existingInsets.bottom, frame.height - self.keyboardInsetY)
				self.additionalSafeAreaInsets = UIEdgeInsets(top: existingInsets.top, left: existingInsets.left, bottom: newBottomInset, right: existingInsets.right)
			} else {
				let bottom = self.originalBottom
				let insets = self.additionalSafeAreaInsets
				self.additionalSafeAreaInsets = UIEdgeInsets(top: insets.top, left: insets.left, bottom: bottom, right: insets.right)
			}
			self.view.layoutIfNeeded()
		}, completion: nil)
	}
#endif
}

// MARK: - Extension - UIGestureRecognizer

public extension UIGestureRecognizer {
	
	typealias GestureCallback = (UIGestureRecognizer) -> Void
	
	private struct ObjcKeys {
		static var recognizer: UInt8 = 1
	}
	
	private var gestureAction: GestureCallback? {
		get { objc_getAssociatedObject(self, &ObjcKeys.recognizer) as? GestureCallback }
		set { objc_setAssociatedObject(self, &ObjcKeys.recognizer, newValue, .OBJC_ASSOCIATION_RETAIN) }
	}
	
	@objc private func handler(_ gesture: UIGestureRecognizer) {
		gestureAction?(gesture)
	}
	
	/// Adds this gesture to a target.
	///
	/// - Parameters:
	///   - view: The target view.
	///   - closure: The gesture callback.
	/// - Returns: Returns the newly created gesture for convenience.
	@discardableResult static func add(on view: UIView, closure: @escaping GestureCallback) -> Self {
		let gesture = Self()
		gesture.gestureAction = closure
		gesture.addTarget(gesture, action: #selector(handler))
		view.addGestureRecognizer(gesture)
		view.isUserInteractionEnabled = true
		return gesture
	}
	
	/// Sets this instance as the only gesture of its kind removing any existing gesture of the same kind.
	///
	/// - Parameters:
	///   - view: The target view.
	///   - closure: The gesture callback.
	/// - Returns: Returns the newly created gesture for convenience.
	@discardableResult static func set(on view: UIView, closure: @escaping GestureCallback) -> Self {
		view.removeAllGesture(of: Self.self)
		return add(on: view, closure: closure)
	}
}

// MARK: - Type - UIHorizontalPanGestureRecognizer

/// Same as Pan Gesture but stricly horizontal, ideal for swipe cell/object actions.
public class UIHorizontalPanGestureRecognizer : UIPanGestureRecognizer, UIGestureRecognizerDelegate {
	
	convenience init() {
		self.init(target: nil, action: nil)
		delegate = self
		allowedTouchTypes = [0, 2]
	}
	
	public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
		let translationX = abs(pan.translation(in: pan.view).x)
		let translationY = abs(pan.translation(in: pan.view).y)
		return translationX > translationY
	}
}
#endif
