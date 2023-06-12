//
//  Created by Diney Bomfim on 5/7/23.
//

import Foundation

// MARK: - Definitions -

public protocol Storageable {
	
	static var shared: Storageable { get }
	func value<T : Decodable>(forKey key: String) -> T?
	func set<T : Encodable>(_ value: T?, forKey key: String)
	func removeObject(forKey: String)
}

// MARK: - Type - DataPersistable

public protocol DataPersistable : DataBindable {
	associatedtype Storage : Storageable
}

// MARK: - Extension - DataPersistable

public extension DataPersistable {
	
// MARK: - Exposed Methods
	
	/// Sets the value and associate it with a given key. The key must be unique and its value is replaced when it's set multiple times.
	/// This method triggers all the binds associated to the key.
	///
	/// - Parameters:
	///   - value: The new value to be stored and associated with the key.
	///   - key: The unique key that represents the value.
	static func set<T : Encodable>(_ value: T?, forKey key: Key) {
		let namespace = namespace(key)
		Storage.shared.set(value, forKey: namespace)
		InMemoryCache.flush(key: namespace)
		send(forKey: key, value: value)
	}
	
	/// Retrieves the value associated with a given key.
	///
	/// - Parameter key: The key associated with the value.
	/// - Returns: The value if it exists, or `nil`.
	static func value<T : Decodable>(forKey key: Key) -> T? {
		let namespace = namespace(key)
		return InMemoryCache.getOrSet(key: namespace, newValue: Storage.shared.value(forKey: namespace))
	}
	
	/// Removes the data associates with a set of keys. If there is a bind associated with the key and the goal is to be notified in case of `nil`,
	/// then it's required to specify the `bindType`, otherwise `nil` values do not trigger the bind closure.
	///
	/// - Parameters:
	///   - keys: The keys to be deleted.
	///   - bindType: A bintType that is commonly associated with all the keys. By default its value is `Any.self`.
	static func remove<T>(keys: [Key], bindType: T.Type? = Any.self) {
		keys.forEach {
			let namespace = namespace($0)
			Storage.shared.removeObject(forKey: namespace)
			InMemoryCache.flush(key: namespace)
			send(forKey: $0, value: nil as T?)
		}
	}
	
	/// Maps a response directly into the data persistence. There is a non-destructive choice, to avoid deleting the old value in case the new value
	/// is `nil`.
	/// This method triggers all the binds associated to the key.
	///
	/// - Parameters:
	///   - key: The key associated with the data.
	///   - nonDestructive: Indicates if the old value should be kept in case the new value is `nil`. By default is `true`, keeping old values.
	///   - completion: The response closure to be received.
	/// - Returns: A new response closure encapsulating the logic.
	static func map<T : Codable>(_ key: Key, nonDestructive: Bool = true, to completion: Response<T>? = nil) -> Response<T> {
		return { result in
			let value = try? result.get()
			
			if !nonDestructive || value != nil {
				set(value, forKey: key)
			}
			
			asyncResponse(completion)(result)
		}
	}
}

// MARK: - Extension - DataPersistable & CaseIterable

public extension DataPersistable where Key : CaseIterable & Hashable {
	
	static func removeAllKeys(except: [Key] = []) {
		guard let all = Key.allCases as? [Key] else { return }
		let filteredKeys = Set(all).subtracting(Set(except))
		remove(keys: Array(filteredKeys))
	}
}

// MARK: - Extension - UserDefaults Storageable

extension UserDefaults : Storageable {
	
	public static let shared: Storageable = UserDefaults(suiteName: Bundle.main.appGroup) ?? UserDefaults.standard
	
	public func value<T : Decodable>(forKey key: String) -> T? { value(forKey: key) as? T }
	public func set<T : Encodable>(_ value: T?, forKey key: String) { set(value as Any, forKey: key) }
}

// MARK: - Extension - FileManager Storageable

extension FileManager : Storageable {
	
	public static let shared: Storageable = FileManager.default
	
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
public struct StateStorage : Storageable {
	
	private static var objects: [String : Any] = [:]
	public static let shared: Storageable = StateStorage()
	
	public func value<T : Decodable>(forKey key: String) -> T? { StateStorage.objects[key] as? T }
	public func set<T : Encodable>(_ value: T?, forKey key: String) { StateStorage.objects[key] = value }
	public func removeObject(forKey: String) { StateStorage.objects[forKey] = nil }
}

// MARK: - Extension - KeychainStorage

/// Keychain as key-value storage. `Codable` Objects can be added and removed from this shared
/// storage.
extension Keychain : Storageable {

	public static let shared: Storageable = Keychain()

	public func value<T : Decodable>(forKey key: String) -> T? { T.load(data: self[key] ?? Data()) }
	public func set<T : Encodable>(_ value: T?, forKey key: String) { self[key] = value?.data }
	public func removeObject(forKey: String) { self[forKey] = nil }
}
