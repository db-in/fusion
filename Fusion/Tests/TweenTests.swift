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
