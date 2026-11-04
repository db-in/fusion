//
//  Created by Diney Bomfim on 7/11/24.
//

import Foundation
import LocalServer
import Testing
@testable import Fusion

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct CountryInfoTests {
		
		init() {
			FusionTestCase.configureBundles()
			let server = StubServer()
			server.route([.GET], url: "tinify\\.net/5Ca") { _, _ in
				StubResponse(string: #"{"US":{"i3":"USA","p":"1","l":["en"],"r":1}}"#)
			}
			StubServer.instance = server
			let configuration = URLSessionConfiguration.default
			configuration.urlCache = nil
			configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
			RESTAuthenticator.session = .init(configuration: configuration, delegate: RESTAuthenticator.shared, delegateQueue: nil)
		}
		
		@Test
		func countryInfo_WithISO2Code_ShouldInitializeWithCode() {
			let country = CountryInfo(code: "US")
			#expect(country.isoCode2 == "US")
			#expect(!country.name.isEmpty)
		}
		
		private func prefetch() async -> Bool {
			await completes(within: 10) {
				await withCheckedContinuation { continuation in
					CountryInfo.prefetchData {
						continuation.resume()
					}
				}
			}
		}
		
		@Test
		func countryInfo_WithISO3Code_ShouldInitializeWithCode() async {
			#expect(await prefetch())
			let country = CountryInfo(code: "USA")
			#expect(country.isoCode2 == "US")
		}
		
		@Test
		func countryInfo_WithPhoneCode_ShouldInitializeWithPhoneCode() {
			let country = CountryInfo(phoneCode: "1")
			#expect(country.phoneCode == "1")
		}
		
		@Test
		func countryInfo_WithLanguageCode_ShouldInitializeWithLanguageCode() {
			let country = CountryInfo(languageCode: "en")
			#expect(country.languageCode == "en")
		}
		
		@Test
		func countryInfo_WithLocale_ShouldInitializeWithLocaleRegion() {
			let locale = Locale(identifier: "en_US")
			let country = CountryInfo(locale: locale)
			#expect(country.isoCode2 == "US")
		}
		
		@Test
		func countryInfo_WithCustomLocale_ShouldUseCustomLocaleForName() {
			let locale = Locale(identifier: "pt_BR")
			let country = CountryInfo(code: "US", locale: locale)
			#expect(!country.name.isEmpty)
		}
		
		@Test
		func countryInfo_WithInvalidCode_ShouldUseCodeAsISO2() {
			let country = CountryInfo(code: "XX")
			#expect(country.isoCode2 == "XX")
		}
		
		@Test
		func countryInfo_PhoneCodeFormatted_ShouldReturnFormattedString() {
			var country = CountryInfo(code: "US")
			country.phoneCode = "1"
			#expect(country.phoneCodeFormatted == "(+1)")
		}
		
		@Test
		func countryInfo_PhoneCodeFormatted_WithEmptyPhoneCode_ShouldReturnEmptyFormat() {
			var country = CountryInfo(code: "US")
			country.phoneCode = ""
			#expect(country.phoneCodeFormatted == "(+)")
		}
		
		@Test
		func countryInfo_Flag_ShouldReturnEmoji() {
			let country = CountryInfo(code: "US")
			let flag = country.flag
			#expect(!flag.isEmpty)
			#expect(flag.unicodeScalars.count >= 2)
		}
		
		@Test
		func countryInfo_Flag_WithTwoLetterCode_ShouldGenerateValidEmoji() {
			let country = CountryInfo(code: "GB")
			let flag = country.flag
			#expect(!flag.isEmpty)
		}
		
		@Test
		func countryInfo_FlagAndName_ShouldCombineFlagAndName() {
			let country = CountryInfo(code: "US")
			let result = country.flagAndName
			#expect(result.contains(country.flag))
			#expect(result.contains(country.name))
		}
		
		@Test
		func countryInfo_FlagPhoneAndName_WithPhoneCode_ShouldReturnFormattedString() {
			var country = CountryInfo(code: "US")
			country.phoneCode = "1"
			let result = country.flagPhoneAndName
			#expect(!result.isEmpty)
			#expect(result.contains(country.flag))
			#expect(result.contains(country.phoneCodeFormatted))
			#expect(result.contains(country.name))
		}
		
		@Test
		func countryInfo_FlagPhoneAndName_WithoutPhoneCode_ShouldReturnFlagAndName() {
			var country = CountryInfo(code: "US")
			country.phoneCode = ""
			let result = country.flagPhoneAndName
			#expect(result == country.flagAndName)
		}
		
		@Test
		func countryInfo_FlagURL_ShouldReturnDefaultURL() {
			let country = CountryInfo(code: "US")
			let url = country.flagURL
			#expect(url.contains("flagcdn.com"))
			#expect(url.contains("us"))
			#expect(url.contains("h80"))
			#expect(url.contains("jpg"))
		}
		
		@Test
		func countryInfo_FlagVectorURL_ShouldReturnVectorURL() {
			let country = CountryInfo(code: "US")
			let url = country.flagVectorURL
			#expect(url.contains("us"))
			#expect(url.contains("svg"))
		}
		
		@Test
		func countryInfo_FlagURLWithType_SmallFlat_ShouldReturnCorrectURL() {
			let country = CountryInfo(code: "US")
			let url = country.flagURL(type: .smallFlat)
			#expect(url.contains("flagcdn.com"))
			#expect(url.contains("h80"))
			#expect(url.contains("jpg"))
			#expect(url.contains("us"))
		}
		
		@Test
		func countryInfo_FlagURLWithType_LargeFlat_ShouldReturnCorrectURL() {
			let country = CountryInfo(code: "US")
			let url = country.flagURL(type: .largeFlat)
			#expect(url.contains("flagcdn.com"))
			#expect(url.contains("h480"))
			#expect(url.contains("jpg"))
			#expect(url.contains("us"))
		}
		
		@Test
		func countryInfo_FlagURLWithType_SmallWaving_ShouldReturnCorrectURL() {
			let country = CountryInfo(code: "US")
			let url = country.flagURL(type: .smallWaving)
			#expect(url.contains("flagcdn.com"))
			#expect(url.contains("128x96"))
			#expect(url.contains("png"))
			#expect(url.contains("us"))
		}
		
		@Test
		func countryInfo_FlagURLWithType_LargeWaving_ShouldReturnCorrectURL() {
			let country = CountryInfo(code: "US")
			let url = country.flagURL(type: .largeWaving)
			#expect(url.contains("flagcdn.com"))
			#expect(url.contains("512x384"))
			#expect(url.contains("png"))
			#expect(url.contains("us"))
		}
		
		@Test
		func countryInfo_FlagURLWithType_Vector_ShouldReturnCorrectURL() {
			let country = CountryInfo(code: "US")
			let url = country.flagURL(type: .vector)
			#expect(url.contains("us"))
			#expect(url.contains("svg"))
		}
		
		@Test
		func countryInfo_Locale_ShouldReturnLocaleWithLanguageAndCountry() {
			let country = CountryInfo(code: "US")
			let locale = country.locale
			#expect(locale.identifier.contains("US") || locale.identifier.contains("us"))
		}
		
		@Test
		func countryInfo_Hashable_ShouldProduceConsistentHash() {
			let country1 = CountryInfo(code: "US")
			let country2 = CountryInfo(code: "US")
			var hasher1 = Hasher()
			var hasher2 = Hasher()
			country1.hash(into: &hasher1)
			country2.hash(into: &hasher2)
			#expect(hasher1.finalize() == hasher2.finalize())
		}
		
		@Test
		func countryInfo_Equatable_WithSameISO2_ShouldBeEqual() {
			let country1 = CountryInfo(code: "US")
			let country2 = CountryInfo(code: "US")
			#expect(country1 == country2)
		}
		
		@Test
		func countryInfo_Equatable_WithDifferentCodes_ShouldNotBeEqual() {
			let country1 = CountryInfo(code: "US")
			let country2 = CountryInfo(code: "GB")
			#expect(country1 != country2)
		}
		
		@Test
		func countryInfo_Comparable_ShouldSortByName() {
			let country1 = CountryInfo(code: "US")
			let country2 = CountryInfo(code: "GB")
			let sorted = [country1, country2].sorted()
			#expect(sorted[0].name <= sorted[1].name)
		}
		
		@Test
		func countryInfo_PrefetchData_ShouldCallCompletion() async {
			#expect(await prefetch())
		}
	}
	
	@Suite
	struct StringCountryInfoExtensionsTests {
		
		@Test
		func string_CountryInfoAsCode_ShouldReturnCountryInfo() {
			let country = "US".countryInfoAsCode
			#expect(country.isoCode2 == "US")
		}
		
		@Test
		func string_CountryInfoAsLanguage_ShouldReturnCountryInfo() {
			let country = "en".countryInfoAsLanguage
			#expect(country.languageCode == "en")
		}
		
		@Test
		func string_LanguageName_ShouldReturnLocalizedLanguageName() {
			let name = "en".languageName
			#expect(!name.isEmpty)
		}
		
		@Test
		func string_LanguageName_WithInvalidCode_ShouldReturnEmpty() {
			let name = "xx".languageName
			#expect(name.isEmpty)
		}
	}
	
	@Suite
	struct LocaleCountryInfoExtensionsTests {
		
		@Test
		func locale_LanguageName_ShouldReturnLocalizedLanguageName() {
			let locale = Locale(identifier: "en_US")
			let name = locale.languageName
			#expect(!name.isEmpty)
		}
		
		@Test
		func locale_CurrencyName_ShouldReturnLocalizedCurrencyName() {
			let locale = Locale(identifier: "en_US")
			let name = locale.currencyName
			if !locale.currencyIdentifier.isEmpty {
				#expect(!name.isEmpty)
			}
		}
		
		@Test
		func locale_CurrencyNameAndCode_ShouldReturnFormattedString() {
			let locale = Locale(identifier: "en_US")
			let result = locale.currencyNameAndCode
			#expect(result.contains("("))
			#expect(result.contains(")"))
			let code = locale.currencyIdentifier
			if !code.isEmpty {
				#expect(result.contains(code.uppercased()))
			}
		}
		
		@Test
		func locale_CurrencyNameAndCode_WithNoCurrency_ShouldReturnEmptyCode() {
			let locale = Locale(identifier: "en")
			let result = locale.currencyNameAndCode
			#expect(result.contains("()"))
		}
		
		@Test
		func locale_AvailableCountries_ShouldReturnNonEmptyArray() {
			let countries = Locale.availableCountries
			#expect(!countries.isEmpty)
			#expect(countries.allSatisfy { !$0.name.isEmpty })
		}
		
		@Test
		func locale_AvailableCountries_ShouldBeSorted() {
			let countries = Locale.availableCountries
			let sorted = countries.sorted()
			#expect(countries.map { $0.name } == sorted.map { $0.name })
		}
	}
	
	@Suite
	struct ArrayCountryInfoExtensionsTests {
		
		@Test
		func array_Ranked_ShouldSortByRank() {
			let country1 = CountryInfo(code: "US")
			let country2 = CountryInfo(code: "GB")
			let country3 = CountryInfo(code: "AE")
			
			let countries = [country1, country2, country3]
			let ranked = countries.ranked
			#expect(ranked.count == countries.count)
			#expect(ranked[0].rank <= ranked[1].rank)
			if ranked.count > 2 {
				#expect(ranked[1].rank <= ranked[2].rank)
			}
		}
		
		@Test
		func array_Ranked_WithMultipleCountries_ShouldMaintainAllCountries() {
			let country1 = CountryInfo(code: "US")
			let country2 = CountryInfo(code: "GB")
			
			let countries = [country1, country2]
			let ranked = countries.ranked
			#expect(ranked.count == 2)
			#expect(ranked.contains { $0.isoCode2 == "US" })
			#expect(ranked.contains { $0.isoCode2 == "GB" })
		}
		
		@Test
		func array_Highlighting_ShouldReorderArray() {
			let countries = [
				CountryInfo(code: "GB"),
				CountryInfo(code: "US"),
				CountryInfo(code: "AE")
			]
			let highlighted = countries.highlighting()
			#expect(highlighted.count == countries.count)
		}
		
		@Test
		func array_AllCountries_ShouldReturnNonEmptyArray() {
			let countries = Array<CountryInfo>.allCountries
			#expect(!countries.isEmpty)
		}
		
		@Test
		func array_AllCountries_ShouldContainValidCountries() {
			let countries = Array<CountryInfo>.allCountries
			#expect(countries.allSatisfy { !$0.isoCode2.isEmpty })
			#expect(countries.allSatisfy { !$0.name.isEmpty })
		}
	}
}
