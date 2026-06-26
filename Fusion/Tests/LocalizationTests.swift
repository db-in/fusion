//
//  Created by Diney on 5/7/23.
//

import XCTest
@testable import Fusion
#if canImport(UIKit)
import UIKit
private typealias TestColor = UIColor
#elseif canImport(AppKit)
import AppKit
private typealias TestColor = NSColor
#endif

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
	
	// MARK: - Language Matching
	
	private let sampleLanguageSet: Set<String> = ["zh-CN", "de", "en", "zh-TW", "tr", "ru", "pt", "ar", "fr", "it", "es"]
	
	func testCodeISO2_WhenBCP47Identifier_ShouldReturnISO2Code() {
		XCTAssertEqual("es-US".codeISO2, "es")
		XCTAssertEqual("en-US".codeISO2, "en")
		XCTAssertEqual("ar-US".codeISO2, "ar")
		XCTAssertEqual("tr-US".codeISO2, "tr")
		XCTAssertEqual("zh-TW".codeISO2, "zh")
		XCTAssertEqual("zh-CN".codeISO2, "zh")
	}
	
	func testMatchingLanguage_WhenBCP47IdentifierMatchesISO2_ShouldReturnISO2Code() {
		XCTAssertEqual("es-US".matchingLanguage(in: sampleLanguageSet), "es")
		XCTAssertEqual("en-US".matchingLanguage(in: sampleLanguageSet), "en")
		XCTAssertEqual("ar-US".matchingLanguage(in: sampleLanguageSet), "ar")
		XCTAssertEqual("tr-US".matchingLanguage(in: sampleLanguageSet), "tr")
	}
	
	func testMatchingLanguage_WhenChineseRegionalIdentifier_ShouldReturnExactMatch() {
		XCTAssertEqual("zh-TW".matchingLanguage(in: sampleLanguageSet), "zh-TW")
		XCTAssertEqual("zh-CN".matchingLanguage(in: sampleLanguageSet), "zh-CN")
	}
	
	func testMatchingLanguage_WhenZhTWPreferred_ShouldNotFallbackToZh() {
		let result = "zh-TW".matchingLanguage(in: sampleLanguageSet)
		XCTAssertEqual(result, "zh-TW")
		XCTAssertNotEqual(result, "zh")
	}
	
	func testMatchingLanguage_WhenNoMatch_ShouldReturnNil() {
		XCTAssertNil("ja-US".matchingLanguage(in: sampleLanguageSet))
		XCTAssertNil("ko-KR".matchingLanguage(in: sampleLanguageSet))
	}
	
	func testMatchingLanguage_WhenExactISO2Code_ShouldReturnSameCode() {
		XCTAssertEqual("de".matchingLanguage(in: sampleLanguageSet), "de")
		XCTAssertEqual("fr".matchingLanguage(in: sampleLanguageSet), "fr")
	}
	
	func testPreferredLanguageResolution_WhenBCP47List_ShouldReturnFirstMatch() {
		let preferred = ["es-US", "en-US", "ar-US", "tr-US"]
		let result = preferred.firstMap { $0.matchingLanguage(in: sampleLanguageSet) }
		XCTAssertEqual(result, "es")
	}
	
	func testPreferredLanguageResolution_WhenZhTWIsFirst_ShouldReturnZhTW() {
		let preferred = ["zh-TW", "en-US", "es-US"]
		let result = preferred.firstMap { $0.matchingLanguage(in: sampleLanguageSet) }
		XCTAssertEqual(result, "zh-TW")
	}
	
	func testPreferredLanguageResolution_WhenZhCNIsFirst_ShouldReturnZhCN() {
		let preferred = ["zh-CN", "zh-TW", "en-US"]
		let result = preferred.firstMap { $0.matchingLanguage(in: sampleLanguageSet) }
		XCTAssertEqual(result, "zh-CN")
	}
	
	func testPreferredLanguageResolution_WhenZhCNAndZhTWBothPresent_ShouldRespectOrder() {
		let twFirst = ["zh-TW", "zh-CN"].firstMap { $0.matchingLanguage(in: sampleLanguageSet) }
		let cnFirst = ["zh-CN", "zh-TW"].firstMap { $0.matchingLanguage(in: sampleLanguageSet) }
		XCTAssertEqual(twFirst, "zh-TW")
		XCTAssertEqual(cnFirst, "zh-CN")
	}
	
	func testPreferredLanguageResolution_WhenNoMatch_ShouldReturnNil() {
		let preferred = ["ja-US", "ko-KR"]
		let result = preferred.firstMap { $0.matchingLanguage(in: sampleLanguageSet) }
		XCTAssertNil(result)
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
		let originalString = "{KG}kg is equal {gr}g".styled([.foregroundColor: TestColor.black])
		let replacedString = originalString.replacing("5".styled([.foregroundColor: TestColor.blue]), "5000".styled([.foregroundColor: TestColor.red]))
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
		XCTAssertEqual(locale?.currencyIdentifier, currencyCode)
		XCTAssertEqual(locale?.languageCodeISO2, languageCode)
	}
	
	func testInitCurrencyCodeLanguageCode_WhenCurrencyExistsForDifferentLanguage_ShouldReturnLocaleWithPreferredLanguage() {
		let currencyCode = "USD"
		let languageCode = "fr"
		let locale = Locale(currencyCode: currencyCode, languageCode: languageCode)
		
		XCTAssertNotNil(locale)
		XCTAssertEqual(locale?.currencyIdentifier, currencyCode)
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
