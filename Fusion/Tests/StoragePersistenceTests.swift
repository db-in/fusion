//
//  Created by Diney Bomfim on 11/12/26.
//

import Foundation
import Testing
#if canImport(Combine)
import Combine
#endif
@testable import Fusion

// MARK: - Definitions -

final class SpyStorage : DataStorageable {
	
	static let shared: DataStorageable = SpyStorage()
	static var spy: SpyStorage { shared as! SpyStorage }
	
	let values = ThreadSafe<[String : Any]>(wrappedValue: [:])
	let reads = ThreadSafe<[String : Int]>(wrappedValue: [:])
	let writes = ThreadSafe<[(key: String, value: Any?)]>(wrappedValue: [])
	let gate = ThreadSafe<DispatchSemaphore?>(wrappedValue: nil)
	
	func value<T : Decodable>(forKey key: String) -> T? {
		reads.mutate { $0[key, default: 0] += 1 }
		return values.wrappedValue[key] as? T
	}
	
	func set<T : Encodable>(_ value: T?, forKey key: String) {
		gate.wrappedValue?.wait()
		values.mutate { $0[key] = value }
		writes.mutate { $0.append((key, value)) }
	}
	
	func removeObject(forKey key: String) {
		gate.wrappedValue?.wait()
		values.mutate { $0[key] = nil }
		writes.mutate { $0.append((key, nil)) }
	}
	
	func readCount(_ key: String) -> Int { reads.wrappedValue[key] ?? 0 }
	
	func writes(for key: String) -> [Any?] { writes.wrappedValue.filter { $0.key == key }.map { $0.value } }
}

struct SpyKey : RawRepresentable, Hashable {
	var rawValue: String
	static var unique: SpyKey { .init(rawValue: UUID().uuidString) }
	static var throttledPrefix: String { "throttled." }
	static var changePrefix: String { "change." }
}

struct SpyStore : DataManageable {
	typealias Storage = SpyStorage
	typealias Key = SpyKey
	
	static func throttleInterval(forKey key: SpyKey) -> TimeInterval {
		key.rawValue.hasPrefix(SpyKey.throttledPrefix) ? 10 : 0
	}
	
	static func notifiesOnlyOnChange(forKey key: SpyKey) -> Bool {
		key.rawValue.hasPrefix(SpyKey.changePrefix)
	}
}

struct SyncSpyStore : DataManageable {
	typealias Storage = SpyStorage
	typealias Key = SpyKey
	
	static func persistsAsynchronously(forKey key: SpyKey) -> Bool { false }
}

struct FileStore : DataManageable {
	typealias Storage = FileManager
	typealias Key = SpyKey
}

struct KeychainStore : DataManageable {
	typealias Storage = Keychain
	typealias Key = SpyKey
}

