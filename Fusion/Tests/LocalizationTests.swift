//
//  Created by Diney on 5/7/23.
//

import Foundation
import Testing
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

extension FusionSuite {
	
	@Suite
	struct LocalizationTests {
		
		// MARK: - Notification and Bundle
		
		@Test
		func post_ShouldPostNotificationSuccessfully() async {
			let notificationName = Notification.Name("TestNotification")
			await confirmation { confirm in
				let observer = NotificationCenter.default.addObserver(forName: notificationName, object: nil, queue: nil) { _ in
					confirm()
				}
				
				NotificationCenter.post(notificationName)
				NotificationCenter.default.removeObserver(observer)
			}
		}
		
		@Test
		func localizedString_WithConcurrentReadsAndFlushes_ShouldStayConsistent() async {
			FusionTestCase.configureBundles()
			let hintsCount = Bundle.hints.count
			let firstHint = Bundle.hints.first
			
			await withTaskGroup(of: Void.self) { group in
				for index in 0..<200 {
					group.addTask {
						_ = "test_string_key_\(index % 10)".localized(for: index.isMultiple(of: 2) ? "en" : "ar")
						if index.isMultiple(of: 7) { Bundle.flushCachedLanguages() }
						if let firstHint { Bundle.registering(firstHint) }
					}
				}
			}
			
			#expect(Bundle.hints.count == hintsCount)
		}
		
		@Test
		func languages_ForValidLanguageCode_ShouldReturnLanguageBundle() {
			let bundle = Bundle.main
			let languageBundle = bundle.languages(for: "en")
			#expect(languageBundle == nil)
		}
		
		@Test
		func languages_ForInvalidLanguageCode_ShouldReturnNil() {
			let bundle = Bundle.main
			let languageBundle = bundle.languages(for: "invalid")
			#expect(languageBundle == nil)
		}
		
		@Test
		func localizedString_ForPreferredLanguage_ShouldReturnLocalizedString() {
			let stringKey = "test_string_key"
			let localizedString = stringKey.localized()
			#expect(localizedString == stringKey)
		}
		
		@Test
		func localizedString_ForInvalidKey_ShouldReturnOriginalKey() {
			let invalidKey = "invalid_key"
			let localizedString = invalidKey.localized()
			#expect(localizedString == invalidKey)
		}
		
		@Test
		func preferredLanguageCodeISO2_ShouldReturnValidCode() {
			let languageCode: String? = Locale.preferredLanguageCodeISO2
			#expect(languageCode != nil)
		}
		
		// MARK: - Language Matching
		
		private let sampleLanguageSet: Set<String> = ["zh-CN", "de", "en", "zh-TW", "tr", "ru", "pt", "ar", "fr", "it", "es"]
		
		@Test(arguments: [("es-US", "es"), ("en-US", "en"), ("ar-US", "ar"), ("tr-US", "tr"), ("zh-TW", "zh"), ("zh-CN", "zh")])
		func codeISO2_WhenBCP47Identifier_ShouldReturnISO2Code(identifier: String, expected: String) {
			#expect(identifier.codeISO2 == expected)
		}
		
		@Test(arguments: [("es-US", "es"), ("en-US", "en"), ("ar-US", "ar"), ("tr-US", "tr")])
		func matchingLanguage_WhenBCP47IdentifierMatchesISO2_ShouldReturnISO2Code(identifier: String, expected: String) {
			#expect(identifier.matchingLanguage(in: sampleLanguageSet) == expected)
		}
		
		@Test
		func matchingLanguage_WhenChineseRegionalIdentifier_ShouldReturnExactMatch() {
			#expect("zh-TW".matchingLanguage(in: sampleLanguageSet) == "zh-TW")
			#expect("zh-CN".matchingLanguage(in: sampleLanguageSet) == "zh-CN")
		}
		
		@Test
		func matchingLanguage_WhenZhTWPreferred_ShouldNotFallbackToZh() {
			let result = "zh-TW".matchingLanguage(in: sampleLanguageSet)
			#expect(result == "zh-TW")
			#expect(result != "zh")
		}
		
