//
//  Created by Diney Bomfim on 8/2/23.
//

import Foundation

// MARK: - Extension - Sequence

public extension Sequence where Element : Hashable {
	
	/// Returns an array containing the unique elements from the sequence.
	///
	/// - Parameter keepLast: A boolean value indicating whether to keep the last occurrence of each duplicated element.
	/// If `true`, the last occurrence is kept. If `false`, the first occurrence is kept. The default value is `false`.
	/// - Returns: An array containing the unique elements from the sequence based on the `keepLast` behavior.
	/// - Complexity: O(n), where `n` is the length of the sequence.
	func unique(keepLast: Bool = false) -> [Iterator.Element] {
		guard !keepLast else { return reversed().unique(keepLast: false).reversed() }
		var seen = Set<Element>()
		return filter { seen.insert($0).inserted }
	}
}

// MARK: - Extension - Array

public extension Array {
	
	/// Accesses the element at the specified position safely, returning nil if the index does not exist.
	/// - Complexity: O(1) for both reading / writing.
	@inlinable subscript(safe index: Int) -> Element?{ indices.contains(index) ? self[index] : nil }
	
	/// Filters the array over the given fields by any combination in the current text direction (LTR or RTL).
	///
	/// - Parameters:
	///   - text: The full text to be matching in the same order.
	///   - fields: All the fields to be searching over, the order is taken into consideration.
	///   - isCaseSensitive: Defines if the algorithm will consider the character case. Default is `false`.
	/// - Returns: The filtered array.
	/// - Complexity: O(n), where `n` is the length of the sequence.
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
	/// - Complexity: O(n), where `n` is the length of the sequence.
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
	
	/// Same as ``firstRecursively(_:where:)`` but for non-optional arrays.
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
	/// - Complexity: O(n), where `n` is the length of the sequence.
	func mapKeys<T>(_ transform: (Key) throws -> T) rethrows -> [T : Value] {
		var result = [T : Value]()
		try forEach { key, value in result[try transform(key)] = value }
		return result
	}
	
	/// Checks if a given dictionary is fully contained inside the current one. The values of both dictionaries must be hashable.
	///
	/// - Parameter other: The other dictionary.
	/// - Returns: Returns true if the given dictionary is fully contained.
	/// - Complexity: O(n), where `n` is the sum of elements in both dictionaries.
	func contains<T: Equatable>(_ other: [Key : T]) -> Bool {
		let keysSet = Set(keys)
		let newKeysSet = Set(other.keys)
		guard newKeysSet.isSubset(of: keysSet), !other.contains(where: { self[$0] as? T != $1 }) else { return false }
		return true
	}
	
	/// Merge two dictionaries together, where the right one can override elements in the original (left).
	///
	/// - Parameters:
	///   - lhs: Original dictionary (left), its keys can be overriden.
	///   - rhs: New dictionary (right), its keys will remain in the result.
	/// - Returns: The resulting new dictionary.
	static func + (lhs: Self, rhs: Self) -> Self { lhs.merging(rhs) { _, new in new} }
}

// MARK: - Extension - Optional Collection

public extension Optional where Wrapped: Collection {
	
	/// Returns `true` if the object is `nil` or `empty`. It returns true for non-zero valid objects.
	var isNilOrEmpty: Bool { self?.isEmpty ?? true }
}

// MARK: - Extension - Hashable

public extension Hashable {
	static func == (lhs: Self, rhs: Self) -> Bool { lhs.hashValue == rhs.hashValue }
}
