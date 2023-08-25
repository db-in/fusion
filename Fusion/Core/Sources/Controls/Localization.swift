//
//  Created by Diney Bomfim on 6/13/23.
//

import Foundation

// MARK: - Extension - NotificationCenter

public extension NotificationCenter {
	
	/// Posts a notification name on a given center with a specified object. This method is a shortcut for the underlaying post notification.
	///
	/// - Parameters:
	///   - name: The notification name.
	///   - object: The object associated with the notification. The default value is `nil`.
	///   - center: The center on which the notification will be posted. The default value is `default`.
	static func post(_ name: Notification.Name, object: Any? = nil, on center: NotificationCenter = .default) {
		center.post(name: name, object: object)
	}
}

// MARK: - Extension - Bundle

public extension Bundle {

// MARK: - Properties
	
	private static var cachedLanguages: [String : [Bundle]] = [:]
	
	/// Returns a combined collection of ``hints`` + `Bundle.allBundles` + `Bundle.allFrameworks`, in this given order.
	static var allAvailable: [Bundle] { hints + allBundles + allFrameworks }
	
	/// Hints are the first bundles to be scanned for loading contents. Including (but not limited to) languages, images, url, etc.
	static var hints: [Bundle] = []
	
// MARK: - Protected Methods
	
	/// Returns the language bundle inside this given bundle for a given language code, otherwise it returns ``nil``.
	///
	/// - Parameter languageCode: The language code for the desired language resource.
	/// - Returns: The bundle containing the language resource if found, otherwise ``nil``.
	func languages(for code: String) -> Bundle? {
		guard let resourcePath = path(forResource: code, ofType: "lproj") else { return nil }
		return .init(path: resourcePath)
	}
	
	/// Returns the language bundle resource for a given language code if it's found inside the application.
	/// This functions will utilize the ``sources`` available, otherwise it loops over all available bundles.
	///
	/// Any valid result will also be cached for future use.
	///
	/// - Parameter languageCode: The language code for the desired language resource.
	/// - Returns: The bundle containing the language resource if found, otherwise ``nil``.
	
	/// Recursively tries to find a valid localized string in ``allAvailable`` bundles.
	///
	/// - Parameters:
	///   - code: The language code alpha-2.
	///   - key: The localization key.
	///   - table: The string table file.
	/// - Returns: The resulting localized string.
	static func localizedString(for code: String, key: String, table: String?) -> String? {
		if let cached = cachedLanguages[code] {
			for bundle in cached {
				let value = bundle.localizedString(forKey: key, value: nil, table: table)
				guard !value.isUntranslated else { continue }
				return value
			}
		}
		
		for bundle in allAvailable {
			guard let languageBundle = bundle.languages(for: code) else { continue }
			let value = languageBundle.localizedString(forKey: key, value: nil, table: table)
			guard !value.isUntranslated else { continue }
			cachedLanguages[code, default: []].appendOnce(languageBundle)
			return value
		}
		
		return nil
	}
}

// MARK: - Extension - Bundle

public extension String {

// MARK: - Properties
	
	private static var tableKey: UInt8 = 1
	
	/// Localizable Table strings.
	static let localizableTable = "Localizable.nocache"
	
