//
//  Created by Diney Bomfim on 5/3/23.
//

import Foundation

// MARK: - Definitions -

private struct Keys {
	static var deinitCallbackKey = "deinitCallback"
}

private struct Wrapper {
	static var all: CacheWrapper<String, [TargetWrapper]> = .init()
}

private class DeinitCallback: NSObject {
	var callbacks: [() -> Void] = []
	deinit { callbacks.forEach { $0() } }
}

private extension NSObject {

	private var deinitCallback: DeinitCallback {
		if let callback = objc_getAssociatedObject(self, &Keys.deinitCallbackKey) as? DeinitCallback {
			return callback
		} else {
			let callback = DeinitCallback()
			objc_setAssociatedObject(self, &Keys.deinitCallbackKey, callback, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			return callback
		}
	}

	func onDeinit(_ callback: @escaping () -> Void) {
		deinitCallback.callbacks.append(callback)
	}
}

private class TargetWrapper: Equatable {
	
	weak var object: AnyObject?
	var binds: [Any?] = []
	
	init(_ object: AnyObject?, callback: Any?) {
		self.object = object
		self.binds = [callback]
	}
	
	func performBinds<T>(value: T?) {
		binds.forEach {
			if let callback = ($0 as? Input<T>) {
				asyncMain { callback(value) }
			} else if let callback = ($0 as? () -> Void) {
				asyncMain { callback() }
			}
		}
	}
	
	static func == (lhs: TargetWrapper, rhs: TargetWrapper) -> Bool {
		lhs.object === rhs.object
	}
}

public typealias Input<T> = (T?) -> Void

// MARK: - Type - DataBindable

public protocol DataBindable {
	associatedtype Key : RawRepresentable
}

public extension DataBindable {
	
	private static var prefix: String { "\(Constant.isDebug ? "d-" : "")\(Self.self)" }
	
	static func namespace<T: RawRepresentable>(_ key: T) -> String { "\(prefix).\(key.rawValue)" }
	
	/// Binds a closure to be executed on every update of a given key. Including also update for the value removal.
	/// To avoid retain cycles it offers a cancellable object that will be used as a reference.
	/// As soon as the reference is deinitialized, the binding of the closure-key is also deleted.
	///
	/// - Complexity: O(1)
	/// - Parameters:
	///   - key: The key to be observed.
	///   - cancellable: A cancellable reference to be observed for deinitialization.
	///   - callback: The closure to be executed on every update of the key.
	static func bind<T>(key: Key, cancellable: NSObject, callback: @escaping Input<T>) {
		let wrapper = TargetWrapper(cancellable, callback: callback)
		let nameKey = namespace(key)
		
		if var item = Wrapper.all[nameKey] {
			if let index = item.firstIndex(of: wrapper) {
				item[index].binds.append(callback)
			} else {
				item.append(wrapper)
			}
		} else {
			Wrapper.all[nameKey] = [wrapper]
		}
		
		cancellable.onDeinit { Wrapper.all[nameKey]?.removeAll(where: { $0 == wrapper }) }
	}
	
	/// Binds a closure to be executed on every update of a given key or its removal.
	/// To avoid never released closures it offers a cancellable object that will be used as a reference.
	/// As soon as the reference is deinitialized, the binding of the closure-key is also deleted.
	///
	/// - Complexity: O(1)
	/// - Parameters:
	///   - key: The key to be observed.
	///   - cancellable: A cancellable reference to be observed for deinitialization.
	///   - callback: The closure to be executed on every update of the key.
	static func bind(key: Key, cancellable: NSObject, callback: @escaping (() -> Void)) {
		let wrapper = TargetWrapper(cancellable, callback: callback)
		let nameKey = namespace(key)
		
		if let item = Wrapper.all[nameKey] {
			if let index = item.firstIndex(of: wrapper) {
				item[index].binds.append(callback)
			} else {
				Wrapper.all[nameKey]?.append(wrapper)
			}
		} else {
			Wrapper.all[nameKey] = [wrapper]
		}
		
		cancellable.onDeinit { Wrapper.all[nameKey]?.removeAll(where: { $0 == wrapper }) }
	}
	
	/// Binds a method in the target to a given key update.
	///
	/// - Complexity: O(1)
	/// - Parameters:
	///   - key: The key to be observed.
	///   - cancellable: The target object that contains the method to be called. The object is weakly referenced.
	///   - callback: The method to be executed on every update of the key.
	static func bind(key: Key, target: NSObject, method: Selector) {
		bind(key: key, cancellable: target) { [weak target] in
			target?.perform(method)
		}
	}
	
	/// Unbinds all closures associated with a given key and cancellable
	///
	/// - Complexity: O(*n*), where n is the current length of the all the keys with a bind.
	/// - Parameters:
	///   - key: A given key that has a bind to it.
	///   - cancellable: A cancellable that has been used in a `bind` call before
	static func unbind(key: Key, cancellable: NSObject) {
		let wrapper = TargetWrapper(cancellable, callback: nil)
		let nameKey = namespace(key)
		
		Wrapper.all[nameKey]?.removeAll(where: { $0 == wrapper })
	}
	
	/// Sends the update message to all the existing valid closures that has used `bind` on the given key.
	///
	/// - Parameters:
	///   - value: The new value that has been updated associated with the given key.
	///   - key: A key that has a bind to it.
	static func send<T>(forKey key: Key, value: T?) {
		Wrapper.all[namespace(key)] = Wrapper.all[namespace(key)]?.compactMap { target in
			guard target.object != nil else { return nil }
			target.performBinds(value: value)
			return target
		}
	}
}
