//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation
import CommonCrypto

// MARK: - Extension - String Encryption

public extension String {
	
	var encryptBase64: String { Data(self.utf8).base64EncodedString() }
	
	var decryptBase64: String {
		guard let data = Data(base64Encoded: self) else { return "" }
		return String(data: data, encoding: .utf8) ?? ""
	}
	
	func encryptBase64(by: Int) -> String { (1...by).reduce(self) { result, _ in result.encryptBase64 } }
	func decryptBase64(by: Int) -> String { (1...by).reduce(self) { result, _ in result.decryptBase64 } }
}

// MARK: - Extension - Sequence Encryption

public extension Sequence where Self.Element == UInt8 {
	
	var hex: String { reduce("") { "\($0)\(String(format: "%02x", $1))" } }
}

// MARK: - Extension - Data Encryption

extension Data {
	
	func sha256(header: [UInt8]? = nil) -> [UInt8] {
		var keyWithHeader = header != nil ? Data(header!) : Data()
		keyWithHeader.append(self)
		var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
		keyWithHeader.withUnsafeBytes {
			_ = CC_SHA256($0.baseAddress, CC_LONG(keyWithHeader.count), &digest)
		}
		
		return digest
	}
	
	func hmacSHA512(key: String) -> [UInt8] {
		var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
		withUnsafeBytes {
			CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA512), key, key.count, $0.baseAddress, count, &digest)
		}
		return digest
	}
	
	func sha512() -> [UInt8] {
		var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))

		_ = digest.withUnsafeMutableBytes { digestBytes -> UInt8 in
			withUnsafeBytes { messageBytes -> UInt8 in
				if let mb = messageBytes.baseAddress,
				   let db = digestBytes.bindMemory(to: UInt8.self).baseAddress {
					let length = CC_LONG(count)
					CC_SHA512(mb, length, db)
				}
				return 0
			}
		}

		return digest
	}
}