		@Test
		func matchingLanguage_WhenNoMatch_ShouldReturnNil() {
			#expect("ja-US".matchingLanguage(in: sampleLanguageSet) == nil)
			#expect("ko-KR".matchingLanguage(in: sampleLanguageSet) == nil)
		}
		
		@Test
		func matchingLanguage_WhenExactISO2Code_ShouldReturnSameCode() {
			#expect("de".matchingLanguage(in: sampleLanguageSet) == "de")
			#expect("fr".matchingLanguage(in: sampleLanguageSet) == "fr")
		}
		
		@Test
		func preferredLanguageResolution_WhenBCP47List_ShouldReturnFirstMatch() {
			let preferred = ["es-US", "en-US", "ar-US", "tr-US"]
			let result = preferred.firstMap { $0.matchingLanguage(in: sampleLanguageSet) }
			#expect(result == "es")
		}
		
		@Test
		func preferredLanguageResolution_WhenZhTWIsFirst_ShouldReturnZhTW() {
			let preferred = ["zh-TW", "en-US", "es-US"]
			let result = preferred.firstMap { $0.matchingLanguage(in: sampleLanguageSet) }
			#expect(result == "zh-TW")
		}
		
		@Test
		func preferredLanguageResolution_WhenZhCNIsFirst_ShouldReturnZhCN() {
			let preferred = ["zh-CN", "zh-TW", "en-US"]
			let result = preferred.firstMap { $0.matchingLanguage(in: sampleLanguageSet) }
			#expect(result == "zh-CN")
		}
		
		@Test
		func preferredLanguageResolution_WhenZhCNAndZhTWBothPresent_ShouldRespectOrder() {
			let twFirst = ["zh-TW", "zh-CN"].firstMap { $0.matchingLanguage(in: sampleLanguageSet) }
			let cnFirst = ["zh-CN", "zh-TW"].firstMap { $0.matchingLanguage(in: sampleLanguageSet) }
			#expect(twFirst == "zh-TW")
			#expect(cnFirst == "zh-CN")
		}
		
		@Test
		func preferredLanguageResolution_WhenNoMatch_ShouldReturnNil() {
			let preferred = ["ja-US", "ko-KR"]
			let result = preferred.firstMap { $0.matchingLanguage(in: sampleLanguageSet) }
			#expect(result == nil)
		}
		
		// MARK: - String Extension
		
		@Test
		func originalKey_WhenSet_ShouldReturnOriginalKey() {
			let originalKey = "originalKey"
			var string = "testString"
			
			string.originalKey = originalKey
			
			#expect(string.originalKey == originalKey)
		}
		
		@Test
		func replacing_WithTemplateAndPlaceholders_ShouldReturnReplacedString() {
			let template = ["5", "5000"]
			let placeholders = ["{KG}", "{gr}"]
			let originalString = "{KG}kg is equal {gr}g"
			let replacedString = originalString.replacing(with: template, placeholders: placeholders)
			#expect(replacedString.content == "5kg is equal 5000g")
		}
		
		@Test
		func replacing_WithTemplate_ShouldReturnReplacedString() {
			let originalString = "{KG}kg is equal {gr}g"
			let replacedString = originalString.replacing("5", "5000")
			#expect(replacedString.content == "5kg is equal 5000g")
		}
		
		@Test
		func replacing_WithTemplateAttributedText_ShouldReturnReplacedText() {
			let originalString = "{KG}kg is equal {gr}g".styled([.foregroundColor: TestColor.black])
			let replacedString = originalString.replacing("5".styled([.foregroundColor: TestColor.blue]), "5000".styled([.foregroundColor: TestColor.red]))
			#expect(replacedString.content == "5kg is equal 5000g")
		}
		
// MARK: - Locale Extension
		
		@Test
		func preferredLocale_ShouldReturnPreferredLocale() {
			let preferredLocale = Locale.preferredLocale
			#expect(preferredLocale.identifier == Locale.preferredLanguageCodeISO2)
		}
		
		@Test
		func languageCodeISO2_ShouldReturnValidCode() {
			let locale = Locale(identifier: "en_US")
			#expect(locale.languageCodeISO2 == "en")
		}
		
		@Test
		func regionCodeISO2_ShouldReturnValidCode() {
			let locale = Locale(identifier: "en_US")
			#expect(locale.regionCodeISO2 == "us")
		}
		
