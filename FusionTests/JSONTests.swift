//
//  Created by Diney on 5/7/23.
//

import XCTest
@testable import Fusion

// MARK: - Definitions -

// MARK: - Type -

class CodableExtensionsTests: XCTestCase {

	struct PersonMock: Codable {
		var name: String
		let age: Int
	}
	
// MARK: - Properties
	
	let person = PersonMock(name: "John", age: 30)
	let personDictionary: [String: Any] = ["name": "John", "age": 30]
	let personArray: [Any] = ["John", 30]
	let personData = try! JSONEncoder().encode(PersonMock(name: "John", age: 30))

// MARK: - Protected Methods
	
	func testEncodable_WithValidData_ShouldReturnsData() throws {
		XCTAssertNotNil(person.data)
	}
	
	func testEncodable_WithValidObject_ShouldReturnsObject() throws {
		XCTAssertNotNil(person.object)
	}
	
	func testEncodable_WithValidDictionaryObject_ShouldReturnsDictionary() throws {
		let dictionary = person.dictionaryObject
		XCTAssertEqual(dictionary.keys, personDictionary.keys)
	}
	
	func testEncodable_WithValidArrayObject_ShouldReturnsArray() throws {
		XCTAssertTrue(person.arrayObject.isEmpty)
	}
	
	func testDecodable_WithValidLoadData_ShouldReturnsDecodedObject() throws {
		let person = PersonMock.load(data: personData)
		XCTAssertEqual(person?.name, "John")
		XCTAssertEqual(person?.age, 30)
	}
	
	func testDecodable_WithValidLoadJsonObject_ShouldReturnsDecodedObject() throws {
		let person = PersonMock.load(jsonObject: personDictionary)
		XCTAssertEqual(person?.name, "John")
		XCTAssertEqual(person?.age, 30)
	}
	
	func testDecodable_WithValidLoadFile_ShouldReturnsDecodedObject() throws {
		let url = Bundle(for: type(of: self)).url(forResource: "Person.json", withExtension: nil)!
		let person = PersonMock.loadFile(at: url)
		XCTAssertEqual(person?.name, "John")
		XCTAssertEqual(person?.age, 30)
	}
	
	func testDictionary_WithValidPlusOperator_ShouldReturnsMergedDictionary() throws {
		let dictionary1 = ["key1": "value1", "key2": "value2"]
		let dictionary2 = ["key3": "value3", "key4": "value4"]
		let mergedDictionary = dictionary1 + dictionary2
		XCTAssertEqual(mergedDictionary, ["key1": "value1", "key2": "value2", "key3": "value3", "key4": "value4"])
	}
	
	func testEncodable_WithInvalidData_ShouldReturnNil() {
		let nilObject: PersonMock? = nil
		XCTAssertTrue(nilObject.dictionaryObject.isEmpty)
		XCTAssertTrue(nilObject.arrayObject.isEmpty)
	}
	
	func testDecodable_WithInvalidData_ShouldReturnNil() {
		let url = FileManager.default.temporaryDirectory.appendingPathComponent("invalid")
		XCTAssertNil(PersonMock.load(data: .init()))
		XCTAssertNil(PersonMock.load(jsonObject: [:]))
		XCTAssertNil(PersonMock.loadFile(at: url))
	}
	
	func testKeyPath_WithEqualityAndInequality_ShouldCompareSuccessfully() {
		let array1 = [PersonMock(name: "Name A", age: 10), PersonMock(name: "Name B", age: 20), PersonMock(name: "Name C", age: 30)]
		
		XCTAssertFalse(array1.filter(\.name == "Name A").isEmpty)
		XCTAssertFalse(array1.filter(\.name != "Name A").isEmpty)
		XCTAssertTrue(array1.filter(\.name == "Name D").isEmpty)
		XCTAssertFalse(array1.filter(\.age == 20).isEmpty)
		XCTAssertTrue(array1.filter(\.age == 50).isEmpty)
	}
	
