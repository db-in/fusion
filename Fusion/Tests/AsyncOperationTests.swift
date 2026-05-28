//
//  Created by Diney Bomfim on 11/11/24.
//

import XCTest
@testable import Fusion

// MARK: - Definitions -

// MARK: - Type -

class AsyncOperationTests : XCTestCase {

// MARK: - Properties

	let queue = OperationQueue()
	
// MARK: - Constructors

// MARK: - Protected Methods

// MARK: - Exposed Methods

	func testAsyncBlock_WithAddingExecutionBlockMethod_ShouldEnableReadyState() {
		let operation = AsyncOperation { op in
			XCTAssert(op.isReady)
		}
		XCTAssert(operation.isReady)
	}
	
	func testAsyncBlock_WithStartMethod_ShouldSetStateToExecuting() {
		let operation = AsyncOperation { _ in }
		XCTAssert(!operation.isExecuting)
		operation.start()
		XCTAssert(operation.isExecuting)
	}

	func testAsyncBlock_WithCancelMethod_ShouldSetStateToCancelled() {
		let operation = AsyncOperation { _ in }
		XCTAssert(!operation.isCancelled)
		operation.cancel()
		XCTAssert(operation.isCancelled)
	}
	
	func testAsyncBlock_WithRestartMethod_ShouldSetStateToReady() {
		let operation = AsyncOperation { _ in }
		operation.state = .executing
		XCTAssert(!operation.isReady)
	}
	
	func testAsyncBlock_WithFinishMethod_ShouldSetStateToFinished() {
		let operation = AsyncOperation { _ in }
		XCTAssert(!operation.isFinished)
		operation.complete()
		XCTAssert(operation.isFinished)
	}
	
	func testAsyncBlock_WithRestartMethodOverCancelledState_ShouldNotChangeState() {
		let operation = AsyncOperation { _ in }
		XCTAssert(!operation.isCancelled)
		operation.cancel()
		XCTAssert(operation.isCancelled)
		operation.state = .ready
		XCTAssert(!operation.isCancelled)
	}
	
	func testAsyncBlock_WithRestartMethodOverFinishedState_ShouldNotChangeState() {
		let operation = AsyncOperation { op in
			op.complete()
			XCTAssert(op.isFinished)
		}
		XCTAssert(!operation.isFinished)
	}
	
	func testAsyncBlock_WithOperationQueue_ShouldTriggerAllTheFlow() {
		let expect = expectation(description: "\(#function)")
		let queue = OperationQueue()
		var value = 1
		let operation = AsyncOperation { op in
			value += 1
			XCTAssert(!op.isFinished)
			op.complete()
			XCTAssert(op.isFinished)
			XCTAssert(value == 2)
			expect.fulfill()
		}
		
		XCTAssert(!operation.isFinished)
		XCTAssert(operation.isReady)
		
		queue.addOperation(operation)
		
		waitForExpectations(timeout: 2.0, handler: { (error) -> Void in
			XCTAssertNil(error)
		})
	}
	
// MARK: - Overridden Methods

}

