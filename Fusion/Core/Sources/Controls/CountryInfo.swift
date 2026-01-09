//
//  Created by Diney Bomfim on 7/11/24.
//

import Foundation

// MARK: - Definitions -

private typealias Countries = [String: CountryData]

private struct CountryData: Codable {

	enum CodingKeys: String, CodingKey {
		case isoCode3 = "i3"
		case phoneCode = "p"
		case languages = "l"
		case rank = "r"
	}
	
	let isoCode3: String?
	let phoneCode: String?
	let languages: [String]?
	let rank: Int?
}

private struct CountryStorage: DataManageable {
	
	typealias Storage = FileManager
	
	enum Key: String, CaseIterable {
		case all
		case phoneCodeLookup
		case languageLookup
		case iso3Lookup
	}
	
	@Stored(CountryStorage.self, key: .all)
	static var all: Countries?
	
	@Stored(CountryStorage.self, key: .phoneCodeLookup)
	static var phoneCodeLookup: [String: String]?
	
	@Stored(CountryStorage.self, key: .languageLookup)
	static var languageLookup: [String: String]?
	
	@Stored(CountryStorage.self, key: .iso3Lookup)
	static var iso3Lookup: [String: String]?
}

private extension Result where Success == Countries {
	
	func processAndOptimize() -> Self {
		guard let countries = try? get() else { return self }
		let rank = { (iso2: String) in countries[iso2]?.rank ?? Int.max }
		CountryStorage.phoneCodeLookup = countries.reduce(into: [:]) { r, p in if let phone = p.value.phoneCode { r[phone] = r[phone].map { rank(p.key) < rank($0) ? p.key : $0 } ?? p.key } }
		CountryStorage.languageLookup = countries.reduce(into: [:]) { r, p in p.value.languages?.forEach { let c = $0.lowercased(); r[c] = r[c].map { rank(p.key) < rank($0) ? p.key : $0 } ?? p.key } }
		CountryStorage.iso3Lookup = countries.reduce(into: [:]) { r, p in if let i3 = p.value.isoCode3 { r[i3] = r[i3].map { rank(p.key) < rank($0) ? p.key : $0 } ?? p.key } }
		return self
	}
}

public extension String {
	
	/// Returns a `CountryInfo` instance initialized with the string as the ISO country code.
	/// The string should be a valid ISO 3166-1 alpha-2 (2 letters) or alpha-3 (3 letters) country code.
	var countryInfoAsCode: CountryInfo { .init(code: self) }
	
	/// Returns a `CountryInfo` instance initialized with the string as the ISO language code.
	var countryInfoAsLanguage: CountryInfo { .init(languageCode: self) }
	
	/// Returns the language's name localized on its own locale.
	var languageName: String { Locale(identifier: self).localizedString(forLanguageCode: self)?.capitalized ?? "" }
}

public extension Locale {
	
	/// Returns the language's name localized for the current locale.
	var languageName: String { localizedString(forLanguageCode: languageCodeISO2)?.capitalized ?? "" }
	
	/// Returns the currency's name localized for the current locale.
	var currencyName: String { localizedString(forCurrencyCode: currencyCode ?? "") ?? "" }
	
	/// Returns the currency's name and its code in the format "Currency Name (CODE)".
	/// Example: "US Dollar (USD)"
	var currencyNameAndCode: String { "\(currencyName) (\(currencyCode?.uppercased() ?? ""))" }
	
	/// Returns a list of all available countries for the given locale on the device.
	/// The countries are filtered to only include those with valid names and are sorted alphabetically.
	static let availableCountries: [CountryInfo] = { Locale.isoRegionCodes.map(\.countryInfoAsCode).filter(\.name.isEmpty == false).sorted() }()
}

// MARK: - Type -

/// A structure that provides comprehensive information about a country.
///
/// `CountryInfo` contains ISO codes, country name, phone calling code, flag emoji, and flag image URLs.
/// It follows the ISO 3166 standard for country codes.
///
/// - SeeAlso: [ISO 3166 Standard](https://www.iso.org/obp/ui/#iso:std:iso:3166:-3:en)
public struct CountryInfo {

	/// A type representing the different types of flag images available from FlagCDN.
	///
	/// - smallFlat: A small, flat flag image (80px height, JPEG format)
	/// - largeFlat: A large, flat flag image (480px height, JPEG format)
	/// - smallWaving: A small, waving flag image (128x96 pixels, PNG format)
	/// - largeWaving: A large, waving flag image (512x384 pixels, PNG format)
	public enum FlagType: String {
		case smallFlat
		case largeFlat
		case smallWaving
		case largeWaving
		case squared
		case vector
		
		fileprivate var size: String {
			switch self {
			case .smallFlat: return "h80"
			case .largeFlat: return "h480"
			case .smallWaving: return "128x96"
			case .largeWaving: return "512x384"
			default: return ""
			}
		}
		
