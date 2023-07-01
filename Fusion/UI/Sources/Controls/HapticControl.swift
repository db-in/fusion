//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit)
import UIKit

// MARK: - Type -

/// Global Haptic control for various types of different vibrations.
public struct HapticControl {
	
// MARK: - Exposed Methods
	
	/// Medium vibration sequence, related to notifications.  It can be customized in its type.
	/// - Parameter type: The type of the vibration. The default is `success`.
	public static func hapticNotification(_ type: UINotificationFeedbackGenerator.FeedbackType = .success) {
		let generator = UINotificationFeedbackGenerator()
		generator.notificationOccurred(type)
	}
	
	/// More prominent vibration related to impacts. It can be customized in its style.
	/// - Parameter type: The style of the vibration. The default is `light`.
	public static func hapticImpact(_ type: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
		let generator = UIImpactFeedbackGenerator(style: type)
		generator.impactOccurred()
	}
	
	/// Small Light vibration most related to change in selection.
	public static func hapticSelectionChanged() {
		let generator = UISelectionFeedbackGenerator()
		generator.selectionChanged()
	}
}
#endif
