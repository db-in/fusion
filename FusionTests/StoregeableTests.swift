//
//  Created by Diney on 5/7/23.
//

import XCTest
@testable import Fusion

// MARK: - Definitions -

// MARK: - Type -

class StoregeableTests: XCTestCase {
	
	enum MockError : Error {
		case ordinary
	}
	
	class MockStorage: DataManageable {
		typealias Storage = StateStorage
		
		enum Key : String {
			case singleTest
			case dualTest
			case mapTest
			case multiTest
		}
	}
	
// MARK: - Properties
	
	let value = "value"
	
// MARK: - Constructors
	
	@objc private func callback() {
		XCTAssertEqual(MockStorage.value(forKey: .multiTest), value)
	}

// MARK: - Protected Methods

	func testDataManageable_WithSet_ShouldSaveValueAndNotifyBinds() {
		let expectation = expectation(description: #function)
		
		MockStorage.bind(key: .singleTest, cancellable: self) { newValue in
			XCTAssertEqual(newValue, self.value)
			MockStorage.unbind(key: .singleTest, cancellable: self)
			expectation.fulfill()
		}
		
		MockStorage.set(value, forKey: .singleTest)
		XCTAssertEqual(MockStorage.value(forKey: .singleTest), value)
		
		wait(for: [expectation], timeout: 0.1)
	}
	
	func testDataManageable_WithSeveralBindCombinations_ShouldProperlyCallAssignedClosure() {
		let expectation = expectation(description: #function)
		expectation.expectedFulfillmentCount = 4
		
		MockStorage.bind(key: .multiTest, target: self, method: #selector(callback))
		MockStorage.bind(key: .multiTest, target: self, method: #selector(callback))
		
		MockStorage.bind(key: .multiTest, cancellable: self) { newValue in
			XCTAssertEqual(newValue, self.value)
			expectation.fulfill()
		}
		
		MockStorage.bind(key: .multiTest, cancellable: self) { newValue in
			XCTAssertEqual(newValue, self.value)
			expectation.fulfill()
		}
		
		MockStorage.bind(key: .multiTest, cancellable: self) {
			XCTAssertEqual(MockStorage.value(forKey: .multiTest), self.value)
			expectation.fulfill()
		}
		
		MockStorage.bind(key: .multiTest, cancellable: self) {
			XCTAssertEqual(MockStorage.value(forKey: .multiTest), self.value)
			expectation.fulfill()
		}
		
		MockStorage.set(value, forKey: .multiTest)
		wait(for: [expectation], timeout: 0.2)
	}

	func testDataManageable_WithValue_ShouldRetrieveTheValueCorrectly() {
		MockStorage.set(value, forKey: .singleTest)
		XCTAssertEqual(MockStorage.value(forKey: .singleTest), value)
	}

	func testDataManageable_WithRemoveMultipleKeys_ShouldRemoveTheKeys() {
		MockStorage.set(value, forKey: .singleTest)
		MockStorage.set(value, forKey: .dualTest)
		MockStorage.remove(keys: [.singleTest, .dualTest])
		XCTAssertNotEqual(MockStorage.value(forKey: .singleTest), value)
		XCTAssertNotEqual(MockStorage.value(forKey: .dualTest), value)
	}

	func testDataManageable_WithMapPreservingCache_ShouldNotOverrideLocalData() {
		let expectation = expectation(description: #function)
		
		let callback1 = MockStorage.map(.mapTest) { (result: Result<String, Error>, _) in
			let newValue = try! result.get()
			XCTAssertEqual(newValue, self.value)
			XCTAssertEqual(MockStorage.value(forKey: .mapTest), self.value)
			
			let callback2 = MockStorage.map(.mapTest, nonDestructive: true) { (result: Result<String, Error>, _) in
				let newValue: String? = try? result.get()
				let oldValue: String? = MockStorage.value(forKey: .mapTest)
				XCTAssertNil(newValue)
				XCTAssertEqual(oldValue, self.value)
				expectation.fulfill()
			}
			
			callback2(.failure(MockError.ordinary), nil)
		}
		
		callback1(.success(value), nil)
		
		wait(for: [expectation], timeout: 0.2)
	}
	
	func testDataManageable_WithMapDiscardingCache_ShouldOverrideLocalData() {
		let expectation = expectation(description: #function)
		
		let callback1 = MockStorage.map(.mapTest) { (result: Result<String, Error>, _) in
			let newValue = try! result.get()
			XCTAssertEqual(newValue, self.value)
			XCTAssertEqual(MockStorage.value(forKey: .mapTest), self.value)
			
			let callback2 = MockStorage.map(.mapTest, nonDestructive: false) { (result: Result<String, Error>, _) in
				let newValue: String? = try? result.get()
				let oldValue: String? = MockStorage.value(forKey: .mapTest)
				XCTAssertNil(newValue)
				XCTAssertNil(oldValue)
				expectation.fulfill()
			}
			
			callback2(.failure(MockError.ordinary), nil)
		}
		
		callback1(.success(value), nil)
		
		wait(for: [expectation], timeout: 0.2)
	}

	func testDataManageable_WithRemoveAllKeys_ShouldRemoveAllKindsAndNotifyBinds() {
		let expectation = expectation(description: #function)
		
		MockStorage.bind(key: .dualTest, cancellable: self) { (newValue: String?) in
			if newValue != nil {
				XCTAssertEqual(newValue, self.value)
			} else {
				MockStorage.unbind(key: .dualTest, cancellable: self)
				expectation.fulfill()
			}
		}
		
		MockStorage.set(value, forKey: .singleTest)
		MockStorage.set(value, forKey: .dualTest)
		MockStorage.remove(keys: [.dualTest], bindType: String.self)
		XCTAssertEqual(MockStorage.value(forKey: .singleTest), value)
		
		wait(for: [expectation], timeout: 0.1)
	}
	
	func testUserDefaultsStorageable_WithSetValidValue_ShouldSaveSuccessfully() {
		let key = #function
		UserDefaults.shared.set(value, forKey: key)
		XCTAssertEqual(UserDefaults.shared.value(forKey: key), value)
	}
	
	func testUserDefaultsStorageable_WithRemovingPreviouslySetValue_ShouldEraseIt() {
		let key = #function
		UserDefaults.shared.set(value, forKey: key)
		UserDefaults.shared.removeObject(forKey: key)
		XCTAssertNotEqual(UserDefaults.shared.value(forKey: key), value)
	}
	
	func testFileManagerStorageable_WithSetValidValue_ShouldSaveSuccessfully() {
		let key = #function
		FileManager.shared.set(value, forKey: key)
		XCTAssertEqual(FileManager.shared.value(forKey: key), value)
	}
	
	func testFileManagerStorageable_WithRemovingPreviouslySetValue_ShouldEraseIt() {
		let key = #function
		FileManager.shared.set(value, forKey: key)
		FileManager.shared.removeObject(forKey: key)
		XCTAssertNotEqual(FileManager.shared.value(forKey: key), value)
	}
	
	func testStateStorageable_WithSetValidValue_ShouldSaveSuccessfully() {
		let key = #function
		StateStorage.shared.set(value, forKey: key)
		XCTAssertEqual(StateStorage.shared.value(forKey: key), value)
	}
	
	func testStateStorageable_WithRemovingPreviouslySetValue_ShouldEraseIt() {
		let key = #function
		StateStorage.shared.set(value, forKey: key)
		StateStorage.shared.removeObject(forKey: key)
		XCTAssertNotEqual(StateStorage.shared.value(forKey: key), value)
	}
	
	func testKeychainStorageable_WithSetValidValue_ShouldSaveSuccessfully() {
		let key = #function
		Keychain.shared.set(value, forKey: key)
		XCTAssertEqual(Keychain.shared.value(forKey: key), value)
	}
	
	func testKeychainStorageable_WithRemovingPreviouslySetValue_ShouldEraseIt() {
		let key = #function
		Keychain.shared.set(value, forKey: key)
		Keychain.shared.removeObject(forKey: key)
		XCTAssertNotEqual(Keychain.shared.value(forKey: key), value)
	}
}
