//
//  Created by Diney Bomfim on 09/06/2023.
//

import Foundation
import LocalServer

// MARK: - Definitions -

extension Bundle {
	static var testing: Bundle { .init(for: ServerMock.self) }
}

// MARK: - Type -

class ServerMock {

// MARK: - Exposed Methods

	static func startLocalServer() {
		let server = StubServer()
		server.setupDefaultRoutes()
		StubServer.instance = server
	}
	
	static func stopLocalServer() {
		StubServer.instance = nil
	}
}

extension StubServer {
	
	func setupDefaultRoutes() {
		setupRootSuccessRoutes()
		setupRootUnauthorizedRoutes()
		setupRootUploadRoutes()
	}
	
	func setupRootSuccessRoutes() {
		route([HTTPMethod.GET, HTTPMethod.POST], url: "http.*") { _, _ in
			StubResponse(filename: "Response", ofType: "json", bundle: .testing)
		}
	}
	
	func setupRootUnauthorizedRoutes() {
		route([HTTPMethod.DELETE], url: "http.*") { _, _ in
			.init().withStatusCode(401)
		}
	}
	
	func setupRootUploadRoutes() {
		route([HTTPMethod.PUT], url: "http.*") { _, _ in
			StubResponse(data: "Success".data(using: .utf8)!)
		}
	}
}
