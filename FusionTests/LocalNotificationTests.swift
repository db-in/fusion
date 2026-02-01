//
//  Created by Diney Bomfim on 09/06/2023.
//

import XCTest
@testable import Fusion

// MARK: - Definitions -

// MARK: - Type -

class LocalNotificationTests: XCTestCase {

// MARK: - Properties
	
// MARK: - Exposed Methods
	
	func testDate_WithComponentsNegation_ShouldCorrectlyInvert() {
		let components = DateComponents(day: 5, hour: 3, minute: 30, second: 45)
		let negatedComponents = -components
		
		XCTAssertEqual(negatedComponents.day, -5)
		XCTAssertEqual(negatedComponents.hour, -3)
		XCTAssertEqual(negatedComponents.minute, -30)
		XCTAssertEqual(negatedComponents.second, -45)
	}
	
	func testDate_WithComponentsAddition_ShouldCorrectlyAddDates() {
		let date = Date()
		let componentsToAdd = DateComponents(day: 5, hour: 3, minute: 30, second: 45)
		let resultDate = date + componentsToAdd
		
		let calendar = Calendar.current
		let expectedDate = calendar.date(byAdding: componentsToAdd, to: date)
		
		XCTAssertEqual(resultDate, expectedDate)
	}
	
	func testDate_WithComponentsSubtraction_ShouldCorrectlySubstract() {
		let date = Date()
		let componentsToSubtract = DateComponents(day: 5, hour: 3, minute: 30, second: 45)
		let resultDate = date - componentsToSubtract
		
		let calendar = Calendar.current
		let expectedDate = calendar.date(byAdding: -componentsToSubtract, to: date)
		
		XCTAssertEqual(resultDate, expectedDate)
	}
	
	func testDate_WithVariousMathematicalEquations_ShouldCalculateCorrectly() {
		let date = Date()
		XCTAssertLessThan(date, date + 1.minutes)
		XCTAssertGreaterThan(date, date - 1.minutes)
		XCTAssertLessThan(date, date + 1.hours)
		XCTAssertGreaterThan(date, date - 1.hours)
		XCTAssertLessThan(date, date + 1.days)
		XCTAssertGreaterThan(date, date - 1.days)
		XCTAssertLessThan(date, date + 1.months)
		XCTAssertGreaterThan(date, date - 1.months)
		XCTAssertLessThan(date, date + 1.years)
		XCTAssertGreaterThan(date, date - 1.years)
	}
	
	func testNotification_WithCancelNotification_ShouldCancelScheduledNotification() {
		let notification = UNNotificationRequest(seconds: 10, title: "Test Notification", message: "This is a test notification")
		notification.schedule()
		notification.cancel()
		XCTAssertFalse(notification.identifier.isEmpty)
	}
	
	func testNotification_WithRequestInit_ShouldCreateSchedule() {
		let title = "Test Notification"
		let message = "This is a test notification"
		let universalLink = "https://example.com"
		let notificationRequest = UNNotificationRequest(seconds: 10, title: title, message: message, universalLink: universalLink)
		
		XCTAssertEqual(notificationRequest.content.title, title)
		XCTAssertEqual(notificationRequest.content.body, message)
		XCTAssertEqual(notificationRequest.content.sound, .default)
		XCTAssertEqual(notificationRequest.content.badge, 1)
		
		if let userInfo = notificationRequest.content.userInfo as? [String: String] {
			XCTAssertEqual(userInfo[UNNotificationRequest.Keys.url], universalLink)
		} else {
			XCTFail("Failed to get user info from the notification request")
		}
	}
	
	func testNotification_WithRequestSchedule_ShouldCreateSchedule() {
		let expectation = expectation(description: #function)
		let center = UNUserNotificationCenter.current()
		let notification = UNNotificationRequest(seconds: 10, title: "Test Notification", message: "This is a test notification")
		
		notification.schedule()
		center.getNotificationSettings { settings in
			guard settings.authorizationStatus == .authorized else {
				expectation.fulfill()
				return
			}
			
			center.getPendingNotificationRequests { requests in
				guard !requests.isEmpty else {
					expectation.fulfill()
					return
				}
				let requestIdentifiers = requests.map { $0.content.title }
				XCTAssertTrue(requestIdentifiers.contains(notification.content.title))
				expectation.fulfill()
			}
		}
		
		waitForExpectations(timeout: 10.0, handler: nil)
	}
	
	func testNotification_WithRequestCancel_ShouldCancelScheduledNotification() {
		let expectation = expectation(description: #function)
		let center = UNUserNotificationCenter.current()
		let notification = UNNotificationRequest(seconds: 10, title: "Test Notification", message: "This is a test notification")
		
		notification.schedule()
		center.getNotificationSettings { settings in
			guard settings.authorizationStatus == .authorized else {
				expectation.fulfill()
				return
			}
			
			center.getPendingNotificationRequests { requests in
				let requestIdentifiers = requests.map { $0.identifier }
				
				notification.cancel()
				
				center.getPendingNotificationRequests { updatedRequests in
					let updatedRequestIdentifiers = updatedRequests.map { $0.identifier }
					XCTAssertFalse(updatedRequestIdentifiers.contains(notification.identifier))
					
					expectation.fulfill()
				}
			}
		}
		
		waitForExpectations(timeout: 10.0, handler: nil)
	}
}
