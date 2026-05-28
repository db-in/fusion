//
//  Created by Diney Bomfim on 5/27/23.
//

import XCTest
@testable import Fusion

// MARK: - Definitions -

// MARK: - Type -

class LoggerTests: XCTestCase {

// MARK: - Properties
	
	let log1Basic = "Log 1 Basic"
	let log1Full = "Log 1 Full"
	let log2Basic = "Log 2 Basic"
	let log2Full = "Log 2 Full"
	
// MARK: - Protected Methods
	
	func testLocalCache_WhenLogsExist_ShouldReturnCache() {
		Logger.flushLocalCache()
		Logger.basic.log(basic: log1Basic, full: log1Full)
		Logger.full.log(basic: log2Basic, full: log2Full)
		
		XCTAssertTrue(Logger.localCache.contains(where: { $0.basic == log1Basic && $0.full == log1Full }))
		XCTAssertTrue(Logger.localCache.contains(where: { $0.basic == log2Basic && $0.full == log2Full }))
	}
	
	func testLocalCache_WhenLogsExist_ShouldReturnDateSortedCacheByTheNewest() {
		let expectation = expectation(description: #function)
		
		Logger.flushLocalCache()
		Logger.silent.log(basic: log1Basic, full: log1Full)
		DispatchQueue.main.async {
			Logger.silent.log(basic: self.log2Basic, full: self.log2Full)
			XCTAssertTrue(Logger.localCache.first!.date >= Logger.localCache.last!.date)
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 1.0)
	}
	
	func testLocalCache_WhenFlushLocalCacheIsCalled_ShouldReturnEmptyCache() {
		Logger.silent.log(full: log1Full)
		Logger.basic.log(full: log1Full)
		Logger.full.log(full: log1Full)
		Logger.silent.log(basic: log1Basic)
		Logger.basic.log(basic: log1Basic)
		Logger.full.log(basic: log1Basic)
		Logger.flushLocalCache()
		
		XCTAssertTrue(Logger.localCache.isEmpty)
	}
	
	func testLocalCache_WhenUsingNone_ShouldNotSaveAnyLog() {
		Logger.flushLocalCache()
		Logger.none.log(full: log1Full)
		Logger.none.log(basic: log1Basic)
		Logger.none.log(basic: log1Basic, full: log1Full)
		Logger.flushLocalCache()
		
		XCTAssertTrue(Logger.localCache.isEmpty)
	}
}