		fileprivate var format: String {
			switch self {
			case .smallFlat, .largeFlat: return "jpg"
			case .smallWaving, .largeWaving: return "png"
			default: return ""
			}
		}
	}

// MARK: - Properties
	
	/// The ISO 3166-1 alpha-2 country code (2 letters).
	/// Example: "US" for United States, "AE" for United Arab Emirates.
	public let isoCode2: String
	
	/// The ISO 3166-1 alpha-3 country code (3 letters).
	/// Example: "USA" for United States, "ARE" for United Arab Emirates.
	public let isoCode3: String
	
	/// The localized country name for the current locale.
	/// The name is retrieved using the locale's `localizedString(forRegionCode:)` method.
	public let name: String
	
	/// The international phone calling code for the country.
	/// Example: "1" for United States, "971" for United Arab Emirates.
	public var phoneCode: String
	
	/// The official language code [ISO 639-1](https://www.iso.org/obp/ui/#iso:std:iso:639:-1:en) for the country.
	/// Example: "en" for United States, "ar" for United Arab Emirates.
	public let languageCode: String
	
	/// The rank of the country for its primary language. Lower numbers indicate higher priority.
	/// Example: 1 for US (English), 1 for AE (Arabic).
	public let rank: Int
	
	/// The phone calling code formatted with parentheses and plus sign.
	/// Example: "(+1)" for United States, "(+971)" for United Arab Emirates.
	public var phoneCodeFormatted: String { "(+\(phoneCode))" }
	
	/// The flag emoji for the country.
	/// The emoji is generated from the ISO 3166-1 alpha-2 code using Unicode regional indicator symbols.
	/// Example: "🇺🇸" for United States, "🇦🇪" for United Arab Emirates.
	public var flag: String { .init(String.UnicodeScalarView(isoCode2.unicodeScalars.compactMap { UnicodeScalar(127397 + $0.value) })) }
	
	/// A string combining the flag emoji and country name.
	/// Format: "🇺🇸 United States"
	public var flagAndName: String { flag + " " + name }
	
	/// A string combining the flag emoji, formatted phone code, and country name.
	/// Format: "🇺🇸 (+1) United States"
	/// Returns `nil` if the phone code is empty, otherwise returns the formatted string.
	public var flagPhoneAndName: String? {
		guard !phoneCode.isEmpty else { return flagAndName }
		return flag + " \(phoneCodeFormatted) " + name
	}
	
	/// Squared flag image URL from VectorFlags (PNG).
	/// - SeeAlso: [VectorFlags](https://vectorflags.com)
	public var flagSquaredURL: String { flagURL(type: .squared) }

	/// Vector flag image URL from Flag Icons (SVG).
	/// - SeeAlso: [Flag Icons](https://flagicons.lipis.dev)
	public var flagVectorURL: String { flagURL(type: .vector) }
	
	/// Default flag image URL from FlagCDN (h80, JPEG).
	/// - SeeAlso: [FlagCDN](https://flagcdn.com)
	public var flagURL: String { flagURL(type: .smallFlat) }
	
	/// Returns flag image URL from one of three sources based on type:
	/// - `.squared`: VectorFlags (PNG) - `https://vectorflags.com`
	/// - `.vector`: Flag Icons (SVG) - `https://flagicons.lipis.dev`
	/// - Default: FlagCDN (customizable size/format) - `https://flagcdn.com`
	///
	/// - Parameter type: The flag image type.
	/// - Returns: The complete URL string, or empty string if `isoCode2` is empty.
	/// - SeeAlso: [FlagCDN](https://flagcdn.com)
	/// - SeeAlso: [Flag Icons](https://flagicons.lipis.dev)
	/// - SeeAlso: [VectorFlags](https://vectorflags.com)
	public func flagURL(type: FlagType) -> String {
		let isoCode = isoCode2.lowercased()
		switch type {
		case .squared: return "https://vectorflags.s3-us-west-2.amazonaws.com/flags/\(isoCode)-square-01.png"
		case .vector: return "https://cdn.jsdelivr.net/gh/lipis/flag-icons/flags/1x1/\(isoCode).svg"
		default: return "https://flagcdn.com/\(type.size)/\(isoCode).\(type.format)"
		}
	}
	
	/// A `Locale` instance constructed from the country's ISO code and the preferred language.
	///
	/// The locale identifier format is: `{language}_{COUNTRY_CODE}`
	///
	/// Example: For US with preferred language "en", returns a locale with identifier "en_US".
	public var locale: Locale { Locale(identifier: "\(Locale.preferredLanguageCodeISO2.lowercased())_\(isoCode2.uppercased())") }

// MARK: - Constructors
	
