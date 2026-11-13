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
	struct LoggerTests {
		
// MARK: - Properties
		
		let log1Basic = "Log 1 Basic"
		let log1Full = "Log 1 Full"
		let log2Basic = "Log 2 Basic"
		let log2Full = "Log 2 Full"
		
// MARK: - Protected Methods
		
		@Test
		func localCache_WhenLogsExist_ShouldReturnCache() {
			Logger.flushLocalCache()
			Logger.basic.log(basic: log1Basic, full: log1Full)
			Logger.full.log(basic: log2Basic, full: log2Full)
			
			#expect(Logger.localCache.contains(where: { $0.basic == log1Basic && $0.full == log1Full }))
			#expect(Logger.localCache.contains(where: { $0.basic == log2Basic && $0.full == log2Full }))
		}
		
		@Test
		func localCache_WhenLogsExist_ShouldReturnDateSortedCacheByTheNewest() async throws {
			Logger.flushLocalCache()
			Logger.silent.log(basic: log1Basic, full: log1Full)
			try? await Task.sleep(nanoseconds: 10_000_000)
			Logger.silent.log(basic: log2Basic, full: log2Full)
			
			let first = try #require(Logger.localCache.first)
			let last = try #require(Logger.localCache.last)
			#expect(first.date >= last.date)
		}
		
		@Test
		func localCache_WhenFlushLocalCacheIsCalled_ShouldReturnEmptyCache() {
			Logger.silent.log(full: log1Full)
			Logger.basic.log(full: log1Full)
			Logger.full.log(full: log1Full)
			Logger.silent.log(basic: log1Basic)
			Logger.basic.log(basic: log1Basic)
			Logger.full.log(basic: log1Basic)
			Logger.flushLocalCache()
			
			#expect(Logger.localCache.isEmpty)
		}
		
		@Test
		func localCache_WhenUsingNone_ShouldNotSaveAnyLog() {
			Logger.flushLocalCache()
			Logger.none.log(full: log1Full)
			Logger.none.log(basic: log1Basic)
			Logger.none.log(basic: log1Basic, full: log1Full)
			Logger.flushLocalCache()
			
			#expect(Logger.localCache.isEmpty)
		}
		
		@Test
		func maxFileSize_WhenChanged_ShouldBeAppliedToTheStorage() {
			let original = Logger.maxFileSize
			defer { Logger.maxFileSize = original }
			
			#expect(original == 15 * 1024 * 1024)
			Logger.maxFileSize = 50 * 1024 * 1024
			#expect(Logger.maxFileSize == 50 * 1024 * 1024)
		}
	}
}
