//
//  Created by Diney on 5/7/23.
//

import Foundation
import Testing
@testable import Fusion

// MARK: - Definitions -

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct KeychainTests {
		
// MARK: - Properties
		
		let keychain = Keychain()
		
// MARK: - Protected Methods
		
		private func clearKeychain() {
			let query: [String: Any] = [
				kSecClass as String: kSecClassGenericPassword,
				kSecAttrSynchronizable as String: kSecAttrSynchronizableAny,
				kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.bundle.main"
			]
			SecItemDelete(query as CFDictionary)
		}
		
		@Test
		func subscript_GetDataForKey_ReturnsCorrectData() throws {
			let key = #function
			let data = try #require("TestValue".data(using: .utf8))
			keychain.set(data, key: key)
			let retrievedData = keychain[key]
			#expect(retrievedData == data)
		}
		
		@Test
		func subscript_SetDataForKey_SetsDataCorrectly() throws {
			let key = #function
			let data = try #require("TestValue".data(using: .utf8))
			keychain[key] = data
			let retrievedData = keychain.getData(key)
			#expect(retrievedData == data)
		}
		
		@Test
		func subscript_SetNilValueForKey_RemovesData() throws {
			let key = #function
			let data = try #require("TestValue".data(using: .utf8))
			keychain.set(data, key: key)
			keychain[key] = nil
			let retrievedData = keychain.getData(key)
			#expect(retrievedData == nil)
		}
		
		@Test
		func getDataForKey_ExistingKey_ReturnsCorrectData() throws {
			let key = #function
			let data = try #require("TestValue".data(using: .utf8))
			keychain.set(data, key: key)
			let retrievedData = keychain.getData(key)
			#expect(retrievedData == data)
		}
		
		@Test
		func getDataForKey_NonExistingKey_ReturnsNil() {
			let key = #function
			let retrievedData = keychain.getData(key)
			#expect(retrievedData == nil)
		}
		
		@Test
		func removeDataForKey_ExistingKey_RemovesData() throws {
			let key = #function
			let data = try #require("TestValue".data(using: .utf8))
			keychain.set(data, key: key)
			keychain.remove(key)
			let retrievedData = keychain.getData(key)
			#expect(retrievedData == nil)
		}
		
		@Test
		func removeDataForKey_NonExistingKey_DoesNothing() {
			let key = #function
			keychain.remove(key)
			let retrievedData = keychain.getData(key)
			#expect(retrievedData == nil)
		}
	}
}
