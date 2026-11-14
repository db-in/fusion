//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Definitions -

fileprivate extension UIWindow {
	
	static var topNavigation: UINavigationController? {
		let currentTop = UIWindow.topViewController
		return (currentTop as? UINavigationController) ?? currentTop?.navigationController
	}
}

fileprivate extension UINavigationController {
	
	func first(like controller: UIViewController) -> UIViewController? {
		let controllerType = type(of: controller)
		return viewControllers.first { type(of: $0) == controllerType }
	}
}

private final class SwipeBackGestureDelegate: NSObject, UIGestureRecognizerDelegate {
	
	weak var navigation: UINavigationController?
	
	init(navigation: UINavigationController) {
		self.navigation = navigation
	}
	
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		guard let navigation else { return false }
		return navigation.viewControllers.count > 1 && navigation.transitionCoordinator == nil
	}
}

private struct SwipeBackKeys {
	static var delegate: UInt8 = 0
}

public extension UINavigationController {
	
	/// Enables the interactive swipe back gesture, even when the navigation bar is hidden or the back button is customized.
	/// It never replaces a delegate assigned by the navigation controller itself.
	func enableSwipeBack() {
		guard let gesture = interactivePopGestureRecognizer else { return }
		guard !(gesture.delegate is SwipeBackGestureDelegate), gesture.delegate !== self else { return }
		let swipeDelegate = SwipeBackGestureDelegate(navigation: self)
		objc_setAssociatedObject(self, &SwipeBackKeys.delegate, swipeDelegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		gesture.delegate = swipeDelegate
	}
	
	fileprivate func enableSwipeBackIfNeeded() {
		guard UserFlow.Config.isSwipeBackEnabled else { return }
		enableSwipeBack()
	}
}

public extension UIViewController {
	
	fileprivate var firstInNavigation: UIViewController { (self as? UINavigationController)?.viewControllers.first ?? self }
	
	
	/// Instantiates the view controller from a ``UserFlow``. This functions calls ``instantiate(storyboardName:)``
	///
	/// - Parameter flow: The ``UserFlow`` which contains the view controller.
	/// - Returns: The instantiated view controller.
	class func instantiate(flow: UserFlow) -> Self? {
		guard let name = flow.name else { return nil }
		return instantiate(storyboardName: name)
	}
}

public enum PresentationStyle {
	
	case root
	case push
	case pushWithRepetition
	case modal
	case modalWithPush
	case fullScreen
	case side(edge: UIRectEdge)
	
	fileprivate func present(_ userFlow: UserFlow) {
		let controller = userFlow.mapped
		
		switch self {
		case .root:
			guard let window = UIWindow.key else { return }
			window.rootViewController = controller
			UIView.transition(with: window, duration: Constant.duration, options: .transitionCrossDissolve, animations: nil)
		case .push:
			let firstController = controller.firstInNavigation
			let navigation = UIWindow.topNavigation
			
			if navigation == nil && UIWindow.topViewController?.isPresentingAsModal == true {
				UIWindow.topViewController?.dismiss(animated: false) {
					self.present(userFlow)
					return
				}
			}
			
			navigation?.enableSwipeBackIfNeeded()
			
			if let existingController = navigation?.first(like: firstController) {
				if existingController === navigation?.children.last {
					navigation?.popViewController(animated: false)
					navigation?.pushViewController(firstController, animated: false)
				} else {
					navigation?.popToViewController(existingController, animated: true)
				}
			} else {
				navigation?.pushViewController(firstController, animated: true)
			}
		case .pushWithRepetition:
			let navigation = UIWindow.topNavigation
			navigation?.enableSwipeBackIfNeeded()
			navigation?.pushViewController(controller.firstInNavigation, animated: true)
		case .modal:
			controller.embededInNavigation().presentOverWindow()
		case .modalWithPush:
			let currentTop = UIWindow.topViewController
			let navigation = (currentTop as? UINavigationController) ?? currentTop?.navigationController
			if currentTop?.isPresentingAsModal == true, let validNavigation = navigation {
				validNavigation.enableSwipeBackIfNeeded()
				validNavigation.pushViewController(controller, animated: true)
			} else {
				controller.embededInNavigation().presentOverWindow()
			}
		case .fullScreen:
			controller.presentOverWindow(style: .fullScreen)
		case .side(edge: let edge):
			controller.presentOverWindow(from: edge.rtlSafe)
		}
	}
}

public struct UserFlowHook {
	
	fileprivate static var record: Set<String> = []
	
	public let event: Notification.Name
	public let style: PresentationStyle
	
	public init(_ event: Notification.Name, style: PresentationStyle) {
		self.event = event
		self.style = style
	}
	
	fileprivate func hook(to userFlow: UserFlow) {
		let hash = "\(userFlow.hashValue)\(event.hashValue)"
		
		guard !UserFlowHook.record.contains(hash) else { return }
		
		UserFlowHook.record.insert(hash)
		NotificationCenter.default.addObserver(forName: event, object: nil, queue: .main) { _ in
			style.present(userFlow)
		}
	}
}

public struct UserFlowUniversalLink {
	
	public typealias Handler = (URL, UserFlow) -> Void
	
	fileprivate static var record: [UserFlow : [UserFlowUniversalLink]] = [:]
	
	public let pattern: String
	public let handler: Handler
	
	public init(_ pattern: String, handler: @escaping Handler = { _, flow in flow.startAsPush() }) {
		self.pattern = pattern
		self.handler = handler
	}
	
