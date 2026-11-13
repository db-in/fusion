//
//  Created by Diney Bomfim on 11/13/26.
//

import XCTest
@testable import Fusion

// MARK: - Definitions -

private struct BenchmarkQuote : Codable {
	let id: Int
	let symbol: String
	let price: Double
	let tags: [String]
	let updated: Date
}

private struct BenchmarkPrice : Codable {
	let price: Double
	let symbol: String
}

private struct BenchmarkRow {
	let name: String
	let detail: String
}

private struct BenchmarkBindStorage : DataManageable {
	typealias Storage = StateStorage
	enum Key : String, CaseIterable {
		case price
	}
}

// MARK: - Type -

final class CorePerformanceTests : PerformanceTestCase {
	
// MARK: - Properties
	
	private let quote = BenchmarkQuote(id: 1, symbol: "AAPL", price: 189.25, tags: ["tech", "nasdaq"], updated: Date(timeIntervalSince1970: 1_700_000_000))
	
	private lazy var quoteData = quote.data ?? Data()
	
	private lazy var quotesData = (0..<500).map {
		BenchmarkQuote(id: $0, symbol: "SYM\($0)", price: Double($0) * 1.5, tags: ["tag\($0 % 7)"], updated: quote.updated)
	}.data ?? Data()
	
	private let rows = (0..<1_000).map { BenchmarkRow(name: "Instrument \($0)", detail: "Market \($0 % 20)") }
	
	private let kilobyte = Data((0..<1_024).map { UInt8($0 % 256) })
	
// MARK: - JSON
	
	func testJSONEncode() {
		measureLoop { _ in _ = quote.data }
	}
	
	func testJSONDecode() {
		let data = quoteData
		measureLoop { _ in _ = BenchmarkQuote.load(data: data) }
	}
	
	func testJSONDecodeArrayOf500() {
		let data = quotesData
		measureLoop(iterations: 20) { _ in _ = [BenchmarkQuote].load(data: data) }
	}
	
	func testAnyCodableKeyPathMap() {
		let object = AnyCodable(["data": ["quote": ["price": 189.25, "symbol": "AAPL"]]])
		measureLoop { _ in _ = object.map(to: BenchmarkPrice.self, keyPath: "data.quote") }
	}
	
// MARK: - Encryption and Text
	
	func testSHA256OfOneKilobyte() {
		let data = kilobyte
		measureLoop { _ in _ = data.sha256() }
	}
	
	func testHMACSHA256() {
		measureLoop { _ = "message \($0)".hmacSHA256(key: "secret") }
	}
	
	func testBase64Encode() {
		measureLoop { _ = "payload \($0)".encryptBase64 }
	}
	
	func testRegexReplacing() {
		measureLoop { _ = "price \($0).56 USD".replacing(regex: "[0-9]", with: "#") }
	}
	
	func testContainsCharacters() {
		measureLoop { _ = "Apple Inc. \($0)".containsCharacters("apl") }
	}
	
// MARK: - Collections
	
	func testUniqueOf1000() {
		let values = (0..<1_000).map { $0 % 100 }
		measureLoop(iterations: 200) { _ in _ = values.unique() }
	}
	
	func testFilteredByTextOf1000() {
		let rows = rows
		measureLoop(iterations: 50) { _ = rows.filtered(by: "\($0 % 10)", fields: [\.name, \.detail]) }
	}
	
// MARK: - Concurrency and Memory Cache
	
	func testThreadSafeRead() {
		let value = ThreadSafe(wrappedValue: 0)
		measureLoop { _ in _ = value.wrappedValue }
	}
	
	func testThreadSafeMutate() {
		let value = ThreadSafe(wrappedValue: 0)
		measureLoop { _ in value.mutate { $0 += 1 } }
	}
	
	func testInMemoryCacheGetOrSet() {
		measureLoop { _ = InMemoryCache.getOrSet(key: "benchmark.\($0 % 100)", newValue: $0) }
		(0..<100).forEach { InMemoryCache.flush(key: "benchmark.\($0)") }
	}
	
// MARK: - Storage
	
	func testStateStorageSetAndRead() {
		measureLoop {
			let key = IndexedKey(rawValue: "state.\($0 % 50)")
			IndexedStateStorage.set($0, forKey: key)
			_ = IndexedStateStorage.value(forKey: key) as Int?
		}
		IndexedStateStorage.removeAllKeys()
	}
	
	func testKeychainWriteAndRead() {
		let keychain = Keychain()
		measureLoop(iterations: 100) {
			let key = "fusion.benchmark.\($0 % 10)"
			keychain[key] = Data("value \($0)".utf8)
			_ = keychain[key]
		}
		(0..<10).forEach { keychain["fusion.benchmark.\($0)"] = nil }
	}
	
	func testFlushPendingWritesWhenIdle() {
		StoragePersistence.flushPendingWrites()
		measureLoop(iterations: 1_000) { _ in StoragePersistence.flushPendingWrites() }
	}
	
	func testFlushPendingWritesWith50TrackedFileKeys() {
		let keys = (0..<50).map { IndexedKey(rawValue: "flush.\($0)") }
		measure(setUp: {
			keys.enumerated().forEach { IndexedFileStorage.set($0.offset, forKey: $0.element) }
		}) {
			IndexedFileStorage.flushPendingWrites()
		}
		IndexedFileStorage.remove(keys: keys)
		IndexedFileStorage.flushPendingWrites()
	}
	
// MARK: - Binding
	
	func testSendToTenSubscribers() {
		let cancellables = (0..<10).map { _ in NSObject() }
		cancellables.forEach { BenchmarkBindStorage.bind(key: .price, cancellable: $0) { (_: Double?) in } }
		measureLoop { BenchmarkBindStorage.send(forKey: .price, value: Double($0)) }
		cancellables.forEach { BenchmarkBindStorage.unbind(key: .price, cancellable: $0) }
		drainMainQueue()
	}
	
// MARK: - Animation Math
	
	func testEaseCalculate() {
		let eases = Ease.allCases
		measureLoop { _ = eases[$0 % eases.count].calculate(0, 100, FPoint($0 % 100) / 100) }
	}
}
