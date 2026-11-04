//
//  Created by Diney Bomfim on 09/06/2023.
//

import Foundation
import Testing
@testable import Fusion

// MARK: - Definitions -

public struct MockModel: Codable, Equatable {
	public let args: [String: String]
	public let origin: String
	public let url: String
}

public struct MockModelStorage : DataManageable {
	
	public typealias Storage = FileManager
	
	public enum Key : String {
		case model
	}
	
	public static var localModel: MockModel? {
		get { value(forKey: .model) }
		set { set(newValue, forKey: .model) }
	}
}

public struct MockService {
	
	static var getRequest: RESTBuilder<MockModel> { .init(url: MockEndpoint.model, method: .get) }
	static var postRequest: RESTBuilder<MockModel> { .init(url: MockEndpoint.model, method: .post) }
	static var deleteRequest: RESTBuilder<MockModel> { .init(url: MockEndpoint.unauthorized, method: .delete) }
	static var noContentRequest: RESTBuilder<Data> { .init(url: MockEndpoint.noContent, method: .get) }
	static var serverErrorRequest: RESTBuilder<MockModel> { .init(url: MockEndpoint.serverError, method: .get) }
	static var malformedRequest: RESTBuilder<MockModel> { .init(url: MockEndpoint.malformed, method: .get) }
	static var uploadRequest: RESTBuilder<Data> { .init(url: MockEndpoint.upload, method: .put) }
	static var uploadFailureRequest: RESTBuilder<Data> { .init(url: MockEndpoint.uploadFailure, method: .put) }
	static var uploadSessionRequest: RESTBuilder<Data> { .init(url: MockEndpoint.uploadSession, method: .put) }
	
	public static func mockSuccess(completion: Response<MockModel>? = nil) {
		getRequest.execute(then: MockModelStorage.map(.model, to: completion))
	}
	
	public static func mockFail(completion: Response<MockModel>? = nil) {
		deleteRequest.execute(then: completion)
	}
	
	public static func mockBody(body: String, completion: Response<MockModel>? = nil) {
		postRequest.execute(body: body, headers: [:], then: MockModelStorage.map(.model, to: completion))
	}
	
