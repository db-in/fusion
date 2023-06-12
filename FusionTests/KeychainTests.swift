//
//  Created by Diney on 5/7/23.
//

import XCTest
@testable import Fusion

// MARK: - Definitions -

// MARK: - Type -

class KeychainTests: XCTestCase {
	
// MARK: - Properties
	
	var keychain = Keychain()
	
// MARK: - Constructors

// MARK: - Protected Methods
	
	private func clearKeychain() {
		let query: [String: Any] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
			kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.bundle.main"
		]
		SecItemDelete(query as CFDictionary)
	}
	
	func testSubscript_GetDataForKey_ReturnsCorrectData() {
		let key = #function
		let data = "TestValue".data(using: .utf8)!
		keychain.set(data, key: key)
		let retrievedData = keychain[key]
		XCTAssertEqual(retrievedData, data)
	}
	
	func testSubscript_SetDataForKey_SetsDataCorrectly() {
		let key = #function
		let data = "TestValue".data(using: .utf8)!
		keychain[key] = data
		let retrievedData = keychain.getData(key)
		XCTAssertEqual(retrievedData, data)
	}
	
	func testSubscript_SetNilValueForKey_RemovesData() {
		let key = #function
		let data = "TestValue".data(using: .utf8)!
		keychain.set(data, key: key)
		keychain[key] = nil
		let retrievedData = keychain.getData(key)
		XCTAssertNil(retrievedData)
	}
	
	func testGetDataForKey_ExistingKey_ReturnsCorrectData() {
		let key = #function
		let data = "TestValue".data(using: .utf8)!
		keychain.set(data, key: key)
		let retrievedData = keychain.getData(key)
		XCTAssertEqual(retrievedData, data)
	}
	
	func testGetDataForKey_NonExistingKey_ReturnsNil() {
		let key = #function
		let retrievedData = keychain.getData(key)
		XCTAssertNil(retrievedData)
	}
	
	func testRemoveDataForKey_ExistingKey_RemovesData() {
		let key = #function
		let data = "TestValue".data(using: .utf8)!
		keychain.set(data, key: key)
		keychain.remove(key)
		let retrievedData = keychain.getData(key)
		XCTAssertNil(retrievedData)
	}
	
	func testRemoveDataForKey_NonExistingKey_DoesNothing() {
		let key = #function
		keychain.remove(key)
		let retrievedData = keychain.getData(key)
		XCTAssertNil(retrievedData)
	}
}
