//
//  Created by Diney Bomfim on 7/31/23.
//

import Foundation

// MARK: - Definitions -

// MARK: - Type -

public struct AnyCodable {

// MARK: - Properties
	
	public let value: Any?
	
	public var keyedValues: [String : Any]? { value as? [String : Any] }
	
	public subscript(key: String) -> AnyCodable { AnyCodable(keyedValues?[key] ?? [:]) }

// MARK: - Constructors

	public init(_ initialValue: Any?) {
		value = initialValue
	}
	
// MARK: - Protected Methods

// MARK: - Exposed Methods
	
	public func map<T : Codable>(to type: T.Type, keyPath: String? = nil) -> T? {
		if var currentValue: Any = keyedValues {
			if let path = keyPath {
				let pattern = #"[.\[]?([^.\[\]]+)\]?"#
				let matches = try? NSRegularExpression(pattern: pattern, options: []).matches(in: path, range: NSRange(path.startIndex..., in: path))
				matches?.forEach { match in
					if let range = Range(match.range(at: 1), in: path) {
						let key = String(path[range])
						
						if let dict = currentValue as? [String: Any] {
							currentValue = dict[key] ?? [:]
						} else if let array = currentValue as? [Any] {
							if let index = Int(key) {
								currentValue = array.count > index ? array[index] : [:]
							}
						}
					}
				}
			}
			return type.load(jsonObject: currentValue)
		} else if let validData = data {
			return type.load(data: validData)
		}
		
		return nil
	}
}

// MARK: - Extension - AnyCodable Codable

extension AnyCodable : Codable {

	public init(from decoder: Decoder) throws {

		let container = try decoder.singleValueContainer()

		if let content = try? container.decode(String.self) {
			value = content
		} else if let content = try? container.decode(Bool.self) {
			value = content
		} else if let content = try? container.decode([String: AnyCodable].self) {
			value = content.mapValues { $0.value }
		} else if let content = try? container.decode([AnyCodable].self) {
			value = content.map { $0.value }
		} else if let content = try? container.decode(Int.self) {
			value = content
		} else if let content = try? container.decode(Double.self) {
			value = content
		} else if container.decodeNil() {
			value = nil
		} else {
			throw DecodingError.dataCorruptedError(in: container, debugDescription: "")
		}
	}

	public func encode(to encoder: Encoder) throws {

		var container = encoder.singleValueContainer()

		guard let item = value else {
			try container.encodeNil()
			return
		}

		switch item {
		case let content as String:
			try container.encode(content)
		case let content as Bool:
			try container.encode(content)
		case let content as Int:
			try container.encode(content)
		case let content as Float:
			try container.encode(content)
		case let content as Double:
			try container.encode(content)
		case let content as [Any?]:
			try container.encode(content.map { AnyCodable($0) })
		case let content as [String : Any?]:
			try container.encode(content.mapValues { AnyCodable($0) })
		case is NSNull:
			try container.encodeNil()
		default:
			throw EncodingError.invalidValue(item, .init(codingPath: container.codingPath, debugDescription: ""))
		}
	}
}

// MARK: - Extension - Encodable AnyCodable

public extension Encodable {
	
	var anyCodable: AnyCodable { .init(object ?? [:]) }
}
