//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation

// MARK: - Definitions -

// MARK: - Type -

public class RESTAuthenticator : NSObject, URLSessionDelegate {
	
	public var hashKeys: [String] = []
	
	public static let shared: RESTAuthenticator = RESTAuthenticator()
	
	public static var session: URLSession = {
		let storage = HTTPCookieStorage.appGroup
		let config = URLSessionConfiguration.default
		
		storage.deleteAll()
		storage.sync(to: .shared)
		storage.cookieAcceptPolicy = .always
		config.urlCache = nil
		config.requestCachePolicy = .reloadIgnoringLocalCacheData
		config.httpCookieStorage = storage
		config.timeoutIntervalForRequest = 30
		config.sharedContainerIdentifier = Bundle.main.appGroup
		
		return .init(configuration: config, delegate: RESTAuthenticator.shared, delegateQueue: nil)
	}()
	
	public func urlSession(_ session: URLSession,
						   didReceive challenge: URLAuthenticationChallenge,
						   completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		guard !hashKeys.isEmpty else {
			completionHandler(.performDefaultHandling, nil)
			return
		}
		
		guard
			challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
			let serverTrust = challenge.protectionSpace.serverTrust
		else {
			completionHandler(.cancelAuthenticationChallenge, nil)
			return
		}
		
		var secresult: CFError?
		let status = SecTrustEvaluateWithError(serverTrust, &secresult)
		let certificate: SecCertificate?
		
		if #available(iOS 15.0, *) {
			let chain = (SecTrustCopyCertificateChain(serverTrust) as NSArray?)?.firstObject as? AnyObject
			if CFGetTypeID(chain) == SecCertificateGetTypeID() {
				certificate = (chain?.firstObject as! SecCertificate)
			} else {
				certificate = nil
			}
		} else {
			certificate = SecTrustGetCertificateAtIndex(serverTrust, 0)
		}
		
		if status, let validCert = certificate {
			
			guard
				let publicKey = SecCertificateCopyKey(validCert),
				let publicKeyData: NSData = SecKeyCopyExternalRepresentation(publicKey, nil)
			else {
				completionHandler(.performDefaultHandling, nil)
				return
			}
			
			let rsa2048Asn1Header:[UInt8] = [
				0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
				0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
			]
			
			let hex = (publicKeyData as Data).sha256(header: rsa2048Asn1Header)
			let keyHash = Data(hex).base64EncodedString()
			
			if hashKeys.contains(keyHash) {
				completionHandler(.useCredential, .init(trust: serverTrust))
				return
			}
		}
		
		completionHandler(.cancelAuthenticationChallenge, nil)
	}
}
