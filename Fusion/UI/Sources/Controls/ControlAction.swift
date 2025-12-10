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
	public let isHighlighted: Bool
	public let action: ControlHandler?
	
// MARK: - Constructors
	
	public init(title: TextConvertible? = nil,
				image: UIImage? = nil,
				enabled: Bool = true,
				selected: Bool = false,
				highlighted: Bool = false,
				action: ControlHandler? = nil) {
		self.title = title
		self.image = image
		self.action = action
		self.isEnabled = enabled
		self.isHighlighted = highlighted
		self.isSelected = selected
	}
	
// MARK: - Exposed Methods
	
	public func execute() {
		action?(self)
	}
}

extension ControlAction: Hashable, Identifiable {
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(title?.content)
		hasher.combine(isSelected)
		hasher.combine(isEnabled)
		hasher.combine(isHighlighted)
	}
	
	public static func == (lhs: ControlAction, rhs: ControlAction) -> Bool { lhs.hashValue == rhs.hashValue }
}
#endif

#if canImport(UIKit) && !os(watchOS)
import UIKit

public extension Constant {
	static let deviceName = UIDevice.current.name
}
#elseif os(macOS)
import AppKit

public extension Constant {
	static let deviceName = Host.current().localizedName ?? ""
}
#elseif os(watchOS)
public extension Constant {
	static let deviceName = WKInterfaceDevice.current().name
}
#else
public extension Constant {
	static let deviceName = ""
}
#endif