	public static func mockUpload(completion: Response<Data?>? = nil) {
		uploadRequest.upload(data: .init(), then: completion)
	}
}

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct NetworkingTests {
		
		init() {
			ServerMock.startLocalServer()
			MockModelStorage.remove(keys: [.model])
		}
		
		@Test
		func fullNetworking_WithMockRequest_ShouldPerformLocalStubServerAndPersistResultDataLocally() async throws {
			let (result, response) = await awaitResponse(MockService.mockSuccess)
			let value = try result.get()
			#expect(value.url == "https://httpbin.org/get")
			#expect(response?.httpStatusCode == 200)
			#expect(MockModelStorage.localModel == value)
		}
		
		@Test
		func fullNetworking_WithMockFailRequest_ShouldFail() async {
			let (result, response) = await awaitResponse(MockService.mockFail)
			#expect(!result.isSuccess)
			#expect(response?.httpStatusCode == 401)
		}
		
		@Test
		func fullNetworking_WithBodyMockRequest_ShouldSucceed() async throws {
			let (result, _) = await awaitResponse { MockService.mockBody(body: "foo", completion: $0) }
			let value = try result.get()
			#expect(value.url == "https://httpbin.org/get")
			#expect(MockModelStorage.localModel == value)
		}
		
		@Test
		func fullNetworking_WithUploadMockRequest_ShouldSucceed() async throws {
			let (result, response) = await awaitResponse(MockService.mockUpload)
			let value = try #require(try result.get())
			#expect(String(data: value, encoding: .utf8) == "Success")
			#expect(response?.httpStatusCode == 200)
		}
		
		@Test
		func fullNetworking_WithNoContentResponse_ShouldSucceedWithEmptyData() async throws {
			let (result, response) = await awaitResponse { MockService.noContentRequest.execute(then: $0) }
			#expect(try result.get().isEmpty)
			#expect(response?.httpStatusCode == 204)
		}
		
		@Test
		func fullNetworking_WithServerError_ShouldFailCarryingTheBody() async {
			let (result, response) = await awaitResponse { MockService.serverErrorRequest.execute(then: $0) }
			let error: RESTError? = result.error()
			guard case let .unkown(data) = error else {
				Issue.record("Expected RESTError.unkown")
				return
			}
			#expect(data.flatMap { String(data: $0, encoding: .utf8) } == "{\"error\":\"server\"}")
			#expect(response?.httpStatusCode == 500)
		}
		
		@Test
		func fullNetworking_WithMalformedJSON_ShouldFail() async {
			let (result, response) = await awaitResponse { MockService.malformedRequest.execute(then: $0) }
			#expect(!result.isSuccess)
			#expect(response?.httpStatusCode == 200)
		}
		
		@Test
		func fullNetworking_WithUnmatchedRoute_ShouldNeverReachTheRealNetwork() async {
			let request = RESTBuilder<MockModel>(url: "https://fusion.test/unknown", method: .get)
			let (result, response) = await awaitResponse { request.execute(then: $0) }
			#expect(!result.isSuccess)
			#expect(response?.httpStatusCode == 404)
		}
		
		@Test
		func upload_WithServerError_ShouldFail() async {
			let (result, response) = await awaitResponse { MockService.uploadFailureRequest.upload(data: .init(), then: $0) }
			#expect(!result.isSuccess)
			#expect(response?.httpStatusCode == 500)
		}
		
		@Test
		func upload_WithConfiguredSession_ShouldUseTheRESTAuthenticatorSession() async {
			let (result, response) = await awaitResponse { MockService.uploadSessionRequest.upload(data: .init(), then: $0) }
			#expect(result.isSuccess)
			#expect(response?.httpStatusCode == 200)
		}
		
		@Test
		func executeAsync_WithSameRoute_ShouldMatchTheCompletionResult() async throws {
			let (completionResult, _) = await awaitResponse { MockService.getRequest.execute(then: $0) }
			let (asyncValue, response) = try await MockService.getRequest.execute()
			#expect(try completionResult.get() == asyncValue)
			#expect(response?.httpStatusCode == 200)
		}
		
		@Test
		func executeAsync_WithBody_ShouldDecodeTheResponse() async throws {
			let (value, _) = try await MockService.postRequest.execute(body: "foo")
			#expect(value.url == "https://httpbin.org/get")
		}
		
		@Test
		func executeAsync_WithDataType_ShouldReturnTheRawData() async throws {
			let (value, response) = try await MockService.noContentRequest.execute()
			#expect(value.isEmpty)
			#expect(response?.httpStatusCode == 204)
		}
		
		@Test
		func executeAsync_WithUnauthorizedRoute_ShouldThrow() async {
			await #expect(throws: RESTError.self) {
				_ = try await MockService.deleteRequest.execute()
			}
		}
		
		@Test
		func executeAsync_WithMalformedJSON_ShouldThrow() async {
			await #expect(throws: (any Error).self) {
				_ = try await MockService.malformedRequest.execute()
			}
		}
		
		@Test
		func uploadAsync_WithSuccess_ShouldReturnTheResponseBody() async throws {
			let data = try #require(try await MockService.uploadRequest.upload(data: .init()))
			#expect(String(data: data, encoding: .utf8) == "Success")
		}
		
		@Test
		func uploadAsync_WithServerError_ShouldThrow() async {
			await #expect(throws: RESTError.self) {
				_ = try await MockService.uploadFailureRequest.upload(data: .init())
			}
		}
		
		@Test
		func withResponse_WithCompletionAPI_ShouldBridgeTheValue() async throws {
			let value = try await withResponse(MockService.mockSuccess)
			#expect(value.url == "https://httpbin.org/get")
			#expect(MockModelStorage.localModel == value)
		}
		
		@Test
		func withResponse_WithCompletionCalledTwice_ShouldResumeOnlyOnce() async throws {
			let value: Int = try await withResponse { completion in
				completion(.success(1), nil)
				completion(.success(2), nil)
			}
			#expect(value == 1)
		}
		
		@Test
		func withURLResponse_WithFailure_ShouldThrowTheSameError() async {
			await #expect(throws: RESTError.self) {
				let _: (Int, URLResponse?) = try await withURLResponse { $0(.failure(RESTError.unkown(nil)), nil) }
			}
		}
	}
	
	@Suite
	struct DictionaryURLQueryItemTests {
		
		@Test
		func dictionary_WithSumOfURLQueryItemOperator_ShouldProperlyCombineBoth() {
			let dictionary: [String: String] = ["key1": "value1", "key2": "value2"]
			let queryItem = URLQueryItem(name: "key3", value: "value3")
			#expect(dictionary + queryItem == ["key1": "value1", "key2": "value2", "key3": "value3"])
		}
	}
	
	@Suite
	struct URLTests {
		
		@Test
		func url_WithValidQueryItemsDictionary_ShouldCorrectlyIdentifyThem() {
			let url = URL(string: "https://example.com?param1=value1&param2=value2")!
			#expect(url.queryItemsDictionary == ["param1": "value1", "param2": "value2"])
		}
		
		@Test
		func url_WithAppendedQueryWithData_ShouldProperlyAppendData() {
			let url = URL(string: "https://example.com")!
			let data: Data? = ["param1": "value1", "param2": "value2"].data
			#expect(url.appendedQuery(data: data).queryItemsDictionary == ["param1": "value1", "param2": "value2"])
		}
		
		@Test
		func url_WithAppendedQueryOnExistingQuery_ShouldCombineQueryItems() {
			let url = URL(string: "https://example.com?existing=keep")!
			let data: Data? = ["param1": "value1"].data
			#expect(url.appendedQuery(data: data).queryItemsDictionary == ["existing": "keep", "param1": "value1"])
		}
		
		@Test
		func url_WithAppendedQueryEmptyData_ShouldKeepTheSameURL() {
			let url = URL(string: "https://example.com?existing=keep")!
			#expect(url.appendedQuery(data: nil) == url)
		}
	}
}
