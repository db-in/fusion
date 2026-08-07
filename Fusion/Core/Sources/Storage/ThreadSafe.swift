//
//  Created by Diney Bomfim on 7/14/23.
//

import Foundation

// MARK: - Definitions -

// MARK: - Type -

@propertyWrapper
public final class ThreadSafe<Value> {
	
	private var value: Value
	private let lock = NSLock()

	public init(wrappedValue: Value) {
		self.value = wrappedValue
	}

	public var wrappedValue: Value {
		get {
			lock.lock()
			defer { lock.unlock() }
			return value
		}
		set {
			lock.lock()
			defer { lock.unlock() }
			value = newValue
		}
	}

	@discardableResult
	public func mutate<Result>(_ transform: (inout Value) -> Result) -> Result {
		lock.lock()
		defer { lock.unlock() }
		return transform(&value)
	}
}
