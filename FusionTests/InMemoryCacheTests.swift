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
}
