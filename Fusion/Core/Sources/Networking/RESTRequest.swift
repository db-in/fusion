//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation

// MARK: - Definitions -

public typealias Response<T> = (Result<T, Error>, URLResponse?) -> Void
public typealias Headers = [String : String]

@inlinable public func syncMain(_ callback: @escaping () -> Void) {
	guard !Thread.isMainThread else { return callback() }
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

/// Bridges any API based on a ``Response`` completion into `async throws`, returning the value and the `URLResponse`.
/// The completion API remains the single source of truth, the bridge only awaits its first callback.
///
/// ```swift
/// let (user, response) = try await withURLResponse { UserService.fetch(completion: $0) }
/// ```
///
/// - Parameter body: A closure that starts the completion based work, forwarding the given completion.
/// - Returns: The successful value and the associated `URLResponse`.
/// - Throws: The failure delivered by the completion.
public func withURLResponse<T>(_ body: (@escaping Response<T>) -> Void) async throws -> (T, URLResponse?) {
	let resumed = ThreadSafe(wrappedValue: false)
	return try await withCheckedThrowingContinuation { continuation in
		body { result, response in
			let isFirst = resumed.mutate { done -> Bool in
				defer { done = true }
				return !done
			}
			guard isFirst else { return }
			continuation.resume(with: result.map { ($0, response) })
		}
	}
}

/// Bridges any API based on a ``Response`` completion into `async throws`.
/// The completion API remains the single source of truth, the bridge only awaits its first callback.
///
/// ```swift
/// public static func fetch() async throws -> User {
///     try await withResponse { fetch(completion: $0) }
/// }
/// ```
///
/// - Parameter body: A closure that starts the completion based work, forwarding the given completion.
/// - Returns: The successful value.
/// - Throws: The failure delivered by the completion.
public func withResponse<T>(_ body: (@escaping Response<T>) -> Void) async throws -> T {
	try await withURLResponse(body).0
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
	
	var id: String { "\(httpMethod ?? "") \(urlString)" }
	
	var hasLog: Bool { allHTTPHeaderFields?.keys.contains("sr") != true }
		
	var fullRequest: String {
		let headers = allHTTPHeaderFields?.description ?? ""
		guard let data = httpBody else { return headers }
		return [headers, .init(data: data, encoding: .utf8) ?? ""].joined(separator: "\n")
	}
	
	func debugLogRequest() {
		guard hasLog else { return }
		Logger.global.log(basic: "=== 🚀 REQUEST === \(id)", full: fullRequest)
	}
	
	func debugLog(response: URLResponse?, data: Data, seconds: TimeInterval) {
		guard hasLog else { return }
		let code = response?.httpStatusCode ?? 0
		let icon = code >= 200 && code < 400 ? "📥" : "📥‼️"
		let time = Int(seconds * 1000)
		
		if Logger.global == .full {
			let header = code >= 200 && code < 400 ? "📦" : "📦‼️"
			Logger.global.log(basic: "=== \(header) HEADERS === \(id)", full: response?.description)
		}
		
		Logger.global.log(basic: "=== \(icon) RESPONSE === \(id) (\(code)) - \(data.byteCount) - \(time)ms", full: String(data: data, encoding: .utf8))
	}
	
	func debugLog(error: Error) {
		guard hasLog else { return }
		Logger.global.log(basic: "=== ❌ ERROR === \(id) \(error)")
	}
}

// MARK: - Extension - URLRequest REST Tasks

public extension URLRequest {
	
	/// Returns the current absolute time in seconds since system boot.
	var currentTime: TimeInterval { CFAbsoluteTimeGetCurrent() }

	/// Returns the absolute string representation of the request's URL, or an empty string if the URL is nil.
	var urlString: String { url?.absoluteString ?? "" }
	
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
		debugLogRequest()
		let time = currentTime
		
		RESTAuthenticator.session.dataTask(with: self) { (data, response, error) in
			let result: Result<Data, Error>
			let elapsed = currentTime - time
			let statusCode = response?.httpStatusCode ?? 0
			
			if let validData = data {
				self.debugLog(response: response, data: validData, seconds: elapsed)
				result = responseResult(statusCode, validData)
			} else {
				let fail = error ?? RESTError.unkown(nil)
				self.debugLog(error: fail)
				result = .failure(fail)
			}
			
			HTTPCookieStorage.appGroup.sync()
			completion?(result, response)
		}.resume()
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

	/// Uploads the given data through ``RESTAuthenticator/session`` and maps the response.
	/// Status codes outside the `200..<400` range are reported as failures carrying the response body.
	/// - Parameters:
	///   - data: The data to upload.
	///   - completion: A closure that receives the result of the upload operation.
	func mapUpload(data: Data, to completion: Response<Data?>?) {
		debugLogRequest()
		let time = currentTime
		
		RESTAuthenticator.session.uploadTask(with: self, from: data) { (data, response, error) in
			let elapsed = currentTime - time
			let result: Result<Data?, Error>
			
			if let validError = error {
				self.debugLog(error: validError)
				result = .failure(validError)
			} else {
				let body = data ?? Data()
				self.debugLog(response: response, data: body, seconds: elapsed)
				result = responseResult(response?.httpStatusCode ?? 0, body).map { _ in data }
			}
			
			HTTPCookieStorage.appGroup.sync()
			completion?(result, response)
		}.resume()
	}
}