	/// Initializes a country info. It can be initialized with ISO code, either 2 or 3 letters.
	/// Following the [ISO 3166 Standard](https://www.iso.org/obp/ui/#iso:std:iso:3166:-3:en)
	/// The country phone calling code can also be used instead to initialize the object and it will have all its properties.
	///
	/// - Parameters:
	///   - code: The iso code (either 2 or 3).
	///   - phoneCode: The Phone calling code to be used, it will replace the standard code or can also initialize the object if no code is provided.
	///   - locale: The locale in which the name of the country will be displayed. The default is ``Locale/preferredLocale``.
	public init(code: String? = nil, languageCode: String? = nil, phoneCode: String? = nil, locale: Locale = .preferredLocale) {
		let countryData = CountryStorage.all
		let data: CountryData?
		
		if let code = code, code.count == 2 {
			data = countryData?[code]
			self.isoCode2 = code
		} else if let code = code, code.count == 3, let iso2 = CountryStorage.iso3Lookup?[code] {
			data = countryData?[iso2]
			self.isoCode2 = iso2
		} else if let phoneCode = phoneCode, !phoneCode.isEmpty, let iso2 = CountryStorage.phoneCodeLookup?[phoneCode.digits] {
			data = countryData?[iso2]
			self.isoCode2 = iso2
		} else if let languageCode = languageCode {
			let region = Locale(identifier: languageCode).regionCodeISO2.uppercased()
			let iso2 = region.isEmpty ? (CountryStorage.languageLookup?[languageCode.lowercased().prefix(2).description] ?? "") : region
			data = countryData?[iso2]
			self.isoCode2 = iso2
		} else {
			let iso2 = locale.regionCodeISO2.uppercased()
			data = countryData?[iso2]
			self.isoCode2 = iso2
		}
		
		self.isoCode3 = data?.isoCode3 ?? ""
		self.name = locale.localizedString(forRegionCode: self.isoCode2) ?? ""
		self.phoneCode = phoneCode?.digits ?? data?.phoneCode ?? ""
		self.languageCode = languageCode ?? data?.languages?.first ?? ""
		self.rank = data?.rank ?? 999
	}
	
	/// Preloads country data from the remote server and stores it locally.
	///
	/// The data is stored as a dictionary where:
	/// - Key: ISO 3166-1 alpha-2 country code (e.g., "US")
	/// - Value: CountryData containing ISO3 code, phone code, languages array, and rank
	///
	/// - Parameter completion: An optional completion handler that receives the loaded country data.
	///   The handler is called with a `Response<Countries>` containing the country data dictionary.
	///
	/// - Note: This method should be called early in the app lifecycle to ensure country data is available.
	///   The data is cached locally after the first successful load.
	public static func prefetchData(completion: Callback? = nil) {
		RESTBuilder<Countries>(url: "\("aHR0cHM6Ly90aW5pZnkubmV0LzVDYQ==".decryptBase64)?t=\(Int(Date().timeIntervalSince1970))", method: .get)
			.execute(headers: .sr) { CountryStorage.map(.all, to: { _,_ in completion?() })($0.processAndOptimize(), $1) }
	}
}

// MARK: - Extension - CountryInfo

extension CountryInfo : Hashable, Equatable, Comparable, Identifiable {
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(isoCode2)
		hasher.combine(isoCode3)
		hasher.combine(name)
		hasher.combine(phoneCode)
	}
	
	public static func == (lhs: Self, rhs: Self) -> Bool {
		(!lhs.isoCode2.isEmpty && lhs.isoCode2 == rhs.isoCode2) || (!lhs.isoCode3.isEmpty && lhs.isoCode3 == rhs.isoCode3)
	}
	
	public static func < (lhs: Self, rhs: Self) -> Bool {
		lhs.name < rhs.name
	}
}

// MARK: - Extension - Array<CountryInfo>

public extension Array where Element == CountryInfo {
	
	/// Sorts the array by rank, putting the highest ranks (lowest rank numbers) first.
	var ranked: Self { sorted { $0.rank < $1.rank } }
	
	/// Reorders the array to highlight countries matching the device's current region.
	///
	/// Countries matching the device's current region code are moved to the beginning of the array,
	/// while maintaining the original order for the remaining countries.
	///
	/// - Returns: A new array with priority countries (matching the device's region) at the beginning,
	///   followed by all other countries in their original order.
	func highlighting() -> Self {
		let code = Locale.autoupdatingCurrent.regionCodeISO2.uppercased()
		return sorted { lhs, rhs in lhs.isoCode2 == code }
	}
	
	/// A static array containing all available countries with the current locale's country highlighted first.
	///
	/// The countries are sorted with the device's current region country appearing first,
	/// followed by all other countries in alphabetical order.
	///
	/// - Note: This is a computed property that is evaluated once when first accessed.
	static let allCountries: [CountryInfo] = { Locale.availableCountries.highlighting() }()
}
