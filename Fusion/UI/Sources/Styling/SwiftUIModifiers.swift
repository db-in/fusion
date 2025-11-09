//
//  Created by Diney Bomfim on 6/30/23.
//

#if canImport(UIKit) && canImport(SwiftUI) && !os(watchOS)
import SwiftUI

// MARK: - SwiftUI Extensions

private struct PressActiveCountKey: PreferenceKey {
	static var defaultValue: Int = 0
	static func reduce(value: inout Int, nextValue: () -> Int) { value += nextValue() }
}

/// A view modifier that provides visual feedback when the user presses on a view.
/// This modifier applies scale and opacity changes to simulate a press effect,
/// commonly used for buttons and interactive elements.
public struct PressEffect: ViewModifier {
	
	private let cancelOnDragBeyond: CGFloat = 12
	@State private var isPressed: Bool = false
	@State private var isFocused: Bool = false
	@State private var didCancel: Bool = false
	@State private var descendantPressCount: Int = 0
	
	/// The scale factor to apply when pressed. Default is 0.95.
	var scale: CGFloat
	
	/// The opacity to apply when pressed. Default is 0.85.
	var opacity: Double
	
	/// The duration of the animation. Currently not used in the implementation.
	var duration: Double
	
	/// Optional callback executed when the press begins.
	var onPress: (() -> Void)?
	
	/// Optional callback executed when the press ends.
	var onRelease: (() -> Void)?
	
	public func body(content: Content) -> some View {
		content
#if os(tvOS)
			.scaleEffect(isFocused ? scale : 1.0)
			.opacity(isFocused ? opacity : 1.0)
			.focusable(true)
			.onChange(of: isFocused) { focused in
				if focused {
					onPress?()
				} else {
					onRelease?()
				}
			}
			.onAppear {
				withAnimation(.easeOut(duration: duration)) {
					isFocused = false
				}
			}
#else
			.scaleEffect(isPressed ? scale : 1.0)
			.opacity(isPressed ? opacity : 1.0)
			.onLongPressGesture(minimumDuration: 0, maximumDistance: cancelOnDragBeyond, pressing: { pressing in
				if pressing {
					if !isPressed && descendantPressCount == 0 {
						withAnimation(.easeOut(duration: duration)) { isPressed = true }
						onPress?()
					}
				} else {
					withAnimation(.easeOut(duration: duration)) { isPressed = false }
				}
			}, perform: {})
			.simultaneousGesture(
				TapGesture().onEnded {
					if descendantPressCount == 0 { onRelease?() }
				}
			)
			.background(Color.clear.preference(key: PressActiveCountKey.self, value: isPressed ? 1 : 0))
			.onPreferenceChange(PressActiveCountKey.self) { total in
				let selfContribution = isPressed ? 1 : 0
				let childCount = max(0, total - selfContribution)
				descendantPressCount = childCount
				if childCount > 0 && isPressed {
					withAnimation(.easeOut(duration: 0.001)) {
						isPressed = false
					}
					didCancel = true
				}
			}
#endif
	}
}

// MARK: - Swipe to Dismiss

/// A view modifier that enables swipe-to-dismiss functionality for views.
/// Users can swipe in the specified direction to trigger a dismiss action.
/// The view will follow the drag gesture and dismiss when swiped beyond a threshold.
public struct SwipeToDismiss: ViewModifier {
	
	@State var dragAmount: CGSize = .zero
	
	/// The direction in which the swipe gesture should be detected.
	public var direction: UIRectEdge
	
	/// The threshold distance that must be exceeded to trigger dismissal.
	public var threshold: CGFloat
	
	/// Optional callback executed when the view should be dismissed.
	public var onDismiss: Callback?
	
	public func body(content: Content) -> some View {
		content
			.offset(dragAmount)
#if !os(tvOS)
			.gesture(
				DragGesture()
					.onChanged { drag in
						withAnimation {
							let translation = drag.translation
							switch direction {
							case .top:
								dragAmount = CGSize(width: 0, height: min(0, translation.height))
							case .bottom:
								dragAmount = CGSize(width: 0, height: max(0, translation.height))
							case .left:
								dragAmount = CGSize(width: min(0, translation.width), height: 0)
							case .right:
								dragAmount = CGSize(width: max(0, translation.width), height: 0)
							default:
								dragAmount = CGSize(width: 0, height: max(0, translation.height))
							}
						}
					}
					.onEnded { drag in
						withAnimation {
							let translation = drag.translation
							let velocity = drag.velocity
							var shouldDismiss = false
							
							switch direction {
							case .top:
								shouldDismiss = translation.height < -threshold || velocity.height < -1000
							case .bottom:
								shouldDismiss = translation.height > threshold || velocity.height > 1000
							case .left:
								shouldDismiss = translation.width < -threshold || velocity.width < -1000
							case .right:
								shouldDismiss = translation.width > threshold || velocity.width > 1000
							default:
								shouldDismiss = translation.height > threshold || velocity.height > 1000
							}
							
							if shouldDismiss {
								onDismiss?()
							} else {
								dragAmount = .zero
							}
						}
					}
			)
#endif
	}
}

