//
//  Created by Diney Bomfim on 5/26/23.
//

import XCTest
@testable import Fusion

// MARK: - Definitions -

private typealias Key = ReferenceWritableKeyPath<UIView, CGFloat>
private typealias Value = CGFloat

// MARK: - Type -

class TweenTests: XCTestCase {
	
	func testMergeWithTargetView_WhenMergingWithTargetView_ShouldMergeValues() {
		let targetView = UIView()
		let dictionary: [Key : Value] = [\UIView.center.x: 100.0, \UIView.alpha: 0.5]
		let other: [Key : Value] = [\UIView.center.y: 200.0, \UIView.alpha: 1.0]
		let result = dictionary.merge(with: other, target: targetView)
		
		XCTAssertEqual(result[\UIView.center.x], [100, 0])
		XCTAssertEqual(result[\UIView.center.y], [0, 200])
		XCTAssertEqual(result[\UIView.alpha], [0.5, 1.0])
	}
	
	func testMergeWithoutTargetView_WhenMergingWithoutTargetView_ShouldReturnEmptyResult() {
		let dictionary: [Key : Value] = [\UIView.center.x: 100.0, \UIView.alpha: 0.5]
		let other: [Key : Value] = [\UIView.center.y: 200.0, \UIView.alpha: 1.0]
		let result = dictionary.merge(with: other, target: nil)
		XCTAssertTrue(result.isEmpty)
	}
	
	func testRestartTween_WhenRestartingTween_ShouldResetValuesAndRemainPaused() {
		let targetView = UIView()
		let tween = Tween(target: targetView, duration: 1.0)
		
		tween.isPaused = true
		tween.restartTween()

		XCTAssertTrue(tween.isPaused)
		XCTAssertEqual(tween.currentCycle, 0)
		XCTAssertEqual(tween.beginTime, 0.0)
		XCTAssertEqual(tween.currentTime, 0.0)
		XCTAssertNotEqual(tween.idleTime, 0.0)
		
		tween.stopTween()
	}

	func testStopTweenWithEndOption_WhenStoppingTweenWithEndOption_ShouldResetValuesAndEndAtZeroSize() {
		let targetView = UIView()
		let tween = Tween(target: targetView, duration: 1.0)
		
		tween.isPaused = true
		tween.stopTween(option: .end)

		XCTAssertTrue(tween.isPaused)
		XCTAssertEqual(tween.currentCycle, 0)
		XCTAssertEqual(tween.beginTime, 0.0)
		XCTAssertEqual(tween.currentTime, 0.0)
		XCTAssertNotEqual(tween.idleTime, 0.0)
		XCTAssertEqual(targetView.frame, CGRect.zero)
	}
	
	func testTweenRestart_WhenRestartingTween_ShouldPerformExpectedBehavior() {
		let expectation = expectation(description: #function)
		let view = UIView()
		let tween = Tween(target: view, duration: 1.0)

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			XCTAssertFalse(tween.isPaused)
			XCTAssertEqual(tween.currentCycle, 0)
			XCTAssertNotEqual(tween.beginTime, 0.0)
			XCTAssertNotEqual(tween.currentTime, 0.0)
			XCTAssertNotEqual(tween.idleTime, 0.0)
			tween.isPaused = true
			tween.restartTween()
			XCTAssertTrue(tween.isPaused)
			XCTAssertEqual(tween.currentCycle, 0)
			XCTAssertEqual(tween.beginTime, 0.0)
			XCTAssertEqual(tween.currentTime, 0.0)
			XCTAssertNotEqual(tween.idleTime, 0.0)
			tween.stopTween()
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 1.0)
	}
	
	func testTweenAnimation_WithMirror_ShouldPerformExpectedBehavior() {
		let expectation = expectation(description: #function)
		let view = UIView()
		let endValue: CGFloat = 100
		let tween = Tween(target: view,
						  duration: 0.5,
						  options: .init(ease: .strongIn, isReversed: true, repetition: .mirrorValuesAndEase, repetitionCount: 2),
						  toValues: [\.center.x : endValue])
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
			XCTAssertFalse(tween.isPaused)
			XCTAssertTrue(tween.isMirrored)
			XCTAssertNotEqual(tween.beginTime, 0.0)
			XCTAssertNotEqual(tween.currentTime, 0.0)
			XCTAssertNotEqual(tween.idleTime, 0.0)
			XCTAssertNotEqual(tween.currentCycle, 0)
			tween.stopTween()
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 5.0)
	}
	
