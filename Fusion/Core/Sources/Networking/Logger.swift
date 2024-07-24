//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation

// MARK: - Definitions -

public struct LogEntry : Codable, Equatable {
	public let date: Date
	public let basic: String?
	public let full: String?
}

fileprivate extension Data {
	
	func appendToFile(key: String? = nil, newLine: Bool = true) {
		let validKey = key ?? "\(type(of: self))"
		let url = FileManager.default.appGroup.appendingPathComponent(validKey.hash.description)
		let newLineData = "\n".data(using: .utf8) ?? Data()
		let finalData = newLine ? self + newLineData : self
		
		if let fileHandle = try? FileHandle(forWritingTo: url) {
			defer { fileHandle.closeFile() }
			fileHandle.seekToEndOfFile()
			fileHandle.write(finalData)
		} else {
			try? finalData.write(to: url, options: .atomic)
		}
	}
	
	static func loadFile(key: String? = nil) -> Self? {
		let validKey = key ?? "\(self)"
		let url = FileManager.default.appGroup.appendingPathComponent(validKey.hash.description)
		return try? Data(contentsOf: url)
	}
}

fileprivate struct LogStorage : DataManageable {
	
	fileprivate typealias Storage = FileManager
	
	fileprivate enum Key : String, CaseIterable {
		case logs
	}
	
// MARK: - Properties
	
	private static var rawLogs: [LogEntry] {
		let namespace = namespace(Key.logs)
		let rawData = Data.loadFile(key: namespace)
		guard let validData = rawData else { return [] }
		let string = String(data: validData, encoding: .utf8)
		let lines = string?.components(separatedBy: "\n")
		let entries = lines?.compactMap(LogEntry.load)
		return entries?.reversed() ?? []
	}
	
	fileprivate static var allLogs: [LogEntry] {
		InMemoryCache.getOrSet(key: namespace(Key.logs), newValue: rawLogs) ?? []
	}
	
	fileprivate static func append(basic: String?, full: String?) {
		let namespace = namespace(Key.logs)
		InMemoryCache.flush(key: namespace)
		LogEntry(date: Date(), basic: basic, full: full).data?.appendToFile(key: namespace, newLine: true)
	}
}

// MARK: - Type -

/// The Logger object, capable of doing adhoc logs or using global shared level.
public enum Logger {
	
	case none
	case silent
	case basic
	case full

// MARK: - Properties
	
	public static var global: Logger = Constant.isDebug ? .basic : .none

	public static var localCache: [LogEntry] { LogStorage.allLogs }
	
// MARK: - Exposed Methods
	
	public func log(basic: @autoclosure () -> String) {
		switch self {
		case .none:
			return
		case .basic, .full:
			debugPrint(basic())
		default:
			break
		}
		
		LogStorage.append(basic: basic(), full: nil)
	}

	public func log(full: @autoclosure () -> String) {
		switch self {
		case .none:
			return
		case .full:
			debugPrint(full())
		default:
			break
		}
		
		LogStorage.append(basic: nil, full: full())
	}

	public func log(basic: @autoclosure () -> String, full: @autoclosure () -> String) {
		switch self {
		case .none:
			return
		case .basic:
			debugPrint(basic())
		case .full:
			debugPrint(basic())
			debugPrint(full())
		default:
			break
		}
		
		LogStorage.append(basic: basic(), full: full())
	}
	
	public static func flushLocalCache() {
		LogStorage.removeAllKeys()
	}
}