/// A view modifier that enables tap-to-dismiss functionality for the first responder.
/// When the user taps anywhere on the view, it will automatically resign the current first responder,
/// which is commonly used to dismiss the keyboard when tapping outside of text fields.
struct TapToResignResponderModifier: ViewModifier {
	
	func body(content: Content) -> some View {
		content
#if !os(tvOS)
			.contentShape(Rectangle())
			.onTapGesture {
				UIApplication.main?.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
			}
#endif
	}
}

/// A view modifier that provides smooth animated transitions for text content.
/// This modifier automatically detects numeric values within text and animates them
/// when the source text changes, creating smooth counting or value transition effects.
/// It preserves text formatting and attributes while animating only the numeric portions.
public struct TextUpdateModifier: ViewModifier, TweenDelegate {
	
// MARK: - Properties
	
	@State private var displayText: NSAttributedString = .init(string: "")
	@State private var template: NSMutableAttributedString = .init()
	@State private var numberRange: NSRange = .init(location: NSNotFound, length: 0)
	@State private var numberAttributes: [NSAttributedString.Key: Any] = [:]
	@State private var decimals: Int = 0
	@State private var currentValue: Double = 0
	
	/// The source text content that will be displayed and animated.
	public let sourceText: TextConvertible
	
	/// The duration of the animation when transitioning between values.
	public let duration: Double
	
	/// The easing curve used for the animation.
	public let ease: Ease
	
	/// The frames per second rate for the animation.
	public let fps: FPoint
	
// MARK: - Protected Methods
	
	private func attributedFrom(_ source: TextConvertible) -> NSAttributedString {
		if let attributed = source as? NSAttributedString { return attributed }
		return NSAttributedString(string: source.content)
	}
	
	private func prepare(from attributed: NSAttributedString) {
		template = .init(attributedString: attributed)
		updateNumberRangeIfNeeded(in: template)
		currentValue = currentNumberValue(in: template)
		displayText = attributed
	}
	
	private func animate(to attributed: NSAttributedString) {
		updateTemplate(with: attributed)
		let newTarget = currentNumberValue(in: template)
		guard newTarget != currentValue else { return }
		Tween(duration: duration,
			  options: .init(ease: ease, delegate: self, fps: fps),
			  fromValues: ["value": CGFloat(currentValue)],
			  toValues: ["value": CGFloat(newTarget)])
	}
	
	private func updateTemplate(with attributed: NSAttributedString) {
		template = .init(attributedString: attributed)
		updateNumberRangeIfNeeded(in: template)
	}
	
	private func updateNumberRangeIfNeeded(in attributed: NSAttributedString) {
		let string = attributed.string
		if let range = firstNumberRange(in: string) {
			numberRange = range
			numberAttributes = attributed.attributes(at: range.location, effectiveRange: nil)
			decimals = fractionDigits(in: (string as NSString).substring(with: range))
		} else {
			numberRange = .init(location: NSNotFound, length: 0)
			numberAttributes = [:]
			decimals = 0
		}
	}
	
	private func updateDisplay(value: Double) {
		guard numberRange.location != NSNotFound else { displayText = template; return }
		let formatted = value.toString(decimals: decimals, locale: .preferredLocale)
		let replacement = NSAttributedString(string: formatted, attributes: numberAttributes)
		let mutable = NSMutableAttributedString(attributedString: template)
		mutable.replaceCharacters(in: numberRange, with: replacement)
		displayText = mutable
		currentValue = value
	}
	
	private func currentNumberValue(in attributed: NSAttributedString) -> Double {
		guard numberRange.location != NSNotFound else { return 0 }
		let substring = (attributed.string as NSString).substring(with: numberRange)
		return parseNumber(from: substring)
	}
	
	private func parseNumber(from string: String) -> Double {
		let locale = Locale.preferredLocale
		let parts = string.decimalComponents(locale: locale)
		if parts.fraction.isEmpty { return Double(parts.integer) ?? 0 }
		return Double("\(parts.integer).\(parts.fraction)") ?? 0
	}
	
