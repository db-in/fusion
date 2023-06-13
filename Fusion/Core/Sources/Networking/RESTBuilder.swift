//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation

// MARK: - Definitions -

public extension Dictionary where Key == String, Value == String {
	
	static func + (lhs: Self, rhs: URLQueryItem) -> Self {
		guard let value = rhs.value else { return lhs }
		return lhs + [rhs.name : value]
	}
}

public extension URL {
	
	var queryItemsDictionary: [String: String] {
		URLComponents(url: self, resolvingAgainstBaseURL: false)?.queryItems?.reduce([:], +) ?? [:]
	}
	
	func appendedQuery(data: Data?) -> URL {
		var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
		let query = data?.dictionaryObject.compactMap { URLQueryItem(name: $0, value: "\($1)") } ?? []
		
		components?.queryItems = query.count > 0 ? query : nil
		
		return components?.url ?? self
	}
}

public extension Data {
	
	/// Prepare some extra data to be appended into the very next request.
	/// The data will be automatically flushed after used, until there it's retained.
	static var dataToAppend: [String : Any]?
	
	/// Appends and flushes the data temporary stored into the `dataToAppend`.
	/// - Returns: The new full data if the merging is completed with success or the original data if it fails.
	func appendDataIfNeeded() -> Data {
		guard
			let data = Self.dataToAppend,
			let jsonDict = try? JSONSerialization.jsonObject(with: self) as? [String : Any]
		else { return self }
		
		Self.dataToAppend = nil
		return (try? JSONSerialization.data(withJSONObject: jsonDict + data)) ?? self
	}
}

// MARK: - Type -

public struct RESTBuilder<T> where T : Codable {
	
// MARK: - Properties
	
	public let url: String
	public let method: HTTPMethod

// MARK: - Constructors
	
	/// Creates a new standard request
	/// - Parameters:
	///   - url: The URL string to the request. It must be a valid absolute URL format.
	///   - method: The HTTP method to be used. The default value is `.get`
	public init(url: String, method: HTTPMethod = .get) {
		self.url = url
		self.method = method
	}
	
// MARK: - Protected Methods
	
	private func buildRequest() -> URLRequest {
		let validURL = URL(string: url) ?? URL(fileURLWithPath: "")
		var request = URLRequest(url: validURL)
		request.httpMethod = method.rawValue
		return request
	}
	
// MARK: - Exposed Methods
	
	/// Builds and executes a network request with a body data
	/// - Parameters:
	///   - body: A body, data or codable as a JSON
	///   - headers: A custom header. The standard header will be used if none is provided
	///   - completion: The result block
	public func execute<U : Codable>(body: U, headers: Headers = [:], then completion: Response<T>?) {
		
		var request = buildRequest()
		let data = (body as? Data) ?? (try? JSONEncoder.standard.encode(body))
		
		if method == .get {
			request.url = request.url?.appendedQuery(data: data?.appendDataIfNeeded())
		} else {
			request.httpBody = data?.appendDataIfNeeded()
		}
		
		request.allHTTPHeaderFields = headers
		
		if let dataCompletion = completion as? Response<Data> {
			request.mapDataResponse(to: dataCompletion)
		} else {
			request.mapJSONResponse(to: completion)
		}
	}
	
	/// Builds and executes a network without body
	/// - Parameters:
	///   - headers: A custom header. The standard header will be used if none is provided
	///   - completion: The result block
	public func execute(headers: Headers = [:], then completion: Response<T>?) {
		var request = buildRequest()
		request.allHTTPHeaderFields = headers
		
		if let dataCompletion = completion as? Response<Data> {
			request.mapDataResponse(to: dataCompletion)
		} else {
			request.mapJSONResponse(to: completion)
		}
	}
	
	/// Builds and executes a data upload with the networking engine
	/// - Parameters:
	///   - data: The data to be uploaded
	///   - completion: The result block
	public func upload(data: Data, headers: Headers = [:], then completion: Response<Data?>?) {
		var request = buildRequest()
		request.allHTTPHeaderFields = headers
		request.mapUpload(data: data, to: completion)
	}
}
