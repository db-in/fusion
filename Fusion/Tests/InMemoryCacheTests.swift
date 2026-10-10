//
//  Created by Diney Bomfim on 5/27/23.
//

import XCTest
@testable import Fusion

// MARK: - Definitions -

// MARK: - Type -

class InMemoryCacheTests: XCTestCase {
	
// MARK: - Protected Methods

	func testGetOrSet_WhenCacheExistsForKeyAndReference_ShouldReturnCachedValue() {
		let key = #function
		let reference = "testReference"
		let cachedValue = "Cached Value"
		let initial = InMemoryCache.getOrSet(key: key, reference: reference, newValue: cachedValue)
		let result = InMemoryCache.getOrSet(key: key, reference: reference, newValue: "New Value")

		XCTAssertEqual(initial, cachedValue)
		XCTAssertEqual(result, cachedValue)
		XCTAssertEqual(initial, result)
	}

	func testGetOrSet_WhenCacheExistsForKeyAndReferenceDoesNotMatch_ShouldReturnNil() {
		let key = #function
		let reference = "testReference"
		let cachedValue = "Cached Value"
		let initial = InMemoryCache.getOrSet(key: key, reference: reference, newValue: cachedValue)
		let result = InMemoryCache.getOrSet(key: key, reference: "New Reference", newValue: "New Value")
		
		XCTAssertNotEqual(initial, result)
	}
	
	func testFlush_WhenCacheExistsForKey_ShouldRemoveCache() {
		let key = #function
		let reference = "testReference"
		let cachedValue = "Cached Value"
		let initial = InMemoryCache.getOrSet(key: key, reference: reference, newValue: cachedValue)
		InMemoryCache.flush(key: key)
		let result = InMemoryCache.getOrSet(key: key, reference: reference, newValue: "New Value")
		
		XCTAssertNotEqual(initial, result)
	}

	func testFlushAll_WhenCalled_ShouldRemoveAllCaches() {
		let key = #function
		let reference = "testReference"
		let cachedValue = "Cached Value"
		let initial = InMemoryCache.getOrSet(key: key, reference: reference, newValue: cachedValue)
		InMemoryCache.flushAll()
		let result = InMemoryCache.getOrSet(key: key, reference: reference, newValue: "New Value")
		
		XCTAssertNotEqual(initial, result)
	}

	func testMutate_WhenNoCacheExistsForKey_ShouldStartFromTheDefaultValue() {
		let key = #function

		InMemoryCache.mutate(key: key, default: [1]) { $0.append(2) }

		XCTAssertEqual(InMemoryCache.get(key: key), [1, 2])
		InMemoryCache.flush(key: key)
	}

	func testMutate_WhenCacheExistsForKey_ShouldMutateItWithoutResolvingTheDefaultValue() {
		let key = #function
		var isDefaultResolved = false
		func makeDefault() -> [Int] {
			isDefaultResolved = true
			return []
		}

		InMemoryCache.set(key: key, newValue: [1])
		InMemoryCache.mutate(key: key, default: makeDefault()) { $0.append(2) }

		XCTAssertEqual(InMemoryCache.get(key: key), [1, 2])
		XCTAssertFalse(isDefaultResolved)
		InMemoryCache.flush(key: key)
	}

	func testMutate_WithTransformReturningAResult_ShouldReturnThatResult() {
		let key = #function

		let count = InMemoryCache.mutate(key: key, default: [1, 2]) { (values: inout [Int]) in
			values.append(3)
			return values.count
		}

		XCTAssertEqual(count, 3)
		InMemoryCache.flush(key: key)
	}

	func testMutate_WithDefaultValueReadingTheCache_ShouldResolveWithoutDeadlock() {
		let key = #function
		let otherKey = key + ".other"

		InMemoryCache.set(key: otherKey, newValue: 10)
		InMemoryCache.mutate(key: key, default: InMemoryCache.get(key: otherKey) ?? 0) { $0 += 1 }

		XCTAssertEqual(InMemoryCache.get(key: key), 11)
		InMemoryCache.flush(key: key)
		InMemoryCache.flush(key: otherKey)
	}

	func testMutate_WithConcurrentCalls_ShouldApplyEveryMutation() {
		let key = #function
		let iterations = 1_000

		DispatchQueue.concurrentPerform(iterations: iterations) { _ in
			InMemoryCache.mutate(key: key, default: 0) { $0 += 1 }
		}

		XCTAssertEqual(InMemoryCache.get(key: key), iterations)
		InMemoryCache.flush(key: key)
	}
}
