//
//  Created by Diney Bomfim on 5/7/23.
//

import Foundation

// MARK: - Definitions -

public func == <T, V: Equatable>(lhs: KeyPath<T, V>, rhs: V) -> (T) -> Bool { { $0[keyPath: lhs] == rhs } }

public func != <T, V: Equatable>(lhs: KeyPath<T, V>, rhs: V) -> (T) -> Bool { { $0[keyPath: lhs] != rhs } }

public extension KeyPath {
	
	/// Returns a string keypath representation of keypath.
	var stringValue: String { "\(self)".replacing(regex: ".*?\\.(.*)", with: "$1") }
}

// MARK: - Extension - Bundle

public extension Bundle {
	
	static func url(named: String, bundle: Bundle) -> URL? {
		bundle.url(forResource: named, withExtension: nil) ?? Bundle.allAvailable.firstMap({ $0.url(forResource: named, withExtension: nil) })
	}
}

// MARK: - Extension - DateFormatter

public extension DateFormatter {
	
	static var validFormats = ["yyyy-MM-dd'T'HH:mm:ss.SSSZ", "yyyy-MM-dd'T'HH:mm:ssZ"]
	
	static var utc: DateFormatter {
		let formatter = DateFormatter()
		formatter.calendar = Calendar(identifier: .iso8601)
		formatter.timeZone = TimeZone(secondsFromGMT: 0)
		formatter.locale = Locale(identifier: "en_US_POSIX")
		return formatter
	}
	
	static func date(from: String) -> Date {
		let formatter = DateFormatter.utc
		
		for format in validFormats {
			formatter.dateFormat = format
			guard let date = formatter.date(from: from) else { continue }
			return date
		}
	
		return Date()
	}
	
	static func string(from date: Date) -> String {
		let formatter = DateFormatter.utc
		if let format = validFormats.first {
			formatter.dateFormat = format
		}
		return formatter.string(from: date)
	}
}

// MARK: - Extension - DateDecodingStrategy

public extension JSONDecoder.DateDecodingStrategy {
	
	static var standardDates: JSONDecoder.DateDecodingStrategy {
		.custom({ (decoder) -> Date in
			let container = try decoder.singleValueContainer()
			let string = try container.decode(String.self)
			return DateFormatter.date(from: string)
		})
	}
}

// MARK: - Extension - DateEncodingStrategy

public extension JSONEncoder.DateEncodingStrategy {
	
	static var standardDates: JSONEncoder.DateEncodingStrategy {
		return .custom({ (date, encoder) in
			var container = encoder.singleValueContainer()
			try container.encode(DateFormatter.string(from: date))
		})
	}
}

// MARK: - Extension - JSONDecoder

public extension JSONDecoder {
	
	static var standard: JSONDecoder = {
		let decoder = JSONDecoder()
		decoder.dateDecodingStrategy = .standardDates
		return decoder
	}()
}

// MARK: - Extension - JSONEncoder

public extension JSONEncoder {
	
	static var standard: JSONEncoder = {
		let encoder = JSONEncoder()
		encoder.dateEncodingStrategy = .standardDates
		return encoder
	}()
}

// MARK: - Extension - Encodable

public extension Encodable {
	
	var data: Data? { try? JSONEncoder.standard.encode(self) }
	
	var object: Any? {
		let encoded = try? JSONEncoder.standard.encode(self)
		guard let encodedData = (self as? Data) ?? encoded else { return nil }
		return try? JSONSerialization.jsonObject(with: encodedData, options: .allowFragments)
	}
	
	var dictionaryObject: [String : Any] { object as? [String: Any] ?? [:] }
	
	var arrayObject: [Any] { object as? [Any] ?? [] }
	
	/// Writes the current encodable to a local file. If no key is provided, the type name itself is used.
	///
	/// - Parameters:
	///   - key: An optional key unique per file. Identical keys will override the same file. If no key is provided, the type name will be used as the key.
	///   - isSecure: If true, the file will be accessibile only while the device is unlocked.
	func writeFile(key: String? = nil, isSecure: Bool = false) {
		let validKey = key ?? "\(type(of: self))"
		let url = FileManager.default.appGroup.appendingPathComponent(validKey.hash.description)
		writeFile(at: url, isSecure: isSecure)
	}
	
