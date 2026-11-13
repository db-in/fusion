//
//  Created by Diney Bomfim on 6/14/23.
//

import Foundation

// MARK: - Definitions -

private func isEqualValue<L : Equatable>(_ lhs: L, _ rhs: Any) -> Bool {
	guard let rhs = rhs as? L else { return false }
	return lhs == rhs
}

private func isSameValue(_ lhs: Any?, _ rhs: Any?) -> Bool {
	switch (lhs, rhs) {
	case (nil, nil):
		return true
	case let (lhs as any Equatable, rhs?):
		return isEqualValue(lhs, rhs)
	default:
		return false
	}
}

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

/// A protocol that provides comprehensive data management capabilities with optimized caching and optional throttled persistence.
///
/// Key Features:
/// - **Optimized InMemoryCache**: All reads and writes go through a fast in-memory cache layer for immediate access
/// - **Per-Key Throttling**: Define individual throttle intervals for specific keys to delay storage operations
/// - **Immediate Updates**: Values are immediately available in memory and trigger all DataBindable notifications
/// - **Deferred Persistence**: Storage I/O operations can be throttled or saved in the background while maintaining real-time data access.
///   See ``persistsAsynchronously(forKey:)`` for what other processes see before the I/O completes
/// - **Thread-Safe**: All operations are thread-safe with proper concurrency handling
/// - **Automatic Cleanup**: Timers and cache entries are automatically managed
///
/// Conforming types can override `throttleInterval(forKey:)` to provide per-key throttle behavior,
/// allowing fine-grained control over which data should have delayed persistence.
public protocol DataManageable : DataBindable {
	associatedtype Storage : DataStorageable

	/// Returns the throttle interval for a specific key. Implement this method to provide per-key throttle behavior.
	/// When set to a value greater than 0, write operations to Storage will be delayed for this key.
	/// For reading purpose the new value reflects immediately and all DataBindable process remains unaffected.
	/// The throttle only affects the I/O operation on the actual Storage.
	///
	/// - Parameter key: The key to check for a specific throttle interval.
	/// - Returns: The throttle interval in seconds for the given key. Default is `0` (no throttling).
	static func throttleInterval(forKey key: Key) -> TimeInterval
	
	/// Returns whether writes for a specific key are saved to `Storage` on a background queue.
	///
	/// When `true`, `set` and `remove` update the in-memory cache and return without waiting for the I/O.
	/// Every read through this type returns the latest value right away, including pending writes, and all
	/// DataBindable notifications are delivered as usual. No subscription is needed to read your own writes.
	///
	/// Pending writes are saved in order, and only the latest pending value of each key reaches the storage.
	/// On iOS, tvOS, visionOS and macOS they are saved automatically when the app resigns active, enters the background or terminates.
	/// On watchOS, call ``flushPendingWrites()`` when the app moves to the background.
	///
	/// Things to consider before keeping the default:
	/// - Readers outside this type, such as app extensions, widgets or direct `FileManager` access to the same files,
	///   can see the previous value until the pending write is saved. Call ``flushPendingWrites()`` before handing over.
	/// - Writes still pending when the process crashes are lost. Return `false` for keys that must survive a crash.
	///
	/// - Parameter key: The key being written or removed.
	/// - Returns: `true` by default for `FileManager` and custom storages. `false` for `StateStorage`, `Keychain` and `UserDefaults`.
	static func persistsAsynchronously(forKey key: Key) -> Bool
	
	static func notifiesOnlyOnChange(forKey key: Key) -> Bool
}

// MARK: - Extension - DataManageable

public extension DataManageable {
	
// MARK: - Exposed Methods
	
	/// The default throttle interval, applied when a conforming type does not implement `throttleInterval(forKey:)`.
	///
	/// - Parameter key: The key to check for a specific throttle interval.
	/// - Returns: `0`, meaning no throttling.
	static func throttleInterval(forKey key: Key) -> TimeInterval { 0 }
	
	/// The default asynchronous persistence, applied when a conforming type does not implement `persistsAsynchronously(forKey:)`.
	///
	/// - Parameter key: The key being written or removed.
	/// - Returns: `false` for `StateStorage`, `Keychain` and `UserDefaults`, which are already fast or shared across processes. `true` otherwise.
	static func persistsAsynchronously(forKey key: Key) -> Bool {
		let storage = Storage.shared
		return !(storage is StateStorage || storage is Keychain || storage is UserDefaults)
	}
	
	static func notifiesOnlyOnChange(forKey key: Key) -> Bool { false }
	