	/// Returns the original key. This property can be called at any given time in any given string.
	/// This property remains the same even after multiple localization processes.
	/// A `nil` is returned if the original key is the current value
	var originalKey: String? {
		get { objc_getAssociatedObject(self, &String.tableKey) as? String }
		set { objc_setAssociatedObject(self, &String.tableKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
	}
	
	/// Returns true if the string is untranslated. It can be untranslated for various reasons, including but not limited to
	/// missing files, missing keys, missing bundles, missing languages, etc.
	var isUntranslated: Bool { isEmpty || originalKey == self }
	
// MARK: - Protected Methods
	
// MARK: - Exposed Methods
	
	/// Alias for `localized()` function
	///
	/// - Parameter language: A given language to be used. By default it's `currentLanguage`
	/// - Returns: The localized version of the string key or the key itself
	func callAsFunction(language: String = Locale.preferredLanguageCodeISO2) -> String { localized(for: language) }
	
	/// Localized string version, using the cached loaded bundle for the current defined language.
	///
	/// - Parameter locale: The iso code for the given locale, matching a valid language folder (lproj).
	/// - Returns: The localized string
	func localized(for locale: String = Locale.preferredLanguageCodeISO2) -> String {
		guard var string = Bundle.localizedString(for: locale, key: self, table: .localizableTable) else { return self }
		string.originalKey = originalKey ?? self
		return string.replacingOccurrences(of: "amp;", with: "").replacingOccurrences(of: "\\", with: "")
	}
	
	/// This function will find and replace placeholders inside a string with other values, the placeholders can be named of unnamed.
	///
	/// ```
	/// "{KG}kg is equal {gr}g".replace(["5", "5000"]) // results in "5kg is equal 5000g"
	/// ```
	///
	/// ```
	/// let string = "{KG}kg is equal {gr}g"
	/// string.replace(["5000", "5"], placeholders: ["{KG}", "{gr}"]) // results in "5kg is equal 5000g"
	/// ```
	///
	/// - Parameters:
	///   - template: An array containing the actual values to be replaced
	///   - placeholders: An array containing the named placeholders. Ommiting this parameter takes advantage of default placeholders.
	/// - Returns: A string with placeholders being replaced.
	func replacing(with template: [String], placeholders: [String]? = nil) -> String {
		
		let suffix = placeholders != nil ? "?" : ""
		let elements = placeholders ?? Array(repeating: "{.*?}", count: template.count)
		let pattern = elements.map { string -> String in
			var item = string.replacingOccurrences(of: "{", with: "\\{")
			item = item.replacingOccurrences(of: "}", with: "\\}")
			
			return "(.*?)\(item)(.*\(suffix))"
		}
		
		let newString = pattern.enumerated().reduce (self) { result, string in
			result.replacingOccurrences(of: string.element, with: "$1\(template[string.offset])$2", options: .regularExpression)
		}
		
		return newString
	}
	
	/// Replaces the default placeholders in a given string with the new values.
	///
	/// - Parameter template: The new values.
	/// - Returns: A string with the replaces values.
	func replacing(_ template: String...) -> String {
		replacing(with: template)
	}
}

// MARK: - Extension - Locale

public extension Locale {

// MARK: - Properties
	
	private static var preferredLanguage: String { Locale.preferredLanguages.first ?? "en" }
	
	/// Standard UTC/GMT locale.
	static var utc: Locale { Locale(identifier: "UTC") }
	
	/// Returns the current language code ISO 3166-2 format (2 alpha codes) in lower case. For example `"en"`.
	static var preferredLanguageCodeISO2: String { "\(preferredLanguage.prefix(2))".lowercased() }
	
	/// Returns the language code in ISO 639-1 format (2 alpha codes).
	var languageCodeISO2: String {
		if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
			return language.languageCode?.identifier.prefix(2).lowercased() ?? ""
		} else {
			return languageCode?.prefix(2).lowercased() ?? ""
		}
	}
	
	/// Returns the region code in ISO 3166-2 format (2 alpha codes).
	var regionCodeISO2: String {
		if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
			return region?.identifier.prefix(2).lowercased() ?? ""
		} else {
			return regionCode?.prefix(2).lowercased() ?? ""
		}
	}
	
	/// Returns true if the given locale has a language code that belong to right to left direction.
	var isRTL: Bool {
		if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
			return language.characterDirection != .leftToRight
		} else {
			return Locale.characterDirection(forLanguage: languageCode ?? "") != .leftToRight
		}
	}
	
	/// A dictionary that groups locales by their currency code.
	static let currencyGroups: [String : [Locale]] = {
		let allLocales = Locale.availableIdentifiers.map(Locale.init)
		if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
			return .init(grouping: allLocales) { ($0.currency?.identifier ?? "").uppercased() }
		} else {
			return .init(grouping: allLocales) { ($0.currencyCode ?? "").uppercased() }
		}
	}()
	
	/// Initializes a Locale instance based on the provided currency code.
	///
	/// - Parameter currencyCode: The currency code to use for initializing the Locale.
	/// - Parameter languageCode: A given language to be used as hint in the search. Serves only as hint and not guarantee.
	/// - Returns: A Locale instance that matches the provided currency code, or nil if no match is found.
	init?(currencyCode: String, languageCode: String = Locale.preferredLanguageCodeISO2) {
		let locales = Locale.currencyGroups[currencyCode.uppercased()]
		guard let locale = locales?.first(where: { $0.languageCodeISO2 == languageCode }) ?? locales?.first else { return nil }
		self = locale
	}
	
	/// Creates a new locale by keeping the same region but replacing the language.
	///
	/// - Parameter language: A new language code. The default is ``preferredLanguageCodeISO2``
	/// - Returns: A new Locale.
	func adjusted(language: String = Locale.preferredLanguageCodeISO2) -> Self { .init(identifier: "\(language.lowercased())_\(regionCodeISO2)") }
}
