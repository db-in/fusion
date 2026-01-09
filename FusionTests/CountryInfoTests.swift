//
//  Created by Diney Bomfim on 7/11/24.
//

import XCTest
@testable import Fusion

// MARK: - Type -

class CountryInfoTests: XCTestCase {
	
	func testCountryInfo_WithISO2Code_ShouldInitializeWithCode() {
		let country = CountryInfo(code: "US")
		XCTAssertEqual(country.isoCode2, "US")
		XCTAssertFalse(country.name.isEmpty)
	}
	
	func testCountryInfo_WithISO3Code_ShouldInitializeWithCode() {
		let country = CountryInfo(code: "USA")
		XCTAssertEqual(country.isoCode2, "US")
	}
	
	func testCountryInfo_WithPhoneCode_ShouldInitializeWithPhoneCode() {
		let country = CountryInfo(phoneCode: "1")
		XCTAssertEqual(country.phoneCode, "1")
	}
	
	func testCountryInfo_WithLanguageCode_ShouldInitializeWithLanguageCode() {
		let country = CountryInfo(languageCode: "en")
		XCTAssertEqual(country.languageCode, "en")
	}
	
	func testCountryInfo_WithLocale_ShouldInitializeWithLocaleRegion() {
		let locale = Locale(identifier: "en_US")
		let country = CountryInfo(locale: locale)
		XCTAssertEqual(country.isoCode2, "US")
	}
	
	func testCountryInfo_WithCustomLocale_ShouldUseCustomLocaleForName() {
		let locale = Locale(identifier: "pt_BR")
		let country = CountryInfo(code: "US", locale: locale)
		XCTAssertFalse(country.name.isEmpty)
	}
	
	func testCountryInfo_WithInvalidCode_ShouldUseCodeAsISO2() {
		let country = CountryInfo(code: "XX")
		XCTAssertEqual(country.isoCode2, "XX")
	}
	
	func testCountryInfo_PhoneCodeFormatted_ShouldReturnFormattedString() {
		var country = CountryInfo(code: "US")
		country.phoneCode = "1"
		XCTAssertEqual(country.phoneCodeFormatted, "(+1)")
	}
	
	func testCountryInfo_PhoneCodeFormatted_WithEmptyPhoneCode_ShouldReturnEmptyFormat() {
		var country = CountryInfo(code: "US")
		country.phoneCode = ""
		XCTAssertEqual(country.phoneCodeFormatted, "(+)")
	}
	
	func testCountryInfo_Flag_ShouldReturnEmoji() {
		let country = CountryInfo(code: "US")
		let flag = country.flag
		XCTAssertFalse(flag.isEmpty)
		XCTAssertTrue(flag.unicodeScalars.count >= 2)
	}
	
	func testCountryInfo_Flag_WithTwoLetterCode_ShouldGenerateValidEmoji() {
		let country = CountryInfo(code: "GB")
		let flag = country.flag
		XCTAssertFalse(flag.isEmpty)
	}
	
	func testCountryInfo_FlagAndName_ShouldCombineFlagAndName() {
		let country = CountryInfo(code: "US")
		let result = country.flagAndName
		XCTAssertTrue(result.contains(country.flag))
		XCTAssertTrue(result.contains(country.name))
	}
	
	func testCountryInfo_FlagPhoneAndName_WithPhoneCode_ShouldReturnFormattedString() {
		var country = CountryInfo(code: "US")
		country.phoneCode = "1"
		let result = country.flagPhoneAndName
		XCTAssertNotNil(result)
		XCTAssertTrue(result!.contains(country.flag))
		XCTAssertTrue(result!.contains(country.phoneCodeFormatted))
		XCTAssertTrue(result!.contains(country.name))
	}
	
	func testCountryInfo_FlagPhoneAndName_WithoutPhoneCode_ShouldReturnFlagAndName() {
		var country = CountryInfo(code: "US")
		country.phoneCode = ""
		let result = country.flagPhoneAndName
		XCTAssertEqual(result, country.flagAndName)
	}
	
	func testCountryInfo_FlagURL_ShouldReturnDefaultURL() {
		let country = CountryInfo(code: "US")
		let url = country.flagURL
		XCTAssertTrue(url.contains("flagcdn.com"))
		XCTAssertTrue(url.contains("us"))
		XCTAssertTrue(url.contains("h80"))
		XCTAssertTrue(url.contains("jpg"))
	}
	
