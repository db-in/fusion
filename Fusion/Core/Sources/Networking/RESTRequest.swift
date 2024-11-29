//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation

// MARK: - Definitions -

public typealias Response<T> = (Result<T, Error>, URLResponse?) -> Void
public typealias Headers = [String : String]

@inlinable public func syncMain(_ callback: @escaping () -> Void) {
	DispatchQueue.main.sync { callback() }
}

@inlinable public func asyncMain(_ callback: @escaping () -> Void) {
	DispatchQueue.main.async { callback() }
}

@inlinable public func asyncMain(after: Double, _ callback: @escaping () -> Void) {
	DispatchQueue.main.asyncAfter(deadline: .now() + after) { callback() }
}

@inlinable public func asyncGlobal(qos: DispatchQoS.QoSClass = .default, callback: @escaping () -> Void) {
	DispatchQueue.global(qos: qos).async { callback() }
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

public extension Headers {
	static var sr: Headers { ["sr": "1"] }
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
	
	/// Tries to get a possible failure and cast it as a given type.
	/// If the type conforms to Codable then tries to parse it as such.
	///
	/// - Returns: The error type or `nil` in case of cast failure. Codable failure also return `nil`, so as successful result.
	func error<T>() -> T? {
		guard case let .failure(error) = self else { return nil }

		guard
			let codableType = T.self as? Codable.Type,
			let apiError = error as? RESTError,
			case let .unkown(data) = apiError,
			let validData = data
		else { return error as? T }
		
		return codableType.load(data: validData) as? T
	}
	
	/// Maps the success result to a given non-optional outcome.
	/// This function can be used to unwraps keypaths and properties inside a successfull response, while failing for `nil` outcomes.
	///
	/// - Parameter transform: The transformation closure.
	/// - Returns: The new result with a generic error.
	@inlinable func mapAndUnwrap<T>(_ transform: (Success) -> T?) -> Result<T, Error> {
		switch self {
		case .success(let value):
			guard let unwrapped = transform(value) else { return .failure(RESTError.unkown(nil)) }
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
	
	var hasLog: Bool { allHTTPHeaderFields?.keys.contains("sr") != true }
		
	var fullRequest: String {
		let headers = allHTTPHeaderFields?.description ?? ""
		guard let data = httpBody else { return headers }
		return [headers, .init(data: data, encoding: .utf8) ?? ""].joined(separator: "\n")
	}
	
	func debugLogRequest() {
		guard hasLog else { return }
		Logger.global.log(basic: "=== 🚀 REQUEST === \(httpMethod ?? "") \(urlString)", full: fullRequest)
	}
	
	func debugLog(response: URLResponse?, seconds: TimeInterval) {
		guard hasLog else { return }
		let code = response?.httpStatusCode ?? 0
		let icon = code >= 200 && code < 400 ? "📦" : "📦‼️"
		let time = Int(seconds * 1000)
		Logger.global.log(basic: "=== \(icon) RESPONSE === \(urlString) (\(code)) - \(time)ms", full: "\(response ?? URLResponse())")
	}
	
	func debugLog(data: Data) {
		guard hasLog else { return }
		Logger.global.log(basic: "=== 📥 RECEIVED === \(urlString) (\(data.byteCount))", full: "\(String(data: data, encoding: .utf8) ?? "")")
	}
	
	func debugLog(error: Error) {
		guard hasLog else { return }
		Logger.global.log(basic: "=== ❌ ERROR === \(urlString) \(error)")
	}
}

// MARK: - Extension - URLRequest REST Tasks

public extension URLRequest {

	@ThreadSafe
	private static var restQueue = AsyncOperationQueue(maxConcurrentTasks: 16)
	
	/// Returns the current absolute time in seconds since system boot.
	var currentTime: TimeInterval { CFAbsoluteTimeGetCurrent() }

	/// Returns the absolute string representation of the request's URL, or an empty string if the URL is nil.
	var urlString: String { url?.absoluteString ?? "" }
	
	/// Maximum number of concurrent network requests allowed.
	/// The default value is 8, but this can be modified by setting a new value.
	static var maxConcurrentRequests: Int {
		get { restQueue.maxConcurrentTasks }
		set { restQueue.maxConcurrentTasks = newValue }
	}
	
	private func responseResult(_ code: Int, _ data: Data) -> Result<Data, Error> {
		switch code {
		case 200..<400:
			return .success(data)
		default:
			return .failure(RESTError.unkown(data))
		}
	}

	/// Maps the response data to a `Result<Data, Error>`.
	/// - Parameters:
	///   - completion: A closure that receives the result of the data mapping.
	func mapDataResponse(to completion: Response<Data>?) {
		URLRequest.restQueue.addTask { operation in
			debugLogRequest()
			let time = currentTime
			
			RESTAuthenticator.session.dataTask(with: self) { (data, response, error) in
				self.debugLog(response: response, seconds: currentTime - time)
				
				let result: Result<Data, Error>
				let statusCode = response?.httpStatusCode ?? 0
				
				if let validData = data {
					self.debugLog(data: validData)
					result = responseResult(statusCode, validData)
				} else {
					let fail = error ?? RESTError.unkown(nil)
					self.debugLog(error: fail)
					result = .failure(fail)
				}
				
				HTTPCookieStorage.appGroup.sync()
				completion?(result, response)
				
				operation.complete()
			}.resume()
		}
	}

	/// Maps the response data to a `Result<T, Error>`, where `T` is a `Codable` type.
	/// - Parameters:
	///   - completion: A closure that receives the result of the JSON decoding.
	func mapJSONResponse<T: Codable>(to completion: Response<T>?) {
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

	/// Uploads the given data and maps the response.
	/// - Parameters:
	///   - data: The data to upload.
	///   - completion: A closure that receives the result of the upload operation.
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
