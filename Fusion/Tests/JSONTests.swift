//
//  Created by Diney on 5/7/23.
//

import Foundation
import Testing
@testable import Fusion

// MARK: - Definitions -

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct CodableExtensionsTests {
		
		struct PersonMock: Codable {
			var name: String
			let age: Int
		}
		
// MARK: - Properties
		
		static var isMacOS: Bool {
#if os(macOS)
			true
#else
			false
#endif
		}
		
		let person = PersonMock(name: "John", age: 30)
		let personDictionary: [String: Any] = ["name": "John", "age": 30]
		let personArray: [Any] = ["John", 30]
		let personData = try! JSONEncoder().encode(PersonMock(name: "John", age: 30))
		
// MARK: - Protected Methods
		
		@Test
		func encodable_WithValidData_ShouldReturnsData() throws {
			#expect(person.data != nil)
		}
		
		@Test
		func encodable_WithValidObject_ShouldReturnsObject() throws {
			#expect(person.object != nil)
		}
		
		@Test
		func encodable_WithValidDictionaryObject_ShouldReturnsDictionary() throws {
			let dictionary = person.dictionaryObject
			#expect(Set(dictionary.keys) == Set(personDictionary.keys))
		}
		
		@Test
		func encodable_WithValidArrayObject_ShouldReturnsArray() throws {
			#expect(person.arrayObject.isEmpty)
		}
		
		@Test
		func decodable_WithValidLoadData_ShouldReturnsDecodedObject() throws {
			let person = PersonMock.load(data: personData)
			#expect(person?.name == "John")
			#expect(person?.age == 30)
		}
		
		@Test
		func decodable_WithValidLoadJsonObject_ShouldReturnsDecodedObject() throws {
			let person = PersonMock.load(jsonObject: personDictionary)
			#expect(person?.name == "John")
			#expect(person?.age == 30)
		}
		
		@Test
		func dictionary_WithValidPlusOperator_ShouldReturnsMergedDictionary() throws {
			let dictionary1 = ["key1": "value1", "key2": "value2"]
			let dictionary2 = ["key3": "value3", "key4": "value4"]
			let mergedDictionary = dictionary1 + dictionary2
			#expect(mergedDictionary == ["key1": "value1", "key2": "value2", "key3": "value3", "key4": "value4"])
		}
		
		@Test
		func encodable_WithInvalidData_ShouldReturnNil() {
			let nilObject: PersonMock? = nil
			#expect(nilObject.dictionaryObject.isEmpty)
			#expect(nilObject.arrayObject.isEmpty)
		}
		
		@Test
		func decodable_WithInvalidData_ShouldReturnNil() {
			let url = FileManager.default.temporaryDirectory.appendingPathComponent("invalid")
			#expect(PersonMock.load(data: .init()) == nil)
			#expect(PersonMock.load(jsonObject: [:]) == nil)
			#expect(PersonMock.loadFile(at: url) == nil)
		}
		
		@Test
		func keyPath_WithEqualityAndInequality_ShouldCompareSuccessfully() {
			let array1 = [PersonMock(name: "Name A", age: 10), PersonMock(name: "Name B", age: 20), PersonMock(name: "Name C", age: 30)]
			
			#expect(!array1.filter(\.name == "Name A").isEmpty)
			#expect(!array1.filter(\.name != "Name A").isEmpty)
			#expect(array1.filter(\.name == "Name D").isEmpty)
			#expect(!array1.filter(\.age == 20).isEmpty)
			#expect(array1.filter(\.age == 50).isEmpty)
		}
		
		@Test
		func encodable_WithWritingAndLoadingFileWithKey_ShouldSaveAndLoad() {
			let key = "TestKey"
			
			person.writeFile(key: key, isSecure: true)
			
			let fileManager = FileManager.default
			let url = fileManager.appGroup.appendingPathComponent(key.hash.description)
			withKnownIssue("Atomic writes with complete file protection fail with EPERM on macOS", isIntermittent: true) {
				#expect(fileManager.fileExists(atPath: url.path))
				#expect(PersonMock.loadFile(key: key)?.name == "John")
			} when: {
				Self.isMacOS
			}
		}
		
		@Test
		func encodable_WithUpdateValues_ShouldProperlyUpdate() {
			let newValue = "Updated"
			var newPerson = person
			let updatedPerson = person.updating(\.name, to: newValue)
			newPerson.update(\.name, to: newValue)
			
			#expect(person.name == "John")
			#expect(newPerson.name == newValue)
			#expect(updatedPerson.name == newValue)
		}
	}
	
	@Suite
	struct FileManagerExtensionsTests {
		
		@Test
		func isInsecureOS_NoInsecureAppsInstalled_ReturnsFalse() {
			let fileManager = FileManager.default
			let isInsecureOS = fileManager.isInsecureOS
			#expect(!isInsecureOS)
		}
		
		@Test
		func appGroup_ConstantIsDebug_ReturnsDebugFolder() {
			#expect(FileManager.default.appGroup.absoluteString.contains("Debug"))
		}
		
		@Test
		func move_SourceFileExists_CopiesFileToDestination() {
			let fromPath = FileManager.default.temporaryDirectory
			let toPath = FileManager.default.appGroup
			
			FileManager.default.removeAllItems(at: fromPath)
			FileManager.default.removeAllItems(at: toPath)
			
			["item"].writeFile(at: fromPath.appendingPathComponent("file"))
			FileManager.default.move(from: fromPath, to: toPath)
			
			let fromResult = try? FileManager.default.contentsOfDirectory(at: fromPath, includingPropertiesForKeys: nil)
			let toResult = try? FileManager.default.contentsOfDirectory(at: toPath, includingPropertiesForKeys: nil)
			#expect(fromResult?.isEmpty == false)
			#expect(toResult?.isEmpty == false)
		}
		
		@Test
		func removeAllItems_DirectoryContainsItems_RemovesAllItems() {
			let url = FileManager.default.temporaryDirectory
			let file = url.appendingPathComponent("file")
			["item"].writeFile(at: file)
			#expect(Array<String>.loadFile(at: file) != nil)
			FileManager.default.removeAllItems(at: url)
			#expect(Array<String>.loadFile(at: file) == nil)
		}
	}
	
	@Suite
	struct BundleExtensionsTests {
		
		static let hasHostAppBundle = Bundle.main.infoDictionary?["CFBundleVersion"] != nil
		
		var bundle: Bundle { .testing }
		
		@Test
		func appGroup_ReturnsAppGroupIdentifier() {
			Bundle.appGroup = "group.test"
			#expect(Bundle.appGroup == "group.test")
			Bundle.appGroup = ""
			#expect(Bundle.appGroup == "")
		}
		
		@Test
		func appName_InfoDictionaryContainsCFBundleName_ReturnsAppName() {
			#expect(bundle.appName != "")
		}
		
		@Test
		func displayName_InfoDictionaryContainsCFBundleDisplayName_ReturnsDisplayName() {
			#expect(bundle.displayName == "")
		}
		
		@Test(.enabled(if: hasHostAppBundle, "Requires a host app bundle"))
		func buildNumber_InfoDictionaryContainsCFBundleVersion_ReturnsBuildNumber() {
			#expect(bundle.buildNumber != "")
		}
		
		@Test(.enabled(if: hasHostAppBundle, "Requires a host app bundle"))
		func shortVersion_InfoDictionaryContainsCFBundleShortVersionString_ReturnsShortVersion() {
			#expect(bundle.shortVersion != "")
		}
		
		@Test(.enabled(if: hasHostAppBundle, "Requires a host app bundle"))
		func fullVersion_InfoDictionaryContainsCFBundleVersionAndCFBundleShortVersionString_ReturnsFullVersion() {
			#expect(bundle.fullVersion != "v  ()")
		}
	}
	
	@Suite
	struct URLCacheExtensionsTests {
		
		@Test
		func appGroup_ReturnsURLCacheWithAppGroupDirectory() {
			#expect(URLCache.appGroup.diskCapacity == URLCache.appGroupDiskCapacity)
			#expect(URLCache.appGroup.memoryCapacity == URLCache.appGroupMemoryCapacity)
		}
		@Test
		func appGroup_WhenAccessedTwice_ShouldReturnTheSameInstance() {
			#expect(URLCache.appGroup === URLCache.appGroup)
		}
	}
}

@Suite
struct CaseDefaultableTests {
	
	private enum SampleStatus: String, Codable, CaseDefaultable {
		case pending
		case completed
		
		static var defaultCase: Self { .pending }
	}
	
	private enum SampleCode: Int, Codable, CaseDefaultable {
		case one = 1
		case two = 2
		
		static var defaultCase: Self { .one }
	}
	
	@Test
	func caseDefaultable_UnknownRawValueFromJSON_ShouldUseDefaultCase() throws {
		let decoded = try JSONDecoder().decode(SampleStatus.self, from: Data(#""unknown""#.utf8))
		#expect(decoded == .pending)
	}
	
	@Test
	func caseDefaultable_ResolvedRawValue_WithUnknownString_ShouldUseDefaultCase() {
		#expect(SampleStatus(rawValue: "unknown") == nil)
		#expect(SampleStatus.defaultCase == .pending)
	}
	
	@Test
	func caseDefaultable_ResolvedRawValue_WithUnknownInt_ShouldUseDefaultCase() {
		#expect(SampleCode(rawValue: 99) == nil)
		#expect(SampleCode.defaultCase == .one)
	}
}
