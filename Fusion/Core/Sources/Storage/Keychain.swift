//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation
import Security

// MARK: - Definitions -

fileprivate extension String {
	
	static let keyClass = String(kSecClass)
	static let keySynchronizable = String(kSecAttrSynchronizable)
	static let keyAccount = String(kSecAttrAccount)
	static let keyAccessible = String(kSecAttrAccessible)
	static let keyPort = String(kSecAttrPort)
	static let keyAccessGroup = String(kSecAttrAccessGroup)
	static let keyServer = String(kSecAttrServer)
	static let keyService = String(kSecAttrService)
	static let keyMatchLimit = String(kSecMatchLimit)
	static let keyReturnData = String(kSecReturnData)
	static let keyValueData = String(kSecValueData)
}

// MARK: - Type -

/// Keychain is a key-value storage for ``Data`` types. Each instance can be configured differently,
/// although the underlaying data persistence is the same. The Keychain store is attached to the
/// main bundle.
///
/// The quickly access to it is provide by subscript, which can fetch, save and delete values.
///
/// - Example:
///```
/// 	let myKeychain = Keychain()
///		myKeychain["key"] = "value"
///		print(myKeychain["key"] == "value")
///		myKeychain["key"] = nil
///		prin(myKeychain["key"] == nil)
///```
public class Keychain {

// MARK: - Properties
	
	/// Subscript for accessing and modifying data in the Keychain.
	///
	/// - Parameter key: The key associated with the data.
	/// - Returns: The data associated with the specified key, or `nil` if no data is found.
	public subscript(key: String) -> Data? {
		get { getData(key) }
		set {
			if let value = newValue {
				set(value, key: key)
			} else {
				remove(key)
			}
		}
	}
	
// MARK: - Constructors

// MARK: - Protected Methods
	
	private func queries() -> [String : Any] {
		
		var dict = [String: Any]()
		
		dict[.keyClass] = kSecClassGenericPassword
		dict[.keySynchronizable] = kSecAttrSynchronizableAny
		dict[.keyService] = Bundle.main.bundleIdentifier
//		dict[.keyAccessGroup] = "group"
		
		return dict
	}
	
	private func commands(key: String?, value: Data) -> [String : Any] {
		var dict: [String: Any]
		
		if key != nil {
			dict = queries()
			dict[.keyAccount] = key
		} else {
			dict = [:]
		}
		
		dict[.keyValueData] = value
		dict[.keyAccessible] = kSecAttrAccessibleAfterFirstUnlock
		dict[.keySynchronizable] = kCFBooleanFalse
		
		return dict
	}

// MARK: - Exposed Methods
	
	/// Retrieves the data associated with the specified key from the Keychain.
	///
	/// - Parameter key: The key associated with the data.
	/// - Returns: The data associated with the specified key, or `nil` if no data is found.
	public func getData(_ key: String) -> Data? {
		
		var result: AnyObject?
		var query = queries()
		query[.keyMatchLimit] = kSecMatchLimitOne
		query[.keyReturnData] = kCFBooleanTrue
		query[.keyAccount] = key
		
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		
		switch status {
		case errSecSuccess:
			guard let data = result as? Data else { return nil }
			return data
		default:
			Logger.global.log(full: "🔑 Keychain: \(status)")
			return nil
		}
	}
	
	/// Stores the specified data in the Keychain with the given key.
	///
	/// - Parameters:
	///   - value: The data to be stored in the Keychain.
	///   - key: The key associated with the data.
	public func set(_ value: Data, key: String) {
		var query = queries()
		query[.keyAccount] = key
		
		var status = SecItemCopyMatching(query as CFDictionary, nil)
		switch status {
		case errSecSuccess, errSecInteractionNotAllowed:
			if status == errSecInteractionNotAllowed && floor(NSFoundationVersionNumber) <= floor(1140.11) {
				remove(key)
				set(value, key: key)
			} else {
				var query = queries()
				query[.keyAccount] = key
				let command = commands(key: nil, value: value)
				status = SecItemUpdate(query as CFDictionary, command as CFDictionary)
				if status != errSecSuccess {
					Logger.global.log(basic: "🔑 Keychain: \(status)")
				}
			}
		case errSecItemNotFound:
			let command = commands(key: key, value: value)
			status = SecItemAdd(command as CFDictionary, nil)
			if status != errSecSuccess {
				Logger.global.log(basic: "🔑 Keychain: \(status)")
			}
		default:
			Logger.global.log(basic: "🔑 Keychain: \(status)")
		}
	}
	
	/// Removes the data associated with the specified key from the Keychain.
	///
	/// - Parameter key: The key associated with the data to be removed.
	public func remove(_ key: String) {
		var query = queries()
		query[.keyAccount] = key
		
		let status = SecItemDelete(query as CFDictionary)
		if status != errSecSuccess && status != errSecItemNotFound {
			Logger.global.log(full: "🔑 Keychain: \(status)")
		}
	}
}
