//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation

// MARK: - Definitions -

public typealias TimerCallback = () -> Void

struct TimerClock {
	
	static let suspensionThreshold: Double = 0.5
	
	var lastTick: Double = 0.0
	var lastGap: Double = 0.0
	var totalGap: Double = 0.0
	
	mutating func tick(at now: Double) {
		let gap = lastTick > 0.0 ? now - lastTick : 0.0
		lastGap = gap > Self.suspensionThreshold ? gap : 0.0
		totalGap += lastGap
		lastTick = now
	}
}

protocol FrameDriving : AnyObject {
	var totalBackgroundTime: Double { get }
	func addItem(key: String, queue: DispatchQueue, callback: @escaping TimerCallback)
	func removeItem(key: String)
}

// MARK: - Type -

/// This class creates a single unique loop running with the interval defined by the constant ``Constant/maxFps``.
final public class TimerControl {

// MARK: - Properties
	
	@ThreadSafe
	private var items: [String : (callback: TimerCallback, queue: DispatchQueue)] = [:]
	
	@ThreadSafe
	private var timer: DispatchSourceTimer?
	
	@ThreadSafe
	private var clock: TimerClock = .init()
	
	private lazy var timerQueue: DispatchQueue = { .init(label: "timer.\(UUID().uuidString)", attributes: .concurrent) }()
	
	/// Returns the count for the current number of items.
	public var itemsCount: Int { items.count }
	
	/// The time passed while in the background. This is only available on the first cycle after resuming activity.
	public var backgroundTime: Double { clock.lastGap }
	
	var totalBackgroundTime: Double { clock.totalGap }
	
	/// The singleton instance of ``TimerControl``.
	public static let shared: TimerControl = TimerControl()

// MARK: - Constructors
	
	public init() {
		startIfNeeded()
	}

// MARK: - Protected Methods
	
	private func newDispatch(fps: FPoint = Constant.maxFps) -> DispatchSourceTimer {
		let source = DispatchSource.makeTimerSource(queue: timerQueue)
		source.schedule(deadline: .now(), repeating: Double(1.0 / fps))
		source.setEventHandler(handler: handleTimerTick)
		source.activate()
		return source
	}
	
	private func startIfNeeded() {
		_timer.mutate { timer in
			guard timer == nil, !items.isEmpty else { return }
			_clock.mutate { $0.lastTick = 0.0 }
			timer = newDispatch()
		}
	}
	
	private func cancelIfNeeded() {
		_timer.mutate { timer in
			guard items.isEmpty else { return }
			timer?.cancel()
			timer = nil
		}
	}
	
	func handleTimerTick() {
		let now = CFAbsoluteTimeGetCurrent()
		_clock.mutate { $0.tick(at: now) }
		
		items.forEach { item in
			let key = item.key
			let callback = item.value.callback
			let queue = item.value.queue
			queue.async { [weak self] in
				guard self?.items[key] != nil else { return }
				callback()
			}
		}
	}
	
// MARK: - Exposed Methods
	
	/// Adds a callback item to the timer. It's added asynchronously and will take effect in the next timer loop.
	///
	/// - Parameters:
	///   - key: A unique key to associate the callback with. The same key can be used later on to remove the callback.
	///   - queue: A queue where the callback will be called on. By default this value is ``main``.
	///   - callback: The callback which will be called on every loop.
	public func addItem(key: String, queue: DispatchQueue = .main, callback: @escaping TimerCallback) {
		_items.mutate { $0[key] = (callback, queue) }
		startIfNeeded()
	}
	
	/// Removes a callback item from the timer associated with a key.
	/// - Parameter key: The key associated with the callback.
	public func removeItem(key: String) {
		_items.mutate { $0[key] = nil }
		cancelIfNeeded()
	}
	
	/// Removes all the current callbacks from the timer.
	public func removeAll() {
		_items.mutate { $0.removeAll() }
		cancelIfNeeded()
	}
	
// MARK: - Overridden Methods
	
}

extension TimerControl : FrameDriving { }

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
