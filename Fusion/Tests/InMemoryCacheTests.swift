//
//  Created by Diney Bomfim on 5/27/23.
//

import Foundation
import Testing
@testable import Fusion

// MARK: - Definitions -

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct InMemoryCacheTests {
		
// MARK: - Protected Methods
		
		@Test
		func getOrSet_WhenCacheExistsForKeyAndReference_ShouldReturnCachedValue() {
			let key = #function
			let reference = "testReference"
			let cachedValue = "Cached Value"
			let initial = InMemoryCache.getOrSet(key: key, reference: reference, newValue: cachedValue)
			let result = InMemoryCache.getOrSet(key: key, reference: reference, newValue: "New Value")
			
			#expect(initial == cachedValue)
			#expect(result == cachedValue)
			#expect(initial == result)
		}
		
		@Test
		func getOrSet_WhenCacheExistsForKeyAndReferenceDoesNotMatch_ShouldReturnNil() {
			let key = #function
			let reference = "testReference"
			let cachedValue = "Cached Value"
			let initial = InMemoryCache.getOrSet(key: key, reference: reference, newValue: cachedValue)
			let result = InMemoryCache.getOrSet(key: key, reference: "New Reference", newValue: "New Value")
			
			#expect(initial != result)
		}
		
		@Test
		func flush_WhenCacheExistsForKey_ShouldRemoveCache() {
			let key = #function
			let reference = "testReference"
			let cachedValue = "Cached Value"
			let initial = InMemoryCache.getOrSet(key: key, reference: reference, newValue: cachedValue)
			InMemoryCache.flush(key: key)
			let result = InMemoryCache.getOrSet(key: key, reference: reference, newValue: "New Value")
			
			#expect(initial != result)
		}
		
		@Test
		func flushAll_WhenCalled_ShouldRemoveAllCaches() {
			let key = #function
			let reference = "testReference"
			let cachedValue = "Cached Value"
			let initial = InMemoryCache.getOrSet(key: key, reference: reference, newValue: cachedValue)
			InMemoryCache.flushAll()
			let result = InMemoryCache.getOrSet(key: key, reference: reference, newValue: "New Value")
			
			#expect(initial != result)
		}
		
		@Test
		func mutate_WhenNoCacheExistsForKey_ShouldStartFromTheDefaultValue() {
			let key = #function
			
			InMemoryCache.mutate(key: key, default: [1]) { $0.append(2) }
			
			let stored: [Int]? = InMemoryCache.get(key: key)
			#expect(stored == [1, 2])
			InMemoryCache.flush(key: key)
		}
		
		@Test
		func mutate_WhenCacheExistsForKey_ShouldMutateItWithoutResolvingTheDefaultValue() {
			let key = #function
			var isDefaultResolved = false
			func makeDefault() -> [Int] {
				isDefaultResolved = true
				return []
			}
			
			InMemoryCache.set(key: key, newValue: [1])
			InMemoryCache.mutate(key: key, default: makeDefault()) { $0.append(2) }
			
			let stored: [Int]? = InMemoryCache.get(key: key)
			#expect(stored == [1, 2])
			#expect(!isDefaultResolved)
			InMemoryCache.flush(key: key)
		}
		
		@Test
		func mutate_WithTransformReturningAResult_ShouldReturnThatResult() {
			let key = #function
			
			let count = InMemoryCache.mutate(key: key, default: [1, 2]) { (values: inout [Int]) in
				values.append(3)
				return values.count
			}
			
			#expect(count == 3)
			InMemoryCache.flush(key: key)
		}
		
		@Test
		func mutate_WithDefaultValueReadingTheCache_ShouldResolveWithoutDeadlock() {
			let key = #function
			let otherKey = key + ".other"
			
			InMemoryCache.set(key: otherKey, newValue: 10)
			InMemoryCache.mutate(key: key, default: InMemoryCache.get(key: otherKey) ?? 0) { $0 += 1 }
			
			let stored: Int? = InMemoryCache.get(key: key)
			#expect(stored == 11)
			InMemoryCache.flush(key: key)
			InMemoryCache.flush(key: otherKey)
		}
		
		@Test
		func mutate_WithConcurrentCalls_ShouldApplyEveryMutation() {
			let key = #function
			let iterations = 1_000
			
			DispatchQueue.concurrentPerform(iterations: iterations) { _ in
				InMemoryCache.mutate(key: key, default: 0) { $0 += 1 }
			}
			
			let stored: Int? = InMemoryCache.get(key: key)
			#expect(stored == iterations)
			InMemoryCache.flush(key: key)
		}
	}
}
