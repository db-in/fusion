//
//  Created by Diney on 5/1/23.
//

import XCTest
@testable import Fusion

class TimerControlTests: XCTestCase {
	
	let timeout: TimeInterval = 1.0
	let frequency: TimeInterval = 1.0 / 60.0
	
	func testTimerCyclePrecision_WhenAddingAnItem_ShouldExecuteCallbackWithExpectedPrecision() {
		let expectation = expectation(description: #function)
		let timer = TimerControl.shared
		var cycles: Int = 0
		
		timer.addItem(key: #function) {
			cycles += 1
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
			XCTAssertEqual(cycles, Int(self.timeout / self.frequency), accuracy: 1)
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: timeout + 1.0)
	}
	
	func testAddItem_WhenAddingAnItem_ShouldExecuteCallback() {
		let expectation = expectation(description: #function)
		let timer = TimerControl()
		
		timer.addItem(key: #function) {
			timer.removeItem(key: #function)
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: timeout)
	}
	
	func testTimer_WhenRemovingAnItem_ShouldNotExecuteCallbackAfterRemoval() {
		let expectation = expectation(description: #function)
		var counter = 0
		let timer = TimerControl()
		
		timer.isPaused = true
		timer.addItem(key: #function) { counter += 1 }
		timer.removeItem(key: #function)

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
			XCTAssertEqual(counter, 0)
			XCTAssertEqual(timer.itemsCount, 0)
			expectation.fulfill()
		}

		wait(for: [expectation], timeout: timeout)
	}
	
	func testMultithreading_WhenAddingAndRemovingMultipleItems_ShouldNotCrash() {
		let expectation = expectation(description: #function)
		let timer = TimerControl()
		let group = DispatchGroup()
		
		for i in 0..<10 {
			group.enter()
			DispatchQueue.global(qos: .background).async {
				timer.addItem(key: "\(#function)_\(i)") { }
				usleep(arc4random_uniform(10))
				timer.removeItem(key: "\(#function)_\(i)")
				group.leave()
			}
		}
		
		group.notify(queue: .main) {
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: timeout + 1.0)
	}
	
	func testTimer_RemoveAll_ShouldRemovesAllItems() {
		let timer = TimerControl()
		timer.addItem(key: "1", queue: .main) {}
		timer.addItem(key: "2", queue: .global()) {}
		timer.addItem(key: "3", queue: .main) {}
		timer.removeAll()
		XCTAssertEqual(timer.itemsCount, 0)
	}
	
	func testTimer_WithPauseAndUnpause_ShouldCorrectlyExecuteBoth() {
		let expectation = expectation(description: #function)
		var counter = 0
		let timer = TimerControl()
		
		timer.isPaused = true
		timer.addItem(key: #function) { counter += 1 }
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
			XCTAssertEqual(counter, 0)
			timer.isPaused = false
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
				XCTAssertGreaterThan(counter, 0)
				timer.removeItem(key: #function)
				expectation.fulfill()
			}
		}
		
		wait(for: [expectation], timeout: timeout)
	}
	
	func testTimer_WithResignAndReactivateState_ShouldProperlyPauseAndResume() {
		let expectation = expectation(description: #function)
		let timer = TimerControl()
		
		timer.addItem(key: #function) { }
		
		NotificationCenter.post(UIApplication.willResignActiveNotification)
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			XCTAssertGreaterThan(timer.itemsCount, 0)
			XCTAssertTrue(timer.isPaused)
			
			NotificationCenter.post(UIApplication.didBecomeActiveNotification)
			
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				XCTAssertFalse(timer.isPaused)
				timer.removeItem(key: #function)
				expectation.fulfill()
			}
		}
		
		wait(for: [expectation], timeout: timeout)
	}
}
