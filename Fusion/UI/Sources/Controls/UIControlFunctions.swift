//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Definitions -

public typealias Callback = () -> Void

public typealias ConfirmationCallback = (Bool) -> Void

private class EventWrapper : NSObject {

	private var event: UIControl.Event
	private weak var control: UIControl?
	private var runnable: Callback?

	init(event: UIControl.Event, control: UIControl, runnable: Callback?) {
		self.event = event
		self.control = control
		self.runnable = runnable
		super.init()
		self.enable()
	}

	@objc
	private func run(_ control: UIControl) {
		runnable?()
	}

	private func enable() {
		control?.addTarget(self, action: #selector(run(_:)), for: event)
		objc_setAssociatedObject(control as Any, Unmanaged.passUnretained(self).toOpaque(), self, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	}

	private func disable() {
		control?.removeTarget(self, action: #selector(run(_:)), for: event)
		objc_setAssociatedObject(control as Any, Unmanaged.passUnretained(self).toOpaque(), nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	}
	
	func shouldDisable(for controlEvent: UIControl.Event) -> Bool {
		guard event == controlEvent else { return true }
		disable()
		return false
	}
}

// MARK: - Extension - UIControl

public extension UIControl {

// MARK: - Properties
	
	private var targets: [EventWrapper] {
		get { (objc_getAssociatedObject(self, Unmanaged.passUnretained(self).toOpaque()) as? [EventWrapper]) ?? [] }
		set { objc_setAssociatedObject(self, Unmanaged.passUnretained(self).toOpaque(), newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
	}

// MARK: - Protected Methods

// MARK: - Exposed Methods
	
	func setAction(for controlEvent: UIControl.Event = .primaryActionTriggered, _ closure: Callback?) {
		targets = targets.filter { $0.shouldDisable(for: controlEvent) }
		targets += [EventWrapper(event: controlEvent, control: self, runnable: closure)]
	}
	
	func setTarget(_ target: Any,
				   action: Selector,
				   for controlEvents: UIControl.Event = .primaryActionTriggered) {
		removeTarget(nil, action: nil, for: controlEvents)
		addTarget(target, action: action, for: controlEvents)
	}
}

// MARK: - Extension - UIButton

public extension UIButton {
	
	func autogenerateAccessbility() {
		accessibilityIdentifier = titleLabel?.text?.originalKey ?? imageView?.image?.accessibilityIdentifier
		accessibilityLabel = titleLabel?.text ?? imageView?.image?.accessibilityIdentifier
	}
}
#endif
