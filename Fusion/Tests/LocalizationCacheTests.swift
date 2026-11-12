//
//  Created by Diney Bomfim on 11/12/26.
//

import Foundation
import Testing
@testable import Fusion

// MARK: - Definitions -

private struct RuntimeBundle {
	
	let root: URL
	let table: String
	
	var bundle: Bundle? { Bundle(path: root.path) }
	
	init(table: String = "Runtime\(UUID().uuidString.prefix(8)).nocache") {
		self.root = FileManager.default.temporaryDirectory.appendingPathComponent("LocalizationCache-\(UUID().uuidString)")
		self.table = table
	}
	
	func write(_ strings: [String : String], language: String) throws {
		let folder = root.appendingPathComponent("\(language).lproj")
		try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
		let content = strings.map { "\"\($0.key)\" = \"\($0.value)\";" }.joined(separator: "\n")
		try Data(content.utf8).write(to: folder.appendingPathComponent("\(table).strings"), options: .atomic)
	}
	
	func writePlural(key: String, one: String, other: String, language: String) throws {
		let folder = root.appendingPathComponent("\(language).lproj")
		try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
		let plist: [String : Any] = [
			key: [
				"NSStringLocalizedFormatKey": "%#@items@",
				"items": [
					"NSStringFormatSpecTypeKey": "NSStringPluralRuleType",
					"NSStringFormatValueTypeKey": "d",
					"one": one,
					"other": other
				]
			]
		]
		let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
		try data.write(to: folder.appendingPathComponent("\(table).stringsdict"), options: .atomic)
	}
	
	func cleanUp() {
		try? FileManager.default.removeItem(at: root)
	}
}

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct LocalizationCacheTests {
		
		private func withHint<T>(_ runtime: RuntimeBundle, _ body: () throws -> T) rethrows -> T {
			let previous = Bundle.hints
			if let bundle = runtime.bundle { Bundle.registering(bundle, at: 0) }
			defer {
				Bundle.hints = previous
				Bundle.flushCachedLanguages()
				runtime.cleanUp()
			}
			return try body()
		}
		
		@Test
		func localized_AfterRuntimeUpdateAndFlush_ShouldReturnTheNewString() throws {
			let runtime = RuntimeBundle()
			try runtime.write(["greeting": "Hello"], language: "en")
			
			try withHint(runtime) {
				#expect("greeting".localized(for: "en", table: runtime.table) == "Hello")
				
				try runtime.write(["greeting": "Hi there"], language: "en")
				#expect("greeting".localized(for: "en", table: runtime.table) == "Hello")
				
				Bundle.flushCachedLanguages()
				#expect("greeting".localized(for: "en", table: runtime.table) == "Hi there")
			}
		}
		
		@Test
		func localized_WithDifferentLanguages_ShouldSwitchTheResult() throws {
			let runtime = RuntimeBundle()
			try runtime.write(["greeting": "Hello"], language: "en")
			try runtime.write(["greeting": "Marhaba"], language: "ar")
			
			withHint(runtime) {
				#expect("greeting".localized(for: "en", table: runtime.table) == "Hello")
				#expect("greeting".localized(for: "ar", table: runtime.table) == "Marhaba")
				#expect("greeting".localized(for: "en", table: runtime.table) == "Hello")
			}
		}
		
		@Test
		func localized_WithCount_ShouldStillPluralize() throws {
			let runtime = RuntimeBundle()
			try runtime.write(["unused": "unused"], language: "en")
			try runtime.writePlural(key: "items_count", one: "%d item", other: "%d items", language: "en")
			
			withHint(runtime) {
				#expect("items_count".localized(for: "en", count: 1, table: runtime.table) == "1 item")
				#expect("items_count".localized(for: "en", count: 5, table: runtime.table) == "5 items")
				#expect("items_count".localized(for: "en", count: 1, table: runtime.table) == "1 item")
			}
		}
		
		@Test
		func localized_FromCache_ShouldKeepTheOriginalKey() throws {
			let runtime = RuntimeBundle()
			try runtime.write(["greeting": "Hello", "escaped": "Hello &amp;amp; welcome\\\\"], language: "en")
			
			withHint(runtime) {
				let first = "greeting".localized(for: "en", table: runtime.table)
				let second = "greeting".localized(for: "en", table: runtime.table)
				#expect(first == second)
				#expect(first.originalKey == "greeting")
				#expect(second.originalKey == "greeting")
				
				let escaped = "escaped".localized(for: "en", table: runtime.table)
				#expect(escaped == "escaped".localized(for: "en", table: runtime.table))
				#expect(!escaped.contains("amp;"))
				#expect(!escaped.contains("\\"))
			}
		}
		
		@Test
		func localized_WhenAMissIsCachedAndAHintIsRegistered_ShouldFindTheNewString() throws {
			let runtime = RuntimeBundle()
			try runtime.write(["late_key": "Late value"], language: "en")
			let previous = Bundle.hints
			defer {
				Bundle.hints = previous
				Bundle.flushCachedLanguages()
				runtime.cleanUp()
			}
			
			#expect("late_key".localized(for: "en", table: runtime.table) == "late_key")
			#expect("late_key".localized(for: "en", table: runtime.table) == "late_key")
			
			if let bundle = runtime.bundle { Bundle.registering(bundle, at: 0) }
			#expect("late_key".localized(for: "en", table: runtime.table) == "Late value")
		}
		
		@Test
		func localized_WhenTheLocalizableTableChanges_ShouldUseTheNewTable() throws {
			let runtime = RuntimeBundle()
			try runtime.write(["table_key": "From table"], language: "en")
			let previousTable = String.localizableTable
			defer { String.localizableTable = previousTable }
			
			try withHint(runtime) {
				String.localizableTable = "Missing.nocache"
				#expect("table_key".localized(for: "en") == "table_key")
				String.localizableTable = runtime.table
				#expect("table_key".localized(for: "en") == "From table")
				_ = try #require(runtime.bundle)
			}
		}
		
		@Test
		func localized_WhenTheSystemLocaleChanges_ShouldFlushTheCache() throws {
			let runtime = RuntimeBundle()
			try runtime.write(["locale_key": "Before"], language: "en")
			
			try withHint(runtime) {
				#expect("locale_key".localized(for: "en", table: runtime.table) == "Before")
				try runtime.write(["locale_key": "After"], language: "en")
				NotificationCenter.default.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)
				#expect("locale_key".localized(for: "en", table: runtime.table) == "After")
			}
		}
		
		@Test
		func preferredLanguage_WhenTheLanguageSetChanges_ShouldResolveAgain() throws {
			let previous = Bundle.languageSet
			defer { Bundle.languageSet = previous }
			let first = try #require(Locale.preferredLanguages.first)
			let expected = first.matchingLanguage(in: [first]) ?? "en"
			
			Bundle.languageSet = []
			#expect(Locale.preferredLanguage == "en")
			#expect(Locale.preferredLocale.identifier == "en")
			
			Bundle.languageSet = [first]
			#expect(Locale.preferredLanguage == expected)
			#expect(Locale.preferredLocale.identifier == Locale(identifier: expected).identifier)
			
			Bundle.languageSet = previous
			let restored = Locale.preferredLanguages.firstMap({ $0.matchingLanguage(in: previous) }) ?? "en"
			#expect(Locale.preferredLanguage == restored)
		}
	}
}
