//
//  Created by Diney Bomfim on 7/2/23.
//

#if canImport(UIKit)
import UIKit

// MARK: - Extension - URL UIImage Manager

private extension URL {
	
	func readImageData(withKey: String) -> Data? {
		try? Data(contentsOf: appendingPathComponent("image-\(withKey.hash.description)"))
	}
	
	func writeImage(data: Data, withKey: String) {
		try? data.write(to: appendingPathComponent("image-\(withKey.hash.description)"))
	}
	
	func flushImageCache() {
		guard let files = try? FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil) else { return }

		files.forEach {
			guard $0.lastPathComponent.hasPrefix("image-") else { return }
			try? FileManager.default.removeItem(at: $0)
		}
	}
}

// MARK: - Extension - UIImage Loader

public extension UIImage {
	
// MARK: - Private Methods
	
	private static var associated: [String : UIImage] = [:]
	private static var inMemory: [String : UIImage] = [:]
	
// MARK: - Protected Methods
	
	private func resolve(badge: Bool, key: String) -> UIImage {
		guard badge, let badgeImage = Self.associated[key] else { return self }
		return addBadge(badgeImage)
	}
	
// MARK: - Exposed Methods
	
	/// Adds a badge to the image by overlaying another image on top of it.
	///
	/// - Parameters:
	///   - image: The badge image to overlay on top of the original image.
	///   - proportion: The scaling proportion of the badge image (default: 0.5).
	/// - Returns: The image with the added badge.
	func addBadge(_ image: UIImage, proportion: CGFloat = 0.5) -> UIImage {
		let scaledSize = CGSize(width: size.width * proportion, height: size.height * proportion)
		let scaledRect = CGRect(origin: .zero, size: scaledSize)
		
		UIGraphicsBeginImageContext(.init(width: size.width + scaledSize.width * 0.25, height: size.height + scaledSize.height * 0.25))
		draw(in: CGRect(origin: .init(x: scaledSize.width * 0.25, y: scaledSize.height * 0.25), size: size))
		image.draw(in: scaledRect, blendMode: .normal, alpha: 1)
		
		guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else { return self }
		UIGraphicsEndImageContext()
		
#if !os(watchOS)
		newImage.accessibilityIdentifier = accessibilityIdentifier
#endif
		
		return newImage
	}
	
	/// This function can associate and dissociate a badge images to be placed on top of the original images when indicated in the loading functions.
	///
	/// - Parameters:
	///   - image: The badge image.
	///   - to: The url which will be used to load the original image later on.
	static func associateBadge(_ image: UIImage?, to: String) {
		associated[to] = image
	}
	
	/// This function exclusively tries to load the image from cache.
	/// Options for using the badge feature or a fallback storage are available.
	///
	/// - Parameters:
	///   - url: The url which originates the cache.
	///   - allowsBadge: Indicates if associated badges are allowed.
	///   - storage: A fallback storage to be used. This storage will receive a copy of the cache when cache is available.
	/// - Returns: The final `UIImage`
	static func loadCache(url: String, allowsBadge: Bool = true, storage: URL? = nil) -> UIImage? {
		if let inMemoryImage = inMemory[url]?.resolve(badge: allowsBadge, key: url) { return inMemoryImage }
			
		guard
			let validURL = URL(string: url),
			let data = URLCache.shared.cachedResponse(for: .init(url: validURL))?.data ?? storage?.readImageData(withKey: url),
			let image = UIImage(data: data)
		else { return nil }
		
		inMemory[url] = image
		storage?.writeImage(data: data, withKey: url)
		
		return image.resolve(badge: allowsBadge, key: url)
	}
	
	/// Forces the download of a given url and caches it locally. This methods triggers the ``loadCache(url:allowsBadge:storage:)`` once
	/// the download is completed.
	///
	/// - Parameters:
	///   - url: The url.
	///   - allowsBadge: Indicates if associated badges are allowed.
	///   - storage: A fallback storage to be used. This storage will receive a copy of the cache when cache is available.
	///   - completion: The completion in which the final image will be sent to.
	static func download(url: String, allowsBadge: Bool = true, storage: URL? = nil, then completion: @escaping (UIImage?) -> Void) {
		
		guard let validURL = URL(string: url) else {
			asyncMain { completion(nil) }
			return
		}
		
		let request = URLRequest(url: validURL)
		let task = URLSession.shared.dataTask(with: request) { (dataResponse, response, error) in
			if let data = dataResponse, let validResponse = response {
				let cachedData = CachedURLResponse(response: validResponse, data: data)
				URLCache.shared.storeCachedResponse(cachedData, for: request)
			}
			
			let image = loadCache(url: url, allowsBadge: allowsBadge, storage: storage)
			asyncMain { completion(image) }
		}
		
		task.resume()
	}
	
	/// Loads an image for an object into a given `keyPath`. This function is able to load from cache or download from the internet.
	/// This function can be called with multiple types of source: `String`, `URL`, `UIImage` or `Data`.
	/// This function also takes care of loading states such as redaction or placeholder images.
	///
	/// For `String` and `URL`, badges are available if chosen.
	///
	/// - Parameters:
	///   - source: The source to be loaded.
	///   - object: The target object.
	///   - at: The mutable `keyPath` that contains the final `UIImage` property.
	///   - placeholder: The placeholder image to be used when redaction is not allowed in the target object.
	///   - allowsBadge: Indicates if badges are allowed. The default is `true`.
	///   - storage: Defines an alternative storage, which will be used to save the image or load from it in case `URLCache` is not available.
	static func load<T>(_ source: Any?,
						for object: T,
						at: ReferenceWritableKeyPath<T, UIImage?>,
						placeholder: UIImage? = .photoPlaceholder,
						allowsBadge: Bool = true,
						storage: URL? = nil) {
		guard let url = source as? String ?? (source as? URL)?.absoluteString else {
			if let image = source as? UIImage {
				object[keyPath: at] = image
			} else if let data = source as? Data {
				object[keyPath: at] = UIImage(data: data)
			} else {
				object[keyPath: at] = nil
			}
			return
		}
		
		object[keyPath: at] = placeholder
		DispatchQueue.global().async {
			if let image = loadCache(url: url, allowsBadge: allowsBadge, storage: storage) {
				asyncMain { object[keyPath: at] = image }
			} else {
				download(url: url, allowsBadge: allowsBadge, storage: storage) { image in
					object[keyPath: at] = image ?? placeholder
				}
			}
		}
	}
	
	/// Removes all the current cached images.
	/// - Parameter storage: An alternative storage used to cache.
	static func flushCache(storage: URL? = nil) {
		URLCache.shared.removeAllCachedResponses()
		storage?.flushImageCache()
		inMemory = [:]
	}
}
#endif
