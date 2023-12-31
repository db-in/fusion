//
//  Created by Diney Bomfim on 6/14/23.
//

import Foundation

// MARK: - Definitions -

@propertyWrapper
public struct Stored<Parent : DataManageable, Value : Codable> {

	private let key: Parent.Key

	public init(_ type: Parent.Type, key: Parent.Key) { self.key = key }

	public var wrappedValue: Value? {
		get { Parent.value(forKey: key) }
		set { Parent.set(newValue, forKey: key) }
	}
}

@propertyWrapper
public struct StoredReadOnly<Parent : DataManageable, Value : Codable> {

	private let key: Parent.Key

	public init(_ type: Parent.Type, key: Parent.Key) { self.key = key }

	public var wrappedValue: Value? { Parent.value(forKey: key) }
}

// MARK: - Type - DataManageable

public protocol DataManageable : DataBindable {
	associatedtype Storage : DataStorageable
}

// MARK: - Extension - DataManageable

public extension DataManageable {
	
// MARK: - Exposed Methods
	
	/// Retrieves the value associated with a given key.
	///
	/// - Parameter key: The key associated with the value.
	/// - Returns: The value if it exists, or `nil`.
	static func value<T : Decodable>(forKey key: Key) -> T? {
		let namespace = namespace(key)
		return InMemoryCache.getOrSet(key: namespace, newValue: Storage.shared.value(forKey: namespace))
	}
	
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
		return { result, response in
			let value = try? result.get()
			
			if !nonDestructive || value != nil {
				set(value, forKey: key)
			}
			
			asyncResponse(completion)(result, response)
		}
	}
}

// MARK: - Extension - DataManageable & CaseIterable

public extension DataManageable where Key : CaseIterable & Hashable {
	
	static func removeAllKeys(except: [Key] = []) {
		guard let all = Key.allCases as? [Key] else { return }
		let filteredKeys = Set(all).subtracting(Set(except))
		remove(keys: Array(filteredKeys))
	}
}
