//
//  Created by Diney Bomfim on 7/2/23.
//

#if canImport(UIKit)
import UIKit

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
		asyncGlobal {
			if let image = UIImage.loadCache(url: "\(self)", allowsBadge: allowsBadge, storage: storage) {
				syncMain { target[keyPath: path] = image }
			} else {
				UIImage.download(url: "\(self)", allowsBadge: allowsBadge, storage: storage) { target[keyPath: path] = $0 ?? target[keyPath: path] }
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

public extension Optional where Wrapped : ImageConvertible {
	func load<T>(on target: T, at path: ReferenceWritableKeyPath<T, UIImage?>) { (self as? ImageConvertible).load(on: target, at: path) }
}

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