	func testCountryInfo_FlagSquaredURL_ShouldReturnSquaredURL() {
		let country = CountryInfo(code: "US")
		let url = country.flagSquaredURL
		XCTAssertTrue(url.contains("vectorflags"))
		XCTAssertTrue(url.contains("us"))
		XCTAssertTrue(url.contains("square"))
	}
	
	func testCountryInfo_FlagVectorURL_ShouldReturnVectorURL() {
		let country = CountryInfo(code: "US")
		let url = country.flagVectorURL
		XCTAssertTrue(url.contains("us"))
		XCTAssertTrue(url.contains("svg"))
	}
	
	func testCountryInfo_FlagURLWithType_SmallFlat_ShouldReturnCorrectURL() {
		let country = CountryInfo(code: "US")
		let url = country.flagURL(type: .smallFlat)
		XCTAssertTrue(url.contains("flagcdn.com"))
		XCTAssertTrue(url.contains("h80"))
		XCTAssertTrue(url.contains("jpg"))
		XCTAssertTrue(url.contains("us"))
	}
	
	func testCountryInfo_FlagURLWithType_LargeFlat_ShouldReturnCorrectURL() {
		let country = CountryInfo(code: "US")
		let url = country.flagURL(type: .largeFlat)
		XCTAssertTrue(url.contains("flagcdn.com"))
		XCTAssertTrue(url.contains("h480"))
		XCTAssertTrue(url.contains("jpg"))
		XCTAssertTrue(url.contains("us"))
	}
	
	func testCountryInfo_FlagURLWithType_SmallWaving_ShouldReturnCorrectURL() {
		let country = CountryInfo(code: "US")
		let url = country.flagURL(type: .smallWaving)
		XCTAssertTrue(url.contains("flagcdn.com"))
		XCTAssertTrue(url.contains("128x96"))
		XCTAssertTrue(url.contains("png"))
		XCTAssertTrue(url.contains("us"))
	}
	
	func testCountryInfo_FlagURLWithType_LargeWaving_ShouldReturnCorrectURL() {
		let country = CountryInfo(code: "US")
		let url = country.flagURL(type: .largeWaving)
		XCTAssertTrue(url.contains("flagcdn.com"))
		XCTAssertTrue(url.contains("512x384"))
		XCTAssertTrue(url.contains("png"))
		XCTAssertTrue(url.contains("us"))
	}
	
	func testCountryInfo_FlagURLWithType_Squared_ShouldReturnCorrectURL() {
		let country = CountryInfo(code: "US")
		let url = country.flagURL(type: .squared)
		XCTAssertTrue(url.contains("vectorflags"))
		XCTAssertTrue(url.contains("us"))
		XCTAssertTrue(url.contains("square"))
	}
	
	func testCountryInfo_FlagURLWithType_Vector_ShouldReturnCorrectURL() {
		let country = CountryInfo(code: "US")
		let url = country.flagURL(type: .vector)
		XCTAssertTrue(url.contains("us"))
		XCTAssertTrue(url.contains("svg"))
	}
	
	func testCountryInfo_Locale_ShouldReturnLocaleWithLanguageAndCountry() {
		let country = CountryInfo(code: "US")
		let locale = country.locale
		XCTAssertTrue(locale.identifier.contains("US") || locale.identifier.contains("us"))
	}
	
	func testCountryInfo_Hashable_ShouldProduceConsistentHash() {
		let country1 = CountryInfo(code: "US")
		let country2 = CountryInfo(code: "US")
		var hasher1 = Hasher()
		var hasher2 = Hasher()
		country1.hash(into: &hasher1)
		country2.hash(into: &hasher2)
		XCTAssertEqual(hasher1.finalize(), hasher2.finalize())
	}
	
	func testCountryInfo_Equatable_WithSameISO2_ShouldBeEqual() {
		let country1 = CountryInfo(code: "US")
		let country2 = CountryInfo(code: "US")
		XCTAssertEqual(country1, country2)
	}
	
	func testCountryInfo_Equatable_WithDifferentCodes_ShouldNotBeEqual() {
		let country1 = CountryInfo(code: "US")
		let country2 = CountryInfo(code: "GB")
		XCTAssertNotEqual(country1, country2)
	}
	
	func testCountryInfo_Comparable_ShouldSortByName() {
		let country1 = CountryInfo(code: "US")
		let country2 = CountryInfo(code: "GB")
		let sorted = [country1, country2].sorted()
		XCTAssertTrue(sorted[0].name <= sorted[1].name)
	}
	
	func testCountryInfo_PrefetchData_ShouldCallCompletion() {
		let expectation = expectation(description: #function)
		CountryInfo.prefetchData {
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 10.0)
	}
}

class StringCountryInfoExtensionsTests: XCTestCase {
	
