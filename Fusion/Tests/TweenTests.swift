//
//  Created by Diney Bomfim on 5/26/23.
//

import Foundation
import Testing
@testable import Fusion
#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Definitions -

private typealias Key = ReferenceWritableKeyPath<UIView, CGFloat>
private typealias Value = CGFloat

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	@MainActor
	struct TweenTests {
		
		@Test
		func mergeWithTargetView_WhenMergingWithTargetView_ShouldMergeValues() {
			let dictionary: [Key : Value] = [\UIView.center.x: 100.0, \UIView.alpha: 0.5]
			let other: [Key : Value] = [\UIView.center.y: 200.0, \UIView.alpha: 1.0]
			let targetView = Tween.Target(view: .init(), paths: [dictionary, other])
			let result = dictionary.mapKeys({ "\($0)" }).merge(with: other.mapKeys({ "\($0)" }), target: targetView)
			
			#expect(result["\\UIView.center.x"] == [100, 0])
			#expect(result["\\UIView.center.y"] == [0, 200])
			#expect(result["\\UIView.alpha"] == [0.5, 1.0])
		}
		
		@Test
		func mergeWithoutTargetView_WhenMergingWithoutTargetView_ShouldReturnEmptyResult() {
			let dictionary: [Key : Value] = [\UIView.center.x: 100.0, \UIView.alpha: 0.5]
			let other: [Key : Value] = [\UIView.center.y: 200.0, \UIView.alpha: 1.0]
			let result = dictionary.mapKeys({ "\($0)" }).merge(with: other.mapKeys({ "\($0)" }), target: nil)
			#expect(result["\\UIView.center.x"] == [100, 0])
			#expect(result["\\UIView.center.y"] == [0, 200])
			#expect(result["\\UIView.alpha"] == [0.5, 1.0])
		}
		
		@Test
		func restartTween_WhenRestartingTween_ShouldResetValuesAndRemainPaused() {
			let targetView = UIView()
			let tween = Tween(targetView, duration: 1.0)
			
			tween.isPaused = true
			tween.restartTween()
			
			#expect(tween.isPaused)
			#expect(tween.currentCycle == 0)
			#expect(tween.beginTime == 0.0)
			#expect(tween.currentTime == 0.0)
			#expect(tween.idleTime != 0.0)
			
			tween.stopTween()
		}
		
		@Test
		func stopTweenWithEndOption_WhenStoppingTweenWithEndOption_ShouldResetValuesAndEndAtZeroSize() {
			let targetView = UIView()
			let tween = Tween(targetView, duration: 1.0)
			
			tween.isPaused = true
			tween.stopTween(option: .final)
			
			#expect(tween.isPaused)
			#expect(tween.currentCycle == 0)
			#expect(tween.beginTime == 0.0)
			#expect(tween.currentTime == 0.0)
			#expect(tween.idleTime != 0.0)
			#expect(targetView.frame == CGRect.zero)
		}
		
		@Test
		func tweenRestart_WhenRestartingTween_ShouldPerformExpectedBehavior() async {
			let view = UIView()
			let tween = Tween(view, duration: 1.0)
			
			try? await Task.sleep(nanoseconds: 500_000_000)
			
			#expect(!tween.isPaused)
			#expect(tween.currentCycle == 0)
			#expect(tween.beginTime != 0.0)
			#expect(tween.currentTime != 0.0)
			#expect(tween.idleTime != 0.0)
			tween.isPaused = true
			tween.restartTween()
			#expect(tween.isPaused)
			#expect(tween.currentCycle == 0)
			#expect(tween.beginTime == 0.0)
			#expect(tween.currentTime == 0.0)
			#expect(tween.idleTime != 0.0)
			tween.stopTween()
		}
		
		@Test
		func tweenAnimation_WithMirror_ShouldPerformExpectedBehavior() async {
			let view = UIView()
			let endValue: CGFloat = 100
			let tween = Tween(view,
							  duration: 0.5,
							  options: .init(ease: .strongIn, isReversed: true, repetition: .mirrorValuesAndEase, repetitionCount: 2),
							  toValues: [\.center.x : endValue])
			
			try? await Task.sleep(nanoseconds: 700_000_000)
			
			#expect(!tween.isPaused)
			#expect(tween.isMirrored)
			#expect(tween.beginTime != 0.0)
			#expect(tween.currentTime != 0.0)
			#expect(tween.idleTime != 0.0)
			#expect(tween.currentCycle != 0)
			tween.stopTween()
		}
		
		@Test
		func tweenAnimation_WithDelayAndFullExecution_ShouldPerformAndStop() async {
			let view = UIView()
			let endValue: CGFloat = 100
			let time: FPoint = 0.1
			let tween = Tween(view,
							  duration: time,
							  options: .init(delay: time, repetition: .mirrorValues, repetitionCount: 1),
							  toValues: [\.center.x : endValue])
			
			#expect(tween.isReady)
			#expect(!tween.isMirrored)
			#expect(tween.deltaTime == 0.0)
			
			try? await Task.sleep(nanoseconds: UInt64(time * 3 * 1_000_000_000))
			
			#expect(tween.isReady)
			#expect(tween.isMirrored)
			#expect(tween.currentCycle != 0)
			tween.stopTween()
		}
		
		@Test
		func tweenAnimation_WithMirrorAndRestart_ShouldReturnToOriginalState() async {
			let view = UIView()
			let endValue: CGFloat = 100
			let tween = Tween(view,
							  duration: 0.2,
							  options: .init(isReversed: true, repetition: .mirrorValues),
							  toValues: [\.center.x : endValue])
			
			await Task.yield()
			
			#expect(!tween.isPaused)
			#expect(view.center.x != 0.0)
			tween.restartTween()
			#expect(view.center.x == 100.0)
			tween.stopTween()
		}
		
		@Test
		func tweenStopWithEndState_WhenStoppingTweenWithEndState_ShouldSetTargetToExpectedState() {
			let view = UIView()
			let endValue: CGFloat = 100
			let tween = Tween(view, duration: 1.0, toValues: [\.center.x : endValue])
			
			tween.stopTween(option: .final)
			
			#expect(view.center.x == endValue)
		}
		
		@Test
		func tweensWithTarget_WhenGettingTweensWithTarget_ShouldReturnExpectedTweens() {
			let view1 = UIView()
			let view2 = UIView()
			let view3 = UIView()
			
			let tween1 = Tween(view1, duration: 1.0)
			let tween2 = Tween(view2, duration: 2.0)
			let tween3 = Tween(view3, duration: 3.0)
			let tweens = Tween.tweens(withTarget: view2)
			
			#expect(tweens.count == 1)
			#expect(tweens.contains(tween2))
			#expect(!tweens.contains(tween1))
			#expect(!tweens.contains(tween3))
			
			[tween1, tween2, tween1].forEach { $0.stopTween() }
		}
		
		@Test
		func tweensWithName_WhenGettingTweensWithName_ShouldReturnExpectedTweens() {
			let view1 = UIView()
			let view2 = UIView()
			let view3 = UIView()
			
			let tween1 = Tween(view1, duration: 1.0, options: .init(name: "Tween1"))
			let tween2 = Tween(view2, duration: 2.0, options: .init(name: "Tween2"))
			let tween3 = Tween(view3, duration: 3.0, options: .init(name: "Tween2"))
			
			let tweens = Tween.tweens(withName: "Tween2")
			
			#expect(tweens.count == 2)
			#expect(tweens.contains(tween2))
			#expect(tweens.contains(tween3))
			#expect(!tweens.contains(tween1))
			
			[tween1, tween2, tween1].forEach { $0.stopTween() }
		}
		
		@Test
		func stopTweensWithTarget_WhenStoppingTweensWithTarget_ShouldSetTweensToExpectedState() {
			let view1 = UIView()
			let view2 = UIView()
			let view3 = UIView()
			
			Tween(view1, duration: 1.0)
			Tween(view2, duration: 2.0)
			Tween(view3, duration: 3.0)
			Tween.stopTweens(withTarget: view2)
			
			let tween1 = Tween.tweens(withTarget: view1)
			let tween2 = Tween.tweens(withTarget: view2)
			let tween3 = Tween.tweens(withTarget: view3)
			
			#expect(tween1.count == 1)
			#expect(tween2.count == 0)
			#expect(tween3.count == 1)
			
			(tween1 + tween2 + tween1).forEach { $0.stopTween() }
		}
		
		@Test
		func stopTweensWithName_WhenStoppingTweensWithName_ShouldSetTweensToExpectedState() {
			let view1 = UIView()
			let view2 = UIView()
			let view3 = UIView()
			
			Tween(view1, duration: 1.0, options: .init(name: "Stop1"))
			Tween(view2, duration: 2.0, options: .init(name: "Stop2"))
			Tween(view3, duration: 3.0, options: .init(name: "Stop2"))
			Tween.stopTweens(withName: "Stop2")
			
			let tweens1 = Tween.tweens(withName: "Stop1")
			let tweens2 = Tween.tweens(withName: "Stop2")
			
			#expect(tweens1.count == 1)
			#expect(tweens2.count == 0)
			
			Tween.stopTweens(withName: "Stop1")
			Tween.stopTweens(withName: "Stop2")
		}
		
		@Test
		func tweens_WhenCreatedAndStoppedConcurrently_ShouldKeepRegistryConsistent() async {
			let name = "Concurrent-\(UUID().uuidString)"
			
			await withTaskGroup(of: Void.self) { group in
				for index in 0..<100 {
					group.addTask {
						let tween = Tween(duration: 1.0, options: .init(name: name), fromValues: ["value": 0], toValues: ["value": 1])
						_ = Tween.tweens(withName: name)
						if index.isMultiple(of: 2) { tween.stopTween() }
					}
				}
			}
			
			#expect(Tween.tweens(withName: name).count == 50)
			Tween.stopTweens(withName: name)
			#expect(Tween.tweens(withName: name).isEmpty)
		}
		
		private final class Recorder {
			var values: [CGFloat] = []
			var finalTime: CFAbsoluteTime?
		}
		
		private func waitUntil(timeout: TimeInterval = 2, _ condition: () -> Bool) async {
			let deadline = Date().addingTimeInterval(timeout)
			while !condition() && Date() < deadline {
				try? await Task.sleep(nanoseconds: 5_000_000)
			}
		}
		
		@Test
		func tween_WithLowFpsAndShortDuration_ShouldRenderTheFinalValueWithoutLag() async {
			let recorder = Recorder()
			let start = CFAbsoluteTimeGetCurrent()
			let tween = Tween(duration: 0.05, options: .init(fps: 2), fromValues: ["value": 0], toValues: ["value": 1]) { _, values in
				guard let value = values["value"] else { return }
				recorder.values.append(value)
				if value == 1, recorder.finalTime == nil { recorder.finalTime = CFAbsoluteTimeGetCurrent() }
			}
			
			await waitUntil { recorder.finalTime != nil }
			tween.stopTween()
			
			let elapsed = (recorder.finalTime ?? .infinity) - start
			#expect(recorder.values.last == 1)
			#expect(elapsed < 0.3, "final value took \(elapsed)s")
		}
		
		@Test
		func tween_WithFirstTick_ShouldStartTheClockImmediately() async {
			let tween = Tween(duration: 1.0, options: .init(fps: 1), fromValues: ["value": 0], toValues: ["value": 1])
			await waitUntil(timeout: 0.5) { tween.beginTime != 0 }
			#expect(tween.beginTime != 0)
			tween.stopTween()
		}
		
		@Test
		func tween_WhenRestartedOnEveryFastTick_ShouldNeverFreezeOnAnOldValue() async {
			let recorder = Recorder()
			let name = "FastTicks-\(UUID().uuidString)"
			var current: CGFloat = 0
			var tweenStart: CGFloat = 0
			var previousTarget: CGFloat = 0
			
			for target in 1...10 {
				let isRunning = !Tween.tweens(withName: name).isEmpty
				let start = CGFloat(TextUpdateModifier.startValue(current: current, tweenStart: tweenStart, previousTarget: previousTarget, isRunning: isRunning))
				Tween.stopTweens(withName: name)
				current = start
				tweenStart = start
				previousTarget = CGFloat(target)
				Tween(duration: 0.05, options: .init(name: name, fps: 2), fromValues: ["value": start], toValues: ["value": CGFloat(target)]) { _, values in
					guard let value = values["value"] else { return }
					current = value
					recorder.values.append(value)
				}
				try? await Task.sleep(nanoseconds: 20_000_000)
			}
			
			await waitUntil { current == 10 }
			Tween.stopTweens(withName: name)
			
			#expect(current == 10)
			#expect(Set(recorder.values).count > 2)
		}
		
		@Test
		func startValue_ShouldSnapToThePreviousTargetOnlyWhenTheRunningTweenMadeNoProgress() {
			#expect(TextUpdateModifier.startValue(current: 5, tweenStart: 5, previousTarget: 9, isRunning: true) == 9)
			#expect(TextUpdateModifier.startValue(current: 6, tweenStart: 5, previousTarget: 9, isRunning: true) == 6)
			#expect(TextUpdateModifier.startValue(current: 5, tweenStart: 5, previousTarget: 9, isRunning: false) == 5)
		}
		
		@Test
		func tween_WhenTheMainThreadLagsAtTheEndOfACycle_ShouldFinishTheCycleOnce() async {
			let tween = Tween(duration: 0.05,
							  options: .init(repetition: .loop, repetitionCount: 20),
							  fromValues: ["value": 0],
							  toValues: ["value": 1])
			Thread.sleep(forTimeInterval: 0.3)
			await Task.yield()
			
			#expect(tween.currentCycle <= 2)
			tween.stopTween()
		}
		
		@Test
		func tween_WithDefaultFps_ShouldStillReachTheFinalValue() async {
			let view = UIView()
			let tween = Tween(view, duration: 0.1, toValues: [\.alpha : 0.25])
			await waitUntil { view.alpha == 0.25 }
			#expect(view.alpha == 0.25)
			tween.stopTween()
		}
		
		@Test
		func tweensWithName_WhenRenamedOrStopped_ShouldKeepTheIndexInSync() {
			let first = "Index-\(UUID().uuidString)"
			let second = "Index-\(UUID().uuidString)"
			let tween = Tween(duration: 1.0, options: .init(name: first), fromValues: ["value": 0], toValues: ["value": 1])
			
			#expect(Tween.tweens(withName: first).contains(tween))
			
			tween.options.name = second
			#expect(Tween.tweens(withName: first).isEmpty)
			#expect(Tween.tweens(withName: second).contains(tween))
			
			tween.stopTween()
			#expect(Tween.tweens(withName: second).isEmpty)
			
			tween.options.name = first
			#expect(Tween.tweens(withName: first).isEmpty)
		}
		
#if os(iOS) || os(tvOS)
		@Test
		func driver_OnUIKitPlatforms_ShouldBeTheDisplayLink() {
			#expect(Tween.driver === DisplayLinkDriver.shared)
		}
		
		@Test
		func displayLinkDriver_WithItems_ShouldTickAndStopWhenEmpty() async {
			let driver = DisplayLinkDriver()
			let ticks = ThreadSafe(wrappedValue: 0)
			driver.addItem(key: "tick", queue: .global()) { ticks.mutate { $0 += 1 } }
			
			await waitUntil { ticks.wrappedValue >= 3 }
			#expect(ticks.wrappedValue >= 3)
			#expect(driver.isActive)
			
			driver.removeItem(key: "tick")
			await waitUntil { !driver.isActive }
			#expect(!driver.isActive)
			#expect(driver.itemsCount == 0)
		}
		
		@Test
		func displayLinkDriver_WithGapAboveThreshold_ShouldAccumulateBackgroundTime() {
			let driver = DisplayLinkDriver()
			driver.handleTick(at: 100)
			driver.handleTick(at: 100.016)
			#expect(driver.totalBackgroundTime == 0)
			
			driver.handleTick(at: 103.016)
			#expect(abs(driver.backgroundTime - 3) < 0.0001)
			#expect(abs(driver.totalBackgroundTime - 3) < 0.0001)
			
			driver.handleTick(at: 103.032)
			#expect(driver.backgroundTime == 0)
			#expect(abs(driver.totalBackgroundTime - 3) < 0.0001)
		}
#endif
		
		@Test
		func allEasing_WhenCalculatingValue_ShouldReturnCorrectInterpolation() {
			let begin: FPoint = 0.0
			let change: FPoint = 100.0
			
			Ease.allCases.forEach {
				#expect($0.calculate(begin, change, 0, 1.0) == begin, "\($0)")
				#expect($0.calculate(begin, change, 1.0, 1.0) == change, "\($0)")
				#expect($0.calculate(begin, change, 0.4, 1.0) != begin, "\($0)")
				#expect($0.calculate(begin, change, 0.4, 1.0) != change, "\($0)")
				#expect($0.calculate(begin, change, 0.6, 1.0) != begin, "\($0)")
				#expect($0.calculate(begin, change, 0.6, 1.0) != change, "\($0)")
				#expect($0.calculate(begin, change, 0.95, 1.0) != begin, "\($0)")
				#expect($0.calculate(begin, change, 0.95, 1.0) != change, "\($0)")
			}
		}
		
		@Test
		func easeCustom_WhenCalculatingValue_ShouldReturnCustomInterpolation() {
			let begin: FPoint = 0.0
			let change: FPoint = 100.0
			let duration: FPoint = 1.0
			let customLinearEase: Easing = { $0 }
			
			let result = Ease.custom(customLinearEase).calculate(begin, change, 0.5, duration)
			
			#expect(result == 50.0)
		}
		
		@Test
		func reversed_WhenReversingEase_ShouldReturnCorrectReversedEase() {
			let testCases: [(ease: Ease, expectedReversed: Ease)] = [
				(.linear, .linear),
				(.smoothIn, .smoothOut),
				(.smoothOut, .smoothIn),
				(.smoothInOut, .smoothInOut),
				(.strongIn, .strongOut),
				(.strongOut, .strongIn),
				(.strongInOut, .strongInOut),
				(.elasticIn, .elasticOut),
				(.elasticOut, .elasticIn),
				(.elasticInOut, .elasticInOut),
				(.bounceIn, .bounceOut),
				(.bounceOut, .bounceIn),
				(.bounceInOut, .bounceInOut),
				(.backIn, .backOut),
				(.backOut, .backIn),
				(.backInOut, .backInOut)
			]
			
			testCases.forEach {
				let reversedEase = $0.ease.reversed
				#expect(reversedEase == $0.expectedReversed)
			}
		}
	}
}
#endif
