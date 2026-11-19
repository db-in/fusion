//
//  Created by Diney Bomfim.
//

#if canImport(UIKit) && canImport(SwiftUI) && !os(watchOS)
import SwiftUI

// MARK: - Type - TextAnimationStyle

/// Defines how the numeric portion of an animated text transitions between values.
public enum TextAnimationStyle {
	
	/// Counts from the old value to the new value, frame by frame, using a ``Tween``.
	case counting
	
	/// Uses the native SwiftUI `numericText` content transition.
	case native
	
	/// Rolls every digit vertically like a mechanical counter.
	///
	/// - Parameter stagger: The delay added for each digit, starting from the trailing digit.
	case odometer(stagger: Double = 0.04)
	
	/// Shuffles the digits randomly and settles them from leading to trailing on the new value.
	case scramble
	
	/// Ripples the digits of the new value in a wave. Requires iOS 18, falling back to ``native`` otherwise.
	///
	/// - Parameter amplitude: The maximum vertical offset of each glyph, in points.
	case wave(amplitude: CGFloat = 6)
}

// MARK: - Extension - Ease

public extension Ease {
	
	/// Creates the SwiftUI `Animation` that best approximates this easing curve.
	///
	/// - Parameter duration: The duration of the animation.
	/// - Returns: A SwiftUI `Animation`.
	func animation(duration: Double) -> Animation {
		switch self {
		case .linear:
			return .linear(duration: duration)
		case .smoothIn:
			return .timingCurve(0.55, 0.085, 0.68, 0.53, duration: duration)
		case .smoothOut:
			return .timingCurve(0.25, 0.46, 0.45, 0.94, duration: duration)
		case .smoothInOut:
			return .timingCurve(0.455, 0.03, 0.515, 0.955, duration: duration)
		case .strongIn:
			return .timingCurve(0.755, 0.05, 0.855, 0.06, duration: duration)
		case .strongOut:
			return .timingCurve(0.23, 1, 0.32, 1, duration: duration)
		case .strongInOut:
			return .timingCurve(0.86, 0, 0.07, 1, duration: duration)
		case .backIn:
			return .timingCurve(0.6, -0.28, 0.735, 0.045, duration: duration)
		case .backOut:
			return .timingCurve(0.175, 0.885, 0.32, 1.275, duration: duration)
		case .backInOut:
			return .timingCurve(0.68, -0.55, 0.265, 1.55, duration: duration)
		case .elasticIn, .elasticOut, .elasticInOut:
			return .spring(duration: duration, bounce: 0.6)
		case .bounceIn, .bounceOut, .bounceInOut:
			return .spring(duration: duration, bounce: 0.35)
		case .custom:
			return .easeOut(duration: duration)
		}
	}
}
#endif