		@Test
		func languageCodeISO2_WhenLanguageCodeAvailable_ShouldReturnLowercasedLanguageCode() {
			let locale = Locale(identifier: "en_US")
			let result = locale.languageCodeISO2
			#expect(result == "en")
		}
		
		@Test
		func languageCodeISO2_WhenLanguageCodeNotAvailable_ShouldReturnEmptyString() {
			let locale = Locale(identifier: "zzz")
			let result = locale.languageCodeISO2
			#expect(result == "zz")
		}
		
		// MARK: regionCodeISO2
		
		@Test
		func regionCodeISO2_WhenRegionCodeAvailable_ShouldReturnLowercasedRegionCode() {
			let locale = Locale(identifier: "en_US")
			let result = locale.regionCodeISO2
			#expect(result == "us")
		}
		
		@Test
		func regionCodeISO2_WhenRegionCodeNotAvailable_ShouldReturnEmptyString() {
			let locale = Locale(identifier: "en")
			let result = locale.regionCodeISO2
			#expect(result == "")
		}
		
		// MARK: isRTL
		
		@Test
		func isRTL_WhenLanguageIsRightToLeft_ShouldReturnTrue() {
			let locale = Locale(identifier: "ar")
			let result = locale.isRTL
			#expect(result)
		}
		
		@Test
		func isRTL_WhenLanguageIsNotRightToLeft_ShouldReturnFalse() {
			let locale = Locale(identifier: "en")
			let result = locale.isRTL
			#expect(!result)
		}
		
		// MARK: currencyGroups
		
		@Test
		func currencyGroups_ShouldGroupLocalesByCurrencyCode() {
			let currencyGroups = Locale.currencyGroups
			let result = Set(currencyGroups.keys)
			let test = Set(["AED", "AUD", "BHD", "CAD", "CHF", "GBP", "JPY",  "OMR", "SAR", "TRY", "USD"])
			#expect(test.isSubset(of: result))
		}
		
		// MARK: init(currencyCode:languageCode:)
		
		@Test
		func initCurrencyCodeLanguageCode_WhenCurrencyExistsForLanguage_ShouldReturnLocale() {
			let currencyCode = "USD"
			let languageCode = "en"
			let locale = Locale(currencyCode: currencyCode, languageCode: languageCode)
			
			#expect(locale != nil)
			#expect(locale?.currencyIdentifier == currencyCode)
			#expect(locale?.languageCodeISO2 == languageCode)
		}
		
		@Test
		func initCurrencyCodeLanguageCode_WhenCurrencyExistsForDifferentLanguage_ShouldReturnLocaleWithPreferredLanguage() {
			let currencyCode = "USD"
			let languageCode = "fr"
			let locale = Locale(currencyCode: currencyCode, languageCode: languageCode)
			
			#expect(locale != nil)
			#expect(locale?.currencyIdentifier == currencyCode)
			#expect(locale?.languageCodeISO2 != "fr")
		}
		
		@Test
		func initCurrencyCodeLanguageCode_WhenCurrencyDoesNotExist_ShouldReturnNil() {
			let currencyCode = "XXX"
			let languageCode = "en"
			let locale = Locale(currencyCode: currencyCode, languageCode: languageCode)
			#expect(locale == nil)
		}
		
		// MARK: adjusted(language:)
		
		@Test
		func adjustedLanguage_WhenLanguageProvided_ShouldReturnLocaleWithAdjustedLanguage() {
			let locale = Locale(identifier: "en_US")
			let adjustedLanguage = "fr"
			let result = locale.adjusted(language: adjustedLanguage)
			#expect(result.identifier.lowercased() == "\(adjustedLanguage)_\(locale.regionCodeISO2)".lowercased())
		}
		
		@Test
		func adjustedLanguage_WhenLanguageNotProvided_ShouldReturnLocaleWithPreferredLanguage() {
			let locale = Locale(identifier: "en_US")
			let result = locale.adjusted()
			#expect(result.identifier.lowercased() == "\(Locale.preferredLanguageCodeISO2)_\(locale.regionCodeISO2)".lowercased())
		}
	}
}
