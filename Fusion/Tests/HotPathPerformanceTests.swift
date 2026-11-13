//
//  Created by Diney Bomfim on 11/12/26.
//

import XCTest
#if canImport(SwiftUI)
import SwiftUI
#endif
@testable import Fusion

// MARK: - Type -

final class HotPathPerformanceTests : XCTestCase {
	
	private let iterations = 2_000
	private let english = Locale(identifier: "en_US")
	private let arabic = Locale(identifier: "ar_SA")
	private let reference = Date(timeIntervalSince1970: 1_700_000_000)
	
	private func measureLoop(_ work: (Int) -> Void) {
		measure(metrics: [XCTClockMetric()]) {
			for index in 0..<iterations {
				work(index)
			}
		}
	}
	
	func testNumberToString() {
		measureLoop { _ = (Double($0) + 0.1234).toString(decimals: 2, locale: english, roundingMode: .halfUp) }
	}
	
	func testConvertedDigitsToLocale() {
		measureLoop { _ = "\($0)".convertedDigitsToLocale(arabic) }
	}
	
	func testDateToStringWithFormat() {
		measureLoop { _ = reference.addingTimeInterval(Double($0)).toString(format: "yyyy-MM-dd HH:mm") }
	}
	
	func testUTCDateParsing() {
		measureLoop { _ = DateFormatter.date(from: "2023-11-14T22:13:\(String(format: "%02d", $0 % 60)).123+0000") }
	}
	
	func testUTCDateFormatting() {
		measureLoop { _ = DateFormatter.string(from: reference.addingTimeInterval(Double($0))) }
	}
	
	func testTimeUnits() {
		measureLoop { _ = $0.toTimeUnits() }
	}
	
	func testAppGroupURL() {
		measureLoop { _ in _ = FileManager.default.appGroup }
	}
	
	func testSilentLoggerWithoutSaving() {
		measureLoop { index in Logger.silent.log(basic: "basic \(index)", full: "full \(index)", save: false) }
	}
	
	func testAbsentKeyReads() {
		measureLoop { _ = IndexedFileStorage.value(forKey: IndexedKey(rawValue: "absent.\($0 % 20)")) as String? }
	}
	
	func testPresentKeyColdReads() {
		let keys = (0..<20).map { IndexedKey(rawValue: "present.\($0)") }
		keys.forEach { IndexedFileStorage.set("value \($0.rawValue)", forKey: $0) }
		IndexedFileStorage.flushPendingWrites()
		measureLoop {
			let key = keys[$0 % keys.count]
			InMemoryCache.flush(key: IndexedFileStorage.namespace(key))
			_ = IndexedFileStorage.value(forKey: key) as String?
		}
		IndexedFileStorage.remove(keys: keys)
		IndexedFileStorage.flushPendingWrites()
	}
	
	func testFileStorageWrites() {
		measureLoop { IndexedFileStorage.set($0, forKey: IndexedKey(rawValue: "hot.\($0 % 20)")) }
		IndexedFileStorage.removeAllKeys()
	}
	
	func testPreferredLocale() {
		measureLoop { _ in _ = Locale.preferredLocale }
	}
	
	func testLocalized() {
		measureLoop { _ = "key_\($0 % 50)".localized() }
	}
	
#if canImport(SwiftUI)
	func testColorHex() {
		measureLoop { _ = Color(hex: "#FF\(String(format: "%02X", $0 % 16))00") }
	}
#endif
}