	/// Saves every pending asynchronous or throttled write to its storage before returning.
	/// Call it before another process reads the same storage, for example right before reloading a widget timeline.
	static func flushPendingWrites() {
		StoragePersistence.flushPendingWrites()
	}
	
	/// Returns the keys of this type that currently hold a value in its `Storage`, including dynamic keys
	/// that are not part of `allCases`. The order is not guaranteed.
	///
	/// - Complexity: O(*n*), where n is the number of keys tracked by the underlying `Storage`.
	/// - Parameter prefix: Filters the keys whose raw value starts with the prefix. By default, all keys of this type are returned.
	/// - Returns: The matching keys.
	static func keys(prefix: String = "") -> [Key] {
		let base = "\(Self.prefix)."
		return Storage.shared.keys(prefix: base + prefix).compactMap { (String($0.dropFirst(base.count)) as? Key.RawValue).flatMap(Key.init(rawValue:)) }
	}
	
	/// Retrieves the value associated with a given key.
	///
	/// - Parameter key: The key associated with the value.
	/// - Returns: The value if it exists, or `nil`.
	static func value<T : Decodable>(forKey key: Key) -> T? {
		let namespace = namespace(key)
		return InMemoryCache.getOrLoad(key: namespace) { () -> T? in
			let pending = StoragePersistence.pendingValue(forKey: namespace)
			guard pending.found else { return Storage.shared.value(forKey: namespace) }
			return pending.value as? T
		}
	}
	
	/// Sets the value and associate it with a given key. The key must be unique and its value is replaced when it's set multiple times.
	/// This method triggers all the binds associated to the key.
	///
	/// - Parameters:
	///   - value: The new value to be stored and associated with the key.
	///   - key: The unique key that represents the value.
	static func set<T : Encodable>(_ value: T?, forKey key: Key) {
		let namespace = namespace(key)
		
		if notifiesOnlyOnChange(forKey: key) {
			let previous = InMemoryCache.getRaw(key: namespace)
			if previous != nil || !Storage.shared.isTracked(key: namespace), isSameValue(value, previous) { return }
		}
		
		InMemoryCache.set(key: namespace, newValue: value)
		Storage.shared.track(key: namespace, isStored: value != nil)
		let interval = throttleInterval(forKey: key)
		let write = { Storage.shared.set(value, forKey: namespace) }
		
		if interval > 0 {
			StoragePersistence.throttle(key: namespace, value: value, interval: interval, write: write)
		} else if persistsAsynchronously(forKey: key) {
			StoragePersistence.enqueue(key: namespace, value: value, write: write)
		} else {
			write()
		}
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
			StoragePersistence.cancel(key: namespace)
			if persistsAsynchronously(forKey: $0) {
				StoragePersistence.enqueue(key: namespace, value: nil) { Storage.shared.removeObject(forKey: namespace) }
			} else {
				Storage.shared.removeObject(forKey: namespace)
			}
			Storage.shared.track(key: namespace, isStored: false)
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
	
	/// Runs an asynchronous operation and persists its result under the key. It's the async counterpart of ``map(_:nonDestructive:to:)``.
	/// When the operation throws, the stored value is kept, unless `nonDestructive` is `false`, in which case it's removed.
	/// This method triggers all the binds associated to the key.
	///
	/// ```swift
	/// let user = try await UserStorage.store(.current) { try await UserService.fetch() }
	/// ```
	///
	/// - Parameters:
	///   - key: The key associated with the data.
	///   - nonDestructive: Indicates if the old value should be kept in case the operation fails. By default is `true`, keeping old values.
	///   - operation: The asynchronous operation producing the value.
	/// - Returns: The value produced by the operation.
	/// - Throws: The error thrown by the operation.
	@discardableResult
	static func store<T : Codable>(_ key: Key, nonDestructive: Bool = true, _ operation: () async throws -> T) async throws -> T {
		do {
			let value = try await operation()
			set(value, forKey: key)
			return value
		} catch {
			if !nonDestructive {
				set(nil as T?, forKey: key)
			}
			throw error
		}
	}
}

// MARK: - Extension - DataManageable & CaseIterable

public extension DataManageable where Key : CaseIterable & Hashable {
	
	static func removeAllKeys(except: [Key] = []) {
		guard let all = Key.allCases as? [Key] else { return }
		let filteredKeys = Set(all).union(keys()).subtracting(Set(except))
		remove(keys: Array(filteredKeys))
	}
}