	private func fractionDigits(in string: String) -> Int {
		let locale = Locale.preferredLocale
		let decimal = locale.decimalSeparator ?? "."
		if let range = string.range(of: decimal) { return string[range.upperBound...].count }
		return 0
	}
	
	private func firstNumberRange(in string: String) -> NSRange? {
		let pattern = "[0-9][0-9.,]*"
		guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
		let range = NSRange(location: 0, length: (string as NSString).length)
		return regex.firstMatch(in: string, options: [], range: range)?.range
	}
	
// MARK: - Exposed Methods
	
	public func body(content: Content) -> some View {
		displayText.text
			.task(id: sourceText.content) {
				let attributed = attributedFrom(sourceText)
				if displayText.string.isEmpty {
					prepare(from: attributed)
				} else {
					animate(to: attributed)
				}
			}
	}
	
	public func tween(_ tween: Tween, values: [String : CGFloat]) {
		guard let value = values["value"] else { return }
		DispatchQueue.asyncMainIfNeeded {
			updateDisplay(value: Double(value))
		}
	}
}

public extension View {
	
	/// Applies a press effect to the view with customizable scale, opacity, and callbacks.
	///
	/// - Parameters:
	///   - scale: The scale factor to apply when pressed. Default is 0.95.
	///   - opacity: The opacity to apply when pressed. Default is 0.85.
	///   - duration: The duration of the animation. Default is 0.1.
	///   - onPress: Optional callback executed when the press begins.
	///   - onRelease: Optional callback executed when the press ends.
	/// - Returns: A modified view with press effect applied.
	func pressEffect(scale: CGFloat = 0.95, opacity: Double = 0.85, duration: Double = 0.1, onPress: Callback? = nil, onRelease: Callback? = nil) -> some View {
		modifier(PressEffect(scale: scale, opacity: opacity, duration: duration, onPress: onPress, onRelease: onRelease))
	}
	
	/// Enables swipe-to-dismiss functionality for the view.
	///
	/// - Parameters:
	///   - direction: The direction in which the swipe gesture should be detected. Default is `.bottom`.
	///   - threshold: The threshold distance that must be exceeded to trigger dismissal. Default is 100.
	///   - onDismiss: Optional callback executed when the view should be dismissed.
	/// - Returns: A modified view with swipe-to-dismiss functionality.
	func swipeToDismiss(direction: UIRectEdge = .bottom, threshold: CGFloat = 100, onDismiss: Callback? = nil) -> some View {
		modifier(SwipeToDismiss(direction: direction, threshold: threshold, onDismiss: onDismiss))
	}
	
	/// Enables tap-to-dismiss functionality for the first responder.
	///
	/// When the user taps anywhere on the view, it will automatically resign the current
	/// first responder, which is commonly used to dismiss the keyboard when tapping
	/// outside of text fields or other input elements.
	///
	/// - Returns: A modified view with tap-to-dismiss functionality.
	func tapToResignResponder() -> some View {
		modifier(TapToResignResponderModifier())
	}
	
	/// Applies smooth animated transitions to text content.
	///
	/// This modifier automatically detects numeric values within the text and animates them
	/// when the source text changes. It preserves text formatting and attributes while
	/// creating smooth counting or value transition effects.
	///
	/// - Parameters:
	///   - text: The text content to display and animate.
	///   - duration: The duration of the animation when transitioning between values. Default is `Constant.duration`.
	///   - animationCurve: The easing curve used for the animation. Default is `.smoothOut`.
	///   - fps: The frames per second rate for the animation. Default is `60.0`.
	/// - Returns: A modified view with animated text transitions.
	func textTransition(_ text: TextConvertible, duration: Double = Constant.duration, animationCurve: Ease = .smoothOut, fps: FPoint = 60.0) -> some View {
		modifier(TextUpdateModifier(sourceText: text, duration: duration, ease: animationCurve, fps: fps))
	}
}

public extension TextConvertible {
	
	/// Creates an animated text view with smooth transitions.
	///
	/// This convenience method applies animated text transitions to the current text content.
	/// It automatically detects numeric values within the text and animates them when
	/// the content changes, creating smooth counting or value transition effects.
	///
	/// - Parameters:
	///   - duration: The duration of the animation when transitioning between values. Default is `Constant.duration`.
	///   - animationCurve: The easing curve used for the animation. Default is `.smoothOut`.
	///   - fps: The frames per second rate for the animation. Default is `60.0`.
	/// - Returns: A view with animated text transitions applied.
	func textAnimated(duration: Double = Constant.duration, animationCurve: Ease = .smoothOut, fps: FPoint = 60.0) -> some View {
		text.textTransition(self, duration: duration, animationCurve: animationCurve, fps: fps)
	}
}
#endif
