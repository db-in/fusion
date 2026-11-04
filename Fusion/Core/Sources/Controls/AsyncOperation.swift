//
//  Created by Diney Bomfim on 11/11/24.
//

import Foundation

// MARK: - Definitions -

/// A type alias for an asynchronous task that takes an `AsyncOperation` instance and returns `Void`.
public typealias AsyncTask = (AsyncOperation) -> Void

/// A class that manages a queue of `AsyncOperation` tasks, allowing control over the maximum number of concurrent tasks.
public class AsyncOperationQueue {
	
	private let queue: OperationQueue
	
	/// The maximum number of tasks that can execute concurrently.
	///
	/// This property wraps the `maxConcurrentOperationCount` of the `OperationQueue` to manage concurrency.
	public var maxConcurrentTasks: Int {
		get { queue.maxConcurrentOperationCount }
		set { queue.maxConcurrentOperationCount = newValue }
	}
	
	/// Initializes an `AsyncOperationQueue` with a specified maximum number of concurrent tasks.
	///
	/// - Parameter maxConcurrentTasks: The maximum number of tasks that can execute concurrently.
	public init(maxConcurrentTasks: Int) {
		queue = OperationQueue()
		self.maxConcurrentTasks = maxConcurrentTasks
	}
	
	/// Adds an asynchronous task to the queue for execution.
	///
	/// - Parameter task: A closure that represents the asynchronous task to be added to the queue.
	public func addTask(_ task: @escaping AsyncTask) {
		queue.addOperation(AsyncOperation(task: task))
	}
	
	/// Cancels all operations in the queue.
	public func cancelAll() {
		queue.cancelAllOperations()
	}
}

// MARK: - AsyncOperation Class -

/// A subclass of `Operation` that represents an asynchronous operation.
///
/// This class is used to manage the state and execution of tasks that require asynchronous operations.
public class AsyncOperation: Operation, @unchecked Sendable {
	
	/// An enumeration representing the state of an `AsyncOperation`.
	public enum State: String {
		case ready
		case executing
		case finished
		case cancelled
		
		fileprivate var keyPaths: [String] {
			switch self {
			case .ready:
				return ["isReady"]
			case .executing:
				return ["isExecuting"]
			case .finished:
				return ["isFinished"]
			case .cancelled:
				return ["isCancelled", "isFinished"]
			}
		}
	}
	
	private let task: AsyncTask
	private let lock = NSLock()
	private var storedState: State = .ready
	
	/// The current state of the operation.
	///
	/// This property is thread safe. It manages state transitions and triggers the `Operation` key-value observation when the state changes.
	/// A cancelled operation is also reported as finished, so an `OperationQueue` releases its slot.
	public var state: State {
		get { lock.withLock { storedState } }
		set {
			let oldValue = state
			guard oldValue != newValue else { return }
			let keyPaths = Array(Set(oldValue.keyPaths + newValue.keyPaths))
			keyPaths.forEach { willChangeValue(forKey: $0) }
			lock.withLock { storedState = newValue }
			keyPaths.forEach { didChangeValue(forKey: $0) }
		}
	}
	
	/// Indicates whether the operation is asynchronous.
	public override var isAsynchronous: Bool { true }
	
	/// Indicates whether the operation is ready to start.
	public override var isReady: Bool { state == .ready }
	
	/// Indicates whether the operation is currently executing.
	public override var isExecuting: Bool { state == .executing }
	
	/// Indicates whether the operation has finished execution or has been cancelled.
	public override var isFinished: Bool { state == .finished || state == .cancelled }
	
	/// Indicates whether the operation has been cancelled.
	public override var isCancelled: Bool { state == .cancelled }
	
// MARK: - Constructors
	
	/// Initializes an `AsyncOperation` with a specified task closure.
	///
	/// - Parameter task: The asynchronous task to be performed by the operation.
	public init(task: @escaping AsyncTask) {
		self.task = task
		super.init()
	}
	
// MARK: - Exposed Methods
	
	/// Marks the operation as completed and sets its state to `.finished`.
	public func complete() {
		state = .finished
	}
	
// MARK: - Overridden Methods
	
	/// Marks the operation as cancelled and sets its state to `.cancelled`. A finished operation is not affected.
	public override func cancel() {
		guard state != .finished else { return }
		state = .cancelled
	}
	
	/// Starts the operation by setting its state to `.executing` and executing the task.
	public override func start() {
		guard !isCancelled else {
			state = .finished
			return
		}
		
		state = .executing
		task(self)
	}
}
