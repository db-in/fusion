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

	class ThrottledMockStorage: DataManageable {
		typealias Storage = StateStorage

		static let interval: TimeInterval = 0.2

		enum Key : String {
			case throttled
			case coalesced
			case immediate
		}

		static func throttleInterval(forKey key: Key) -> TimeInterval {
			switch key {
			case .throttled, .coalesced: return interval
			case .immediate: return 0
			}
		}
	}
	
	enum DynamicKey : Hashable, RawRepresentable, CaseIterable {
		case item(String)
		case fixed

		init?(rawValue: String) {
			if rawValue.hasPrefix("item.") {
				self = .item(String(rawValue.dropFirst("item.".count)))
			} else if rawValue == "fixed" {
				self = .fixed
			} else {
				return nil
			}
		}

		var rawValue: String {
			switch self {
			case .item(let code): return "item.\(code)"
			case .fixed: return "fixed"
			}
		}

		static var allCases: [DynamicKey] { [.fixed] }
	}

	class DynamicMockStorage<S : DataStorageable>: DataManageable {
		typealias Storage = S
		typealias Key = DynamicKey
	}

	class SharedMockStorage: DataManageable {
		typealias Storage = StateStorage
		typealias Key = DynamicKey
	}

	class SharedMockStorageExtended: DataManageable {
		typealias Storage = StateStorage
		typealias Key = DynamicKey
	}

	class IntegerMockStorage: DataManageable {
		typealias Storage = StateStorage

		enum Key : Int, CaseIterable {
			case one = 1
		}
	}

	struct RawKey : RawRepresentable {
		var rawValue: String
	}

	typealias StateDynamic = DynamicMockStorage<StateStorage>
	typealias FileDynamic = DynamicMockStorage<FileManager>
	typealias KeychainDynamic = DynamicMockStorage<Keychain>
	typealias DefaultsDynamic = DynamicMockStorage<UserDefaults>

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

	func testThrottleInterval_WithConformerDefinedInterval_ShouldDeferStorageWriteAndKeepValueReadable() {
		let namespace = ThrottledMockStorage.namespace(ThrottledMockStorage.Key.throttled)

		ThrottledMockStorage.set(value, forKey: .throttled)

		let persisted: String? = StateStorage.shared.value(forKey: namespace)
		XCTAssertNil(persisted)
		XCTAssertEqual(ThrottledMockStorage.value(forKey: .throttled), value)
	}

	func testThrottleInterval_WithZeroInterval_ShouldWriteToStorageImmediately() {
		let namespace = ThrottledMockStorage.namespace(ThrottledMockStorage.Key.immediate)

		ThrottledMockStorage.set(value, forKey: .immediate)

		let persisted: String? = StateStorage.shared.value(forKey: namespace)
		XCTAssertEqual(persisted, value)
	}

	func testThrottleInterval_WithRepeatedWritesInsideTheWindow_ShouldPersistOnlyTheLatestValueAfterTheInterval() {
		let expectation = expectation(description: #function)
		let namespace = ThrottledMockStorage.namespace(ThrottledMockStorage.Key.coalesced)
		let latest = "latest"

		ThrottledMockStorage.set(value, forKey: .coalesced)
		ThrottledMockStorage.set("intermediate", forKey: .coalesced)
		ThrottledMockStorage.set(latest, forKey: .coalesced)

		let duringWindow: String? = StateStorage.shared.value(forKey: namespace)
		XCTAssertNil(duringWindow)

		DispatchQueue.main.asyncAfter(deadline: .now() + ThrottledMockStorage.interval * 2) {
			let afterWindow: String? = StateStorage.shared.value(forKey: namespace)
			XCTAssertEqual(afterWindow, latest)
			expectation.fulfill()
		}

		wait(for: [expectation], timeout: 1.0)
	}

	func testKeys_WithDynamicKeys_ShouldListThemByPrefix() {
		StateDynamic.set(value, forKey: .item("AAPL"))
		StateDynamic.set(value, forKey: .item("TSLA"))
		StateDynamic.set(value, forKey: .fixed)

		XCTAssertEqual(Set(StateDynamic.keys(prefix: "item.")), [.item("AAPL"), .item("TSLA")])
		XCTAssertEqual(Set(StateDynamic.keys()), [.item("AAPL"), .item("TSLA"), .fixed])

		StateDynamic.removeAllKeys()
	}

	func testKeys_WithRemoveAndNilSet_ShouldUntrackThem() {
		StateDynamic.set(value, forKey: .item("REMOVED"))
		StateDynamic.set(value, forKey: .item("NILLED"))
		StateDynamic.set(value, forKey: .item("KEPT"))

		StateDynamic.remove(keys: [.item("REMOVED")])
		StateDynamic.set(nil as String?, forKey: .item("NILLED"))

		XCTAssertEqual(StateDynamic.keys(prefix: "item."), [.item("KEPT")])

		StateDynamic.removeAllKeys()
	}

	func testKeys_WithFileAndKeychainStorages_ShouldPersistTheTrackingInTheirOwnStorage() {
		let expectation = expectation(description: #function)
		let fileKey = FileDynamic.namespace(FileDynamic.Key.item("AAPL"))
		let keychainKey = KeychainDynamic.namespace(KeychainDynamic.Key.item("TOKEN"))

		FileDynamic.set(value, forKey: .item("AAPL"))
		KeychainDynamic.set(value, forKey: .item("TOKEN"))

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			let fileKeys: [String : Bool]? = FileManager.shared.value(forKey: "\(type(of: FileManager.shared)).keys")
			let keychainKeys: [String : Bool]? = Keychain.shared.value(forKey: "\(type(of: Keychain.shared)).keys")
			XCTAssertEqual(fileKeys?[fileKey], true)
			XCTAssertEqual(keychainKeys?[keychainKey], true)

			FileDynamic.removeAllKeys()
			KeychainDynamic.removeAllKeys()
			XCTAssertTrue(FileDynamic.keys().isEmpty)
			XCTAssertTrue(KeychainDynamic.keys().isEmpty)
			XCTAssertNil(FileDynamic.value(forKey: .item("AAPL")) as String?)
			expectation.fulfill()
		}

		wait(for: [expectation], timeout: 3.0)
	}

	func testRemoveAllKeys_WithExceptKeys_ShouldKeepThemTracked() {
		StateDynamic.set(value, forKey: .item("KEEP"))
		StateDynamic.set(value, forKey: .item("DROP"))

		StateDynamic.removeAllKeys(except: [.item("KEEP")])

		XCTAssertEqual(StateDynamic.keys(), [.item("KEEP")])
		XCTAssertEqual(StateDynamic.value(forKey: .item("KEEP")), value)

		StateDynamic.removeAllKeys()
	}

	func testKeys_WithEmptyMemoryCache_ShouldReloadTheTrackedKeysFromStorage() {
		let expectation = expectation(description: #function)

		FileDynamic.set(value, forKey: .item("COLD"))

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			InMemoryCache.flushAll()

			XCTAssertEqual(FileDynamic.keys(prefix: "item."), [.item("COLD")])
			XCTAssertEqual(FileDynamic.value(forKey: .item("COLD")), self.value)

			FileDynamic.removeAllKeys()
			expectation.fulfill()
		}

		wait(for: [expectation], timeout: 3.0)
	}

	func testKeys_WithAnotherTypeNameStartingTheSame_ShouldListOnlyItsOwnKeys() {
		SharedMockStorage.set(value, forKey: .item("OWN"))
		SharedMockStorageExtended.set(value, forKey: .item("OTHER"))

		XCTAssertEqual(SharedMockStorage.keys(), [.item("OWN")])
		XCTAssertEqual(SharedMockStorageExtended.keys(), [.item("OTHER")])

		SharedMockStorage.removeAllKeys()
		SharedMockStorageExtended.removeAllKeys()
	}

	func testRemoveAllKeys_WithAnotherTypeSharingTheStorage_ShouldKeepTheOtherTypeKeysAndValues() {
		SharedMockStorage.set(value, forKey: .item("REMOVED"))
		SharedMockStorageExtended.set(value, forKey: .item("KEPT"))

		SharedMockStorage.removeAllKeys()

		XCTAssertTrue(SharedMockStorage.keys().isEmpty)
		XCTAssertEqual(SharedMockStorageExtended.keys(), [.item("KEPT")])
		XCTAssertEqual(SharedMockStorageExtended.value(forKey: .item("KEPT")), value)

		SharedMockStorageExtended.removeAllKeys()
	}

	func testKeys_WithUserDefaultsStorage_ShouldPersistTheTrackingInUserDefaults() {
		let expectation = expectation(description: #function)
		let defaultsKey = DefaultsDynamic.namespace(DefaultsDynamic.Key.item("SETTING"))

		DefaultsDynamic.set(value, forKey: .item("SETTING"))

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			let defaultsKeys: [String : Bool]? = UserDefaults.shared.value(forKey: "\(type(of: UserDefaults.shared)).keys")
			XCTAssertEqual(defaultsKeys?[defaultsKey], true)
			XCTAssertEqual(DefaultsDynamic.keys(), [.item("SETTING")])

			DefaultsDynamic.removeAllKeys()
			XCTAssertTrue(DefaultsDynamic.keys().isEmpty)
			expectation.fulfill()
		}

		wait(for: [expectation], timeout: 3.0)
	}

	func testTrack_WithUpdateOfAnExistingKey_ShouldNotSaveTheTrackedKeysAgain() {
		let expectation = expectation(description: #function)
		let keysName = "\(type(of: StateStorage.shared)).keys"
		let sentinel = ["sentinel" : true]

		StateDynamic.set(value, forKey: .item("UPDATED"))

		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			StateStorage.shared.set(sentinel, forKey: keysName)
			StateDynamic.set("updated", forKey: .item("UPDATED"))

			DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
				let persisted: [String : Bool]? = StateStorage.shared.value(forKey: keysName)
				XCTAssertEqual(persisted, sentinel)

				StateDynamic.removeAllKeys()
				expectation.fulfill()
			}
		}

		wait(for: [expectation], timeout: 3.0)
	}

	func testKeys_WithValueWrittenDirectlyToTheStorage_ShouldNotTrackIt() {
		let namespace = StateDynamic.namespace(StateDynamic.Key.item("DIRECT"))

		StateStorage.shared.set(value, forKey: namespace)

		XCTAssertFalse(StateDynamic.keys().contains(.item("DIRECT")))

		StateStorage.shared.removeObject(forKey: namespace)
	}

	func testKeys_WithTrackedRawValueTheKeyCannotParse_ShouldSkipIt() {
		let unknown = StateDynamic.namespace(RawKey(rawValue: "unknown"))

		StateDynamic.set(value, forKey: .item("KNOWN"))
		StateStorage.shared.track(key: unknown, isStored: true)

		XCTAssertEqual(StateDynamic.keys(), [.item("KNOWN")])

		StateStorage.shared.track(key: unknown, isStored: false)
		StateDynamic.removeAllKeys()
	}

	func testKeys_WithNonStringRawValues_ShouldNotListThem() {
		IntegerMockStorage.set(value, forKey: .one)

		XCTAssertTrue(IntegerMockStorage.keys().isEmpty)
		XCTAssertEqual(IntegerMockStorage.value(forKey: .one), value)

		IntegerMockStorage.removeAllKeys()
		XCTAssertNil(IntegerMockStorage.value(forKey: .one) as String?)
	}
}
