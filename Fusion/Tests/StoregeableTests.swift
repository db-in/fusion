//
//  Created by Diney on 5/7/23.
//

import Foundation
import Testing
@testable import Fusion

// MARK: - Definitions -

private final class BindTarget: NSObject {
	
	private let action: () -> Void
	
	init(_ action: @escaping () -> Void = {}) {
		self.action = action
		super.init()
	}
	
	@objc func callback() {
		action()
	}
}

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct StoregeableTests {
		
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
		
// MARK: - Protected Methods
		
		@Test
		func dataManageable_WithSet_ShouldSaveValueAndNotifyBinds() async {
			let cancellable = NSObject()
			let received = ThreadSafe(wrappedValue: nil as String?)
			let finished = await completes(within: 1) {
				await withCheckedContinuation { continuation in
					MockStorage.bind(key: .singleTest, cancellable: cancellable) { (newValue: String?) in
						received.wrappedValue = newValue
						MockStorage.unbind(key: .singleTest, cancellable: cancellable)
						continuation.resume()
					}
					
					MockStorage.set(value, forKey: .singleTest)
					#expect(MockStorage.value(forKey: .singleTest) == value)
				}
			}
			
			#expect(finished)
			#expect(received.wrappedValue == value)
		}
		
		@Test
		func dataManageable_WithSeveralBindCombinations_ShouldProperlyCallAssignedClosure() async {
			let value = value
			let fired = ThreadSafe(wrappedValue: 0)
			let target = BindTarget {
				#expect(MockStorage.value(forKey: .multiTest) == value)
			}
			
			let finished = await completes(within: 1) {
				await withCheckedContinuation { continuation in
					let fulfill = {
						let total = fired.mutate { count -> Int in
							count += 1
							return count
						}
						if total == 4 { continuation.resume() }
					}
					
					MockStorage.bind(key: .multiTest, target: target, method: #selector(BindTarget.callback))
					MockStorage.bind(key: .multiTest, target: target, method: #selector(BindTarget.callback))
					
					MockStorage.bind(key: .multiTest, cancellable: target) { (newValue: String?) in
						#expect(newValue == value)
						fulfill()
					}
					
					MockStorage.bind(key: .multiTest, cancellable: target) { (newValue: String?) in
						#expect(newValue == value)
						fulfill()
					}
					
					MockStorage.bind(key: .multiTest, cancellable: target) {
						#expect(MockStorage.value(forKey: .multiTest) == value)
						fulfill()
					}
					
					MockStorage.bind(key: .multiTest, cancellable: target) {
						#expect(MockStorage.value(forKey: .multiTest) == value)
						fulfill()
					}
					
					MockStorage.set(value, forKey: .multiTest)
				}
			}
			
			#expect(finished)
			#expect(fired.wrappedValue == 4)
			MockStorage.unbind(key: .multiTest, cancellable: target)
		}
		
		@Test
		func dataManageable_WithValue_ShouldRetrieveTheValueCorrectly() {
			MockStorage.set(value, forKey: .singleTest)
			#expect(MockStorage.value(forKey: .singleTest) == value)
		}
		
		@Test
		func dataManageable_WithRemoveMultipleKeys_ShouldRemoveTheKeys() {
			MockStorage.set(value, forKey: .singleTest)
			MockStorage.set(value, forKey: .dualTest)
			MockStorage.remove(keys: [.singleTest, .dualTest])
			#expect(MockStorage.value(forKey: .singleTest) != value)
			#expect(MockStorage.value(forKey: .dualTest) != value)
		}
		
		@Test
		func dataManageable_WithMapPreservingCache_ShouldNotOverrideLocalData() async throws {
			let (first, _) = await awaitResponse { MockStorage.map(.mapTest, to: $0)(.success(value), nil) }
			#expect(try first.get() == value)
			#expect(MockStorage.value(forKey: .mapTest) == value)
			
			let (second, _): (Result<String, Error>, URLResponse?) = await awaitResponse {
				MockStorage.map(.mapTest, nonDestructive: true, to: $0)(.failure(MockError.ordinary), nil)
			}
			let newValue: String? = try? second.get()
			let oldValue: String? = MockStorage.value(forKey: .mapTest)
			#expect(newValue == nil)
			#expect(oldValue == value)
		}
		
		@Test
		func dataManageable_WithMapDiscardingCache_ShouldOverrideLocalData() async throws {
			let (first, _) = await awaitResponse { MockStorage.map(.mapTest, to: $0)(.success(value), nil) }
			#expect(try first.get() == value)
			#expect(MockStorage.value(forKey: .mapTest) == value)
			
			let (second, _): (Result<String, Error>, URLResponse?) = await awaitResponse {
				MockStorage.map(.mapTest, nonDestructive: false, to: $0)(.failure(MockError.ordinary), nil)
			}
			let newValue: String? = try? second.get()
			let oldValue: String? = MockStorage.value(forKey: .mapTest)
			#expect(newValue == nil)
			#expect(oldValue == nil)
		}
		
		@Test
		func dataManageable_WithRemoveAllKeys_ShouldRemoveAllKindsAndNotifyBinds() async {
			let value = value
			let cancellable = NSObject()
			let finished = await completes(within: 1) {
				await withCheckedContinuation { continuation in
					MockStorage.bind(key: .dualTest, cancellable: cancellable) { (newValue: String?) in
						if newValue != nil {
							#expect(newValue == value)
						} else {
							MockStorage.unbind(key: .dualTest, cancellable: cancellable)
							continuation.resume()
						}
					}
					
					MockStorage.set(value, forKey: .singleTest)
					MockStorage.set(value, forKey: .dualTest)
					MockStorage.remove(keys: [.dualTest], bindType: String.self)
					#expect(MockStorage.value(forKey: .singleTest) == value)
				}
			}
			
			#expect(finished)
		}
		
		@Test
		func userDefaultsStorageable_WithSetValidValue_ShouldSaveSuccessfully() {
			let key = #function
			UserDefaults.shared.set(value, forKey: key)
			#expect(UserDefaults.shared.value(forKey: key) == value)
		}
		
		@Test
		func userDefaultsStorageable_WithRemovingPreviouslySetValue_ShouldEraseIt() {
			let key = #function
			UserDefaults.shared.set(value, forKey: key)
			UserDefaults.shared.removeObject(forKey: key)
			#expect(UserDefaults.shared.value(forKey: key) != value)
		}
		
		@Test
		func fileManagerStorageable_WithSetValidValue_ShouldSaveSuccessfully() {
			let key = #function
			FileManager.shared.set(value, forKey: key)
			#expect(FileManager.shared.value(forKey: key) == value)
		}
		
		@Test
		func fileManagerStorageable_WithRemovingPreviouslySetValue_ShouldEraseIt() {
			let key = #function
			FileManager.shared.set(value, forKey: key)
			FileManager.shared.removeObject(forKey: key)
			#expect(FileManager.shared.value(forKey: key) != value)
		}
		
		@Test
		func stateStorageable_WithSetValidValue_ShouldSaveSuccessfully() {
			let key = #function
			StateStorage.shared.set(value, forKey: key)
			#expect(StateStorage.shared.value(forKey: key) == value)
		}
		
		@Test
		func stateStorageable_WithRemovingPreviouslySetValue_ShouldEraseIt() {
			let key = #function
			StateStorage.shared.set(value, forKey: key)
			StateStorage.shared.removeObject(forKey: key)
			#expect(StateStorage.shared.value(forKey: key) != value)
		}
		
		@Test
		func keychainStorageable_WithSetValidValue_ShouldSaveSuccessfully() {
			let key = #function
			Keychain.shared.set(value, forKey: key)
			#expect(Keychain.shared.value(forKey: key) == value)
		}
		
		@Test
		func keychainStorageable_WithRemovingPreviouslySetValue_ShouldEraseIt() {
			let key = #function
			Keychain.shared.set(value, forKey: key)
			Keychain.shared.removeObject(forKey: key)
			#expect(Keychain.shared.value(forKey: key) != value)
		}
		
		@Test
		func throttleInterval_WithConformerDefinedInterval_ShouldDeferStorageWriteAndKeepValueReadable() {
			let namespace = ThrottledMockStorage.namespace(ThrottledMockStorage.Key.throttled)
			
			ThrottledMockStorage.set(value, forKey: .throttled)
			
			let persisted: String? = StateStorage.shared.value(forKey: namespace)
			#expect(persisted == nil)
			#expect(ThrottledMockStorage.value(forKey: .throttled) == value)
		}
		
		@Test
		func throttleInterval_WithZeroInterval_ShouldWriteToStorageImmediately() {
			let namespace = ThrottledMockStorage.namespace(ThrottledMockStorage.Key.immediate)
			
			ThrottledMockStorage.set(value, forKey: .immediate)
			
			let persisted: String? = StateStorage.shared.value(forKey: namespace)
			#expect(persisted == value)
		}
		
		@Test
		func throttleInterval_WithRepeatedWritesInsideTheWindow_ShouldPersistOnlyTheLatestValueAfterTheInterval() async {
			let namespace = ThrottledMockStorage.namespace(ThrottledMockStorage.Key.coalesced)
			let latest = "latest"
			
			ThrottledMockStorage.set(value, forKey: .coalesced)
			ThrottledMockStorage.set("intermediate", forKey: .coalesced)
			ThrottledMockStorage.set(latest, forKey: .coalesced)
			
			let duringWindow: String? = StateStorage.shared.value(forKey: namespace)
			#expect(duringWindow == nil)
			
			try? await Task.sleep(nanoseconds: UInt64(ThrottledMockStorage.interval * 2 * 1_000_000_000))
			
			let afterWindow: String? = StateStorage.shared.value(forKey: namespace)
			#expect(afterWindow == latest)
		}
		
		@Test
		func keys_WithDynamicKeys_ShouldListThemByPrefix() {
			StateDynamic.set(value, forKey: .item("AAPL"))
			StateDynamic.set(value, forKey: .item("TSLA"))
			StateDynamic.set(value, forKey: .fixed)
			
			#expect(Set(StateDynamic.keys(prefix: "item.")) == [.item("AAPL"), .item("TSLA")])
			#expect(Set(StateDynamic.keys()) == [.item("AAPL"), .item("TSLA"), .fixed])
			
			StateDynamic.removeAllKeys()
		}
		
		@Test
		func keys_WithRemoveAndNilSet_ShouldUntrackThem() {
			StateDynamic.set(value, forKey: .item("REMOVED"))
			StateDynamic.set(value, forKey: .item("NILLED"))
			StateDynamic.set(value, forKey: .item("KEPT"))
			
			StateDynamic.remove(keys: [.item("REMOVED")])
			StateDynamic.set(nil as String?, forKey: .item("NILLED"))
			
			#expect(StateDynamic.keys(prefix: "item.") == [.item("KEPT")])
			
			StateDynamic.removeAllKeys()
		}
		
		@Test
		func keys_WithFileAndKeychainStorages_ShouldPersistTheTrackingInTheirOwnStorage() async {
			let fileKey = FileDynamic.namespace(FileDynamic.Key.item("AAPL"))
			let keychainKey = KeychainDynamic.namespace(KeychainDynamic.Key.item("TOKEN"))
			
			FileDynamic.set(value, forKey: .item("AAPL"))
			KeychainDynamic.set(value, forKey: .item("TOKEN"))
			
			try? await Task.sleep(nanoseconds: 300_000_000)
			
			let fileKeys: [String : Bool]? = FileManager.shared.value(forKey: "\(type(of: FileManager.shared)).keys")
			let keychainKeys: [String : Bool]? = Keychain.shared.value(forKey: "\(type(of: Keychain.shared)).keys")
			#expect(fileKeys?[fileKey] == true)
			#expect(keychainKeys?[keychainKey] == true)
			
			FileDynamic.removeAllKeys()
			KeychainDynamic.removeAllKeys()
			#expect(FileDynamic.keys().isEmpty)
			#expect(KeychainDynamic.keys().isEmpty)
			#expect(FileDynamic.value(forKey: .item("AAPL")) as String? == nil)
		}
		
		@Test
		func removeAllKeys_WithExceptKeys_ShouldKeepThemTracked() {
			StateDynamic.set(value, forKey: .item("KEEP"))
			StateDynamic.set(value, forKey: .item("DROP"))
			
			StateDynamic.removeAllKeys(except: [.item("KEEP")])
			
			#expect(StateDynamic.keys() == [.item("KEEP")])
			#expect(StateDynamic.value(forKey: .item("KEEP")) == value)
			
			StateDynamic.removeAllKeys()
		}
		
		@Test
		func keys_WithEmptyMemoryCache_ShouldReloadTheTrackedKeysFromStorage() {
			FileDynamic.set(value, forKey: .item("COLD"))
			FileDynamic.flushPendingWrites()
			InMemoryCache.flushAll()
			
			#expect(FileDynamic.keys(prefix: "item.") == [.item("COLD")])
			#expect(FileDynamic.value(forKey: .item("COLD")) == value)
			
			FileDynamic.removeAllKeys()
		}
		
		@Test
		func keys_WithAnotherTypeNameStartingTheSame_ShouldListOnlyItsOwnKeys() {
			SharedMockStorage.set(value, forKey: .item("OWN"))
			SharedMockStorageExtended.set(value, forKey: .item("OTHER"))
			
			#expect(SharedMockStorage.keys() == [.item("OWN")])
			#expect(SharedMockStorageExtended.keys() == [.item("OTHER")])
			
			SharedMockStorage.removeAllKeys()
			SharedMockStorageExtended.removeAllKeys()
		}
		
		@Test
		func removeAllKeys_WithAnotherTypeSharingTheStorage_ShouldKeepTheOtherTypeKeysAndValues() {
			SharedMockStorage.set(value, forKey: .item("REMOVED"))
			SharedMockStorageExtended.set(value, forKey: .item("KEPT"))
			
			SharedMockStorage.removeAllKeys()
			
			#expect(SharedMockStorage.keys().isEmpty)
			#expect(SharedMockStorageExtended.keys() == [.item("KEPT")])
			#expect(SharedMockStorageExtended.value(forKey: .item("KEPT")) == value)
			
			SharedMockStorageExtended.removeAllKeys()
		}
		
		@Test
		func keys_WithUserDefaultsStorage_ShouldPersistTheTrackingInUserDefaults() async {
			let defaultsKey = DefaultsDynamic.namespace(DefaultsDynamic.Key.item("SETTING"))
			
			DefaultsDynamic.set(value, forKey: .item("SETTING"))
			
			try? await Task.sleep(nanoseconds: 300_000_000)
			
			let defaultsKeys: [String : Bool]? = UserDefaults.shared.value(forKey: "\(type(of: UserDefaults.shared)).keys")
			#expect(defaultsKeys?[defaultsKey] == true)
			#expect(DefaultsDynamic.keys() == [.item("SETTING")])
			
			DefaultsDynamic.removeAllKeys()
			#expect(DefaultsDynamic.keys().isEmpty)
		}
		
		@Test
		func track_WithUpdateOfAnExistingKey_ShouldNotSaveTheTrackedKeysAgain() async {
			let keysName = "\(type(of: StateStorage.shared)).keys"
			let sentinel = ["sentinel" : true]
			
			StateDynamic.set(value, forKey: .item("UPDATED"))
			
			try? await Task.sleep(nanoseconds: 300_000_000)
			StateStorage.shared.set(sentinel, forKey: keysName)
			StateDynamic.set("updated", forKey: .item("UPDATED"))
			
			try? await Task.sleep(nanoseconds: 300_000_000)
			let persisted: [String : Bool]? = StateStorage.shared.value(forKey: keysName)
			#expect(persisted == sentinel)
			
			StateDynamic.removeAllKeys()
		}
		
		@Test
		func keys_WithValueWrittenDirectlyToTheStorage_ShouldNotTrackIt() {
			let namespace = StateDynamic.namespace(StateDynamic.Key.item("DIRECT"))
			
			StateStorage.shared.set(value, forKey: namespace)
			
			#expect(!StateDynamic.keys().contains(.item("DIRECT")))
			
			StateStorage.shared.removeObject(forKey: namespace)
		}
		
		@Test
		func keys_WithTrackedRawValueTheKeyCannotParse_ShouldSkipIt() {
			let unknown = StateDynamic.namespace(RawKey(rawValue: "unknown"))
			
			StateDynamic.set(value, forKey: .item("KNOWN"))
			StateStorage.shared.track(key: unknown, isStored: true)
			
			#expect(StateDynamic.keys() == [.item("KNOWN")])
			
			StateStorage.shared.track(key: unknown, isStored: false)
			StateDynamic.removeAllKeys()
		}
		
		@Test
		func keys_WithNonStringRawValues_ShouldNotListThem() {
			IntegerMockStorage.set(value, forKey: .one)
			
			#expect(IntegerMockStorage.keys().isEmpty)
			#expect(IntegerMockStorage.value(forKey: .one) == value)
			
			IntegerMockStorage.removeAllKeys()
			#expect(IntegerMockStorage.value(forKey: .one) as String? == nil)
		}
	}
}
