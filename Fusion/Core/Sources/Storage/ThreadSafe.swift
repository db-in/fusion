//
//  Created by Diney Bomfim on 7/14/23.
//

import Foundation
import os

// MARK: - Definitions -

// MARK: - Type -

@propertyWrapper
public final class ThreadSafe<Value> {
	
	private let storage: OSAllocatedUnfairLock<Value>

	public init(wrappedValue: Value) {
		storage = OSAllocatedUnfairLock(uncheckedState: wrappedValue)
	}

	public var wrappedValue: Value {
		get { storage.withLockUnchecked { $0 } }
		set { storage.withLockUnchecked { $0 = newValue } }
	}

	@discardableResult
	public func mutate<Result>(_ transform: (inout Value) -> Result) -> Result {
		storage.withLockUnchecked(transform)
	}
}

extension ThreadSafe : @unchecked Sendable {}
