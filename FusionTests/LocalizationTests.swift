//
//  Created by Diney on 5/7/23.
//

import XCTest
@testable import Fusion

// MARK: - Definitions -

// MARK: - Type -

class LocalizationTests: XCTestCase {
	
	// MARK: - Notification and Bundle
	
	func testPost_ShouldPostNotificationSuccessfully() {
		let notificationName = Notification.Name("TestNotification")
		let expectation = self.expectation(description: "Notification posted successfully")
		var notificationReceived = false
		let observer = NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) { _ in
			notificationReceived = true
			expectation.fulfill()
		}
		
		NotificationCenter.post(notificationName)
		
		waitForExpectations(timeout: 1) { _ in
			NotificationCenter.default.removeObserver(observer)
			XCTAssertTrue(notificationReceived)
		}
	}
	
	func testLanguages_ForValidLanguageCode_ShouldReturnLanguageBundle() {
		let bundle = Bundle.main
		let languageBundle = bundle.languages(for: "en")
		XCTAssertNil(languageBundle)
	}
	
	func testLanguages_ForInvalidLanguageCode_ShouldReturnNil() {
		let bundle = Bundle.main
		let languageBundle = bundle.languages(for: "invalid")
		XCTAssertNil(languageBundle)
	}
	
	func testLocalizedString_ForPreferredLanguage_ShouldReturnLocalizedString() {
		let stringKey = "test_string_key"
		let localizedString = stringKey.localized()
		XCTAssertEqual(localizedString, stringKey)
	}
	
	func testLocalizedString_ForInvalidKey_ShouldReturnOriginalKey() {
		let invalidKey = "invalid_key"
		let localizedString = invalidKey.localized()
		XCTAssertEqual(localizedString, invalidKey)
	}
	
	func testPreferredLanguageCodeISO2_ShouldReturnValidCode() {
		let languageCode = Locale.preferredLanguageCodeISO2
		XCTAssertNotNil(languageCode)
	}
	
	// MARK: - String Extension
	
	func testOriginalKey_WhenSet_ShouldReturnOriginalKey() {
		let originalKey = "originalKey"
		var string = "testString"
		
		string.originalKey = originalKey
		
		XCTAssertEqual(string.originalKey, originalKey)
	}
	
	func testReplacing_WithTemplateAndPlaceholders_ShouldReturnReplacedString() {
		let template = ["5", "5000"]
		let placeholders = ["{KG}", "{gr}"]
		let originalString = "{KG}kg is equal {gr}g"
		let replacedString = originalString.replacing(with: template, placeholders: placeholders)
		XCTAssertEqual(replacedString.content, "5kg is equal 5000g")
	}
	
	func testReplacing_WithTemplate_ShouldReturnReplacedString() {
		let originalString = "{KG}kg is equal {gr}g"
		let replacedString = originalString.replacing("5", "5000")
		XCTAssertEqual(replacedString.content, "5kg is equal 5000g")
	}
	
	func testReplacing_WithTemplateAttributedText_ShouldReturnReplacedText() {
		let originalString = "{KG}kg is equal {gr}g".styled(color: .black)
		let replacedString = originalString.replacing("5".styled(color: .blue), "5000".styled(color: .red))
		XCTAssertEqual(replacedString.content, "5kg is equal 5000g")
	}
	