	func testString_CountryInfoAsCode_ShouldReturnCountryInfo() {
		let country = "US".countryInfoAsCode
		XCTAssertEqual(country.isoCode2, "US")
	}
	
	func testString_CountryInfoAsLanguage_ShouldReturnCountryInfo() {
		let country = "en".countryInfoAsLanguage
		XCTAssertEqual(country.languageCode, "en")
	}
	
	func testString_LanguageName_ShouldReturnLocalizedLanguageName() {
		let name = "en".languageName
		XCTAssertFalse(name.isEmpty)
	}
	
	func testString_LanguageName_WithInvalidCode_ShouldReturnEmpty() {
		let name = "xx".languageName
		XCTAssertTrue(name.isEmpty)
	}
}

class LocaleCountryInfoExtensionsTests: XCTestCase {
	
	func testLocale_LanguageName_ShouldReturnLocalizedLanguageName() {
		let locale = Locale(identifier: "en_US")
		let name = locale.languageName
		XCTAssertFalse(name.isEmpty)
	}
	
	func testLocale_CurrencyName_ShouldReturnLocalizedCurrencyName() {
		let locale = Locale(identifier: "en_US")
		let name = locale.currencyName
		if locale.currencyCode != nil {
			XCTAssertFalse(name.isEmpty)
		}
	}
	
	func testLocale_CurrencyNameAndCode_ShouldReturnFormattedString() {
		let locale = Locale(identifier: "en_US")
		let result = locale.currencyNameAndCode
		XCTAssertTrue(result.contains("("))
		XCTAssertTrue(result.contains(")"))
		if let currencyCode = locale.currencyCode {
			XCTAssertTrue(result.contains(currencyCode.uppercased()))
		}
	}
	
	func testLocale_CurrencyNameAndCode_WithNoCurrency_ShouldReturnEmptyCode() {
		let locale = Locale(identifier: "en")
		let result = locale.currencyNameAndCode
		XCTAssertTrue(result.contains("()"))
	}
	
	func testLocale_AvailableCountries_ShouldReturnNonEmptyArray() {
		let countries = Locale.availableCountries
		XCTAssertFalse(countries.isEmpty)
		XCTAssertTrue(countries.allSatisfy { !$0.name.isEmpty })
	}
	
	func testLocale_AvailableCountries_ShouldBeSorted() {
		let countries = Locale.availableCountries
		let sorted = countries.sorted()
		XCTAssertEqual(countries.map { $0.name }, sorted.map { $0.name })
	}
}

class ArrayCountryInfoExtensionsTests: XCTestCase {
	
	func testArray_Ranked_ShouldSortByRank() {
		let country1 = CountryInfo(code: "US")
		let country2 = CountryInfo(code: "GB")
		let country3 = CountryInfo(code: "AE")
		
		let countries = [country1, country2, country3]
		let ranked = countries.ranked
		XCTAssertEqual(ranked.count, countries.count)
		XCTAssertTrue(ranked[0].rank <= ranked[1].rank)
		if ranked.count > 2 {
			XCTAssertTrue(ranked[1].rank <= ranked[2].rank)
		}
	}
	
	func testArray_Ranked_WithMultipleCountries_ShouldMaintainAllCountries() {
		let country1 = CountryInfo(code: "US")
		let country2 = CountryInfo(code: "GB")
		
		let countries = [country1, country2]
		let ranked = countries.ranked
		XCTAssertEqual(ranked.count, 2)
		XCTAssertTrue(ranked.contains { $0.isoCode2 == "US" })
		XCTAssertTrue(ranked.contains { $0.isoCode2 == "GB" })
	}
	
	func testArray_Highlighting_ShouldReorderArray() {
		let countries = [
			CountryInfo(code: "GB"),
			CountryInfo(code: "US"),
			CountryInfo(code: "AE")
		]
		let highlighted = countries.highlighting()
		XCTAssertEqual(highlighted.count, countries.count)
	}
	
	func testArray_AllCountries_ShouldReturnNonEmptyArray() {
		let countries = Array<CountryInfo>.allCountries
		XCTAssertFalse(countries.isEmpty)
	}
	
	func testArray_AllCountries_ShouldContainValidCountries() {
		let countries = Array<CountryInfo>.allCountries
		XCTAssertTrue(countries.allSatisfy { !$0.isoCode2.isEmpty })
		XCTAssertTrue(countries.allSatisfy { !$0.name.isEmpty })
	}
}
