//
//  Created by Diney Bomfim on 6/13/23.
//

import Foundation

#if canImport(UIKit) && (os(iOS) || os(visionOS) || os(tvOS))
import UIKit
#elseif canImport(AppKit) && os(macOS)
import AppKit
#endif

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
	
	/// Alias for ``localized(for:table:count:)`` function.
	///
	/// - Parameters:
	///   - language: A given language to be used. By default it's `currentLanguage`
	///   - count: Optional count value used for pluralization via `.stringsdict` files. If `nil`, returns regular localized string.
	/// - Returns: The localized version of the string key (pluralized if count is provided) or the key itself
	func callAsFunction(language: String = Locale.preferredLanguage, count: Int? = nil) -> String { localized(for: language, count: count) }
	
	/// Localized string version, using the a high `speed dynamic loading algorithm` - ``localizedString(language:key:table:)`` -
	/// for the `current preferred language` - ``preferredLanguage``.
	/// Supports pluralization via `.stringsdict` files when `count` is provided.
	///
	/// - Parameters:
	///   - locale: The iso code for the given locale, matching a valid language folder (lproj).
	///   - table: The string table file. Defaults to `Localizable.nocache`.
	///   - count: Optional count value used for pluralization. If `nil`, returns regular localized string.
	/// - Returns: The localized string (pluralized if count is provided)
	/// - SeeAlso: ``localizedString(language:key:table:)`` and ``preferredLanguage``.
	func localized(for locale: String = Locale.preferredLanguage, table: String? = .localizableTable, count: Int? = nil) -> String {
		guard var string = Bundle.localizedString(language: locale, key: self, table: table) else { return self }
		if let count = count { string = String.localizedStringWithFormat(string, count) }
		string.originalKey = originalKey ?? self
		return string.replacingOccurrences(of: "amp;", with: "").replacingOccurrences(of: "\\", with: "")
	}
}

// MARK: - Extension - Locale

public extension Locale {

// MARK: - Properties
	
	/// Standard UTC/GMT locale.
	static var utc: Locale { Locale(identifier: "UTC") }
	
	/// Returns the preferred language code in ISO 639-1 format (2 alpha codes) in lower case. For example `"en"`.
	/// - SeeAlso: [ISO 639-1](https://en.wikipedia.org/wiki/ISO_639-1)
	static var preferredLanguage: String { Locale.preferredLanguages.first(where: { Bundle.languageSet.contains($0) }) ?? "en" }

	/// Returns the preferred language code in ISO 639-1 format (2 alpha codes) in lower case. For example `"en"`.
	/// - SeeAlso: [ISO 639-1](https://en.wikipedia.org/wiki/ISO_639-1)
	static var preferredLanguageCodeISO2: String { "\(preferredLanguage.prefix(2))".lowercased() }
	
	/// Returns the current preferred locale.
	static var preferredLocale: Locale { Locale(identifier: preferredLanguage) }
	
	/// Returns the language identifier in BCP 47 format (language-region).
	/// Example: "ar-AE", "en-US", "de-DE". Returns only language code if region is not available.
	/// Suitable for use with AppleLanguages UserDefaults key.
	/// - SeeAlso: [BCP 47](https://en.wikipedia.org/wiki/BCP_47)
	var languageIdentifier: String {
		if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
			return language.languageCode?.identifier ?? ""
		} else {
			return languageCode ?? ""
		}
	}
	
	/// Returns the language code in ISO 639-1 format (2 alpha codes).
	/// - SeeAlso: [ISO 639-1](https://en.wikipedia.org/wiki/ISO_639-1)
	var languageCodeISO2: String { languageIdentifier.prefix(2).lowercased() }
	
	/// Returns the region identifier in BCP 47 format (region subtag).
	/// Example: "US", "DE", "AE". Returns an empty string if region is not available.
	/// Suitable for use with AppleLanguages UserDefaults key and locale construction.
	/// - SeeAlso: [BCP 47](https://en.wikipedia.org/wiki/BCP_47)
	var regionIdentifier: String {
		if #available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *) {
			return region?.identifier ?? ""
		} else {
			return regionCode ?? ""
		}
	}

	/// Returns the region code in ISO 3166-1 alpha-2 format (2 alpha codes).
	/// - SeeAlso: [ISO 3166-1](https://en.wikipedia.org/wiki/ISO_3166-1)
	var regionCodeISO2: String { regionIdentifier.prefix(2).lowercased() }
	
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
	init?(currencyCode: String, languageCode: String = Locale.preferredLanguage) {
		let locales = Locale.currencyGroups[currencyCode.uppercased()]
		guard let locale = locales?.first(where: { languageCode.contains($0.languageCodeISO2) }) ?? locales?.first else { return nil }
		self = locale
	}
	
	/// Creates a new locale by keeping the same region but replacing the language.
	///
	/// - Parameter language: A new language code. The default is ``preferredLanguageCodeISO2``
	/// - Returns: A new Locale.
	func adjusted(language: String = Locale.preferredLanguageCodeISO2) -> Self { .init(identifier: "\(language.lowercased())_\(regionCodeISO2)") }
}

// MARK: - Extension - String

public extension String {
	
	func setAsPreferredLanguage() {
		let locale = countryInfoAsLanguage.locale
		let isRTL = locale.isRTL
		
#if canImport(UIKit) && (os(iOS) || os(visionOS))
		let direction: UISemanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight
		UIView.appearance().semanticContentAttribute = direction
		UIWindow.key?.semanticContentAttribute = direction
#elseif canImport(UIKit) && os(tvOS)
		let direction: UISemanticContentAttribute = isRTL ? .forceRightToLeft : .forceLeftToRight
		UIView.appearance().semanticContentAttribute = direction
#endif
		
		UserDefaults.standard.set([self], forKey: "AppleLanguages")
		UserDefaults.standard.synchronize()
	}
}