	/// Writes the current encodable to a local URL.
	///
	/// - Parameters:
	///   - url: The absolute local valid URL.
	///   - isSecure: If true, the file will be accessibile only while the device is unlocked.
	func writeFile(at url: URL, isSecure: Bool = false) {
		do {
			let jsonData = try JSONEncoder.standard.encode(self).base64EncodedData()
			try jsonData.write(to: url, options: isSecure ? [.completeFileProtection, .atomic] : .atomic)
		} catch {
			Logger.global.log(full: "Encodable error \(error)")
		}
	}
	
	/// Updates the value of a given keypath inside a given mutable target.
	///
	/// - Parameters:
	///   - value: The value to be updated.
	///   - keyPath: The keypath.
	mutating func update<T>(_ keyPath: WritableKeyPath<Self, T>, to value: T) {
		self[keyPath: keyPath] = value
	}
	
	/// Updates the value of a given keypath and returns a copy of it.
	///
	/// - Parameters:
	///   - keyPath: The keypath.
	///   - value: The value to be updated.
	/// - Returns: Returns a new copy of the target.
	func updating<T>(_ keyPath: WritableKeyPath<Self, T>, to value: T) -> Self {
		var copy = self
		copy.update(keyPath, to: value)
		return copy
	}
}

// MARK: - Extension - Decodable

public extension Decodable {
	
	/// Loads the object with a given data.
	///
	/// - Parameter data: The JSON data to load the decodable object.
	/// - Returns: The loaded object or nil in case of error. It prints a console log for the error.
	static func load(data: Data) -> Self? {
		do {
			return try JSONDecoder.standard.decode(self, from: data)
		} catch {
			Logger.global.log(full: "Decodable error: \(error)")
			return nil
		}
	}
	
	/// Loads the object with a given object.
	///
	/// - Parameter jsonObject: The JSON data to load the decodable object.
	/// - Returns: The loaded object or nil in case of error. It prints a console log for the error.
	static func load(jsonObject: Any) -> Self? {
		guard let data = try? JSONSerialization.data(withJSONObject: jsonObject) else { return nil }
		return load(data: data)
	}
	
	/// Loads the object with a given JSON string.
	///
	/// - Parameter jsonString: The JSON string
	/// - Returns: The loaded object or nil in case of error. It prints a console log for the error.
	static func load(jsonString: String) -> Self? {
		guard let data = jsonString.data(using: .utf8) else { return nil }
		return load(data: data)
	}
	
	/// Retrieves the content from a file with a given key.
	///
	/// - Parameter key: An optional key. If no key is provided, the type name will be used as the key.
	/// - Returns: The decoded data in the file.
	static func loadFile(key: String? = nil) -> Self? {
		let validKey = key ?? "\(self)"
		let url = FileManager.default.appGroup.appendingPathComponent(validKey.hash.description)
		guard let data = try? Data(contentsOf: url) else { return nil }
		return load(data: Data(base64Encoded: data) ?? data)
	}
	
	/// Retrieves the content from a file with a given name.
	///
	/// - Parameters:
	///   - url: The full file url.
	/// - Returns: The decoded data in the file.
	static func loadFile(at url: URL) -> Self? {
		guard let data = try? Data(contentsOf: url) else { return nil }
		return load(data: Data(base64Encoded: data) ?? data)
	}
	
	/// Removes a given file from disk.
	///
	/// - Parameter withKey: An optional key. If no key is provided, the type name will be used as the key.
	static func removeFile(key: String? = nil) {
		let validKey = key ?? "\(self)"
		let fileManager = FileManager.default
		let url = fileManager.appGroup.appendingPathComponent(validKey.hash.description)
		try? fileManager.removeItem(at: url)
	}
}

// MARK: - Extension - Codable

public extension Decodable where Self : Encodable {
	
	/// Updates the value of a given a key and returns a copy of it.
	///
	/// - Parameters:
	///   - key: The key to be updated.
	///   - value: The value to be updated.
	/// - Returns: Returns a new copy of the target.
	func updating<T>(_ key: String, to value: T) -> Self {
		var dict = dictionaryObject
		dict[key] = value
		return Self.load(jsonObject: dict) ?? self
	}
	
