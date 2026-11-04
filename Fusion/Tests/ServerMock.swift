//
//  Created by Diney Bomfim on 09/06/2023.
//

import Foundation
import LocalServer
@testable import Fusion

// MARK: - Definitions -

extension Bundle {
	static var testing: Bundle {
#if SWIFT_PACKAGE
		.module
#else
		.init(for: ServerMock.self)
#endif
	}
}

enum MockEndpoint {
	static let host = "https://fusion.test"
	static let model = "\(host)/model"
	static let unauthorized = "\(host)/unauthorized"
	static let upload = "\(host)/upload"
	static let uploadFailure = "\(host)/upload-failure"
	static let uploadSession = "\(host)/upload-session"
	static let noContent = "\(host)/no-content"
	static let serverError = "\(host)/server-error"
	static let malformed = "\(host)/malformed"
	static let sessionHeader = "X-Fusion-Session"
}

// MARK: - Type -

final class ServerMock {

// MARK: - Exposed Methods

	static func startLocalServer() {
		FusionTestCase.configureBundles()
		let server = StubServer()
		server.setupDefaultRoutes()
		StubServer.instance = server
		let configuration = URLSessionConfiguration.default
		configuration.httpAdditionalHeaders = [MockEndpoint.sessionHeader: "1"]
		RESTAuthenticator.session = .init(configuration: configuration, delegate: RESTAuthenticator.shared, delegateQueue: nil)
	}
	
	static func stopLocalServer() {
		StubServer.instance = nil
	}
}

extension StubServer {
	
	func setupDefaultRoutes() {
		route([.GET, .POST], url: MockEndpoint.model) { _, _ in
			StubResponse(filename: "Response", ofType: "json", bundle: .testing)
		}
		
		route([.DELETE], url: MockEndpoint.unauthorized) { _, _ in
			StubResponse().withStatusCode(401)
		}
		
		route([.GET], url: MockEndpoint.noContent) { _, _ in
			StubResponse().withStatusCode(204)
		}
		
		route([.GET], url: MockEndpoint.serverError) { _, _ in
			StubResponse(string: "{\"error\":\"server\"}").withStatusCode(500)
		}
		
		route([.GET], url: MockEndpoint.malformed) { _, _ in
			StubResponse(string: "{")
		}
		
		route([.PUT], url: MockEndpoint.uploadFailure) { _, _ in
			StubResponse(string: "Failure").withStatusCode(500)
		}
		
		route([.PUT], url: MockEndpoint.uploadSession) { request, _ in
			guard request.value(forHTTPHeaderField: MockEndpoint.sessionHeader) == "1" else {
				return StubResponse().withStatusCode(418)
			}
			return StubResponse(string: "Success")
		}
		
		route([.PUT], url: MockEndpoint.upload) { _, _ in
			StubResponse(string: "Success")
		}
	}
}
