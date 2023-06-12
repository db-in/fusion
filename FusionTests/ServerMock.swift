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
		
		server.route([HTTPMethod.GET, HTTPMethod.POST], url: ".") { request, headers in
			StubResponse(filename: "Response", ofType: "json", bundle: .testing)
		}
		
		server.route([HTTPMethod.DELETE], url: ".") { _, _ in
				.init().withStatusCode(401)
		}
		
		server.route([HTTPMethod.PUT], url: ".") { _, _ in
			StubResponse(data: "Success".data(using: .utf8)!)
		}

		StubServer.instance = server
	}
	
	static func stopLocalServer() {
		StubServer.instance = nil
	}
}
