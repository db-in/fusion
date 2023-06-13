//
//  Created by Diney Bomfim on 09/06/2023.
//

import XCTest
@testable import Fusion

// MARK: - Definitions -

public struct MockModel: Codable {
	public let args: [String: String]
	public let origin: String
	public let url: String
}

public struct MockModelStorage : DataPersistable {
	
	public typealias Storage = FileManager
	
	public enum Key : String {
		case model
	}
	
	public static var localMode: MockModel? {
		get { value(forKey: .model) }
		set { set(newValue, forKey: .model) }
	}
}

// MARK: - Type -

public struct MockService {
	
// MARK: - Properties
	
	private static var getRequest: RESTBuilder<MockModel> {
		.init(url: "https://t.ly/SYGU", method: .get)
	}
	
	private static var deleteRequest: RESTBuilder<MockModel> {
		.init(url: "https://invalid.url.com", method: .delete)
	}
	
	private static var dataRequest: RESTBuilder<MockModel> {
		.init(url: "https://t.ly/SYGU", method: .post)
	}
	
	private static var dataUpload: RESTBuilder<Data> {
		.init(url: "https://t.ly/SYGU", method: .put)
	}
	
// MARK: - Exposed Methods
	
	public static func mockSuccess(completion: Response<MockModel>? = nil) {
		getRequest.execute(then: MockModelStorage.map(.model, to: completion))
	}
	
	public static func mockFail(completion: Response<MockModel>? = nil) {
		deleteRequest.execute(then: completion)
	}
	
	public static func mockBody(body: String, completion: Response<MockModel>? = nil) {
		dataRequest.execute(body: body, headers: [:], then: MockModelStorage.map(.model, to: completion))
	}
	
	public static func mockUpload(completion: Response<Data?>? = nil) {
		dataUpload.upload(data: .init(), then: completion)
	}
}

// MARK: - Type -

class NetworkingTests: XCTestCase {

	override class func setUp() {
		ServerMock.startLocalServer()
	}
	
	func testFullNetworking_WithMockRequest_ShouldPerformLocalStubServerAndPersistResultDataLocally() {
		let expectation = expectation(description: #function)
		
		MockService.mockSuccess { result, _ in
			let value = try! result.get()
			XCTAssertEqual(value.url, "https://httpbin.org/get")
			XCTAssertEqual(MockModelStorage.localMode?.url, value.url)
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 15.0)
	}
	
	func testFullNetworking_WithMockFailRequest_ShouldFail() {
		let expectation = expectation(description: #function)
		
		MockService.mockFail { result, _ in
			switch result {
			case .failure(_):
				expectation.fulfill()
			default:
				XCTFail("It should not be successfully")
			}
		}
		
		wait(for: [expectation], timeout: 15.0)
	}
	
	func testFullNetworking_WithBodyMockRequest_ShouldSucceed() {
		let expectation = expectation(description: #function)
		
		MockService.mockBody(body: "foo") { result, _ in
			let value = try! result.get()
			XCTAssertEqual(value.url, "https://httpbin.org/get")
			XCTAssertEqual(MockModelStorage.localMode?.url, value.url)
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 15.0)
	}
	
	func testFullNetworking_WithUploadMockRequest_ShouldSucceed() {
		let expectation = expectation(description: #function)
		
		MockService.mockUpload { result, _ in
			let value = try! result.get()
			XCTAssertNotEqual(value?.count, 0)
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 15.0)
	}
}

class DictionaryURLQueryItemTests: XCTestCase {

	func testDictionary_WithSumOfURLQueryItemOperator_ShouldProperlyCombineBoth() {
		let dictionary: [String: String] = ["key1": "value1", "key2": "value2"]
		let queryItem = URLQueryItem(name: "key3", value: "value3")
		let result = dictionary + queryItem
		XCTAssertEqual(result, ["key1": "value1", "key2": "value2", "key3": "value3"])
	}
}

class URLTests: XCTestCase {

	func testURL_WithValidQueryItemsDictionary_ShouldCorrectlyIdentifyThem() {
		let url = URL(string: "https://example.com?param1=value1&param2=value2")!
		let queryItemsDictionary = url.queryItemsDictionary
		XCTAssertEqual(queryItemsDictionary, ["param1": "value1", "param2": "value2"])
	}

	func testURL_WithAppendedQueryWithData_ShouldProperlyAppendData() {
		let url = URL(string: "https://example.com")!
		let data: Data? = ["param1": "value1", "param2": "value2"].data
		let result = url.appendedQuery(data: data)
		let expectedURL = URL(string: "https://example.com?param1=value1&param2=value2")!
		XCTAssertEqual(result.queryItemsDictionary, expectedURL.queryItemsDictionary)
	}
	
	func testURL_WithAppendedQueryEmptyData_ShouldKeepTheSameURL() {
		let url = URL(string: "https://example.com")!
		let data: Data? = nil
		let result = url.appendedQuery(data: data)
		XCTAssertEqual(result, url)
	}
}