	/// Updates the value of a given a key and returns a copy of it.
	///
	/// - Parameters:
	///   - keyPath: The keyPath to be updated.
	///   - value: The value to be updated.
	/// - Returns: Returns a new copy of the target.
	func updating<T>(_ keyPath: KeyPath<Self, T>, to value: T) -> Self {
		updating(keyPath.stringValue, to: value)
	}
}

// MARK: - Extension - String

public extension String {
	
	/// Returns a `Date` using `DateFormatter.validFormats`. Returns current date if the format is invalid.
	/// This property takes advantage of `InMemoryCache` and is optimized for maximum performance.
	var toDate: Date { InMemoryCache.getOrSet(key: "Date-\(self)", newValue: DateFormatter.date(from: self)) ?? .init() }
	
	/// Returns the current string as URL.
	var toURL: URL { .init(string: self) ?? .init(fileURLWithPath: "") }
	
	/// Returns a pretty-printed JSON representation of the string if it contains valid JSON data.
	///
	/// - Returns: A string with indented JSON representation if the current string is valid JSON; otherwise, returns the original string.
	var prettyJSON: String {
		guard
			let data = data(using: .utf8),
			let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
			let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
		else { return self }
		
		return .init(data: prettyData, encoding: .utf8) ?? self
	}
	
	/// Creates a URL using the string as the resource name.
	///
	/// - Parameter bundle: The bundle in which to search for the resource. The default value is `.main`.
	/// - Returns: A URL constructed using the resource name from the string and the specified bundle.
	func toURL(in bundle: Bundle = .main) -> URL {
		bundle.url(forResource: self, withExtension: nil) ?? .init(fileURLWithPath: "")
	}
	
	/// Generates a random string of the specified length.
	///
	/// - Parameter length: The length of the random string to generate.
	/// - Returns: A random string containing characters from the set of lowercase and uppercase letters, digits, and spaces.
	static func randomString(_ length: Int) -> String {
		let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 "
		return .init((0..<length).compactMap { _ in letters.randomElement() })
	}
}

// MARK: - Extension - FileManager

public extension FileManager {
	
	private var isInsecureFileSystem: Bool {
		do {
			let file = "/private/file.txt"
			try "-".write(toFile: file, atomically: true, encoding: .utf8)
			try removeItem(atPath: file)
			return true
		} catch {
			return false
		}
	}
	
	var isInsecureOS: Bool {
		let apps = ["Cydia", "FakeCarrier", "Icy", "IntelliScreen", "SBSettings"]
		let hasInsecureApps = apps.first { access("/Applications/\($0).app", F_OK) != -1 } != nil
		
		return hasInsecureApps || isInsecureFileSystem
	}
	
	var appGroup: URL {
		let directory = containerURL(forSecurityApplicationGroupIdentifier: Bundle.appGroup) ?? temporaryDirectory
		guard Constant.isDebug else { return directory }
		
		let debugFolder = directory.appendingPathComponent("Debug")
		if !fileExists(atPath: debugFolder.path) {
			try? createDirectory(atPath: debugFolder.path, withIntermediateDirectories: true, attributes: nil)
		}
		
		return debugFolder
	}
	
	func move(from: URL, to: URL) {
		guard
			from != to,
			fileExists(atPath: from.path, isDirectory: nil)
		else { return }
		
		do {
			try copyItem(at: from, to: to)
		} catch {
			Logger.global.log(full: "Moving error \(from) -> \(to) :: \(error)")
		}
	}
	
	func removeAllItems(at: URL) {
		let items = try? contentsOfDirectory(at: at, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
		items?.forEach { try? removeItem(at: $0) }
	}
}

// MARK: - Extension - Bundle

public extension Bundle {
	
	var appName: String { infoDictionary?["CFBundleName"] as? String ?? "" }
	
	var displayName: String { infoDictionary?["CFBundleDisplayName"] as? String ?? "" }
	
	var buildNumber: String { infoDictionary?["CFBundleVersion"] as? String ?? "" }
	
	var shortVersion: String { infoDictionary?["CFBundleShortVersionString"] as? String ?? "" }
	
	var fullVersion: String { "v \(shortVersion) (\(buildNumber))" }
	
	@objc static var appGroup: String = ""
}

// MARK: - Extension - URLCache

public extension URLCache {
	
	static var appGroup: URLCache {
		let directory = FileManager.default.appGroup.appendingPathComponent("Assets")
		return .init(memoryCapacity: .max, diskCapacity: .max, directory: directory)
	}
}
