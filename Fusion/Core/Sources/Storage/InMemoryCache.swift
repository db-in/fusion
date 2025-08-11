//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation

// MARK: - Definitions -

// MARK: - Type -

/// In memory key/value cache that works as a lightening cache layer 2 over any other storage.
/// It allows the value to be read from the cache or if not found allows the caller to set it.
public struct InMemoryCache {

// MARK: - Properties
	
	@ThreadSafe
	private static var data: [String : Any] = [:]
	
	@ThreadSafe
	private static var references: [String : String] = [:]

// MARK: - Constructors

// MARK: - Protected Methods

// MARK: - Exposed Methods
	
	/// Returns the cached value if it exists for a given key.
	///
	/// - Parameters:
	///   - key: A given key for the cache.
	///   - reference: An optional reference, if set the key will be bind to its reference, if reference changes, the key is invalidated.
	/// - Returns: The cached value or the new value defined.
	public static func get<T>(key: String, reference: String? = nil) -> T? {
		guard let cache = data[key], references[key] == reference else { return nil }
		return cache as? T
	}

	/// Sets the value for a given key.
	///
	/// - Parameters:
	///   - key: A given key for the cache.
	///   - reference: An optional reference, if set the key will be bind to its reference, if reference changes, the key is invalidated.
	///   - newValue: An autoclosure encapsulated that will only triggers if there is no cache available for the given key.
	/// - Returns: The cached value or the new value defined.
	@discardableResult
	public static func set<T>(key: String, reference: String? = nil, newValue: @autoclosure () -> T?) -> T? {
		let value = newValue()
		data[key] = value
		references[key] = reference
		return value
	}

	/// Returns the cached value if it exists for a given key,
	/// otherwise uses the `newValue` parameter to define the new value and caches it.
	///
	/// - Parameters:
	///   - key: A given key for the cache.
	///   - reference: An optional reference, if set the key will be bind to its reference, if reference changes, the key is invalidated.
	///   - newValue: An autoclosure encapsulated that will only triggers if there is no cache available for the given key.
	/// - Returns: The cached value or the new value defined.
	@discardableResult
	public static func getOrSet<T>(key: String, reference: String? = nil, newValue: @autoclosure () -> T?) -> T? {
		guard let cache: T = get(key: key, reference: reference) else { return set(key: key, reference: reference, newValue: newValue()) }
		return cache
	}

	/// Clears the existing cache for a given key.
	/// - Parameter key: The key to be cleared
	public static func flush(key: String) {
		data[key] = nil
		references[key] = nil
	}

	/// Flushes the in memory cache enterely.
	public static func flushAll() {
		data.removeAll()
		references.removeAll()
	}
}
