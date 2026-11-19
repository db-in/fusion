//
//  Created by Diney Bomfim on 6/30/23.
//

#if canImport(UIKit) && canImport(SwiftUI) && !os(watchOS)
import SwiftUI

/// A view modifier that provides smooth animated transitions for text content.
/// This modifier automatically detects numeric values within text and animates them
/// when the source text changes, using the given ``TextAnimationStyle``.
/// It preserves text formatting and attributes while animating only the numeric portions.
///
/// The source is parsed and converted once per change. Frame based styles only rebuild
/// the numeric run on each tick, keeping the main thread cost to a few microseconds per frame.
public struct TextUpdateModifier: ViewModifier, TweenDelegate {
	
// MARK: - Properties
	
	@State private var segments: TextAnimationSegments = .init()
	@State private var display: AttributedString = .init()
	@State private var identifier: String = ""
	@State private var isPrepared: Bool = false
	@State private var currentValue: Double = 0
	@State private var tweenStartValue: Double = 0
	@State private var targetValue: Double = 0
	@State private var waveCycle: Double = 0
	@State private var tweenName: String = UUID().uuidString
	
	/// The source text content that will be displayed and animated.
	public let sourceText: TextConvertible
	
	/// The style used to animate the numeric portion of the text.
	public let style: TextAnimationStyle
	
	/// The duration of the animation when transitioning between values.
	public let duration: Double
	
	/// The easing curve used for the animation.
	public let ease: Ease
	
	/// The frames per second rate for the frame based styles.
	public let fps: FPoint
	
	@ViewBuilder
	private var styledText: some View {
		switch style {
		case .counting, .scramble:
			Text(display)
		case .native:
			nativeText
		case .odometer(let stagger):
			OdometerText(segments: segments, animation: ease.animation(duration: duration), stagger: stagger)
		case .wave(let amplitude):
			if #available(iOS 18.0, tvOS 18.0, visionOS 2.0, *) {
				WaveText(segments: segments, amplitude: amplitude, cycle: waveCycle)
			} else {
				nativeText
			}
		}
	}
	
	private var nativeText: some View {
		Text(segments.full)
			.contentTransition(.numericText(value: targetValue))
	}
	
// MARK: - Protected Methods
	
	private func attributedFrom(_ source: TextConvertible) -> NSAttributedString {
		if let attributed = source as? NSAttributedString { return attributed }
		return NSAttributedString(string: source.content)
	}
	
	private func prepare(from attributed: NSAttributedString) {
		segments = .init(attributed)
		currentValue = segments.value
		tweenStartValue = currentValue
		targetValue = currentValue
		display = segments.full
	}
	
	static func startValue(current: Double, tweenStart: Double, previousTarget: Double, isRunning: Bool) -> Double {
		guard isRunning, current == tweenStart else { return current }
		return previousTarget
	}
	
	static func scrambled<G: RandomNumberGenerator>(_ target: String, progress: Double, using generator: inout G) -> String {
		let total = target.reduce(0) { $1.isWholeNumber ? $0 + 1 : $0 }
		guard total > 0 else { return target }
		var result = ""
		result.reserveCapacity(target.utf8.count)
		var index = 0
		for character in target {
			guard character.isWholeNumber else {
				result.append(character)
				continue
			}
			index += 1
			if progress >= Double(index) / Double(total) {
				result.append(character)
			} else {
				result.unicodeScalars.append(Unicode.Scalar(UInt8.random(in: 48...57, using: &generator)))
			}
		}
		return result
	}
	
	private func animate(to attributed: NSAttributedString) {
		switch style {
		case .counting:
			animateCounting(to: attributed)
		case .scramble:
			animateScramble(to: attributed)
		case .native, .odometer:
			withAnimation(ease.animation(duration: duration)) {
				prepare(from: attributed)
			}
		case .wave:
			let previous = targetValue
			prepare(from: attributed)
			guard targetValue != previous else { return }
			withAnimation(ease.animation(duration: duration)) {
				waveCycle += 1
			}
		}
	}
	
	private func animateCounting(to attributed: NSAttributedString) {
		segments = .init(attributed)
		let newTarget = segments.value
		guard newTarget != currentValue else {
			if !Tween.tweens(withName: tweenName).isEmpty { return }
			display = segments.full
			return
		}
		let isRunning = !Tween.tweens(withName: tweenName).isEmpty
		let start = Self.startValue(current: currentValue, tweenStart: tweenStartValue, previousTarget: targetValue, isRunning: isRunning)
		Tween.stopTweens(withName: tweenName)
		if start != currentValue { updateDisplay(value: start) }
		tweenStartValue = start
		targetValue = newTarget
		Tween(duration: duration,
			  options: .init(name: tweenName, ease: ease, delegate: self, fps: fps),
			  fromValues: ["value": CGFloat(start)],
			  toValues: ["value": CGFloat(newTarget)])
	}
	
	private func animateScramble(to attributed: NSAttributedString) {
		Tween.stopTweens(withName: tweenName)
		let previous = targetValue
		prepare(from: attributed)
		guard targetValue != previous, segments.hasNumber else { return }
		updateScramble(progress: 0)
		Tween(duration: duration,
			  options: .init(name: tweenName, ease: ease, delegate: self, fps: fps),
			  fromValues: ["progress": 0],
			  toValues: ["progress": 1])
	}
	
	private func updateDisplay(value: Double) {
		display = segments.composed(value: value)
		currentValue = value
	}
	
	private func updateScramble(progress: Double) {
		var generator = SystemRandomNumberGenerator()
		display = segments.composed(number: Self.scrambled(segments.number, progress: progress, using: &generator))
	}
	
// MARK: - Exposed Methods
	
	public func body(content: Content) -> some View {
		styledText
			.accessibilityIdentifier(identifier)
			.task(id: sourceText.content) {
				let attributed = attributedFrom(sourceText)
				if isPrepared {
					animate(to: attributed)
				} else {
					identifier = sourceText.content.originalKey ?? ""
					isPrepared = true
					prepare(from: attributed)
				}
			}
	}
	
	public func tween(_ tween: Tween, values: [String : CGFloat]) {
		DispatchQueue.asyncMainIfNeeded {
			if let value = values["value"] {
				updateDisplay(value: Double(value))
			} else if let progress = values["progress"] {
				updateScramble(progress: Double(progress))
			}
		}
	}
}
#endif
