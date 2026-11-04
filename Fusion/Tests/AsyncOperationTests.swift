//
//  Created by Diney Bomfim on 11/11/24.
//

import Foundation
import Testing
@testable import Fusion

// MARK: - Definitions -

private final class KeyPathRecorder: NSObject {
	
	@ThreadSafe
	private(set) var keyPaths: [String] = []
	private let target: NSObject
	private let observed = ["isReady", "isExecuting", "isFinished", "isCancelled"]
	
	init(_ target: NSObject) {
		self.target = target
		super.init()
		observed.forEach { target.addObserver(self, forKeyPath: $0, options: [], context: nil) }
	}
	
	deinit {
		observed.forEach { target.removeObserver(self, forKeyPath: $0) }
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		guard let keyPath else { return }
		_keyPaths.mutate { $0.append(keyPath) }
	}
}

func completes(within seconds: Double, _ operation: @escaping @Sendable () async -> Void) async -> Bool {
	let resumed = ThreadSafe(wrappedValue: false)
	return await withCheckedContinuation { continuation in
		let resume: @Sendable (Bool) -> Void = { value in
			let shouldResume = resumed.mutate { done -> Bool in
				defer { done = true }
				return !done
			}
			if shouldResume { continuation.resume(returning: value) }
		}
		Task {
			await operation()
			resume(true)
		}
		Task {
			try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
			resume(false)
		}
	}
}

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct AsyncOperationTests {
		
		@Test
		func asyncBlock_WithAddingExecutionBlockMethod_ShouldEnableReadyState() {
			let operation = AsyncOperation { _ in }
			#expect(operation.isReady)
		}
		
		@Test
		func asyncBlock_WithStartMethod_ShouldSetStateToExecuting() {
			let operation = AsyncOperation { _ in }
			#expect(!operation.isExecuting)
			operation.start()
			#expect(operation.isExecuting)
		}
		
		@Test
		func asyncBlock_WithCancelMethod_ShouldSetStateToCancelled() {
			let operation = AsyncOperation { _ in }
			#expect(!operation.isCancelled)
			operation.cancel()
			#expect(operation.isCancelled)
		}
		
		@Test
		func asyncBlock_WithCancelMethod_ShouldAlsoReportFinished() {
			let operation = AsyncOperation { _ in }
			operation.cancel()
			#expect(operation.isFinished)
			#expect(!operation.isExecuting)
		}
		
		@Test
		func asyncBlock_WithRestartMethod_ShouldSetStateToReady() {
			let operation = AsyncOperation { _ in }
			operation.state = .executing
			#expect(!operation.isReady)
		}
		
		@Test
		func asyncBlock_WithFinishMethod_ShouldSetStateToFinished() {
			let operation = AsyncOperation { _ in }
			#expect(!operation.isFinished)
			operation.complete()
			#expect(operation.isFinished)
		}
		
		@Test
		func asyncBlock_WithRestartMethodOverCancelledState_ShouldNotChangeState() {
			let operation = AsyncOperation { _ in }
			operation.cancel()
			#expect(operation.isCancelled)
			operation.state = .ready
			#expect(!operation.isCancelled)
		}
		
		@Test
		func asyncBlock_WithRestartMethodOverFinishedState_ShouldNotChangeState() {
			let operation = AsyncOperation { op in
				op.complete()
				#expect(op.isFinished)
			}
			#expect(!operation.isFinished)
		}
		
		@Test
		func asyncBlock_WithStateChanges_ShouldNotifyOperationKeyPaths() {
			let operation = AsyncOperation { _ in }
			let recorder = KeyPathRecorder(operation)
			operation.start()
			operation.complete()
			#expect(recorder.keyPaths.contains("isExecuting"))
			#expect(recorder.keyPaths.contains("isFinished"))
			#expect(!recorder.keyPaths.contains("executing"))
			#expect(!recorder.keyPaths.contains("finished"))
		}
		
		@Test
		func asyncBlock_WithOperationQueue_ShouldTriggerAllTheFlow() async {
			let queue = OperationQueue()
			await confirmation { confirm in
				await withCheckedContinuation { continuation in
					let operation = AsyncOperation { op in
						#expect(!op.isFinished)
						op.complete()
						#expect(op.isFinished)
						confirm()
						continuation.resume()
					}
					#expect(operation.isReady)
					queue.addOperation(operation)
				}
			}
		}
		
		@Test
		func asyncQueue_WithMoreTasksThanTheLimit_ShouldRunThemAll() async {
			let queue = AsyncOperationQueue(maxConcurrentTasks: 1)
			let counter = ThreadSafe(wrappedValue: 0)
			let finished = await completes(within: 2) {
				await withCheckedContinuation { continuation in
					for _ in 0..<3 {
						queue.addTask { operation in
							DispatchQueue.global().async {
								let total = counter.mutate { value -> Int in
									value += 1
									return value
								}
								operation.complete()
								if total == 3 { continuation.resume() }
							}
						}
					}
				}
			}
			#expect(finished)
			#expect(counter.wrappedValue == 3)
		}
		
		@Test
		func asyncQueue_WithCancelledRunningTask_ShouldReleaseItsSlot() async {
			let queue = AsyncOperationQueue(maxConcurrentTasks: 1)
			let started = await completes(within: 2) {
				await withCheckedContinuation { continuation in
					queue.addTask { _ in continuation.resume() }
				}
			}
			#expect(started)
			queue.cancelAll()
			let next = await completes(within: 2) {
				await withCheckedContinuation { continuation in
					queue.addTask { operation in
						operation.complete()
						continuation.resume()
					}
				}
			}
			#expect(next)
		}
	}
}
