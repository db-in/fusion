//
//  Created by Diney Bomfim on 6/13/23.
//

import Foundation

// MARK: - Definitions -

public extension Collection {
	
	/// Returns the first non-nil result by applying the provided closure to each element.
	/// This function iterates through the elements and applies the closure. It returns the first non-nil result, or `nil` if no result is found.
	///
	/// ```
	/// let numbers = [1, 2, 3, 4, 5]
	/// if let even = numbers.firstMap({ $0 % 2 == 0 ? "Even" : nil }) {
	///     print(even) // Output: "Even"
	/// }
	/// ```
	///
	/// - Parameter transform: A closure that maps an element to an optional value.
	/// - Returns: The first non-nil result obtained by applying the closure, or `nil` if no result is found.
	/// - Complexity: O(n), where n is the number of elements in the collection.
	func firstMap<T>(_ transform: (Element) -> T?) -> T? {
		for element in self {
			guard let mapped = transform(element) else { continue }
			return mapped
		}
		return nil
	}
}

public extension Bundle {

// MARK: - Properties
	
	private static var cachedBundles: [String : Bundle] = [:]
	
	/// Returns a combined collection of `Bundle.allBundles` + `Bundle.allFrameworks`
	static var allAvailable: [Bundle] { allBundles + allFrameworks }
	
	/// Defines a set of bundle targets for each language.
	/// For example:
	///
	/// ```
	/// Bundle.sources = ["en" : .main, "fr" : anotherBundle]
	/// ```
	static var sources: [String : Bundle] = [:]
	
// MARK: - Protected Methods
	
	/// Returns the language bundle inside this given bundle for a given language code, otherwise it returns ``nil``.
	///
	/// - Parameter languageCode: The language code for the desired language resource.
	/// - Returns: The bundle containing the language resource if found, otherwise ``nil``.
	func languages(for languageCode: String) -> Bundle? {
		guard let resourcePath = path(forResource: languageCode, ofType: "lproj") else { return nil }
		return .init(path: resourcePath)
	}
	
	/// Returns the language bundle resource for a given language code if it's found inside the application.
	/// This functions will utilize the ``sources`` available, otherwise it loops over all available bundles.
	///
	/// Any valid result will also be cached for future use.
	///
	/// - Parameter languageCode: The language code for the desired language resource.
	/// - Returns: The bundle containing the language resource if found, otherwise ``nil``.
	static func languages(for languageCode: String) -> Bundle? {
		if let cached = cachedBundles[languageCode] {
			return cached
		}
		
		guard
			let bundle = sources[languageCode]?.languages(for: languageCode) ?? allAvailable.firstMap({ $0.languages(for: languageCode) })
		else { return languageCode != "en" ? languages(for: "en") : nil }
		
		cachedBundles[languageCode] = bundle
		
		return bundle
	}
}

// MARK: - Type -

public extension Locale {

// MARK: - Properties
	
	private static var preferredLanguage: String { Locale.preferredLanguages.first ?? "en" }
	
	/// Standard UTC/GMT locale.
	static var utc: Locale { Locale(identifier: "UTC") }
	
	/// Returns the current langauge code in lower case. For example `"en"`.
	static var currentLanguage: String { "\(preferredLanguage.prefix(2))".lowercased() }
	
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
	/// - Returns: A Locale instance that matches the provided currency code, or nil if no match is found.
	init?(currencyCode: String) {
		guard let locale = Locale.currencyGroups[currencyCode.uppercased()]?.first else { return nil }
		self = locale
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
		get { return objc_getAssociatedObject(self, &String.tableKey) as? String }
		set { objc_setAssociatedObject(self, &String.tableKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
	}
	
// MARK: - Protected Methods
	
// MARK: - Exposed Methods
	
	/// Alias for `localized()` function
	///
	/// - Parameter language: A given language to be used. By default it's `currentLanguage`
	/// - Returns: The localized version of the string key or the key itself
	func callAsFunction(language: String = Locale.currentLanguage) -> String { localized(for: language) }
	
	/// Localized string version, using the cached loaded bundle for the current defined language.
	///
	/// - Parameter locale: The iso code for the given locale, matching a valid language folder (lproj).
	/// - Returns: The localized string
	func localized(for locale: String = Locale.currentLanguage) -> String {
		guard let bundle = Bundle.languages(for: locale) else { return self }
		var string = bundle.localizedString(forKey: self, value: nil, table: .localizableTable)
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
