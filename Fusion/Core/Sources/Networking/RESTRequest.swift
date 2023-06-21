//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation

// MARK: - Definitions -

public typealias Response<T> = (Result<T, Error>, URLResponse?) -> Void
public typealias Headers = [String : String]

@inlinable public func asyncMain(_ callback: @escaping () -> Void) {
	DispatchQueue.main.async { callback() }
}

@inlinable public func asyncMain(after: Double, _ callback: @escaping () -> Void) {
	DispatchQueue.main.asyncAfter(deadline: .now() + after) { callback() }
}

@inlinable public func asyncResponse<T>(_ callback: Response<T>?) -> Response<T> {
	{ result, response in asyncMain { callback?(result, response) } }
}

public enum HTTPMethod : String {
	case get = "GET"
	case post = "POST"
	case put = "PUT"
	case patch = "PATCH"
	case delete = "DELETE"
}

public enum RESTError : Error {
	case unkown(Data?)
}

public extension Result {
	
	/// Quick result check based on its enum.
	var isSuccess: Bool {
		switch self {
		case .success: return true
		case .failure: return false
		}
	}
	
	/// Tries to transform the received error into a codable model.
	///
	/// - Returns: The error model or `nil` if it fails to parse.
	func error<T : Codable>() -> T? {
		guard
			case let .failure(error) = self,
			let apiError = error as? RESTError,
			case let .unkown(data) = apiError,
			let validData = data
		else { return nil }
		
		return T.self.load(data: validData)
	}
	
	/// Maps the success result to a given non-optional outcome.
	/// This function can be used to unwraps keypaths and properties inside a successfull response, while failing for `nil` outcomes.
	///
	/// - Parameter transform: The transformation closure.
	/// - Returns: The new result with a generic error.
	@inlinable public func mapAndUnwrap<T>(_ transform: (Success) -> T?) -> Result<T, Error> {
		switch self {
		case .success(let value):
			guard let unwrapped = transform(value) else { return .failure(NSError()) }
			return .success(unwrapped)
		case .failure(let error):
			return .failure(error)
		}
	}
}

public extension URLResponse {
	
	/// The possible `HTTPURLResponse` in this response.
	var http: HTTPURLResponse? { self as? HTTPURLResponse }
	
	/// The possible HTTP Status Code.
	var httpStatusCode: Int { http?.statusCode ?? 0 }
	
	/// The possible HTTP header in the response.
	var httpHeaders: Headers { (http?.allHeaderFields as? Headers) ?? [:] }
}

// MARK: - Extension - URLRequest Logs

private extension URLRequest {
	
	func debugLogRequest() {
		Logger.global.log(basic: "=== 🚀 REQUEST === \(httpMethod ?? "") \(urlString)",
						  full: allHTTPHeaderFields?.description ?? "")
	}
	
	func debugLog(response: URLResponse?, seconds: TimeInterval) {
		let code = (response as? HTTPURLResponse)?.statusCode ?? 0
		let icon = code >= 200 && code < 400 ? "📦" : "📦‼️"
		Logger.global.log(basic: "=== \(icon) RESPONSE === \(urlString) (\(code)) - \(Int(seconds * 1000))ms",
						  full: "\(response ?? URLResponse())")
	}
	
	func debugLog(data: Data) {
		let byte = ByteCountFormatter()
		byte.allowedUnits = [.useKB]
		byte.countStyle = .file
		Logger.global.log(basic: "=== 📥 RECEIVED === \(urlString) (\(byte.string(fromByteCount: Int64(data.count))))",
						  full: "\(String(data: data, encoding: .utf8) ?? "")")
	}
	
	func debugLog(error: Error) {
		Logger.global.log(basic: "=== ❌ ERROR === \(urlString) \(error)")
	}
}

// MARK: - Extension - URLRequest REST Tasks

public extension URLRequest {

	var currentTime: TimeInterval { CFAbsoluteTimeGetCurrent() }
	
	var urlString: String { url?.absoluteString ?? "" }
	
	private func responseResult(_ response: URLResponse?, _ data: Data) -> Result<Data, Error> {
		let code = (response as? HTTPURLResponse)?.statusCode ?? 0
		
		switch code {
		case 200..<400:
			return .success(data)
		default:
			return .failure(RESTError.unkown(data))
		}
	}
	
	func mapDataResponse(to completion: Response<Data>?) {
		debugLogRequest()
		let time = currentTime
		
		RESTAuthenticator.session.dataTask(with: self) { (data, response, error) in
			let result: Result<Data, Error>

			self.debugLog(response: response, seconds: currentTime - time)
			
			if let validData = data {
				self.debugLog(data: validData)
				result = responseResult(response, validData)
			} else {
				let fail = error ?? RESTError.unkown(nil)
				self.debugLog(error: fail)
				result = .failure(fail)
			}
			
			HTTPCookieStorage.appGroup.sync()
			completion?(result, response)
		}.resume()
	}
	
	func mapJSONResponse<T : Codable>(to completion: Response<T>?) {
		mapDataResponse { result, response in
			switch result {
			case .failure(let error):
				completion?(.failure(error), response)
			case .success(let data):
				do {
					let result = try JSONDecoder.standard.decode(T.self, from: data)
					completion?(.success(result), response)
				} catch {
					self.debugLog(error: error)
					completion?(.failure(RESTError.unkown(nil)), response)
				}
			}
		}
	}
	
	func mapUpload(data: Data, to completion: Response<Data?>?) {
		debugLogRequest()
		let time = currentTime
		
		URLSession.shared.uploadTask(with: self, from: data) { (data, response, error) in
			if let httpResponse = response as? HTTPURLResponse {
				self.debugLog(response: httpResponse, seconds: currentTime - time)
			}
			
			if let validError = error {
				self.debugLog(error: validError)
				completion?(.failure(validError), response)
			} else {
				self.debugLog(data: data ?? Data())
				completion?(.success(data), response)
			}
		}.resume()
	}
}
