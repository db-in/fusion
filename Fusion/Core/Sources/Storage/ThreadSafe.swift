//
//  Created by Diney Bomfim on 7/14/23.
//

import Foundation

// MARK: - Definitions -

// MARK: - Type -

@propertyWrapper
public final class ThreadSafe<Value> {
	
	private var value: Value
	private let queue = DispatchQueue(label: "\(UUID().uuidString)", attributes: .concurrent)

	public init(wrappedValue: Value) {
		self.value = wrappedValue
	}

	public var wrappedValue: Value {
		get { queue.sync(flags: .barrier) { value } }
		set {
			queue.async(flags: .barrier) { [weak self] in
				self?.value = newValue
			}
		}
	}
}
