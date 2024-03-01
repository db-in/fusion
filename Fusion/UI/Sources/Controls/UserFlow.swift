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

public extension UIViewController {
	
	fileprivate var firstInNavigation: UIViewController { (self as? UINavigationController)?.viewControllers.first ?? self }
	
	
	/// Instantiates the view controller from a ``UserFlow``. This functions calls ``instantiate(storyboardName:)``
	///
	/// - Parameter flow: The ``UserFlow`` which contains the view controller.
	/// - Returns: The instantiated view controller.
	class func instantiate(flow: UserFlow) -> Self? { instantiate(storyboardName: flow.name) }
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
			UIWindow.topNavigation?.pushViewController(controller.firstInNavigation, animated: true)
		case .modal:
			controller.embededInNavigation().presentOverWindow()
		case .modalWithPush:
			let currentTop = UIWindow.topViewController
			let navigation = (currentTop as? UINavigationController) ?? currentTop?.navigationController
			if currentTop?.isPresentingAsModal == true, let validNavigation = navigation {
				validNavigation.pushViewController(controller, animated: true)
			} else {
				controller.embededInNavigation().presentOverWindow()
			}
		case .fullScreen:
			controller.presentOverWindow(style: .fullScreen)
		case .side(edge: let edge):
			controller.presentOverWindow(from: .right)
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
	
	public init(_ pattern: String, handler: @escaping Handler) {
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

public struct UserFlow {
	
// MARK: - Properties
	
	public let name: String
	public let bundle: Bundle
	public let map: UserFlowMapping?
	
	/// The original storyboard initial controller or an empty new `UIViewController` if no initial is found.
	public var initial: UIViewController { UIStoryboard(name: name, bundle: bundle).instantiateInitialViewController() ?? UIViewController() }
	
	/// Mapped controller, after the UserFlow mapping function is executed.
	public var mapped: UIViewController { map?(self) ?? initial }
	
// MARK: - Constructors

	public init(_ name: String,
				bundle: Bundle,
				hooks: [UserFlowHook] = [],
				links: [UserFlowUniversalLink] = [],
				map: UserFlowMapping? = nil) {
		self.name = name
		self.bundle = bundle
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
		type.instantiate(storyboardName: name)
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
		
		guard let url = activity.webpageURL else { return false }
		let link = url.absoluteString
		
		for (userFlow, links) in UserFlowUniversalLink.record {
			if let universalLink = links.first(where: { link.hasMatch(regex: $0.pattern) }) {
				asyncMain {
					universalLink.handler(url, userFlow)
				}
				return true
			}
		}
		
		return false
	}
	
	/// Simulates a Universal Link navigation inside the application itself.
	///
	/// - Parameter link: An universal link either relative or absolute.
	public static func universalLink(into link: String) {
		let finalLink = link.contains("https") ? link : "https://www.com/\(link)"
		guard let url = URL(string: finalLink) else { return }
		let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
		activity.webpageURL = url
		handle(activity)
	}
	
// MARK: - Overridden Methods

}

// MARK: - Extension - UserFlow

extension UserFlow : Hashable {
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(name)
		hasher.combine(bundle)
	}
}
#endif
