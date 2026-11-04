//
//  Created by Diney Bomfim on 11/4/26.
//

import Foundation
import Testing
@testable import Fusion

// MARK: - Definitions -

struct AsyncMockStorage : DataManageable {
	
	typealias Storage = StateStorage
	
	enum Key : String, CaseIterable {
		case value
		case notification
		case stored
	}
}

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct DataBindableAsyncTests {
		
		init() {
			AsyncMockStorage.removeAllKeys()
		}
		
		@Test
		func waitForValue_WhenKeyIsUpdated_ShouldReturnTheNewValue() async {
			let task = Task { () -> String? in await AsyncMockStorage.waitForValue(key: .value) }
			try? await Task.sleep(nanoseconds: 50_000_000)
			AsyncMockStorage.set("updated", forKey: .value)
			#expect(await task.value == "updated")
		}
		
		@Test
		func waitForNotification_WhenKeyIsUpdated_ShouldResume() async {
			let task = Task { await AsyncMockStorage.waitForNotification(key: .notification) }
			try? await Task.sleep(nanoseconds: 50_000_000)
			AsyncMockStorage.set(1, forKey: .notification)
			#expect(await completes(within: 1) { await task.value })
		}
		
		@Test
		func waitForValue_WhenTaskIsCancelled_ShouldReturnNil() async {
			let task = Task { () -> String? in await AsyncMockStorage.waitForValue(key: .value) }
			try? await Task.sleep(nanoseconds: 50_000_000)
			task.cancel()
			let finished = await completes(within: 1) { _ = await task.value }
			#expect(finished)
		}
		
		@Test
		func waitForNotification_WhenTaskIsCancelled_ShouldResume() async {
			let task = Task { await AsyncMockStorage.waitForNotification(key: .notification) }
			try? await Task.sleep(nanoseconds: 50_000_000)
			task.cancel()
			let finished = await completes(within: 1) { await task.value }
			#expect(finished)
		}
		
		@Test
		func stream_WhenKeyIsUpdated_ShouldYieldEveryValueIncludingRemoval() async {
			let task = Task { () -> [String?] in
				var values: [String?] = []
				for await value: String? in AsyncMockStorage.stream(key: .value) {
					values.append(value)
					if values.count == 3 { break }
				}
				return values
			}
			try? await Task.sleep(nanoseconds: 50_000_000)
			AsyncMockStorage.set("first", forKey: .value)
			try? await Task.sleep(nanoseconds: 20_000_000)
			AsyncMockStorage.set("second", forKey: .value)
			try? await Task.sleep(nanoseconds: 20_000_000)
			AsyncMockStorage.remove(keys: [.value], bindType: String.self)
			#expect(await task.value == ["first", "second", nil])
		}
		
		@Test
		func stream_WhenKeyIsUpdated_ShouldYieldVoidNotifications() async {
			let task = Task { () -> Int in
				var count = 0
				for await _ in AsyncMockStorage.stream(key: .notification) as AsyncStream<Void> {
					count += 1
					if count == 2 { break }
				}
				return count
			}
			try? await Task.sleep(nanoseconds: 50_000_000)
			AsyncMockStorage.set(1, forKey: .notification)
			try? await Task.sleep(nanoseconds: 20_000_000)
			AsyncMockStorage.set(2, forKey: .notification)
			#expect(await task.value == 2)
		}
		
		@Test
		func stream_WhenIteratingTaskIsCancelled_ShouldTerminate() async {
			let task = Task {
				for await _ in AsyncMockStorage.stream(key: .value) as AsyncStream<String?> { }
			}
			try? await Task.sleep(nanoseconds: 50_000_000)
			task.cancel()
			#expect(await completes(within: 1) { await task.value })
		}
		
		@Test
		func store_WithSuccessfulOperation_ShouldPersistAndReturnTheValue() async throws {
			let value = try await AsyncMockStorage.store(.stored) { "fresh" }
			let stored: String? = AsyncMockStorage.value(forKey: .stored)
			#expect(value == "fresh")
			#expect(stored == "fresh")
		}
		
		@Test
		func store_WithFailingOperation_ShouldKeepTheExistingValue() async {
			AsyncMockStorage.set("existing", forKey: .stored)
			await #expect(throws: RESTError.self) {
				try await AsyncMockStorage.store(.stored) { () async throws -> String in throw RESTError.unkown(nil) }
			}
			let stored: String? = AsyncMockStorage.value(forKey: .stored)
			#expect(stored == "existing")
		}
		
		@Test
		func store_WithFailingOperationAndDestructiveMode_ShouldRemoveTheExistingValue() async {
			AsyncMockStorage.set("existing", forKey: .stored)
			await #expect(throws: RESTError.self) {
				try await AsyncMockStorage.store(.stored, nonDestructive: false) { () async throws -> String in throw RESTError.unkown(nil) }
			}
			let stored: String? = AsyncMockStorage.value(forKey: .stored)
			#expect(stored == nil)
		}
		
		@Test
		func store_WithSuccessfulOperation_ShouldNotifyTheBinds() async throws {
			let waiter = Task { () -> String? in await AsyncMockStorage.waitForValue(key: .stored) }
			try? await Task.sleep(nanoseconds: 50_000_000)
			try await AsyncMockStorage.store(.stored) { "notified" }
			#expect(await waiter.value == "notified")
		}
		
		@Test
		func waitForValue_WhenAlreadyCancelled_ShouldReturnImmediately() async {
			let task = Task { () -> String? in
				withUnsafeCurrentTask { $0?.cancel() }
				return await AsyncMockStorage.waitForValue(key: .value)
			}
			let finished = await completes(within: 1) { _ = await task.value }
			#expect(finished)
		}
	}
	
	@Suite
	struct DataAppendTests {
		
		init() {
			Data.dataToAppend = nil
		}
		
		@Test
		func appendDataIfNeeded_WithPendingData_ShouldMergeAndFlush() throws {
			Data.dataToAppend = ["extra": "value"]
			let data = try #require(["key": "value"].data)
			let merged = data.appendDataIfNeeded()
			let object = try #require(try JSONSerialization.jsonObject(with: merged) as? [String: String])
			#expect(object == ["key": "value", "extra": "value"])
			#expect(Data.dataToAppend == nil)
		}
		
		@Test
		func appendDataIfNeeded_WithNonJSONData_ShouldKeepThePendingData() {
			Data.dataToAppend = ["extra": "value"]
			let data = Data("plain".utf8)
			#expect(data.appendDataIfNeeded() == data)
			#expect(Data.dataToAppend != nil)
			Data.dataToAppend = nil
		}
		
		@Test
		func appendDataIfNeeded_WithConcurrentCalls_ShouldConsumeThePendingDataOnlyOnce() async throws {
			let data = try #require(["key": "value"].data)
			for _ in 0..<200 {
				Data.dataToAppend = ["extra": "value"]
				let merges = ThreadSafe(wrappedValue: 0)
				await withTaskGroup(of: Void.self) { group in
					for _ in 0..<8 {
						group.addTask {
							if data.appendDataIfNeeded() != data {
								merges.mutate { $0 += 1 }
							}
						}
					}
				}
				#expect(merges.wrappedValue == 1)
			}
		}
	}
}
