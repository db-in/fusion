//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation

// MARK: - Definitions -

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
	
	fileprivate static func append(entry: LogEntry) {
		let namespace = namespace(Key.logs)
		InMemoryCache.flush(key: namespace)
		entry.data?.appendToFile(key: namespace, newLine: true)
	}
}

public typealias LogString = () -> String?

/// A structure that represents a log entry with a `basic` and `full` log message.
public struct LogEntry: Codable, Equatable, CustomStringConvertible {
	
	/// The date the log entry was created.
	public let date: Date
	
	/// The basic log message.
	public let basic: String?
	
	/// The full log message.
	public let full: String?
	
	/// A computed description of the log entry, including both basic and full messages, joined by a newline.
	public var description: String { [basic, full].compactMap({ $0 }).joined(separator: "\n") }
	
	/// Initializes a new `LogEntry` instance with optional basic and full log messages.
	///
	/// - Parameters:
	///   - date: The date of the log entry. Default is the current date.
	///   - basic: The basic log message. Default is `nil`.
	///   - full: The full log message. Default is `nil`.
	public init(date: Date = Date(), basic: String? = nil, full: String? = nil) {
		self.date = date
		self.basic = basic
		self.full = full
	}
	
	/// Prints the log entry to the debug console and returns the log entry instance.
	///
	/// - Returns: The log entry instance.
	@discardableResult public func printing(_ logLevel: Logger) -> Self {
		switch logLevel {
		case .basic:
			if let basic = basic {
				debugPrint(basic)
			}
		case.full:
			debugPrint(self)
		default:
			break
		}
		
		return self
	}
}

// MARK: - Type -

/// Logger is an enumeration that defines different logging levels.
public enum Logger {
	
	/// The basic logging level, prints minimal log details.
	case basic
	
	/// The full logging level, prints detailed log information.
	case full
	
	/// The silent logging level, does not print any logs.
	case silent
	
	/// No logging is performed.
	case none

// MARK: - Properties

	/// The global logger configuration, determined by the `Constant.isDebug` flag.
	public static var global: Logger = Constant.isDebug ? .basic : .none
	
	/// A local cache of all log entries.
	public static var localCache: [LogEntry] { LogStorage.allLogs }

// MARK: - Exposed Methods

	/// Logs the basic and/or full log messages depending on the current logging level.
	///
	/// - Parameters:
	///   - basic: A closure that provides the basic log message. Default is `nil`.
	///   - full: A closure that provides the full log message. Default is `nil`.
	///   - save: A Boolean indicating whether to save the log entry to storage. Default is `true`.
	public func log(basic: @autoclosure LogString = nil, full: @autoclosure LogString = nil, save: Bool = true) {
		let log: LogEntry
		
		switch self {
		case .basic, .full, .silent:
			log = .init(basic: basic(), full: full()).printing(self)
		case .none:
			return
		}
		
		guard save else { return }
		LogStorage.append(entry: log)
	}
	
	/// Logs the execution time of a closure, formatted with a specified precision.
	///
	/// - Parameters:
	///   - basic: A closure that provides the basic log message. Default is `nil`.
	///   - full: A closure that provides the full log message. Default is `nil`.
	///   - precision: The number of decimal places to display for the elapsed time. Default is `5`.
	///   - save: A Boolean indicating whether to save the log entry to storage. Default is `false`.
	///   - closure: The closure whose execution time will be logged.
	public func logTimeProfile(basic: @autoclosure LogString = nil, full: @autoclosure LogString = nil, precision: Int = 5, save: Bool = false, closure: Callback) {
		let date = Date()
		closure()
		let elapsedTime = Date().timeIntervalSince(date)
		let timeLog = [String(format: "⏱️ Time Profile: %.\(precision)fs", elapsedTime), basic()].compactMap({ $0 }).joined(separator: " - ")
		log(basic: timeLog, full: full(), save: save)
	}
	
	/// Clears all local cached logs.
	public static func flushLocalCache() {
		LogStorage.removeAllKeys()
	}
}
