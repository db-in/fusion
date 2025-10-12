//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation

// MARK: - Extension - Int

public extension Int {
	
	/// Converts an integer to the localized date formart, consider the integer represents the value in seconds.
	///
	/// - Parameters:
	///   - units: The calendar units to consider. The default value is `[.minute, .second]`
	///   - style: The unit style. The default value `.positional`
	///   - zero: The zero formatting. The default value is `.pad`
	/// - Returns: The resulting string
	func toTimeUnits(_ units: NSCalendar.Unit = [.minute, .second],
					 style: DateComponentsFormatter.UnitsStyle = .positional,
					 zero: DateComponentsFormatter.ZeroFormattingBehavior = .pad) -> String {
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = units
		formatter.unitsStyle = style
		formatter.zeroFormattingBehavior = zero
		return formatter.string(from: TimeInterval(self)) ?? ""
	}
	
	/// Converts a Unix timestamp (seconds since 1970) to a Date object.
	///
	/// - Returns: A Date object representing the timestamp
	func toDate() -> Date { .init(timeIntervalSince1970: TimeInterval(self)) }
}

// MARK: - Extension - DateFormatter

public extension DateFormatter {
	
	/// Defines the standard formatter. It uses `medium` date style and `short` time style.
	/// For example: `"Nov 23, 1937 at 3:30 PM"`
	static let standard: DateFormatter = .init(dateStyle: .medium, timeStyle: .short)
	
	/// Defines the standard formatter. It uses `medium` date style and `none` time style.
	/// For example: `"Nov 23, 1937"`
	static let date: DateFormatter = .init(dateStyle: .medium, timeStyle: .none)
	
	/// Defines the time formatter. It uses `none` date style and `short` time style.
	/// For example: `"3:30 PM"`
	static let time: DateFormatter = .init(dateStyle: .none, timeStyle: .short)
	
	/// Initializes a DateFormatter with localized style and templates for a given locale.
	///
	/// - Parameters:
	///   - dateStyle: The output date style. Default is `none`.
	///   - timeStyle: The output time style. Default is `none`.
	///   - template: The output template, aka format. Templates are used as reference.
	///   the standard library merges the styles with the templates wisely regarding each locale.
	///   Default is `nil`.
	///   - timeZone: The timezone to convert the date to. The default value is `current`
	///   - locale: The locale to convert the date to. The default value is `preferredLocale`
	convenience init(dateStyle: DateFormatter.Style = .none,
					 timeStyle: DateFormatter.Style = .none,
					 template: CustomStringConvertible? = nil,
					 timeZone: TimeZone = .current,
					 locale: Locale = .preferredLocale) {
		self.init()
		self.calendar = .autoupdatingCurrent
		self.dateStyle = dateStyle
		self.timeStyle = locale.isRTL && timeStyle != .none ? .long : timeStyle
		self.timeZone = timeZone
		self.locale = locale.isRTL ? Locale(identifier: "ar_AE") : locale
		
		if let string = template {
			setLocalizedDateFormatFromTemplate("\(string)")
		}
	}
	
	/// Initializes DateFormatter with a fixed format.
	///
	/// - Parameters:
	///   - format: The given fixed format.
	///   - locale: The locale to convert the date to. The default value is `preferredLocale`
	convenience init(format: String, locale: Locale = .preferredLocale) {
		self.init()
		self.locale = locale
		self.dateFormat = format
	}
}

// MARK: - Extension - Date

public extension Date {
	
	/// Generates a String from a date object with a given output template using current locale.
	///
	/// - Parameters:
	///   - format: The given fixed format.
	///   - formatter: A given formatter object. Default is `standard`.
	/// - Returns: A new String object with the final format.
	func toString(format: CustomStringConvertible? = nil, formatter: DateFormatter = .standard) -> String {
		if let newFormat = format {
			formatter.dateFormat = "\(newFormat)"
		}
		
		return formatter.string(from: self)
	}
}

// MARK: - Extension - String

public extension String {
	
	/// Generates a Date object from a formatted date string.
	///
	/// - Parameters:
	///   - dateFormat: The given fixed format.
	///   - formatter: A given formatter object. Default is `standard`.
	/// - Returns: A date object if the string corresponds to valid date or nil otherwise.
	func toDate(format: CustomStringConvertible? = nil, formatter: DateFormatter = .standard) -> Date? {
		if let newFormat = format {
			formatter.dateFormat = "\(newFormat)"
		}
		
		return formatter.date(from: self)
	}
}
