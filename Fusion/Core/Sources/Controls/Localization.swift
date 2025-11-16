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
	
	/// Hints are the first bundles to be scanned for loading contents. Including (but not limited to) languages, images, url, etc.
	static var hints: [Bundle] = []
	
	/// Returns a combined collection of `Bundle.allBundles` + `Bundle.allFrameworks`, in this given order.
	static var allOthers: [Bundle] { allBundles + allFrameworks }
	
	/// Returns a combined collection of ``hints`` + `Bundle.allBundles` + `Bundle.allFrameworks`, in this given order.
	static var allAvailable: [Bundle] { hints + allOthers }
	
	static var languageSet: Set<String> = { Set(main.localizations) }()
	
// MARK: - Protected Methods
	
	/// Returns the language bundle inside this given bundle for a given language code, otherwise it returns `nil`.
	///
	/// - Parameter languageCode: The language code for the desired language resource.
	/// - Returns: The bundle containing the language resource if found, otherwise `nil`.
	func languages(for code: String) -> Bundle? {
		guard let resourcePath = path(forResource: code, ofType: "lproj") else { return nil }
		return .init(path: resourcePath)
	}
	
	/// Returns a localized string for the specified key and table.
	///
	/// - Parameters:
	///   - key: The key for a string in the specified table.
	///   - table: The receiver's string table to search.
	/// - Returns: A localized version of the string, or `nil` if the key is not found.
	func localizedString(forKey key: String, table: String?) -> String? {
		let value = localizedString(forKey: key, value: nil, table: table)
		return !(value.isEmpty || value == key) ? value : nil
	}
	
	/// Returns a localized string for the specified language code, key, and table.
	///
	/// - Parameters:
	///   - language: The language code alpha-2.
	///   - key: The key for a string in the specified table.
	///   - table: The receiver's string table to search.
	/// - Returns: A localized version of the string designated by `key`, `table`, and the language `code`, or `nil` if the key is not found.
	func localizedString(language: String, key: String, table: String?) -> String? {
		guard
			let languageBundle = languages(for: language),
			let value = languageBundle.localizedString(forKey: key, table: table)
		else { return nil }
		Self.cachedLanguages[language, default: []].appendOnce(languageBundle)
		return value
	}
	
	/// Recursively tries to find the first valid localized string in ``allAvailable`` bundles, leveraging the speed of ``hints`` bundles.
	///
	/// - Parameters:
	///   - language: The language code alpha-2.
	///   - key: The localization key.
	///   - table: The string table file.
	/// - Returns: The resulting localized string.
	/// - Important: This function utilizes caching to optimize
	/// subsequent reads of the same language or key. The cache can't be clean programatically as it relies on the string file table naming
	/// convention, utilizing `nocache` to avoid strong caching.
	/// - SeeAlso: [Apple Loading String Resources Documentation](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/LoadingResources/Strings/Strings.html#//apple_ref/doc/uid/10000051i-CH6-97055-CJBFDJGF)
	static func localizedString(language: String, key: String, table: String?) -> String? {
		let value = cachedLanguages[language]?.firstMap({ $0.localizedString(forKey: key, table: table) })
		return value ?? allAvailable.firstMap({ $0.localizedString(language: language, key: key, table: table) })
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
	
// MARK: - Protected Methods
	
// MARK: - Exposed Methods
	
	/// Alias for ``localized(for:table:)`` function.
	///
	/// - Parameter language: A given language to be used. By default it's `currentLanguage`
	/// - Returns: The localized version of the string key or the key itself
	func callAsFunction(language: String = Locale.preferredLanguageCodeISO2) -> String { localized(for: language) }
	
	/// Localized string version, using the a high `speed dynamic loading algorithm` - ``localizedString(language:key:table:)`` -
	/// for the `current preferred language` - ``preferredLanguageCodeISO2``.
	///
	/// - Parameter locale: The iso code for the given locale, matching a valid language folder (lproj).
	/// - Returns: The localized string
	/// - SeeAlso: ``localizedString(language:key:table:)`` and ``preferredLanguageCodeISO2``.
	func localized(for locale: String = Locale.preferredLanguageCodeISO2, table: String? = .localizableTable) -> String {
		guard var string = Bundle.localizedString(language: locale, key: self, table: table) else { return self }
		string.originalKey = originalKey ?? self
		return string.replacingOccurrences(of: "amp;", with: "").replacingOccurrences(of: "\\", with: "")
	}
}

// MARK: - Extension - Locale

public extension Locale {

// MARK: - Properties
	
	private static var preferredLanguage: String { Locale.preferredLanguages.first(where: { Bundle.languageSet.contains($0.prefix(2).lowercased()) }) ?? "en" }
	
	/// Standard UTC/GMT locale.
	static var utc: Locale { Locale(identifier: "UTC") }
	
	/// Returns the current language code ISO 3166-2 format (2 alpha codes) in lower case. For example `"en"`.
	static var preferredLanguageCodeISO2: String { "\(preferredLanguage.prefix(2))".lowercased() }
	
	/// Returns the current preferred locale.
	static var preferredLocale: Locale { Locale(identifier: preferredLanguageCodeISO2) }
	
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
