//  
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation
#if os(macOS)
	import AppKit
#elseif os(iOS) || os(tvOS)
	import UIKit
#endif

// MARK: - Definitions -

public typealias TimerCallback = () -> Void

// MARK: - Type -

/// This class creates a single unique loop running with the interval defined by the constant ``Constant.maxFps``.
final public class TimerControl {

// MARK: - Properties
	
	private var items: [String : (callback: TimerCallback, queue: DispatchQueue)] = [:]
	private var timer: DispatchSourceTimer?
	private lazy var timerQueue: DispatchQueue = { .init(label: "timer.\(UUID().uuidString)", attributes: .concurrent) }()
	
	/// Pauses or resumes the cycle.
	/// Set this property to true if you want to pause the animation temporary. Set it to false again to resume the timer.
	/// The default value is false.
	public var isPaused: Bool = false {
		didSet {
			if isPaused && !oldValue {
				timerQueue.async(flags: .barrier) { [weak self] in
					self?.timer?.suspend()
				}
			} else if !isPaused && oldValue  {
				timerQueue.async(flags: .barrier) { [weak self] in
					self?.timer?.resume()
				}
			}
		}
	}
	
	/// Returns the count for the current number of items.
	public var itemsCount: Int {
		timerQueue.sync(flags: .barrier) { items.count }
	}
	
	/// The time passed while in the background. This is only available on the first cycle after resuming activity.
	public private(set) var backgroundTime: Double = 0.0
	
	/// The singleton instance of ``TimerControl``.
	public static let shared: TimerControl = TimerControl()

// MARK: - Constructors
	
	public init() {
		timer = newDispatch()
		setupNotifications()
	}

// MARK: - Protected Methods
	
	private func newDispatch(fps: Float = Constant.maxFps) -> DispatchSourceTimer {
		let source = DispatchSource.makeTimerSource(queue: timerQueue)
		source.schedule(deadline: .now(), repeating: Double(1.0 / fps))
		source.setEventHandler(handler: handleTimerTick)
		source.activate()
		return source
	}
	
	private func cancelIfNeeded() {
		guard items.isEmpty else { return }
		timer?.cancel()
	}
	
	private func handleTimerTick() {
		timerQueue.async(flags: .barrier) { [weak self] in
			self?.items.forEach { item in
				let callback = item.value.callback
				let queue = item.value.queue
				queue.async {
					guard self?.isPaused == false else { return }
					callback()
				}
			}
			
			self?.backgroundTime = 0.0
		}
	}
	
	private func setupNotifications() {
		let center = NotificationCenter.default
		center.removeObserver(self)
		
#if os(macOS)
		center.addObserver(self, selector: #selector(pauseForBackground), name: NSApplication.willResignActiveNotification, object: nil)
		center.addObserver(self, selector: #selector(resumeFromBackground), name: NSApplication.didBecomeActiveNotification, object: nil)
		center.addObserver(self, selector: #selector(pauseForBackground), name: NSApplication.willTerminateNotification, object: nil)
#elseif os(iOS) || os(tvOS)
		center.addObserver(self, selector: #selector(pauseForBackground), name: UIApplication.willResignActiveNotification, object: nil)
		center.addObserver(self, selector: #selector(resumeFromBackground), name: UIApplication.didBecomeActiveNotification, object: nil)
		center.addObserver(self, selector: #selector(pauseForBackground), name: UIApplication.willTerminateNotification, object: nil)
#endif
	}
	
	@objc private func pauseForBackground() {
		isPaused = true
		backgroundTime = CFAbsoluteTimeGetCurrent()
	}
	
	@objc private func resumeFromBackground() {
		isPaused = false
		guard backgroundTime > 0.0 else { return }
		backgroundTime = CFAbsoluteTimeGetCurrent() - backgroundTime
	}
	
// MARK: - Exposed Methods
	
	/// Adds a callback item to the timer. It's added asynchronously and will take effect in the next timer loop.
	///
	/// - Parameters:
	///   - key: A unique key to associate the callback with. The same key can be used later on to remove the callback.
	///   - queue: A queue where the callback will be called on. By default this value is ``main``.
	///   - callback: The callback which will be called on every loop.
	public func addItem(key: String, queue: DispatchQueue = .main, callback: @escaping TimerCallback) {
		timerQueue.async(flags: .barrier) { [weak self] in
			self?.items[key] = (callback, queue)
		}
	}
	
	/// Removes a callback item from the timer associated with a key.
	/// - Parameter key: The key associated with the callback.
	public func removeItem(key: String) {
		timerQueue.async(flags: .barrier) { [weak self] in
			self?.items[key] = nil
			self?.cancelIfNeeded()
		}
	}
	
	/// Removes all the current callbacks from the timer.
	public func removeAll() {
		timerQueue.async(flags: .barrier) { [weak self] in
			self?.items = [:]
			self?.cancelIfNeeded()
		}
	}
	
// MARK: - Overridden Methods
	
}

// MARK: - Extension - DispatchQueue

public extension DispatchQueue {
	
	static func asyncMainIfNeeded(_ work: @escaping () -> Void) {
		if Thread.isMainThread {
			work()
		} else {
			DispatchQueue.main.async {
				work()
			}
		}
	}
}
