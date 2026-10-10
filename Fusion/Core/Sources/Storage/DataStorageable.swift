//
//  Created by Diney Bomfim on 5/7/23.
//

import Foundation

// MARK: - Definitions -

private let keysQueue = DispatchQueue(label: "Fusion.DataStorageable.keys", qos: .utility)

public protocol DataStorageable {
	
	static var shared: DataStorageable { get }
	func value<T : Decodable>(forKey key: String) -> T?
	func set<T : Encodable>(_ value: T?, forKey key: String)
	func removeObject(forKey: String)
}

// MARK: - Extension - DataStorageable Key Tracking

extension DataStorageable {
	
	private var keysName: String { "\(type(of: self)).keys" }
	
	private func withKeys<Result>(_ transform: (inout [String : Bool]) -> Result) -> Result {
		InMemoryCache.mutate(key: keysName, default: value(forKey: keysName) ?? [:], transform)
	}
	
	/// Tracks whether a key holds a value in this storage. The tracking is updated immediately in memory and saved
	/// in the background to this same storage under a side key, which is the source of truth for cold launches.
	/// Changes that happen while a save is still queued are coalesced into that save.
	///
	/// - Complexity: O(1) in the calling thread.
	/// - Parameters:
	///   - key: The full storage key being written or removed.
	///   - isStored: `true` when the key holds a value, `false` when it was removed.
	func track(key: String, isStored: Bool) {
		let pendingName = keysName + ".pending"
		guard
			withKeys({ isStored ? $0.updateValue(true, forKey: key) == nil : $0.removeValue(forKey: key) != nil }),
			InMemoryCache.mutate(key: pendingName, default: false, { (isPending: inout Bool) in defer { isPending = true }; return !isPending })
		else { return }
		keysQueue.async {
			InMemoryCache.set(key: pendingName, newValue: false)
			set(withKeys { $0 }, forKey: keysName)
		}
	}
	
	/// Returns the tracked keys of this storage. The order is not guaranteed.
	///
	/// - Complexity: O(*n*), where n is the number of keys tracked by this storage.
	/// - Parameter prefix: Filters the keys that start with the prefix. By default, all tracked keys are returned.
	/// - Returns: The matching keys.
	func keys(prefix: String = "") -> [String] {
		withKeys { $0.keys.filter { $0.hasPrefix(prefix) } }
	}
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
	
	@ThreadSafe
	private static var objects: [String : Any] = [:]
	public static let shared: DataStorageable = StateStorage()
	
	public func value<T : Decodable>(forKey key: String) -> T? { StateStorage.objects[key] as? T }
	public func set<T : Encodable>(_ value: T?, forKey key: String) {
		StateStorage._objects.mutate { $0[key] = value }
	}
	public func removeObject(forKey: String) {
		StateStorage._objects.mutate { $0[forKey] = nil }
	}
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
