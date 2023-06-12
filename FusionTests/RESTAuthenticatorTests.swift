//
//  Created by Diney Bomfim on 09/06/2023.
//

import XCTest
@testable import Fusion

// MARK: - Definitions -

class MockSpace : URLProtectionSpace {
	
	private var isValid: Bool
	private var signature: String {
  """
  -----BEGIN CERTIFICATE-----
  MIIDWTCCAkGgAwIBAgIJAKxTSxNvww62MA0GCSqGSIb3DQEBCwUAMEIxCzAJBgNV
  BAYTAlVTMREwDwYDVQQIDAhMaW1hc2hlbGwxEjAQBgNVBAcMCUxpbWFzaGVsbDEY
  MBYGA1UECgwPT3BlbkFJIFNlY3VyaXR5MRMwEQYDVQQDDApNb2NrIENvbW1vbjAe
  Fw0yMTA5MjgxODI2MzFaFw0zMTA5MjUxODI2MzFaMEIxCzAJBgNVBAYTAlVTMREw
  DwYDVQQIDAhMaW1hc2hlbGwxEjAQBgNVBAcMCUxpbWFzaGVsbDEYMBYGA1UECgwP
  T3BlbkFJIFNlY3VyaXR5MRMwEQYDVQQDDApNb2NrIENvbW1vbjCCASIwDQYJKoZI
  hvcNAQEBBQADggEPADCCAQoCggEBAMNBKmltpYnGJey4NLHrDq7thSxrL0PoyEJH
  d38OFaXYsG4WBlAQ3MeFibjUjNQy4ZPVuBq5/McUj1kmhIGq8zGkZ09ZQU9ijM9I
  9qNSzpdn86xwazVt4IpevjoR1pDw5g+tjIJbT5S0pQ2H/Fbpm25fW7OotcUrKwIs
  4aPTbR0/1UwvmWRaVlDN8q3bX7ZQ74fQLhKf9oAGiog/tT5VlxpNFBWSDEcHwX5O
  /R3VQ0ieQbN3Q/rSy0Kf5i5AkVEnDEsRmv5EDj0G6sMpkfCKE2qMLlm7kD1QdVZi
  v/dPYOWh+eT+xHfYqYk25r0PjDVuoM4Np3G8BJyGKTy6ewovrXkCAwEAAaNTMFEw
  HQYDVR0OBBYEFMIf45C7gKh25sDTTNySOJixSlTlMB8GA1UdIwQYMBaAFMIf45C7
  gKh25sDTTNySOJixSlTlMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQAD
  ggEBAInJq0+DyS3/+H7G4iYpRn8/hugIFN0XgffNE6nBzZvPGznxFDCzFYmo5A1k
  fW2o3/tJWexElvYVh/w4Y9Uaz9HOM/yOYemfh3uvMo1aFw+DQz6POX2k3aeGijhM
  or3rGNhqMl7NVmf67oYqzMlFzg6gcOMCJ5eBdQK4/RL1X0p6O/yMfd6j1L1Ukozq
  dnG/Fb3YiDJGneE1PrTEBwWZP8Q7YzwvthlCYiVPOK34VeFeY+e7plzGjxUARy3u
  6tKjHLQUA9oyxW7MBFIsfYfyrW1OmS8PMz0VzCIPM8rJgffv3gjW8mVYbXKgeTfT
  4eW6BwRlPCqlM75xGZyvdqR7Ndo=
  -----END CERTIFICATE-----
  """
	}
	
	override var authenticationMethod: String {
		NSURLAuthenticationMethodServerTrust
	}
	
//	override var serverTrust: SecTrust? {
//		isValid ? createValidServerTrust() : createInvalidServerTrust()
//	}
	
	init(isValid: Bool) {
		self.isValid = isValid
		super.init(
			host: "example.com",
			port: 443,
			protocol: "https",
			realm: nil,
			authenticationMethod: NSURLAuthenticationMethodServerTrust
		)
	}
	
	required convenience init?(coder: NSCoder) {
		self.init(isValid: true)
	}
	
	private func createValidServerTrust() -> SecTrust {
		var trust: SecTrust?
		let certificateData = signature.data(using: .utf8)!
		let certificate = SecCertificateCreateWithData(nil, certificateData as CFData)!
		SecTrustCreateWithCertificates([certificate] as CFArray, SecPolicyCreateBasicX509(), &trust)
		return trust!
	}

	private func createInvalidServerTrust() -> SecTrust {
		var trust: SecTrust?
		let certificateData = Data()
		let certificate = SecCertificateCreateWithData(nil, certificateData as CFData)!
		SecTrustCreateWithCertificates([certificate] as CFArray, SecPolicyCreateBasicX509(), &trust)
		return trust!
	}
	
}

class MockSender: NSObject, URLAuthenticationChallengeSender {
	func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) { }
	func continueWithoutCredential(for challenge: URLAuthenticationChallenge) { }
	func cancel(_ challenge: URLAuthenticationChallenge) { }
	func performDefaultHandling(for challenge: URLAuthenticationChallenge) { }
	func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) { }
}

// MARK: - Type -

class RESTAuthenticatorTests: XCTestCase {
	
	private func challenge(withTrust: Bool) -> URLAuthenticationChallenge {
		.init(protectionSpace: MockSpace(isValid: withTrust),
			  proposedCredential: nil,
			  previousFailureCount: 0,
			  failureResponse: nil,
			  error: nil,
			  sender: MockSender())
	}
	
	func testUrlSession_NoHashKeys_PerformDefaultHandling() {
		let authenticator = RESTAuthenticator()
		let session = URLSession.shared
		
		authenticator.hashKeys = []
		authenticator.urlSession(session, didReceive: challenge(withTrust: false)) { disposition, credential in
			XCTAssertEqual(disposition, .performDefaultHandling)
			XCTAssertNil(credential)
		}
	}
	
	func testUrlSession_InvalidAuthenticationMethod_CancelAuthenticationChallenge() {
		let authenticator = RESTAuthenticator()
		let session = URLSession.shared
		
		authenticator.hashKeys = [""]
		authenticator.urlSession(session, didReceive: challenge(withTrust: true)) { disposition, credential in
			XCTAssertEqual(disposition, .cancelAuthenticationChallenge)
			XCTAssertNil(credential)
		}
	}
	
	func testUrlSession_ValidServerTrust_EvaluateCertificate() {
		let authenticator = RESTAuthenticator()
		let session = URLSession.shared
		
		authenticator.hashKeys = [""]
		authenticator.urlSession(session, didReceive: challenge(withTrust: true)) { disposition, credential in
			XCTAssertEqual(disposition, .cancelAuthenticationChallenge)
			XCTAssertNil(credential)
		}
	}
	
	func testUrlSession_InvalidServerTrust_CancelAuthenticationChallenge() {
		let authenticator = RESTAuthenticator()
		let session = URLSession.shared
		
		authenticator.urlSession(session, didReceive: challenge(withTrust: true)) { disposition, credential in
			XCTAssertEqual(disposition, .performDefaultHandling)
			XCTAssertNil(credential)
		}
	}
}
