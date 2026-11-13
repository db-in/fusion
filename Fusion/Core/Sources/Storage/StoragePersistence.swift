//
//  Created by Diney Bomfim on 11/12/26.
//

import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Definitions -

private struct PendingWrite {
	let value: Any?
	let generation: UInt64
	let write: () -> Void
}

private struct PendingState {
	var writes: [String : PendingWrite] = [:]
	var timers: [String : DispatchSourceTimer] = [:]
	var generation: UInt64 = 0
}

// MARK: - Type -

public enum StoragePersistence {
	
// MARK: - Properties
	
	private static let queue = DispatchQueue(label: "Fusion.StoragePersistence", qos: .utility)
	private static let state = ThreadSafe<PendingState>(wrappedValue: .init())
	
	private static let lifecycleObservers: [NSObjectProtocol] = {
#if canImport(UIKit) && !os(watchOS)
		let names: [Notification.Name] = [
			UIApplication.willResignActiveNotification,
			UIApplication.didEnterBackgroundNotification,
			UIApplication.willTerminateNotification
		]
#elseif canImport(AppKit)
		let names: [Notification.Name] = [
			NSApplication.willResignActiveNotification,
			NSApplication.willTerminateNotification
		]
#else
		let names: [Notification.Name] = []
#endif
		return names.map {
			NotificationCenter.default.addObserver(forName: $0, object: nil, queue: nil) { _ in flushPendingWrites() }
		}
	}()
	
	static var pendingCount: Int { state.wrappedValue.writes.count }
	
// MARK: - Protected Methods
	
	private static func register(key: String, value: Any?, write: @escaping () -> Void) -> UInt64 {
		_ = lifecycleObservers
		return state.mutate {
			$0.generation &+= 1
			$0.writes[key] = PendingWrite(value: value, generation: $0.generation, write: write)
			return $0.generation
		}
	}
	
	private static func commit(key: String, generation: UInt64?) {
		let entry: PendingWrite? = state.mutate {
			guard let entry = $0.writes[key], generation == nil || entry.generation == generation else { return nil }
			return entry
		}
		guard let entry else { return }
		entry.write()
		state.mutate {
			if $0.writes[key]?.generation == entry.generation { $0.writes[key] = nil }
		}
	}
	
// MARK: - Internal Methods
	
	static func pendingValue(forKey key: String) -> (found: Bool, value: Any?) {
		guard let entry = state.wrappedValue.writes[key] else { return (false, nil) }
		return (true, entry.value)
	}
	
	static func enqueue(key: String, value: Any?, write: @escaping () -> Void) {
		let generation = register(key: key, value: value, write: write)
		queue.async { commit(key: key, generation: generation) }
	}
	
	static func throttle(key: String, value: Any?, interval: TimeInterval, write: @escaping () -> Void) {
		_ = register(key: key, value: value, write: write)
		state.mutate { state in
			guard state.timers[key] == nil else { return }
			let timer = DispatchSource.makeTimerSource(queue: queue)
			timer.schedule(deadline: .now() + interval)
			timer.setEventHandler {
				StoragePersistence.state.mutate { $0.timers[key] = nil }
				commit(key: key, generation: nil)
			}
			state.timers[key] = timer
			timer.resume()
		}
	}
	
	static func cancel(key: String) {
		state.mutate { state in
			state.timers.removeValue(forKey: key)?.cancel()
			state.writes[key] = nil
		}
	}
	
	static func waitForPendingWrites() {
		queue.sync { }
	}
	
// MARK: - Exposed Methods
	
	/// Saves every pending asynchronous or throttled write of every storage before returning.
	/// On iOS, tvOS, visionOS and macOS it runs automatically when the app resigns active, enters the background or terminates.
	public static func flushPendingWrites() {
		queue.sync {
			let keys: [String] = state.mutate { state in
				state.timers.values.forEach { $0.cancel() }
				state.timers.removeAll()
				return Array(state.writes.keys)
			}
			keys.forEach { commit(key: $0, generation: nil) }
		}
		DataStorageableKeyTracking.flush()
	}
}
