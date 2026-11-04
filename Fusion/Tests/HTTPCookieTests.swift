//
//  Created by Diney Bomfim on 09/06/2023.
//

import Foundation
import Testing
@testable import Fusion

// MARK: - Definitions -

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct HTTPCookieTests {
		
		init() {
			HTTPCookieStorage.shared.deleteAll()
			HTTPCookieStorage.appGroup.deleteAll()
		}
		
		@Test
		func httpCookie_WithMerge_ShouldCreateNewValidCookie() {
			let oldCookie = HTTPCookie(properties: [
				.domain: "domain.com",
				.name: "name",
				.value: "oldValue",
				.path: "/oldPath"
			])
			
			let newProperties: HTTPCookieInfo = [
				.value: "newValue",
				.domain: "newdomain.com",
				.expires: Date(timeIntervalSinceNow: 3600)
			]
			
			let newCookie = oldCookie?.merged(with: newProperties)
			
			#expect(newCookie?.value == "newValue")
			#expect(newCookie?.domain == "newdomain.com")
			#expect(newCookie?.path == "/oldPath")
		}
		
		@Test
		func setCookie() throws {
			let cookieStorage = HTTPCookieStorage.shared
			let oldCookie = try #require(HTTPCookie(properties: [
				.domain: "domain.com",
				.name: "name",
				.value: "oldValue",
				.path: "/oldPath"
			]))
			let cookieProperties: HTTPCookieInfo = [
				.name: "cookieName",
				.value: "cookieValue",
				.domain: "example.com",
				.expires: Date(timeIntervalSinceNow: 3600),
				.path: "/testPath"
			]
			
			cookieStorage.setCookies([oldCookie])
			cookieStorage.addCookie(cookieProperties)
			#expect(cookieStorage.cookies?.first?.value == "cookieValue")
			
			cookieStorage.addCookie([:])
			#expect(cookieStorage.cookies?.first?.value == "cookieValue")
			
			cookieStorage.addCookie([.init(rawValue: "invalidKey"): "invalidValue"])
			#expect(cookieStorage.cookies?.first?.value == "cookieValue")
			
			cookieStorage.addCookie([.name : "newName"])
			#expect(cookieStorage.cookies?.first?.value == "cookieValue")
			#expect(cookieStorage.cookies?.first?.name == "cookieName")
		}
		
		@Test
		func setCookies() {
			let cookieStorage = HTTPCookieStorage.shared
			let cookie1Properties: HTTPCookieInfo = [
				.name: "cookie1",
				.value: "value1",
				.domain: "example.com",
				.path: "/path1"
			]
			let cookie2Properties: HTTPCookieInfo = [
				.name: "cookie2",
				.value: "value2",
				.domain: "example.com",
				.path: "/path2"
			]
			let cookies = [HTTPCookie(properties: cookie1Properties), HTTPCookie(properties: cookie2Properties)].compactMap { $0 }
			
			cookieStorage.setCookies(cookies)
			#expect(cookieStorage.cookies?.count == 2)
			
			cookieStorage.setCookies([])
			#expect(cookieStorage.cookies?.count == 0)
		}
		
		@Test
		func deleteAll() {
			let cookieStorage = HTTPCookieStorage.shared
			let cookieProperties: HTTPCookieInfo = [
				.name: "cookieName",
				.value:"cookieValue",
				.domain: "example.com",
				.path: "/testPath"
			]
			cookieStorage.addCookie(cookieProperties)
			#expect(cookieStorage.hasCookies == true)
			
			cookieStorage.deleteAll()
			#expect(cookieStorage.hasCookies == false)
		}
		
		@Test
		func syncTo() throws {
			let cookieStorage = HTTPCookieStorage.shared
			let otherCookieStorage = HTTPCookieStorage.appGroup
			
			let cookieProperties: HTTPCookieInfo = [
				.name: "cookieName",
				.value: "cookieValue",
				.domain: "example.com",
				.expires: Date(timeIntervalSinceNow: 3600),
				.path: "/testPath"
			]
			
			let cookie = try #require(HTTPCookie(properties: cookieProperties))
			
			cookieStorage.setCookie(cookie)
			
			#expect(cookieStorage.hasCookies == true)
			#expect(otherCookieStorage.hasCookies == false)
			#expect(cookieStorage.cookies?.first?.name == "cookieName")
			#expect(cookieStorage.cookies?.first?.value == "cookieValue")
			#expect(cookieStorage.cookies?.first?.domain == "example.com")
			#expect(cookieStorage.cookies?.first?.path == "/testPath")
			
			cookieStorage.sync(to: otherCookieStorage)
			
			#expect(cookieStorage.hasCookies == true)
			#expect(otherCookieStorage.hasCookies == true)
			#expect(otherCookieStorage.cookies?.first?.name == "cookieName")
			#expect(otherCookieStorage.cookies?.first?.value == "cookieValue")
			#expect(otherCookieStorage.cookies?.first?.domain == "example.com")
			#expect(otherCookieStorage.cookies?.first?.path == "/testPath")
		}
	}
}