	func testEncodable_WithWritingAndLoadingFileWithKey_ShouldSaveAndLoad() {
		let key = "TestKey"
		
		person.writeFile(key: key, isSecure: true)
		
		let fileManager = FileManager.default
		let url = fileManager.appGroup.appendingPathComponent(key.hash.description)
		XCTAssertTrue(fileManager.fileExists(atPath: url.path))
		XCTAssertEqual(PersonMock.loadFile(key: key)?.name, "John")
	}
	
	func testEncodable_WithUpdateValues_ShouldProperlyUpdate() {
		let newValue = "Updated"
		var newPerson = person
		let updatedPerson = person.updating(\.name, to: newValue)
		newPerson.update(\.name, to: newValue)
		
		XCTAssertEqual(person.name, "John")
		XCTAssertEqual(newPerson.name, newValue)
		XCTAssertEqual(updatedPerson.name, newValue)
	}
}

class FileManagerExtensionsTests: XCTestCase {

	func testIsInsecureOS_NoInsecureAppsInstalled_ReturnsFalse() {
		let fileManager = FileManager.default
		let isInsecureOS = fileManager.isInsecureOS
		XCTAssertFalse(isInsecureOS)
	}

	func testAppGroup_ConstantIsDebug_ReturnsDebugFolder() {
		XCTAssert(FileManager.default.appGroup.absoluteString.contains("Debug"))
	}

	func testMove_SourceFileExists_CopiesFileToDestination() {
		let fromPath = FileManager.default.temporaryDirectory
		let toPath = FileManager.default.appGroup
		
		FileManager.default.removeAllItems(at: fromPath)
		FileManager.default.removeAllItems(at: toPath)
		
		["item"].writeFile(at: fromPath.appendingPathComponent("file"))
		FileManager.default.move(from: fromPath, to: toPath)
		
		let fromResult = try? FileManager.default.contentsOfDirectory(at: fromPath, includingPropertiesForKeys: nil)
		let toResult = try? FileManager.default.contentsOfDirectory(at: toPath, includingPropertiesForKeys: nil)
		XCTAssert(fromResult?.isEmpty == false)
		XCTAssert(toResult?.isEmpty == false)
	}
	
	func testRemoveAllItems_DirectoryContainsItems_RemovesAllItems() {
		let url = FileManager.default.temporaryDirectory
		let file = url.appendingPathComponent("file")
		["item"].writeFile(at: file)
		XCTAssertNotNil(Array<String>.loadFile(at: file))
		FileManager.default.removeAllItems(at: url)
		XCTAssertNil(Array<String>.loadFile(at: file))
	}
}

class BundleExtensionsTests: XCTestCase {
	
	var bundle: Bundle { .init(for: type(of: self)) }
	
	func testAppGroup_ReturnsAppGroupIdentifier() {
		Bundle.appGroup = "group.test"
		XCTAssertEqual(Bundle.appGroup, "group.test")
		Bundle.appGroup = ""
		XCTAssertEqual(Bundle.appGroup, "")
	}
	
	func testAppName_InfoDictionaryContainsCFBundleName_ReturnsAppName() {
		XCTAssertEqual(bundle.appName, "FusionTests")
	}

	func testDisplayName_InfoDictionaryContainsCFBundleDisplayName_ReturnsDisplayName() {
		XCTAssertEqual(bundle.displayName, "")
	}

	func testBuildNumber_InfoDictionaryContainsCFBundleVersion_ReturnsBuildNumber() {
		XCTAssertEqual(bundle.buildNumber, "1")
	}

	func testShortVersion_InfoDictionaryContainsCFBundleShortVersionString_ReturnsShortVersion() {
		XCTAssertEqual(bundle.shortVersion, "1.0")
	}

	func testFullVersion_InfoDictionaryContainsCFBundleVersionAndCFBundleShortVersionString_ReturnsFullVersion() {
		XCTAssertEqual(bundle.fullVersion, "v 1.0 (1)")
	}
}

class URLCacheExtensionsTests: XCTestCase {

	func testAppGroup_ReturnsURLCacheWithAppGroupDirectory() {
		XCTAssertEqual(URLCache.appGroup.diskCapacity, .max)
		XCTAssertEqual(URLCache.appGroup.memoryCapacity, .max)
	}
}
