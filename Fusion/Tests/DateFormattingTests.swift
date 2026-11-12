//
//  Created by Diney Bomfim on 11/12/26.
//

import Foundation
import Testing
@testable import Fusion

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct DateFormattingTests {
		
		private let reference = Date(timeIntervalSince1970: 1_700_000_000.123)
		
		@Test
		func utcDate_WithMillisecondsFormat_ShouldRoundTrip() {
			let string = DateFormatter.string(from: reference)
			#expect(string == "2023-11-14T22:13:20.123+0000")
			#expect(abs(DateFormatter.date(from: string).timeIntervalSince(reference)) < 0.001)
		}
		
		@Test
		func utcDate_WithSecondsFormat_ShouldFallBackToTheSecondFormat() {
			let date = DateFormatter.date(from: "2023-11-14T22:13:20+0000")
			#expect(date.timeIntervalSince1970 == 1_700_000_000)
		}
		
		@Test
		func utcDate_WithInvalidString_ShouldReturnNow() {
			let date = DateFormatter.date(from: "invalid")
			#expect(abs(date.timeIntervalSinceNow) < 1)
		}
		
		@Test
		func utc_ShouldStillReturnAFreshConfigurableFormatter() {
			let first = DateFormatter.utc
			let second = DateFormatter.utc
			#expect(first !== second)
			#expect(first.timeZone == TimeZone(secondsFromGMT: 0))
			#expect(first.locale.identifier == "en_US_POSIX")
		}
		
		@Test
		func standardDates_WithJSONCoding_ShouldRoundTrip() throws {
			struct Payload : Codable, Equatable { let date: Date }
			let payload = Payload(date: Date(timeIntervalSince1970: 1_700_000_000))
			let data = try #require(payload.data)
			#expect(Payload.load(data: data) == payload)
		}
		
		@Test
		func toDate_WithTheSameStringTwice_ShouldReturnTheSameDate() {
			let string = "2023-11-14T22:13:20.123+0000"
			#expect(string.toDate == string.toDate)
			#expect(abs(string.toDate.timeIntervalSince(reference)) < 0.001)
		}
		
		@Test
		func formatting_WithMixedFormatsConcurrently_ShouldBeStable() {
			let formats = ["yyyy-MM-dd", "HH:mm:ss", "dd/MM/yyyy HH:mm", "EEEE"]
			let formatter = DateFormatter(format: "yyyy", locale: Locale(identifier: "en_US_POSIX"))
			formatter.timeZone = TimeZone(secondsFromGMT: 0)
			let expected = formats.map { format -> String in
				let fresh = DateFormatter(format: format, locale: Locale(identifier: "en_US_POSIX"))
				fresh.timeZone = TimeZone(secondsFromGMT: 0)
				return fresh.string(from: reference)
			}
			let mismatches = ThreadSafe(wrappedValue: 0)
			let reference = reference
			
			DispatchQueue.concurrentPerform(iterations: 2_000) { index in
				let position = index % formats.count
				if reference.toString(format: formats[position], formatter: formatter) != expected[position] {
					mismatches.mutate { $0 += 1 }
				}
				if DateFormatter.string(from: reference) != "2023-11-14T22:13:20.123+0000" {
					mismatches.mutate { $0 += 1 }
				}
			}
			
			#expect(mismatches.wrappedValue == 0)
		}
		
		@Test
		func toString_WithFormat_ShouldNotChangeTheSharedFormatter() {
			let format = DateFormatter.standard.dateFormat
			_ = reference.toString(format: "yyyy")
			#expect(DateFormatter.standard.dateFormat == format)
		}
		
		@Test
		func toDate_WithFormat_ShouldParseUsingThatFormat() {
			let formatter = DateFormatter(format: "yyyy", locale: Locale(identifier: "en_US_POSIX"))
			formatter.timeZone = TimeZone(secondsFromGMT: 0)
			let date = "2024-02-03".toDate(format: "yyyy-MM-dd", formatter: formatter)
			#expect(date?.toString(format: "dd.MM.yyyy", formatter: formatter) == "03.02.2024")
			#expect(formatter.dateFormat == "yyyy")
		}
		
		@Test
		func toTimeUnits_ShouldMatchAFreshComponentsFormatter() {
			let fresh = DateComponentsFormatter()
			fresh.allowedUnits = [.minute, .second]
			fresh.unitsStyle = .positional
			fresh.zeroFormattingBehavior = .pad
			#expect(125.toTimeUnits() == fresh.string(from: 125))
			#expect(3725.toTimeUnits([.hour, .minute], style: .abbreviated, zero: .dropAll) != 3725.toTimeUnits())
		}
		
		@Test
		func logger_WithoutSaving_ShouldNotEvaluateUnusedMessages() {
			let basicCalls = ThreadSafe(wrappedValue: 0)
			let fullCalls = ThreadSafe(wrappedValue: 0)
			let basic: () -> String? = { basicCalls.mutate { $0 += 1 }; return "basic" }
			let full: () -> String? = { fullCalls.mutate { $0 += 1 }; return "full" }
			
			Logger.basic.log(basic: basic(), full: full(), save: false)
			#expect(basicCalls.wrappedValue == 1)
			#expect(fullCalls.wrappedValue == 0)
			
			Logger.silent.log(basic: basic(), full: full(), save: false)
			#expect(basicCalls.wrappedValue == 1)
			#expect(fullCalls.wrappedValue == 0)
			
			Logger.full.log(basic: basic(), full: full(), save: false)
			#expect(basicCalls.wrappedValue == 2)
			#expect(fullCalls.wrappedValue == 1)
			
			Logger.none.log(basic: basic(), full: full())
			#expect(basicCalls.wrappedValue == 2)
			#expect(fullCalls.wrappedValue == 1)
		}
		
		@Test
		func logger_WithSaving_ShouldKeepBothMessages() {
			Logger.flushLocalCache()
			Logger.basic.log(basic: "saved basic", full: "saved full")
			#expect(Logger.localCache.contains { $0.basic == "saved basic" && $0.full == "saved full" })
			Logger.flushLocalCache()
			#expect(Logger.localCache.isEmpty)
		}
		
		@Test
		func logger_WithManyEntries_ShouldKeepTheNewestFirst() {
			Logger.flushLocalCache()
			(0..<50).forEach { Logger.silent.log(basic: "entry \($0)") }
			#expect(Logger.localCache.count == 50)
			#expect(Logger.localCache.first?.basic == "entry 49")
			Logger.flushLocalCache()
		}
		
		@Test
		func appGroup_WhenAccessedTwice_ShouldReturnTheSameExistingFolder() {
			let folder = FileManager.default.appGroup
			#expect(FileManager.default.appGroup == folder)
			#expect(FileManager.default.fileExists(atPath: folder.path))
		}
	}
}