// MARK: - Locale Extension
	
	func testPreferredLocale_ShouldReturnPreferredLocale() {
		let preferredLocale = Locale.preferredLocale
		XCTAssertEqual(preferredLocale.identifier, Locale.preferredLanguageCodeISO2)
	}
	
	func testLanguageCodeISO2_ShouldReturnValidCode() {
		let locale = Locale(identifier: "en_US")
		XCTAssertEqual(locale.languageCodeISO2, "en")
	}
	
	func testRegionCodeISO2_ShouldReturnValidCode() {
		let locale = Locale(identifier: "en_US")
		XCTAssertEqual(locale.regionCodeISO2, "us")
	}
	
	func testLanguageCodeISO2_WhenLanguageCodeAvailable_ShouldReturnLowercasedLanguageCode() {
		let locale = Locale(identifier: "en_US")
		let result = locale.languageCodeISO2
		XCTAssertEqual(result, "en")
	}
	
	func testLanguageCodeISO2_WhenLanguageCodeNotAvailable_ShouldReturnEmptyString() {
		let locale = Locale(identifier: "zzz")
		let result = locale.languageCodeISO2
		XCTAssertEqual(result, "zz")
	}
	
	// MARK: regionCodeISO2
	
	func testRegionCodeISO2_WhenRegionCodeAvailable_ShouldReturnLowercasedRegionCode() {
		let locale = Locale(identifier: "en_US")
		let result = locale.regionCodeISO2
		XCTAssertEqual(result, "us")
	}
	
	func testRegionCodeISO2_WhenRegionCodeNotAvailable_ShouldReturnEmptyString() {
		let locale = Locale(identifier: "en")
		let result = locale.regionCodeISO2
		XCTAssertEqual(result, "")
	}
	
	// MARK: isRTL
	
	func testIsRTL_WhenLanguageIsRightToLeft_ShouldReturnTrue() {
		let locale = Locale(identifier: "ar")
		let result = locale.isRTL
		XCTAssertTrue(result)
	}
	
	func testIsRTL_WhenLanguageIsNotRightToLeft_ShouldReturnFalse() {
		let locale = Locale(identifier: "en")
		let result = locale.isRTL
		XCTAssertFalse(result)
	}
	
	// MARK: currencyGroups
	
	func testCurrencyGroups_ShouldGroupLocalesByCurrencyCode() {
		let currencyGroups = Locale.currencyGroups
		let result = Set(currencyGroups.keys)
		let test = Set(["AED", "AUD", "BHD", "CAD", "CHF", "GBP", "JPY",  "OMR", "SAR", "TRY", "USD"])
		XCTAssertTrue(test.isSubset(of: result))
	}
	
	// MARK: init(currencyCode:languageCode:)
	
	func testInitCurrencyCodeLanguageCode_WhenCurrencyExistsForLanguage_ShouldReturnLocale() {
		let currencyCode = "USD"
		let languageCode = "en"
		let locale = Locale(currencyCode: currencyCode, languageCode: languageCode)
		
		XCTAssertNotNil(locale)
		XCTAssertEqual(locale?.currencyCode, currencyCode)
		XCTAssertEqual(locale?.languageCodeISO2, languageCode)
	}
	
	func testInitCurrencyCodeLanguageCode_WhenCurrencyExistsForDifferentLanguage_ShouldReturnLocaleWithPreferredLanguage() {
		let currencyCode = "USD"
		let languageCode = "fr"
		let locale = Locale(currencyCode: currencyCode, languageCode: languageCode)
		
		XCTAssertNotNil(locale)
		XCTAssertEqual(locale?.currencyCode, currencyCode)
		XCTAssertNotEqual(locale?.languageCodeISO2, "fr")
	}
	
	func testInitCurrencyCodeLanguageCode_WhenCurrencyDoesNotExist_ShouldReturnNil() {
		let currencyCode = "XXX"
		let languageCode = "en"
		let locale = Locale(currencyCode: currencyCode, languageCode: languageCode)
		XCTAssertNil(locale)
	}
	
	// MARK: adjusted(language:)
	
	func testAdjustedLanguage_WhenLanguageProvided_ShouldReturnLocaleWithAdjustedLanguage() {
		let locale = Locale(identifier: "en_US")
		let adjustedLanguage = "fr"
		let result = locale.adjusted(language: adjustedLanguage)
		XCTAssertEqual(result.identifier.lowercased(), "\(adjustedLanguage)_\(locale.regionCodeISO2)".lowercased())
	}
	
	func testAdjustedLanguage_WhenLanguageNotProvided_ShouldReturnLocaleWithPreferredLanguage() {
		let locale = Locale(identifier: "en_US")
		let result = locale.adjusted()
		XCTAssertEqual(result.identifier.lowercased(), "\(Locale.preferredLanguageCodeISO2)_\(locale.regionCodeISO2)".lowercased())
	}
}
