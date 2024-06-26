//
//  Created by Diney Bomfim on 5/7/23.
//

import Foundation

// MARK: - Definitions -

public protocol DataStorageable {
	
	static var shared: DataStorageable { get }
	func value<T : Decodable>(forKey key: String) -> T?
	func set<T : Encodable>(_ value: T?, forKey key: String)
	func removeObject(forKey: String)
}

// MARK: - Extension - UserDefaults DataStorageable

extension UserDefaults : DataStorageable {
	
	public static let appGroup: UserDefaults = UserDefaults(suiteName: Bundle.appGroup) ?? UserDefaults.standard
	public static var shared: DataStorageable { appGroup }
	
	public func value<T : Decodable>(forKey key: String) -> T? { value(forKey: key) as? T }
	public func set<T : Encodable>(_ value: T?, forKey key: String) { set(value as Any, forKey: key) }
	public func removeAllKeys() { dictionaryRepresentation().keys.forEach(removeObject(forKey:)) }
}

// MARK: - Extension - FileManager DataStorageable

extension FileManager : DataStorageable {
	
	public static let shared: DataStorageable = FileManager.default
	
	public func value<T : Decodable>(forKey key: String) -> T? { return T.loadFile(key: key) }
	public func set<T : Encodable>(_ value: T?, forKey key: String) {
		guard let newValue = value else {
			removeObject(forKey: key)
			return
		}
		newValue.writeFile(key: key)
	}
	public func removeObject(forKey: String) { String.removeFile(key: forKey) }
}

// MARK: - Type - StateStorage

/// Key-Value temporary in memory storage (RAM). `Codable` Objects can be added and removed from this shared
/// storage.
public struct StateStorage : DataStorageable {
	
	private static var objects: [String : Any] = [:]
	public static let shared: DataStorageable = StateStorage()
	
	public func value<T : Decodable>(forKey key: String) -> T? { StateStorage.objects[key] as? T }
	public func set<T : Encodable>(_ value: T?, forKey key: String) { StateStorage.objects[key] = value }
	public func removeObject(forKey: String) { StateStorage.objects[forKey] = nil }
}

// MARK: - Extension - KeychainStorage

/// Keychain as key-value storage. `Codable` Objects can be added and removed from this shared
/// storage.
extension Keychain : DataStorageable {

	public static let shared: DataStorageable = Keychain()

	public func value<T : Decodable>(forKey key: String) -> T? { T.load(data: self[key] ?? Data()) }
	public func set<T : Encodable>(_ value: T?, forKey key: String) { self[key] = value?.data }
	public func removeObject(forKey: String) { self[forKey] = nil }
}
