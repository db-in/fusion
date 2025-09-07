//
//  Created by Diney Bomfim on 6/30/23.
//

#if canImport(UIKit) && canImport(SwiftUI) && !os(watchOS)
import SwiftUI

// MARK: - SwiftUI Extensions

/// A view modifier that provides visual feedback when the user presses on a view.
/// This modifier applies scale and opacity changes to simulate a press effect,
/// commonly used for buttons and interactive elements.
public struct PressEffect: ViewModifier {
	
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
	
	@State private var isPressed: Bool = false
	
	public func body(content: Content) -> some View {
		content
			.scaleEffect(isPressed ? scale : 1.0)
			.opacity(isPressed ? opacity : 1.0)
			.simultaneousGesture(
				DragGesture(minimumDistance: 0)
					.onChanged({ _ in
						if !isPressed {
							withAnimation(.easeOut) {
								isPressed = true
							}
							onPress?()
						}
					})
					.onEnded({ _ in
						withAnimation(.easeOut) {
							isPressed = false
						}
						onRelease?()
					})
			)
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
}
#endif
