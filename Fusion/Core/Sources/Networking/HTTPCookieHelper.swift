//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation

// MARK: - Definitions -

public typealias HTTPCookieInfo = [HTTPCookiePropertyKey : Any]

// MARK: - Extension - HTTPCookie

public extension HTTPCookie {
	
	private var allProperties: HTTPCookieInfo { properties ?? [:] }
	
	func merged(with newProperties: HTTPCookieInfo) -> Self {
		return Self.init(properties: allProperties + newProperties) ?? self
	}
}

// MARK: - Extension - HTTPCookieStorage

public extension HTTPCookieStorage {
	
	static var appGroup: HTTPCookieStorage { .sharedCookieStorage(forGroupContainerIdentifier: Bundle.main.appGroup) }
	
	var hasCookies: Bool { cookies?.isEmpty == false }
	
	func addCookie(_ info: HTTPCookieInfo) {
		guard let first = cookies?.first else {
			setCookie(.init(properties: info) ?? .init())
			return
		}
		setCookie(first.merged(with: info))
	}
	
	func setCookies(_ items: [HTTPCookie]) {
		deleteAll()
		items.forEach(setCookie)
	}
	
	func deleteAll() { cookies?.forEach(deleteCookie) }
	
	func sync(to storage: HTTPCookieStorage = .shared) {
		guard let validCookies = cookies else { return }
		storage.setCookies(validCookies)
	}
}
