//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation
import UserNotifications

// MARK: - Definitions -

public extension Int {
	
	var negative: Int { self * -1 }
	var seconds: DateComponents { DateComponents(second: self) }
	var minutes: DateComponents { DateComponents(minute: self) }
	var hours: DateComponents { DateComponents(hour: self) }
	var days: DateComponents { DateComponents(day: self) }
	var months: DateComponents { DateComponents(month: self) }
	var years: DateComponents { DateComponents(year: self) }
}

// MARK: - Extension - DateComponents

public extension DateComponents {
	
	prefix static func - (components: DateComponents) -> DateComponents {
		var result = DateComponents()
		result.second = components.second?.negative
		result.minute = components.minute?.negative
		result.hour = components.hour?.negative
		result.day = components.day?.negative
		result.month = components.month?.negative
		result.year = components.year?.negative
		return result
	}
	
	static func + (lhs: Date, rhs: DateComponents) -> Date { Calendar.current.date(byAdding: rhs, to: lhs) ?? Date() }
	static func - (lhs: Date, rhs: DateComponents) -> Date { lhs + (-rhs) }
	static func += (lhs: inout Date, rhs: DateComponents) { lhs = lhs + rhs }
	static func -= (lhs: inout Date, rhs: DateComponents) { lhs = lhs - rhs }
}

// MARK: - Extension - UNNotificationRequest

public extension UNNotificationRequest {
	
	public struct Keys {
		static let url: String = "url"
	}
	
	convenience init(seconds: TimeInterval, title: String, message: String, universalLink: String? = nil, repeats: Bool = false) {
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: repeats)
		let content = UNMutableNotificationContent()
		
		content.title = title
		content.body = message
		content.sound = .default
		content.badge = 1
		
		if let validLink = universalLink {
			content.userInfo = [Keys.url : validLink]
		}
		
		self.init(identifier: "\(title.hashValue)", content: content, trigger: trigger)
	}
	
	func schedule() {
		let center = UNUserNotificationCenter.current()
		center.removePendingNotificationRequests(withIdentifiers: [identifier])
		center.requestAuthorization(options: [.alert, .badge, .sound]) { success, _ in
			guard success else { return }
			center.add(self)
		}
	}
	
	func cancel() {
		let center = UNUserNotificationCenter.current()
		center.removePendingNotificationRequests(withIdentifiers: [identifier])
	}
}
