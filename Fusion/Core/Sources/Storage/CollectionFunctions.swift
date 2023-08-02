//
//  Created by Diney Bomfim on 8/2/23.
//

import Foundation

// MARK: - Definitions -

// MARK: - Extension - Array Search
public extension Array {
	
	/// Filters the array over the given fields by any combination in the current text direction (LTR or RTL).
	///
	/// - Parameters:
	///   - text: The full text to be matching in the same order.
	///   - fields: All the fields to be searching over, the order is taken into consideration.
	///   - isCaseSensitive: Defines if the algorithm will consider the character case. Default is `false`.
	/// - Returns: The filtered array.
	func filtered(by text: String, fields: [KeyPath<Element, String>], isCaseSensitive: Bool = false) -> Self {
		filter { item in fields.reduce("", { $0 + item[keyPath: $1] }).containsCharacters(text, isCaseSensitive: isCaseSensitive) }
	}
	
	/// Filters the array over the given fields by matching exactly the given text.
	///
	/// - Parameters:
	///   - text: The full text to be matching in the same order.
	///   - fields: All the fields to be searching over, the order is taken into consideration.
	///   - isCaseSensitive: Defines if the algorithm will consider the character case. Default is `false`.
	/// - Returns: The filtered array.
	func matched(by text: String, fields: [KeyPath<Element, String>], isCaseSensitive: Bool = false) -> Self {
		filter { item in fields.reduce("", { $0 + item[keyPath: $1] }).containsSequence(text, isCaseSensitive: isCaseSensitive) }
	}
	
	/// Recursively searches for the first element in the array or its subarrays that satisfies the given predicate.
	///
	/// - Parameters:
	///   - keyPath: The key path used to access the subarray within each element.
	///   - predicate: The predicate used to test elements for a condition.
	/// - Returns: The first element that satisfies the predicate, or `nil` if no such element is found.
	/// - Complexity: O(n^k), where `n` is the number of elements in the array and `k` is the average number of sub elements.
	func firstRecursively(_ keyPath: KeyPath<Element, [Element]?>, where predicate: (Element) throws -> Bool) rethrows -> Element? {
		for element in self {
			guard try predicate(element) else {
				guard let subLevel = try element[keyPath: keyPath]?.firstRecursively(keyPath, where: predicate) else { continue }
				return subLevel
			}
			return element
		}
		return nil
	}
	
	/// Same as ``firstRecursively(_:where:)-71nb2`` but for non-optional arrays.
	///
	/// - Parameters:
	///   - keyPath: The key path used to access the subarray within each element.
	///   - predicate: The predicate used to test elements for a condition.
	/// - Returns: The first element that satisfies the predicate, or `nil` if no such element is found.
	/// - Complexity: O(n^k), where `n` is the number of elements in the array and `k` is the average number of sub elements.
	func firstRecursively(_ keyPath: KeyPath<Element, [Element]>, where predicate: (Element) throws -> Bool) rethrows -> Element? {
		for element in self {
			guard try predicate(element) else {
				guard let subLevel = try element[keyPath: keyPath].firstRecursively(keyPath, where: predicate) else { continue }
				return subLevel
			}
			return element
		}
		return nil
	}
}

// MARK: - Extension - Dictionary

public extension Dictionary {
	
	/// Maps the current dictinary into a new dictionary with new keys while keeping the same values.
	///
	/// - Parameter transform: The predicate that will transform the keys.
	/// - Returns: The new dictionary.
	func mapKeys<T>(_ transform: (Key) throws -> T) rethrows -> [T : Value] {
		var result = [T : Value]()
		try forEach { key, value in result[try transform(key)] = value }
		return result
	}
	
	static func + (lhs: Self, rhs: Self) -> Self { lhs.merging(rhs) { _, new in new} }
}