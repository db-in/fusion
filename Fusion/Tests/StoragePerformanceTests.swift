//
//  Created by Diney Bomfim on 8/7/26.
//

import XCTest
import os
@testable import Fusion

// MARK: - Definitions -

@propertyWrapper
final class LockedAtomic<Value> {
	private let lock = NSLock()
	private var value: Value

	init(wrappedValue: Value) {
		self.value = wrappedValue
	}

	var wrappedValue: Value {
		get {
			lock.lock()
			defer { lock.unlock() }
			return value
		}
		set {
			lock.lock()
			defer { lock.unlock() }
			value = newValue
		}
	}

	func mutate(_ transform: (inout Value) -> Void) {
		lock.lock()
		defer { lock.unlock() }
		transform(&value)
	}
}

@propertyWrapper
final class RecursiveLockedAtomic<Value> {
	private let lock = NSRecursiveLock()
	private var value: Value

	init(wrappedValue: Value) {
		self.value = wrappedValue
	}

	var wrappedValue: Value {
		get {
			lock.lock()
			defer { lock.unlock() }
			return value
		}
		set {
			lock.lock()
			defer { lock.unlock() }
			value = newValue
		}
	}

	func mutate(_ transform: (inout Value) -> Void) {
		lock.lock()
		defer { lock.unlock() }
		transform(&value)
	}
}

@propertyWrapper
final class GCDAtomic<Value> {
	private let queue = DispatchQueue(
		label: "com.fusion.gcd-atomic",
		attributes: .concurrent
	)
	private var value: Value

	init(wrappedValue: Value) {
		self.value = wrappedValue
	}

	var wrappedValue: Value {
		get {
			queue.sync { value }
		}
		set {
			queue.async(flags: .barrier) { self.value = newValue }
		}
	}

	func mutate(_ transform: @escaping (inout Value) -> Void) {
		queue.sync(flags: .barrier) {
			transform(&self.value)
		}
	}
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
@propertyWrapper
struct UnfairLockAtomic<Value>: @unchecked Sendable {
	private let storage: OSAllocatedUnfairLock<Value>

	init(wrappedValue: Value) {
		self.storage = OSAllocatedUnfairLock(uncheckedState: wrappedValue)
	}

	var wrappedValue: Value {
		get { storage.withLockUnchecked { $0 } }
		nonmutating set { storage.withLockUnchecked { $0 = newValue } }
	}

	func mutate<Result>(_ transform: (inout Value) -> Result) -> Result {
		storage.withLockUnchecked(transform)
	}
}

actor AtomicStorage<Value> {
	private var value: Value

	init(_ value: Value) {
		self.value = value
	}

	var current: Value {
		value
	}

	func set(_ newValue: Value) {
		value = newValue
	}

	func mutate<Result>(_ transform: (inout Value) -> Result) -> Result {
		transform(&value)
	}
}

@propertyWrapper
struct ActorAtomic<Value>: Sendable where Value: Sendable {
	private let storage: AtomicStorage<Value>

	init(_ value: Value) {
		self.storage = AtomicStorage(value)
	}

	var wrappedValue: AtomicStorage<Value> {
		storage
	}

	var projectedValue: AtomicStorage<Value> {
		storage
	}
}

struct TestStorage: DataManageable {

	typealias Storage = StateStorage

	enum Key: String, CaseIterable {
		case counterKey
	}

	@Stored(TestStorage.self, key: .counterKey)
	static var counter: Int?
}

// MARK: - Type -

class StoragePerformanceTests: XCTestCase {

// MARK: - Properties

	private let taskCount = 8
	private let opsPerTask = 50_000

// MARK: - Protected Methods

	private func elapsedSeconds(since start: DispatchTime) -> Double {
		Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000_000
	}

	private func report(_ name: String, _ seconds: Double, count: Int) {
		let paddedName = name.padding(toLength: 28, withPad: " ", startingAt: 0)
		print(paddedName + String(format: "%8.4f s", seconds) + "  (final count: \(count))")
	}

	private func benchmarkThreads(_ name: String, increment: () -> Void, finalCount: () -> Int) -> Int {
		let start = DispatchTime.now()
		DispatchQueue.concurrentPerform(iterations: taskCount) { _ in
			for _ in 0..<opsPerTask {
				increment()
			}
		}
		let count = finalCount()
		report(name, elapsedSeconds(since: start), count: count)
		return count
	}

	private func benchmarkActor(_ name: String) async -> Int {
		@ActorAtomic(0) var counter
		let storage = $counter
		let start = DispatchTime.now()
		await withTaskGroup(of: Void.self) { group in
			for _ in 0..<taskCount {
				group.addTask {
					for _ in 0..<self.opsPerTask {
						await storage.mutate { $0 += 1 }
					}
				}
			}
		}
		let count = await storage.current
		report(name, elapsedSeconds(since: start), count: count)
		return count
	}

// MARK: - Exposed Methods

	func testConcurrentAtomicCandidates_ShouldMeasureAndCompareAgainstStorage() async {
		let expected = taskCount * opsPerTask
		print("Simulating \(taskCount) concurrent tasks × \(opsPerTask) increments each (\(expected) total per candidate)")
		print("1–6 use atomic mutate; 7 uses @Stored get+set (not atomic under contention)\n")

		let nsLock = LockedAtomic(wrappedValue: 0)
		XCTAssertEqual(benchmarkThreads("1. NSLock") {
			nsLock.mutate { $0 += 1 }
		} finalCount: {
			nsLock.wrappedValue
		}, expected)

		let recursiveLock = RecursiveLockedAtomic(wrappedValue: 0)
		XCTAssertEqual(benchmarkThreads("2. NSRecursiveLock") {
			recursiveLock.mutate { $0 += 1 }
		} finalCount: {
			recursiveLock.wrappedValue
		}, expected)

		let gcd = GCDAtomic(wrappedValue: 0)
		XCTAssertEqual(benchmarkThreads("3. GCD barrier") {
			gcd.mutate { $0 += 1 }
		} finalCount: {
			gcd.wrappedValue
		}, expected)

		if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
			let unfairLock = UnfairLockAtomic(wrappedValue: 0)
			XCTAssertEqual(benchmarkThreads("4. OSAllocatedUnfairLock") {
				unfairLock.mutate { $0 += 1 }
			} finalCount: {
				unfairLock.wrappedValue
			}, expected)
		}

		let actorCount = await benchmarkActor("5. Actor")
		XCTAssertEqual(actorCount, expected)

		let threadSafe = ThreadSafe(wrappedValue: 0)
		XCTAssertEqual(benchmarkThreads("6. Fusion ThreadSafe") {
			threadSafe.mutate { $0 += 1 }
		} finalCount: {
			threadSafe.wrappedValue
		}, expected)

		TestStorage.counter = 0
		_ = benchmarkThreads("7. Fusion Storage") {
			TestStorage.counter = (TestStorage.counter ?? 0) + 1
		} finalCount: {
			TestStorage.counter ?? 0
		}
		TestStorage.remove(keys: [.counterKey])
	}
}
