//
//  Created by Diney Bomfim on 6/30/23.
//

#if canImport(UIKit) && canImport(SwiftUI) && !os(watchOS)
import SwiftUI

// MARK: - SwiftUI Extensions

/// A shape that applies rounded corners to specific corners of a rectangle.
/// This shape allows you to round only selected corners rather than all corners uniformly,
/// providing more flexible corner radius customization for views.
public struct RoundedCorner: Shape {
	
	/// The radius of the rounded corners.
	public let radius: CGFloat
	
	/// The corners that should be rounded.
	public let corners: UIRectCorner
	
	/// Creates a rounded corner shape with the specified radius and corners.
	///
	/// - Parameters:
	///   - radius: The radius of the rounded corners. Default is `.infinity` (fully rounded).
	///   - corners: The corners that should be rounded. Default is `.allCorners`.
	public init(radius: CGFloat = .infinity, corners: UIRectCorner = .allCorners) {
		self.radius = radius
		self.corners = corners
	}
	
	public func path(in rect: CGRect) -> Path {
		let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
		return Path(path.cgPath)
	}
}

private struct PressEffectStyle: ButtonStyle {
	
	var scale: CGFloat
	var opacity: Double
	var duration: Double
	var onPress: (() -> Void)?
	
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
			.scaleEffect(configuration.isPressed ? scale : 1.0)
			.opacity(configuration.isPressed ? opacity : 1.0)
			.animation(.easeOut(duration: duration), value: configuration.isPressed)
			.onChange(of: configuration.isPressed) { _, pressed in
				if pressed { onPress?() }
			}
	}
}

/// A view modifier that provides visual feedback when the user presses on a view.
/// This modifier applies scale and opacity changes to simulate a press effect,
/// commonly used for buttons and interactive elements.
///
/// Nested ``pressEffect`` controls use SwiftUI `Button` exclusivity so an inner
/// control (for example an eye toggle) does not also trigger a parent card action.
public struct PressEffect: ViewModifier {
	
	@State private var isFocused: Bool = false
	
	/// The scale factor to apply when pressed. Default is 0.95.
	var isEnabled: Bool
	
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
	
	@ViewBuilder
	public func body(content: Content) -> some View {
		if !isEnabled {
			content
				.allowsHitTesting(false)
		} else {
#if os(tvOS)
			content
				.contentShape(Rectangle())
				.scaleEffect(isFocused ? scale : 1.0)
				.opacity(isFocused ? opacity : 1.0)
				.focusable(true)
				.onChange(of: isFocused) { _, focused in
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
			Button(action: { onRelease?() }) {
				content
					.contentShape(Rectangle())
			}
			.buttonStyle(PressEffectStyle(scale: scale, opacity: opacity, duration: duration, onPress: onPress))
#endif
		}
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

public extension View {
	
	/// Applies a press effect to the view with customizable scale, opacity, and callbacks.
	///
	/// - Parameters:
	///   - isEnabled: Whether the press effect is enabled. Default is true.
	///   - scale: The scale factor to apply when pressed. Default is 0.95.
	///   - opacity: The opacity to apply when pressed. Default is 0.85.
	///   - duration: The duration of the animation. Default is 0.1.
	///   - onPress: Optional callback executed when the press begins.
	///   - onRelease: Optional callback executed when the press ends.
	/// - Returns: A modified view with press effect applied.
	func pressEffect(isEnabled: Bool = true,
					 scale: CGFloat = 0.95,
					 opacity: Double = 0.85,
					 duration: Double = 0.1,
					 onPress: Callback? = nil,
					 onRelease: Callback? = nil) -> some View {
		modifier(PressEffect(isEnabled: isEnabled, scale: scale, opacity: opacity, duration: duration, onPress: onPress, onRelease: onRelease))
	}
	
	/// Applies a press effect to the view with customizable scale, opacity, and callbacks.
	///
	/// - Parameters:
	///   - isEnabled: Whether the press effect is enabled. Default is true.
	///   - scale: The scale factor to apply when pressed. Default is 0.95.
	///   - opacity: The opacity to apply when pressed. Default is 0.85.
	///   - duration: The duration of the animation. Default is 0.1.
	///   - onRelease: Optional callback executed when the press ends.
	/// - Returns: A modified view with press effect applied.
	func pressEffect(isEnabled: Bool = true,
					 scale: CGFloat = 0.95,
					 opacity: Double = 0.85,
					 duration: Double = 0.1,
					 onRelease: Callback?) -> some View {
		modifier(PressEffect(isEnabled: isEnabled, scale: scale, opacity: opacity, duration: duration, onPress: nil, onRelease: onRelease))
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
	/// animating the value with the given ``TextAnimationStyle``.
	///
	/// - Parameters:
	///   - text: The text content to display and animate.
	///   - style: The animation style applied to the numeric portion. Default is `.counting`.
	///   - duration: The duration of the animation when transitioning between values. Default is `Constant.duration`.
	///   - animationCurve: The easing curve used for the animation. Default is `.smoothOut`.
	///   - fps: The frames per second rate for the frame based styles. Default is `60.0`.
	/// - Returns: A modified view with animated text transitions.
	func textTransition(_ text: TextConvertible,
						style: TextAnimationStyle = .counting,
						duration: Double = Constant.duration,
						animationCurve: Ease = .smoothOut,
						fps: FPoint = 60.0) -> some View {
		modifier(TextUpdateModifier(sourceText: text, style: style, duration: duration, ease: animationCurve, fps: fps))
	}
	
	/// Applies rounded corners to specific corners of the view.
	///
	/// This modifier allows you to round only selected corners of a view rather than all corners,
	/// providing more flexible corner radius customization. The shape is clipped to the rounded
	/// rectangle, ensuring content respects the corner radius boundaries.
	///
	/// - Parameters:
	///   - radius: The radius of the rounded corners. Use `.infinity` for fully rounded corners.
	///   - corners: The corners that should be rounded. Default is `.allCorners`.
	/// - Returns: A modified view with rounded corners applied to the specified corners.
	func roundedCorner(radius: CGFloat, corners: UIRectCorner = .allCorners) -> some View {
		clipShape(RoundedCorner(radius: radius, corners: corners))
	}
}

public extension TextConvertible {
	
	/// Creates an animated text view with smooth transitions.
	///
	/// This convenience method applies animated text transitions to the current text content.
	/// It automatically detects numeric values within the text and animates them when
	/// the content changes, using the given ``TextAnimationStyle``.
	///
	/// - Parameters:
	///   - style: The animation style applied to the numeric portion. Default is `.counting`.
	///   - duration: The duration of the animation when transitioning between values. Default is `Constant.duration`.
	///   - animationCurve: The easing curve used for the animation. Default is `.smoothOut`.
	///   - fps: The frames per second rate for the frame based styles. Default is `60.0`.
	/// - Returns: A view with animated text transitions applied.
	func textAnimated(style: TextAnimationStyle = .counting,
					  duration: Double = Constant.duration,
					  animationCurve: Ease = .smoothOut,
					  fps: FPoint = 60.0) -> some View {
		Text(verbatim: "").textTransition(self, style: style, duration: duration, animationCurve: animationCurve, fps: fps)
	}
}
#endif
