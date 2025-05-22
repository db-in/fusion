//
//  Created by Diney Bomfim on 7/2/23.
//

#if canImport(UIKit)
import UIKit

private struct LoaderControl {
	
	@ThreadSafe
	private static var loaders: [String : Int] = [:]
	
	let key: String
	let reference: Int
	
	init<T>(target: T) {
		self.key = "\(target)".replacing(regex: ".*?0x(.*?);.*", with: "$1")
		self.reference = .random(in: 0...9999999)
		Self.loaders[key] = reference
	}
	
	static func isValid(_ control: LoaderControl) -> Bool { loaders[control.key] == control.reference }
	
	static func flush(_ control: LoaderControl) { loaders[control.key] = nil }
}

// MARK: - Type - ImageConvertible

public protocol ImageConvertible {
	
	/// Loads an image for an object into a given `keyPath`. This function is able to load from cache or download from the internet.
	/// This function can be called with multiple types of source: `String`, `URL`, `UIImage` or `Data`.
	///
	/// - Parameters:
	///   - target: The target object.
	///   - path: The mutable `keyPath` that contains the final `UIImage` property.
	func load<T>(on target: T, at path: ReferenceWritableKeyPath<T, UIImage?>)
}

extension ImageConvertible where Self : CustomStringConvertible {
	
	public func load<T>(on target: T, at path: ReferenceWritableKeyPath<T, UIImage?>) {
		load(on: target, at: path, allowsBadge: true)
	}
	
	/// Same as ``load(on:at:)`` with the option of badge and storage.
	///
	/// - Parameters:
	///   - target: The target object.
	///   - path: The mutable `keyPath` that contains the final `UIImage` property.
	///   - allowsBadge: Indicates if badges are allowed.
	///   - storage: Defines an alternative storage, which will be used to save the image or load from it in case `URLCache` is not available.
	/// - SeeAlso: ``load(on:at:)``
	public func load<T>(on target: T, at path: ReferenceWritableKeyPath<T, UIImage?>, allowsBadge: Bool, storage: URL? = nil) {
		let control = LoaderControl(target: target)
		if let image = UIImage.loadCache(url: "\(self)", allowsBadge: allowsBadge, storage: storage) {
			target[keyPath: path] = image
			LoaderControl.flush(control)
		} else {
			UIImage.download(url: "\(self)", allowsBadge: allowsBadge, storage: storage) {
				guard LoaderControl.isValid(control) else { return }
				target[keyPath: path] = $0 ?? target[keyPath: path]
				LoaderControl.flush(control)
			}
		}
	}
}

// MARK: - Extension - UIImage ImageConvertible

extension UIImage : ImageConvertible {
	public func load<T>(on target: T, at path: ReferenceWritableKeyPath<T, UIImage?>) { target[keyPath: path] = self }
}

// MARK: - Extension - Data ImageConvertible

extension Data : ImageConvertible {
	public func load<T>(on target: T, at path: ReferenceWritableKeyPath<T, UIImage?>) { target[keyPath: path] = .init(data: self) }
}

// MARK: - Extension - URL ImageConvertible

extension URL : ImageConvertible { }

// MARK: - Extension - String ImageConvertible

extension String : ImageConvertible { }

// MARK: - Extension - Optional ImageConvertible

public extension Optional where Wrapped == ImageConvertible {
	
	func load<T>(on target: T, at path: ReferenceWritableKeyPath<T, UIImage?>) {
		switch self {
		case let .some(value):
			value.load(on: target, at: path)
		default:
			target[keyPath: path] = nil
		}
	}
}
#endif
