//
//  Created by Diney on 5/1/23.
//

import Foundation
import Testing
@testable import Fusion
#if canImport(UIKit)
import UIKit
#endif

private func sleep(seconds: Double) async {
	try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
}

extension FusionSuite {
	
	@Suite
	struct TimerControlTests {
		
		let timeout: Double = 1.0
		let frequency: Double = 1.0 / 60.0
		
		@Test
		func timerCyclePrecision_WhenAddingAnItem_ShouldExecuteCallbackWithExpectedPrecision() async {
			let timer = TimerControl()
			let cycles = ThreadSafe(wrappedValue: 0)
			timer.addItem(key: #function, queue: .global()) { cycles.mutate { $0 += 1 } }
			await sleep(seconds: timeout)
			timer.removeAll()
			let expected = Int(timeout / frequency)
			#expect(abs(cycles.wrappedValue - expected) <= expected / 10)
		}
		
		@Test
		func addItem_WithItemsAddedWhileRunning_ShouldKeepTheTickFrequency() async {
			let timer = TimerControl()
			let cycles = ThreadSafe(wrappedValue: 0)
			let start = CFAbsoluteTimeGetCurrent()
			timer.addItem(key: "first", queue: .global()) { cycles.mutate { $0 += 1 } }
			for index in 0..<250 {
				timer.addItem(key: "item_\(index)", queue: .global()) { }
				await sleep(seconds: 0.002)
			}
			timer.removeAll()
			let elapsed = CFAbsoluteTimeGetCurrent() - start
			#expect(Double(cycles.wrappedValue) <= elapsed / frequency * 1.5 + 2)
		}
		
		@Test
		func removeAll_AfterAddingItems_ShouldStopEveryCallback() async {
			let timer = TimerControl()
			let cycles = ThreadSafe(wrappedValue: 0)
			timer.addItem(key: "first", queue: .global()) { cycles.mutate { $0 += 1 } }
			timer.addItem(key: "second", queue: .global()) { }
			await sleep(seconds: 0.1)
			timer.removeAll()
			await sleep(seconds: 0.05)
			let stopped = cycles.wrappedValue
			await sleep(seconds: 0.2)
			#expect(cycles.wrappedValue == stopped)
		}
		
		@Test
		func addItem_WhenAddingAnItem_ShouldExecuteCallback() async {
			let timer = TimerControl()
			await confirmation { confirm in
				await withCheckedContinuation { continuation in
					timer.addItem(key: #function) {
						timer.removeItem(key: #function)
						confirm()
						continuation.resume()
					}
				}
			}
		}
		
		@Test
		func timer_WhenRemovingAnItem_ShouldNotExecuteCallbackAfterRemoval() async {
			let timer = TimerControl()
			let counter = ThreadSafe(wrappedValue: 0)
			timer.addItem(key: #function) { counter.mutate { $0 += 1 } }
			timer.removeItem(key: #function)
			await sleep(seconds: 0.2)
			#expect(counter.wrappedValue == 0)
			#expect(timer.itemsCount == 0)
		}
		
		@Test
		func multithreading_WhenAddingAndRemovingMultipleItems_ShouldNotCrash() async {
			let timer = TimerControl()
			await withTaskGroup(of: Void.self) { group in
				for i in 0..<100 {
					group.addTask {
						timer.addItem(key: "item_\(i)") { }
						usleep(arc4random_uniform(10))
						timer.removeItem(key: "item_\(i)")
					}
				}
			}
			#expect(timer.itemsCount == 0)
		}
		
		@Test
		func multithreading_WhenAddingItemsConcurrently_ShouldKeepEveryItem() async {
			let timer = TimerControl()
			await withTaskGroup(of: Void.self) { group in
				for i in 0..<200 {
					group.addTask { timer.addItem(key: "item_\(i)", queue: .global()) { } }
				}
			}
			#expect(timer.itemsCount == 200)
			timer.removeAll()
		}
		
		@Test
		func timer_RemoveAll_ShouldRemovesAllItems() {
			let timer = TimerControl()
			timer.addItem(key: "1", queue: .main) {}
			timer.addItem(key: "2", queue: .global()) {}
			timer.addItem(key: "3", queue: .main) {}
			timer.removeAll()
			#expect(timer.itemsCount == 0)
		}
		
		@Test
		func timer_WithPauseAndUnpause_ShouldCorrectlyExecuteBoth() async {
			let counter = ThreadSafe(wrappedValue: 0)
			let timer = TimerControl()
			timer.addItem(key: #function, queue: .global()) { counter.mutate { $0 += 1 } }
			await sleep(seconds: 0.2)
			#expect(counter.wrappedValue > 0)
			await sleep(seconds: 0.2)
			#expect(counter.wrappedValue > 0)
			timer.removeItem(key: #function)
		}
		
		@Test
		func handleTimerTick_WithGapAboveThreshold_ShouldAccumulateBackgroundTime() async {
			let timer = TimerControl()
			timer.handleTimerTick()
			#expect(timer.backgroundTime == 0)
			await sleep(seconds: 0.6)
			timer.handleTimerTick()
			#expect(timer.backgroundTime >= 0.5)
			#expect(timer.totalBackgroundTime >= 0.5)
			timer.handleTimerTick()
			#expect(timer.backgroundTime == 0)
			#expect(timer.totalBackgroundTime >= 0.5)
		}
		
		@Test
		func handleTimerTick_WithGapBelowThreshold_ShouldNotAccumulateBackgroundTime() async {
			let timer = TimerControl()
			timer.handleTimerTick()
			await sleep(seconds: 0.05)
			timer.handleTimerTick()
			#expect(timer.backgroundTime == 0)
			#expect(timer.totalBackgroundTime == 0)
		}
		
#if canImport(UIKit)
		@Test
		func timer_WithResignAndReactivateState_ShouldProperlyPauseAndResume() async {
			let timer = TimerControl()
			timer.addItem(key: #function) { }
			NotificationCenter.post(UIApplication.willResignActiveNotification)
			await sleep(seconds: 0.1)
			#expect(timer.itemsCount > 0)
			NotificationCenter.post(UIApplication.didBecomeActiveNotification)
			await sleep(seconds: 0.1)
			timer.removeItem(key: #function)
		}
#endif
	}
}
