//
//  Created by Diney Bomfim on 09/06/2023.
//

import Foundation
import Security
import Testing
@testable import Fusion

// MARK: - Definitions -

private enum MockCertificate {
	
	static let pem = """
	MIIC7jCCAdagAwIBAgIUAl8NV/ByXXxnn88HSPvJVlqIpgEwDQYJKoZIhvcNAQEL
	BQAwFjEUMBIGA1UEAwwLZnVzaW9uLnRlc3QwIBcNMjYxMTA0MDgzMjUyWhgPMjEy
	NjEwMTEwODMyNTJaMBYxFDASBgNVBAMMC2Z1c2lvbi50ZXN0MIIBIjANBgkqhkiG
	9w0BAQEFAAOCAQ8AMIIBCgKCAQEA6Y1EdvxShpIC85HTtX5HU+dk6AqfDYj5EyBl
	s651S9vUMv/EDcF0LVIcMdkjwLPtSsiDEf4r2atDR/2msPU2IZXs5Jn1QOLRq5RT
	1RxGLjsn6P6Wsri7k5JViTXhPkABE4WwwoB7vBvcGv4asRebDZsPJSrKaZbE7QBS
	U6DxEqZ91x5tEyh9X2RC62iRK91CUTuHMzq5u/W6qzFfjP0R836BR1BOQxQRuoI4
	dx/GqpsbsfZw7Kd509tnyPuAEaTF1ZG1b9PpKIc7ul7AaA/JpbK3aEjMZyC2KC8H
	DH5Sn3rvMAh/Ia3lyDHvNj/HKdHKxij+5pyiji7Mj/+FWnbn1wIDAQABozIwMDAd
	BgNVHQ4EFgQU4UnHDRsLAfPiqUO+aZDkRiCAyxwwDwYDVR0TAQH/BAUwAwEB/zAN
	BgkqhkiG9w0BAQsFAAOCAQEABZS/K5jGcS5RAJSrK73VN4kiDmoPA7F7Mav0JTPM
	x1bJeBTd3ha/kKJDmJbeHEBEiOcP+qcQow/GC86Nu51Yj1FOUwsZFjRGN168/It+
	4OWwsXRxwU9II6ptqFmTFmOkBVfVDK7yf+VNL6fu/zZS8b2YeCK4VGSLD2Zqdc01
	VxVFo1P6LfpMFDYltbom/Xhk/sktki+NLzZM4sUfqIckUvXYayoW8ED73yYe5MHI
	Yq0SS/yh0UA6w1nl1v8E76CYkrk+kEHMnkI5tD8ld+4LyrJe0p/Slct2HQZcnd9j
	99CLZnj/Kxtssqe6Vd3+CVFcMQD6rmnIjeJUgZh9ofkB/A==
	"""
	
	static var certificate: SecCertificate? {
		Data(base64Encoded: pem, options: .ignoreUnknownCharacters).flatMap { SecCertificateCreateWithData(nil, $0 as CFData) }
	}
	
	static func trust(anchored: Bool) -> SecTrust? {
		guard let certificate else { return nil }
		var trust: SecTrust?
		SecTrustCreateWithCertificates([certificate] as CFArray, SecPolicyCreateBasicX509(), &trust)
		if anchored, let trust {
			SecTrustSetAnchorCertificates(trust, [certificate] as CFArray)
			SecTrustSetAnchorCertificatesOnly(trust, true)
		}
		return trust
	}
	
	static var publicKeyHash: String? {
		guard
			let certificate,
			let key = SecCertificateCopyKey(certificate),
			let data = SecKeyCopyExternalRepresentation(key, nil) as Data?
		else { return nil }
		let header: [UInt8] = [
			0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
			0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
		]
		return Data(data.sha256(header: header)).base64EncodedString()
	}
}

final class MockSpace : URLProtectionSpace, @unchecked Sendable {
	
	private let trust: SecTrust?
	
	override var authenticationMethod: String { NSURLAuthenticationMethodServerTrust }
	
	override var serverTrust: SecTrust? { trust }
	
	init(trust: SecTrust?) {
		self.trust = trust
		super.init(host: "fusion.test", port: 443, protocol: "https", realm: nil, authenticationMethod: NSURLAuthenticationMethodServerTrust)
	}
	
	required init?(coder: NSCoder) {
		self.trust = nil
		super.init(coder: coder)
	}
}

final class MockSender: NSObject, URLAuthenticationChallengeSender {
	func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) { }
	func continueWithoutCredential(for challenge: URLAuthenticationChallenge) { }
	func cancel(_ challenge: URLAuthenticationChallenge) { }
	func performDefaultHandling(for challenge: URLAuthenticationChallenge) { }
	func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) { }
}

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct RESTAuthenticatorTests {
		
		private func challenge(trust: SecTrust?) -> URLAuthenticationChallenge {
			.init(protectionSpace: MockSpace(trust: trust),
				  proposedCredential: nil,
				  previousFailureCount: 0,
				  failureResponse: nil,
				  error: nil,
				  sender: MockSender())
		}
		
		private func evaluate(hashKeys: [String], trust: SecTrust?) -> (URLSession.AuthChallengeDisposition, URLCredential?) {
			let authenticator = RESTAuthenticator()
			var outcome: (URLSession.AuthChallengeDisposition, URLCredential?) = (.rejectProtectionSpace, nil)
			authenticator.hashKeys = hashKeys
			authenticator.urlSession(.shared, didReceive: challenge(trust: trust)) { outcome = ($0, $1) }
			return outcome
		}
		
		@Test
		func urlSession_NoHashKeys_PerformDefaultHandling() {
			let (disposition, credential) = evaluate(hashKeys: [], trust: nil)
			#expect(disposition == .performDefaultHandling)
			#expect(credential == nil)
		}
		
		@Test
		func urlSession_MissingServerTrust_CancelAuthenticationChallenge() {
			let (disposition, credential) = evaluate(hashKeys: [""], trust: nil)
			#expect(disposition == .cancelAuthenticationChallenge)
			#expect(credential == nil)
		}
		
		@Test
		func urlSession_UntrustedServerTrust_CancelAuthenticationChallengeWithoutCrashing() throws {
			let trust = try #require(MockCertificate.trust(anchored: false))
			let (disposition, credential) = evaluate(hashKeys: ["unmatched"], trust: trust)
			#expect(disposition == .cancelAuthenticationChallenge)
			#expect(credential == nil)
		}
		
		@Test
		func urlSession_TrustedServerTrustWithUnmatchedPin_CancelAuthenticationChallenge() throws {
			let trust = try #require(MockCertificate.trust(anchored: true))
			let (disposition, credential) = evaluate(hashKeys: ["unmatched"], trust: trust)
			#expect(disposition == .cancelAuthenticationChallenge)
			#expect(credential == nil)
		}
		
		@Test
		func urlSession_TrustedServerTrustWithMatchedPin_UseCredential() throws {
			let trust = try #require(MockCertificate.trust(anchored: true))
			let hash = try #require(MockCertificate.publicKeyHash)
			let (disposition, credential) = evaluate(hashKeys: [hash], trust: trust)
			#expect(disposition == .useCredential)
			#expect(credential != nil)
		}
	}
}
