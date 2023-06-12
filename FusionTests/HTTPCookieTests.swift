//
//  Created by Diney Bomfim on 09/06/2023.
//

import XCTest
@testable import Fusion

// MARK: - Definitions -

// MARK: - Type -

class HTTPCookieTests: XCTestCase {
	
	func testHTTPCookie_WithMerge_ShouldCreateNewValidCookie() {
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
		
		XCTAssertEqual(newCookie?.value, "newValue")
		XCTAssertEqual(newCookie?.domain, "newdomain.com")
		XCTAssertEqual(newCookie?.path, "/oldPath")
	}
	
	func testSetCookie() {
		let cookieStorage = HTTPCookieStorage.shared
		let oldCookie = HTTPCookie(properties: [
			.domain: "domain.com",
			.name: "name",
			.value: "oldValue",
			.path: "/oldPath"
		])!
		let cookieProperties: HTTPCookieInfo = [
			.name: "cookieName",
			.value: "cookieValue",
			.domain: "example.com",
			.expires: Date(timeIntervalSinceNow: 3600),
			.path: "/testPath"
		]
		
		cookieStorage.setCookies([oldCookie])
		cookieStorage.addCookie(cookieProperties)
		XCTAssertEqual(cookieStorage.cookies?.first?.value, "cookieValue")
		
		cookieStorage.addCookie([:])
		XCTAssertEqual(cookieStorage.cookies?.first?.value, "cookieValue")
		
		cookieStorage.addCookie([.init(rawValue: "invalidKey"): "invalidValue"])
		XCTAssertEqual(cookieStorage.cookies?.first?.value, "cookieValue")
		
		cookieStorage.addCookie([.name : "newName"])
		XCTAssertEqual(cookieStorage.cookies?.first?.value, "cookieValue")
		XCTAssertEqual(cookieStorage.cookies?.first?.name, "cookieName")
	}
	
	func testSetCookies() {
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
		XCTAssertEqual(cookieStorage.cookies?.count, 2)
		
		cookieStorage.setCookies([])
		XCTAssertEqual(cookieStorage.cookies?.count, 0)
	}
	
	func testDeleteAll() {
		let cookieStorage = HTTPCookieStorage.shared
		let cookieProperties: HTTPCookieInfo = [
			.name: "cookieName",
			.value:"cookieValue",
			.domain: "example.com",
			.path: "/testPath"
		]
		let cookie = HTTPCookie(properties: cookieProperties)
		cookieStorage.addCookie(cookieProperties)
		XCTAssertEqual(cookieStorage.hasCookies, true)
		
		cookieStorage.deleteAll()
		XCTAssertEqual(cookieStorage.hasCookies, false)
	}
	
	func testSyncTo() {
		let cookieStorage = HTTPCookieStorage.shared
		let otherCookieStorage = HTTPCookieStorage.appGroup
		
		let cookieProperties: HTTPCookieInfo = [
			.name: "cookieName",
			.value: "cookieValue",
			.domain: "example.com",
			.expires: Date(timeIntervalSinceNow: 3600),
			.path: "/testPath"
		]
		
		let cookie = HTTPCookie(properties: cookieProperties)!
		
		cookieStorage.setCookie(cookie)
		
		XCTAssertEqual(cookieStorage.hasCookies, true)
		XCTAssertEqual(otherCookieStorage.hasCookies, false)
		XCTAssertEqual(cookieStorage.cookies?.first?.name, "cookieName")
		XCTAssertEqual(cookieStorage.cookies?.first?.value, "cookieValue")
		XCTAssertEqual(cookieStorage.cookies?.first?.domain, "example.com")
		XCTAssertEqual(cookieStorage.cookies?.first?.path, "/testPath")
		
		cookieStorage.sync(to: otherCookieStorage)
		
		XCTAssertEqual(cookieStorage.hasCookies, true)
		XCTAssertEqual(otherCookieStorage.hasCookies, true)
		XCTAssertEqual(otherCookieStorage.cookies?.first?.name, "cookieName")
		XCTAssertEqual(otherCookieStorage.cookies?.first?.value, "cookieValue")
		XCTAssertEqual(otherCookieStorage.cookies?.first?.domain, "example.com")
		XCTAssertEqual(otherCookieStorage.cookies?.first?.path, "/testPath")
	}
}
