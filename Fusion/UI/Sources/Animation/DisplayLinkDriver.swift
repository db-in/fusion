//
//  Created by Diney Bomfim on 11/12/26.
//

#if os(iOS) || os(tvOS)
import UIKit
import QuartzCore

// MARK: - Type -

final class DisplayLinkDriver : NSObject, FrameDriving {
	
// MARK: - Properties
	
	static let shared: DisplayLinkDriver = .init()
	
	private let items = ThreadSafe<[String : (callback: TimerCallback, queue: DispatchQueue)]>(wrappedValue: [:])
	private let clock = ThreadSafe<TimerClock>(wrappedValue: .init())
	private let isRunning = ThreadSafe<Bool>(wrappedValue: false)
	private var displayLink: CADisplayLink?
	
	private lazy var thread: Thread = {
		let thread = Thread { [weak self] in self?.runLoopMain() }
		thread.name = "Fusion.DisplayLinkDriver"
		thread.qualityOfService = .userInteractive
		thread.start()
		return thread
	}()
	
	var itemsCount: Int { items.wrappedValue.count }
	
	var totalBackgroundTime: Double { clock.wrappedValue.totalGap }
	
	var backgroundTime: Double { clock.wrappedValue.lastGap }
	
	var isActive: Bool { isRunning.wrappedValue }
	
// MARK: - Protected Methods
	
	private func runLoopMain() {
		let runLoop = RunLoop.current
		runLoop.add(NSMachPort(), forMode: .default)
		while true {
			autoreleasepool {
				_ = runLoop.run(mode: .default, before: .distantFuture)
			}
		}
	}
	
	@objc private func startLink() {
		guard displayLink == nil else { return }
		let link = CADisplayLink(target: self, selector: #selector(tick))
		link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 120, preferred: 120)
		link.add(to: .current, forMode: .common)
		displayLink = link
	}
	
	@objc private func stopLink() {
		let shouldStop = isRunning.mutate { running -> Bool in
			guard running, items.wrappedValue.isEmpty else { return false }
			running = false
			return true
		}
		guard shouldStop else { return }
		displayLink?.invalidate()
		displayLink = nil
	}
	
	private func startIfNeeded() {
		let shouldStart = isRunning.mutate { running -> Bool in
			guard !running else { return false }
			running = true
			return true
		}
		guard shouldStart else { return }
		clock.mutate { $0.lastTick = 0.0 }
		perform(#selector(startLink), on: thread, with: nil, waitUntilDone: false)
	}
	
	private func stopIfNeeded() {
		guard items.wrappedValue.isEmpty, isRunning.wrappedValue else { return }
		perform(#selector(stopLink), on: thread, with: nil, waitUntilDone: false)
	}
	
	@objc func tick() {
		handleTick(at: CFAbsoluteTimeGetCurrent())
	}
	
	func handleTick(at now: Double) {
		clock.mutate { $0.tick(at: now) }
		items.wrappedValue.values.forEach { item in
			item.queue.async(execute: item.callback)
		}
	}
	
// MARK: - Exposed Methods
	
	func addItem(key: String, queue: DispatchQueue, callback: @escaping TimerCallback) {
		items.mutate { $0[key] = (callback, queue) }
		startIfNeeded()
	}
	
	func removeItem(key: String) {
		items.mutate { $0[key] = nil }
		stopIfNeeded()
	}
}
#endif
