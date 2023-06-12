//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation

// MARK: - Definitions -

final class CacheWrapper<Key : Hashable, Value> {
	
	private final class WrappedKey: NSObject {
		let key: Key
		init(_ key: Key) { self.key = key }
		override var hash: Int { key.hashValue }
		override func isEqual(_ object: Any?) -> Bool { (object as? WrappedKey)?.key == key }
	}
	
	private final class Entry {
		let value: Value
		init(_ value: Value) { self.value = value }
	}
	
	private var wrapped: [WrappedKey : Entry] = .init()
	private let queue: DispatchQueue = .init(label: "\(CacheWrapper.self)", attributes: .concurrent)
	
	subscript(key: Key) -> Value? {
		get { queue.sync { wrapped[WrappedKey(key)]?.value } }
		set {
			queue.async(flags: .barrier) { [weak self] in
				guard let value = newValue else {
					self?.wrapped[WrappedKey(key)] = nil
					return
				}
				
				self?.wrapped[WrappedKey(key)] = .init(value)
			}
		}
	}
	
	func removeAll() {
		queue.async(flags: .barrier) { [weak self] in
			self?.wrapped.removeAll()
		}
	}
}

// MARK: - Type -

/// In memory key/value cache that works as a lightening cache layer 2 over any other storage.
/// It allows the value to be read from the cache or if not found allows the caller to set it.
public struct InMemoryCache {

// MARK: - Properties
	
	private static var data: CacheWrapper<String, Any> = .init()
	private static var references: CacheWrapper<String, String?> = .init()

// MARK: - Constructors

// MARK: - Protected Methods

// MARK: - Exposed Methods

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
		if let cache = data[key], references[key] == reference {
			return cache as? T
		}
		
		let value = newValue()
		data[key] = value
		references[key] = reference
		
		return value
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