	func testTweenAnimation_WithDelayAndFullExecution_ShouldPerformAndStop() {
		let expectation = expectation(description: #function)
		let view = UIView()
		let endValue: CGFloat = 100
		let time: FPoint = 0.2
		let tween = Tween(target: view,
						  duration: time,
						  options: .init(delay: time, repetition: .mirrorValues, repetitionCount: 1),
						  toValues: [\.center.x : endValue])
		
		DispatchQueue.main.asyncAfter(deadline: .now() + (time * 0.5)) {
			XCTAssertFalse(tween.isReady)
			XCTAssertFalse(tween.isMirrored)
			XCTAssertEqual(tween.deltaTime, 0.0)
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + (time * 3)) {
			XCTAssertTrue(tween.isReady)
			XCTAssertTrue(tween.isMirrored)
			XCTAssertNotEqual(tween.deltaTime, 0.0)
			XCTAssertNotEqual(tween.currentCycle, 0)
			tween.stopTween()
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 5.0)
	}
	
	func testTweenAnimation_WithMirrorAndRestart_ShouldReturnToOriginalState() {
		let expectation = expectation(description: #function)
		let view = UIView()
		let endValue: CGFloat = 100
		let tween = Tween(target: view,
						  duration: 0.2,
						  options: .init(isReversed: true, repetition: .mirrorValues),
						  toValues: [\.center.x : endValue])
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			XCTAssertFalse(tween.isPaused)
			XCTAssertTrue(tween.isMirrored)
			XCTAssertNotEqual(view.center.x, 0.0)
			tween.restartTween()
			XCTAssertEqual(view.center.x, 100.0)
			tween.stopTween()
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 1.0)
	}

	func testTweenStopWithEndState_WhenStoppingTweenWithEndState_ShouldSetTargetToExpectedState() {
		let view = UIView()
		let endValue: CGFloat = 100
		let tween = Tween(target: view, duration: 1.0, toValues: [\.center.x : endValue])

		tween.stopTween(option: .end)
		
		XCTAssertEqual(view.center.x, endValue)
	}

	func testTweensWithTarget_WhenGettingTweensWithTarget_ShouldReturnExpectedTweens() {
		let view1 = UIView()
		let view2 = UIView()
		let view3 = UIView()

		let tween1 = Tween(target: view1, duration: 1.0)
		let tween2 = Tween(target: view2, duration: 2.0)
		let tween3 = Tween(target: view3, duration: 3.0)
		let tweens = Tween.tweens(withTarget: view2)

		XCTAssertEqual(tweens.count, 1)
		XCTAssertTrue(tweens.contains(tween2))
		XCTAssertFalse(tweens.contains(tween1))
		XCTAssertFalse(tweens.contains(tween3))
		
		[tween1, tween2, tween1].forEach { $0.stopTween() }
	}

	func testTweensWithName_WhenGettingTweensWithName_ShouldReturnExpectedTweens() {
		let view1 = UIView()
		let view2 = UIView()
		let view3 = UIView()

		let tween1 = Tween(target: view1, duration: 1.0, options: .init(name: "Tween1"))
		let tween2 = Tween(target: view2, duration: 2.0, options: .init(name: "Tween2"))
		let tween3 = Tween(target: view3, duration: 3.0, options: .init(name: "Tween2"))

		let tweens = Tween.tweens(withName: "Tween2")

		XCTAssertEqual(tweens.count, 2)
		XCTAssertTrue(tweens.contains(tween2))
		XCTAssertTrue(tweens.contains(tween3))
		XCTAssertFalse(tweens.contains(tween1))
		
		[tween1, tween2, tween1].forEach { $0.stopTween() }
	}

	func testStopTweensWithTarget_WhenStoppingTweensWithTarget_ShouldSetTweensToExpectedState() {
		let view1 = UIView()
		let view2 = UIView()
		let view3 = UIView()

		Tween(target: view1, duration: 1.0)
		Tween(target: view2, duration: 2.0)
		Tween(target: view3, duration: 3.0)
		Tween.stopTweens(withTarget: view2)
		
		let tween1 = Tween.tweens(withTarget: view1)
		let tween2 = Tween.tweens(withTarget: view2)
		let tween3 = Tween.tweens(withTarget: view3)
		
		XCTAssertEqual(tween1.count, 1)
		XCTAssertEqual(tween2.count, 0)
		XCTAssertEqual(tween3.count, 1)
		
		(tween1 + tween2 + tween1).forEach { $0.stopTween() }
	}

	func testStopTweensWithName_WhenStoppingTweensWithName_ShouldSetTweensToExpectedState() {
		let view1 = UIView()
		let view2 = UIView()
		let view3 = UIView()

		Tween(target: view1, duration: 1.0, options: .init(name: "Stop1"))
		Tween(target: view2, duration: 2.0, options: .init(name: "Stop2"))
		Tween(target: view3, duration: 3.0, options: .init(name: "Stop2"))
		Tween.stopTweens(withName: "Stop2")
		
		let tweens1 = Tween.tweens(withName: "Stop1")
		let tweens2 = Tween.tweens(withName: "Stop2")

		XCTAssertEqual(tweens1.count, 1)
		XCTAssertEqual(tweens2.count, 0)
		
		Tween.stopTweens(withName: "Stop1")
		Tween.stopTweens(withName: "Stop2")
	}
	
	func testAllEasing_WhenCalculatingValue_ShouldReturnCorrectInterpolation() {
		let begin: FPoint = 0.0
		let change: FPoint = 100.0
		
		Ease.allCases.forEach {
			XCTAssertEqual($0.calculate(begin, change, 0, 1.0), begin, "\($0)")
			XCTAssertEqual($0.calculate(begin, change, 1.0, 1.0), change, "\($0)")
			XCTAssertNotEqual($0.calculate(begin, change, 0.4, 1.0), begin, "\($0)")
			XCTAssertNotEqual($0.calculate(begin, change, 0.4, 1.0), change, "\($0)")
			XCTAssertNotEqual($0.calculate(begin, change, 0.6, 1.0), begin, "\($0)")
			XCTAssertNotEqual($0.calculate(begin, change, 0.6, 1.0), change, "\($0)")
			XCTAssertNotEqual($0.calculate(begin, change, 0.95, 1.0), begin, "\($0)")
			XCTAssertNotEqual($0.calculate(begin, change, 0.95, 1.0), change, "\($0)")
		}
	}
	
	func testEaseCustom_WhenCalculatingValue_ShouldReturnCustomInterpolation() {
		let begin: FPoint = 0.0
		let change: FPoint = 100.0
		let duration: FPoint = 1.0
		let customLinearEase: Easing = { $0 }
		
		let result = Ease.custom(customLinearEase).calculate(begin, change, 0.5, duration)
		
		XCTAssertEqual(result, 50.0)
	}
	
	func testReversed_WhenReversingEase_ShouldReturnCorrectReversedEase() {
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
			XCTAssertEqual(reversedEase, $0.expectedReversed)
		}
	}
}
