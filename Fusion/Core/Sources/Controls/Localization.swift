//
//  Created by Diney Bomfim on 6/13/23.
//

import Foundation

// MARK: - Definitions -

// MARK: - Type -

public extension Locale {

// MARK: - Properties
	
	private static var language: String { Locale.preferredLanguages.first ?? Locale.autoupdatingCurrent.languageCode ?? "en" }
	
	/// Standard UTC/GMT locale.
	static var utc: Locale { Locale(identifier: "UTC") }
	
	/// Returns the current langauge code in lower case. For example `"en"`.
	static var currentLanguage: String { "\(language.prefix(2))".lowercased() }
}
