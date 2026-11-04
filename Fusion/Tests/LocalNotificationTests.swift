//
//  Created by Diney Bomfim on 09/06/2023.
//

import Foundation
import Testing
import UserNotifications
@testable import Fusion

// MARK: - Definitions -

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct LocalNotificationTests {
		
// MARK: - Exposed Methods
		
		@Test
		func date_WithComponentsNegation_ShouldCorrectlyInvert() {
			let components = DateComponents(day: 5, hour: 3, minute: 30, second: 45)
			let negatedComponents = -components
			
			#expect(negatedComponents.day == -5)
			#expect(negatedComponents.hour == -3)
			#expect(negatedComponents.minute == -30)
			#expect(negatedComponents.second == -45)
		}
		
		@Test
		func date_WithComponentsAddition_ShouldCorrectlyAddDates() {
			let date = Date()
			let componentsToAdd = DateComponents(day: 5, hour: 3, minute: 30, second: 45)
			let resultDate = date + componentsToAdd
			
			let calendar = Calendar.current
			let expectedDate = calendar.date(byAdding: componentsToAdd, to: date)
			
			#expect(resultDate == expectedDate)
		}
		
		@Test
		func date_WithComponentsSubtraction_ShouldCorrectlySubstract() {
			let date = Date()
			let componentsToSubtract = DateComponents(day: 5, hour: 3, minute: 30, second: 45)
			let resultDate = date - componentsToSubtract
			
			let calendar = Calendar.current
			let expectedDate = calendar.date(byAdding: -componentsToSubtract, to: date)
			
			#expect(resultDate == expectedDate)
		}
		
		@Test
		func date_WithVariousMathematicalEquations_ShouldCalculateCorrectly() {
			let date = Date()
			#expect(date < date + 1.minutes)
			#expect(date > date - 1.minutes)
			#expect(date < date + 1.hours)
			#expect(date > date - 1.hours)
			#expect(date < date + 1.days)
			#expect(date > date - 1.days)
			#expect(date < date + 1.months)
			#expect(date > date - 1.months)
			#expect(date < date + 1.years)
			#expect(date > date - 1.years)
		}
		
		#if !os(macOS)
		@Test
		func notification_WithCancelNotification_ShouldCancelScheduledNotification() {
			let notification = UNNotificationRequest(seconds: 10, title: "Test Notification", message: "This is a test notification")
			notification.schedule()
			notification.cancel()
			#expect(!notification.identifier.isEmpty)
		}
		
		@Test
		func notification_WithRequestInit_ShouldCreateSchedule() {
			let title = "Test Notification"
			let message = "This is a test notification"
			let universalLink = "https://example.com"
			let notificationRequest = UNNotificationRequest(seconds: 10, title: title, message: message, universalLink: universalLink)
			
			#expect(notificationRequest.content.title == title)
			#expect(notificationRequest.content.body == message)
			#expect(notificationRequest.content.sound != nil)
			#expect(notificationRequest.content.badge == 1)
			
			if let userInfo = notificationRequest.content.userInfo as? [String: String] {
				#expect(userInfo[UNNotificationRequest.Keys.url] == universalLink)
			} else {
				Issue.record("Failed to get user info from the notification request")
			}
		}
		
		@Test
		func notification_WithRequestSchedule_ShouldCreateSchedule() async {
			let center = UNUserNotificationCenter.current()
			let notification = UNNotificationRequest(seconds: 10, title: "Test Notification", message: "This is a test notification")
			
			notification.schedule()
			let settings = await center.notificationSettings()
			guard settings.authorizationStatus == .authorized else { return }
			
			let requests = await center.pendingNotificationRequests()
			guard !requests.isEmpty else { return }
			let requestIdentifiers = requests.map { $0.content.title }
			#expect(requestIdentifiers.contains(notification.content.title))
		}
		
		@Test
		func notification_WithRequestCancel_ShouldCancelScheduledNotification() async {
			let center = UNUserNotificationCenter.current()
			let notification = UNNotificationRequest(seconds: 10, title: "Test Notification", message: "This is a test notification")
			
			notification.schedule()
			let settings = await center.notificationSettings()
			guard settings.authorizationStatus == .authorized else { return }
			
			_ = await center.pendingNotificationRequests()
			notification.cancel()
			
			let updatedRequests = await center.pendingNotificationRequests()
			let updatedRequestIdentifiers = updatedRequests.map { $0.identifier }
			#expect(!updatedRequestIdentifiers.contains(notification.identifier))
		}
		#endif
	}
}