	fileprivate func link(to userFlow: UserFlow) {
		if UserFlowUniversalLink.record[userFlow] != nil {
			UserFlowUniversalLink.record[userFlow]?.append(self)
		} else {
			UserFlowUniversalLink.record[userFlow] = [self]
		}
	}
}

public typealias UserFlowMapping = (UserFlow) -> UIViewController?

// MARK: - Type -

public struct UserFlow: Hashable {
	
	public struct Config {
		
		/// When `true`, every navigation controller used by a ``UserFlow`` push or created by `embededInNavigation`
		/// gets the interactive swipe back gesture, including hidden navigation bars. The default is `false`.
		public static var isSwipeBackEnabled: Bool = false
	}
	
// MARK: - Properties
	
	private let identifier: String
	public let name: String?
	public let bundle: Bundle?
	public let map: UserFlowMapping?
	
	/// The original storyboard initial controller or an empty new `UIViewController` if no initial is found.
	public var initial: UIViewController {
		guard let storyboardName = name else { return mapped }
		return UIStoryboard(name: storyboardName, bundle: bundle).instantiateInitialViewController() ?? .init()
	}
	
	/// Mapped controller, after the UserFlow mapping function is executed.
	public var mapped: UIViewController {
		guard name != nil else { return map?(self) ?? .init() }
		return map?(self) ?? initial
	}
	
// MARK: - Constructors

	public init(_ name: String,
				bundle: Bundle,
				hooks: [UserFlowHook] = [],
				links: [UserFlowUniversalLink] = [],
				map: UserFlowMapping? = nil) {
		self.identifier = "\(name)-\(bundle.bundleIdentifier ?? "")"
		self.name = name
		self.bundle = bundle
		self.map = map
		hooks.forEach { $0.hook(to: self) }
		links.forEach { $0.link(to: self) }
	}
	
	public init(_ map: UserFlowMapping?,
				hooks: [UserFlowHook] = [],
				links: [UserFlowUniversalLink] = []) {
		self.identifier = UUID().uuidString
		self.name = nil
		self.bundle = nil
		self.map = map
		hooks.forEach { $0.hook(to: self) }
		links.forEach { $0.link(to: self) }
	}
	
// MARK: - Protected Methods
	
// MARK: - Exposed Methods
	
	/// A given identifiable controller inside the storyboard. It must be set the StoryboardID exactly as the class name.
	///
	/// - Parameter given: The type of the controller to be instantiated.
	/// - Returns: The initialized controller or nil if not found.
	public func identified<T : UIViewController>(_ type: T.Type) -> T? {
		guard let storyboardName = name else { return nil }
		return type.instantiate(storyboardName: storyboardName)
	}
	
	/// Presents the mapped controller by using modal.
	///
	/// - Parameters:
	///   - withNavigation: Defines it a new navigation controller should be created for it. The default is `false`.
	///   - style: Defines the modal presentation style. The default valus is `fullScreen`.
	public func startAsModal(withNavigation: Bool = false, style: UIModalPresentationStyle = .fullScreen) {
		(withNavigation ? mapped.embededInNavigation() : mapped).presentOverWindow(style: style)
	}
	
	/// Presents the mapped controller by pushing in the current navigation controller.
	/// This mode doesn't allow repetitions. If previously existing in the navigation stack, it will pop back to it.
	public func startAsPush() {
		PresentationStyle.push.present(self)
	}
	
	/// Presents the mapped controller by pushing in the current navigation controller.
	/// This mode allows repetition of the same controller.
	public func startAsPushWithRepetition() {
		PresentationStyle.pushWithRepetition.present(self)
	}
	
	/// Presents the mapped controller by replacing the root of the key window.
	public func startAsRoot() {
		PresentationStyle.root.present(self)
	}
	
	/// Just for static memory initialization. Without it the memory won't be loaded up-front.
	///
	/// - Parameter flows: The flows to be activated.
	public static func activate(_ flows: [UserFlow]) { }
	
	/// Handles a NSUserActivity used for Universal Link.
	///
	/// - Parameter activity: A valid NSUserActivity
	/// - Returns: A Bool indicating if the activity was successfully handled or not.
	@discardableResult public static func handle(_ activity: NSUserActivity) -> Bool {
		let urls = [activity.webpageURL, activity.referrerURL].compactMap { $0 }
		guard !urls.isEmpty else { return false }
		
		for url in urls {
			let urlString = url.absoluteString
			for (userFlow, links) in UserFlowUniversalLink.record {
				if let universalLink = links.first(where: { urlString.hasMatch(regex: $0.pattern) }) {
					asyncMain {
						universalLink.handler(url, userFlow)
					}
					return true
				}
			}
		}
		
		return false
	}
	
	/// Simulates a Universal Link navigation inside the application itself.
	///
	/// - Parameter link: An universal link either relative or absolute.
	/// - Returns: Returns true if the universal link can be handled.
	@discardableResult public static func universalLink(into link: String) -> Bool {
		let finalLink = link.contains("https") ? link : "https://www.com/\(link)"
		guard let url = URL(string: finalLink) else { return false }
		let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
		activity.webpageURL = url
		return handle(activity)
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(identifier)
	}
	
	public static func == (lhs: UserFlow, rhs: UserFlow) -> Bool {
		lhs.identifier == rhs.identifier
	}
// MARK: - Overridden Methods

}
#endif