struct DefaultsStore : DataManageable {
	typealias Storage = UserDefaults
	typealias Key = SpyKey
}

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct StoragePersistenceTests {
		
		private var spy: SpyStorage { SpyStorage.spy }
		
		@Test
		func value_WithAbsentKey_ShouldSeeAValueWrittenLaterOutsideTheStore() {
			let key = SpyKey.unique
			let namespace = SpyStore.namespace(key)
			
			#expect(SpyStore.value(forKey: key) as String? == nil)
			spy.values.mutate { $0[namespace] = "external" }
			
			#expect(SpyStore.value(forKey: key) == "external")
		}
		
		@Test
		func value_ReadWithAnotherType_ShouldNotHideTheStoredValue() {
			let key = SpyKey.unique
			
			SpyStore.set("text", forKey: key)
			#expect(SpyStore.value(forKey: key) as Int? == nil)
			
			#expect(SpyStore.value(forKey: key) == "text")
		}
		
		@Test
		func remove_ThenAnExternalWrite_ShouldReadTheNewValue() {
			let key = SpyKey.unique
			let namespace = SyncSpyStore.namespace(key)
			
			SyncSpyStore.set("value", forKey: key)
			SyncSpyStore.remove(keys: [key])
			spy.values.mutate { $0[namespace] = "external" }
			
			#expect(SyncSpyStore.value(forKey: key) == "external")
		}
		
		@Test
		func set_WithSynchronousPersistenceOptOut_ShouldWriteBeforeReturning() {
			let key = SpyKey.unique
			let namespace = SyncSpyStore.namespace(key)
			
			SyncSpyStore.set("value", forKey: key)
			
			#expect(spy.values.wrappedValue[namespace] as? String == "value")
		}
		
		@Test
		func set_WithAsynchronousPersistence_ShouldReadBackImmediatelyAndPersistLater() {
			let key = SpyKey.unique
			let namespace = SpyStore.namespace(key)
			
			SpyStore.set("value", forKey: key)
			#expect(SpyStore.value(forKey: key) == "value")
			
			StoragePersistence.waitForPendingWrites()
			#expect(spy.values.wrappedValue[namespace] as? String == "value")
			#expect(spy.readCount(namespace) == 0)
		}
		
		@Test
		func set_WithNilValue_ShouldReadNilAndRemoveFromStorage() {
			let key = SpyKey.unique
			let namespace = SpyStore.namespace(key)
			
			SpyStore.set("value", forKey: key)
			SpyStore.set(nil as String?, forKey: key)
			
			#expect(SpyStore.value(forKey: key) as String? == nil)
			StoragePersistence.waitForPendingWrites()
			#expect(spy.values.wrappedValue[namespace] == nil)
		}
		
		@Test
		func set_WithNilValueOnAThrottledKey_ShouldNotReadTheStaleValue() {
			let key = SpyKey(rawValue: SpyKey.throttledPrefix + UUID().uuidString)
			let namespace = SpyStore.namespace(key)
			spy.values.mutate { $0[namespace] = "stale" }
			
			SpyStore.set("fresh", forKey: key)
			SpyStore.set(nil as String?, forKey: key)
			
			#expect(SpyStore.value(forKey: key) as String? == nil)
			InMemoryCache.flush(key: namespace)
			#expect(SpyStore.value(forKey: key) as String? == nil)
			
			StoragePersistence.flushPendingWrites()
			#expect(spy.values.wrappedValue[namespace] == nil)
		}
		
		@Test
		func value_AfterMemoryFlushWithAPendingWrite_ShouldReturnTheLatestValue() {
			let key = SpyKey.unique
			let namespace = SpyStore.namespace(key)
			let gate = DispatchSemaphore(value: 0)
			spy.gate.wrappedValue = gate
			
			SpyStore.set("first", forKey: key)
			SpyStore.set("second", forKey: key)
			InMemoryCache.flushAll()
			
			#expect(SpyStore.value(forKey: key) == "second")
			#expect(spy.readCount(namespace) == 0)
			
			spy.gate.wrappedValue = nil
			gate.signal()
			gate.signal()
			StoragePersistence.waitForPendingWrites()
			#expect(spy.values.wrappedValue[namespace] as? String == "second")
		}
		
		@Test
		func set_WithManySequentialWrites_ShouldPersistInOrderAndEndWithTheLatest() {
			let key = SpyKey.unique
			let namespace = SpyStore.namespace(key)
			
			for index in 0..<200 {
				SpyStore.set(index, forKey: key)
			}
			StoragePersistence.waitForPendingWrites()
			
			let persisted = spy.writes(for: namespace).compactMap { $0 as? Int }
			#expect(persisted.last == 199)
			#expect(persisted == persisted.sorted())
			#expect(spy.values.wrappedValue[namespace] as? Int == 199)
		}
		
		@Test
		func remove_WithAsynchronousPersistence_ShouldReadNilAndRemoveFromStorage() {
			let key = SpyKey.unique
			let namespace = SpyStore.namespace(key)
			
			SpyStore.set("value", forKey: key)
			SpyStore.remove(keys: [key])
			
			#expect(SpyStore.value(forKey: key) as String? == nil)
			StoragePersistence.waitForPendingWrites()
			#expect(spy.values.wrappedValue[namespace] == nil)
		}
		
		@Test
		func flushPendingWrites_WithAThrottledWrite_ShouldPersistImmediately() {
			let key = SpyKey(rawValue: SpyKey.throttledPrefix + UUID().uuidString)
			let namespace = SpyStore.namespace(key)
			
			SpyStore.set("throttled", forKey: key)
			#expect(spy.values.wrappedValue[namespace] == nil)
			
			SpyStore.flushPendingWrites()
			#expect(spy.values.wrappedValue[namespace] as? String == "throttled")
			#expect(StoragePersistence.pendingValue(forKey: namespace).found == false)
		}
		
		@Test
		func persistsAsynchronously_ShouldDefaultToFalseForMemoryKeychainAndDefaults() {
			#expect(SpyStore.persistsAsynchronously(forKey: .unique))
			#expect(FileStore.persistsAsynchronously(forKey: .unique))
			#expect(!AsyncMockStorage.persistsAsynchronously(forKey: .value))
			#expect(!KeychainStore.persistsAsynchronously(forKey: .unique))
			#expect(!DefaultsStore.persistsAsynchronously(forKey: .unique))
			#expect(!SyncSpyStore.persistsAsynchronously(forKey: .unique))
		}
		
		@Test
		func notifiesOnlyOnChange_WhenEnabled_ShouldSkipRepeatedValues() async {
			let key = SpyKey(rawValue: SpyKey.changePrefix + UUID().uuidString)
			let cancellable = NSObject()
			let received = ThreadSafe<[String?]>(wrappedValue: [])
			SpyStore.bind(key: key, cancellable: cancellable) { (value: String?) in received.mutate { $0.append(value) } }
			
			SpyStore.set("a", forKey: key)
			SpyStore.set("a", forKey: key)
			SpyStore.set("b", forKey: key)
			SpyStore.set(nil as String?, forKey: key)
			SpyStore.set(nil as String?, forKey: key)
			
			_ = await completes(within: 1) { while received.wrappedValue.count < 3 { await Task.yield() } }
			try? await Task.sleep(nanoseconds: 50_000_000)
			#expect(received.wrappedValue == ["a", "b", nil])
			SpyStore.unbind(key: key, cancellable: cancellable)
		}
		
		@Test
		func notifiesOnlyOnChange_ByDefault_ShouldNotifyEveryWrite() async {
			let key = SpyKey.unique
			let cancellable = NSObject()
			let received = ThreadSafe(wrappedValue: 0)
			SpyStore.bind(key: key, cancellable: cancellable) { (_: String?) in received.mutate { $0 += 1 } }
			
			SpyStore.set("a", forKey: key)
			SpyStore.set("a", forKey: key)
			
			_ = await completes(within: 1) { while received.wrappedValue < 2 { await Task.yield() } }
			#expect(received.wrappedValue == 2)
			SpyStore.unbind(key: key, cancellable: cancellable)
		}
		
		@Test
		func stream_WithBufferingNewest_ShouldKeepOnlyTheLatestValue() async {
			let key = SpyKey.unique
			let stream: AsyncStream<Int?> = SpyStore.stream(key: key, bufferingPolicy: .bufferingNewest(1))
			
			SpyStore.set(1, forKey: key)
			SpyStore.set(2, forKey: key)
			SpyStore.set(3, forKey: key)
			
			var iterator = stream.makeAsyncIterator()
			let first = await iterator.next()
			#expect(first == 3)
		}
		
		@Test
		func stream_WithDefaultBuffering_ShouldKeepEveryValue() async {
			let key = SpyKey.unique
			let stream: AsyncStream<Int?> = SpyStore.stream(key: key)
			
			SpyStore.set(1, forKey: key)
			SpyStore.set(2, forKey: key)
			
			var iterator = stream.makeAsyncIterator()
			let first = await iterator.next()
			let second = await iterator.next()
			#expect(first == 1)
			#expect(second == 2)
		}
		
		@Test
		func send_WhileOtherThreadsBindAndUnbind_ShouldNotDeadlock() async {
			let key = SpyKey.unique
			let holders = (0..<50).map { _ in NSObject() }
			holders.forEach { holder in SpyStore.bind(key: key, cancellable: holder) { (_: Int?) in } }
			
			let finished = await completes(within: 5) {
				await withTaskGroup(of: Void.self) { group in
					for index in 0..<200 {
						group.addTask {
							if index.isMultiple(of: 2) {
								SpyStore.send(forKey: key, value: index)
							} else {
								let holder = NSObject()
								SpyStore.bind(key: key, cancellable: holder) { (_: Int?) in SpyStore.unbind(key: key, cancellable: holder) }
								SpyStore.unbind(key: key, cancellable: holder)
							}
						}
					}
				}
			}
			
			#expect(finished)
			holders.forEach { SpyStore.unbind(key: key, cancellable: $0) }
		}
		
		@Test
		func stream_WhenConsumerUnbindsInsideDelivery_ShouldNotDeadlock() async {
			let key = SpyKey.unique
			let finished = await completes(within: 2) {
				let stream: AsyncStream<Int?> = SpyStore.stream(key: key)
				let consumer = Task { () -> Int? in
					for await value in stream { return value }
					return nil
				}
				try? await Task.sleep(nanoseconds: 20_000_000)
				SpyStore.send(forKey: key, value: 7)
				SpyStore.send(forKey: key, value: 8)
				_ = await consumer.value
			}
			#expect(finished)
		}
		
		@Test
		func namespace_ShouldUseTheCachedTypePrefix() {
			let expected = "\(Constant.isDebug ? "d-" : "")SpyStore.key"
			#expect(SpyStore.namespace(SpyKey(rawValue: "key")) == expected)
			#expect(SpyStore.prefix == SpyStore.prefix)
			#expect(SyncSpyStore.prefix != SpyStore.prefix)
		}
		
#if canImport(Combine)
		@Test
		func bindPublisher_AfterResubscription_ShouldStillDeliverOnMain() async {
			let key = SpyKey.unique
			let publisher: AnyPublisher<String?, Never> = SpyStore.bind(key: key)
			let first = publisher.sink { _ in }
			first.cancel()
			
			let received = ThreadSafe<(value: String?, isMain: Bool)?>(wrappedValue: nil)
			let second = SpyStore.bind(key: key).sink { (value: String?) in
				received.wrappedValue = (value, Thread.isMainThread)
			}
			
			SpyStore.set("published", forKey: key)
			_ = await completes(within: 1) { while received.wrappedValue == nil { await Task.yield() } }
			
			#expect(received.wrappedValue?.value == "published")
			#expect(received.wrappedValue?.isMain == true)
			second.cancel()
		}
		
		@Test
		func bindPublisher_WithMultipleSubscribers_ShouldDeliverToEachAndUnbindWhenAllCancel() async {
			let key = SpyKey.unique
			let count = ThreadSafe(wrappedValue: 0)
			let subscriptions = (0..<3).map { _ in SpyStore.bind(key: key).sink { count.mutate { $0 += 1 } } }
			
			SpyStore.send(forKey: key, value: 1)
			_ = await completes(within: 1) { while count.wrappedValue < 3 { await Task.yield() } }
			#expect(count.wrappedValue == 3)
			
			subscriptions.forEach { $0.cancel() }
			SpyStore.send(forKey: key, value: 2)
			try? await Task.sleep(nanoseconds: 50_000_000)
			#expect(count.wrappedValue == 3)
		}
#endif
	}
}
