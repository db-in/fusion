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
}

// MARK: - Extension - UIImage Loader

public extension UIImage {
	
// MARK: - Private Methods
	
	private static var associated: [String : UIImage] = [:]
	
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
		guard let validURL = URL(string: url) else { return nil }
		
		let request = URLRequest(url: validURL)
		let cache = URLCache.shared
		guard let data = cache.cachedResponse(for: request)?.data ?? storage?.readImageData(withKey: url) else { return nil }
		let image = UIImage(data: data)
		storage?.writeImage(data: data, withKey: url)
		
		if let badge = associated[url], allowsBadge {
			return image?.addBadge(badge)
		} else {
			return image
		}
	}
	
	/// Only downloads a given url and caches it locally. It returns immediately if the image is already cached.
	/// If a storage is provided, it will also receives a copy of the image even if there is no new download.
	///
	/// - Parameters:
	///   - url: The url.
	///   - storage: A fallback storage to be used to save the image or load from it if `URLCache` is not available.
	///   - completion: The completion in which the final image will be sent to.
	static func download(url: String, storage: URL? = nil, then completion: @escaping (UIImage?) -> Void) {
		
		guard let validURL = URL(string: url) else {
			completion(nil)
			return
		}
		
		let request = URLRequest(url: validURL)
		let cache = URLCache.shared
		
		if let data = cache.cachedResponse(for: request)?.data ?? storage?.readImageData(withKey: url) {
			storage?.writeImage(data: data, withKey: url)
			completion(UIImage(data: data))
		} else {
			URLSession.shared.dataTask(with: request, completionHandler: { (dataResponse, response, error) in
				let image: UIImage?
				
				if let data = dataResponse, let validResponse = response {
					let cachedData = CachedURLResponse(response: validResponse, data: data)
					cache.storeCachedResponse(cachedData, for: request)
					image = UIImage(data: data)
					storage?.writeImage(data: data, withKey: url)
				} else {
					image = nil
				}
				
				asyncMain {
					completion(image)
				}
			}).resume()
		}
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
	///   - allowsBadge: Indicates if badges are allowed. The default is `true`.
	///   - storage: Defines an alternative storage, which will be used to save the image or load from it in case `URLCache` is not available.
	///   - placeholder: The placeholder image to be used when redaction is not allowed in the target object.
	static func load<T>(_ source: Any?,
						for object: T,
						at: ReferenceWritableKeyPath<T, UIImage?>,
						allowsBadge: Bool = true,
						storage: URL? = nil,
						placeholder: UIImage? = .photoPlaceholder) {
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
		download(url: url, storage: storage) { image in
			let finalImage = image ?? placeholder

			if let badge = associated[url], allowsBadge {
				object[keyPath: at] = finalImage?.addBadge(badge)
			} else {
				object[keyPath: at] = finalImage
			}
		}
	}
}

// MARK: - Extension - Array

public extension Array {
	
	/// Loops the array elements taking the `keyPath` of each item and tries to load from cache or download from the internet.
	///
	/// - Parameters:
	///   - keyPath: The `keyPath` of the property to be used as the url.
	///   - storage: The local path to be used as a storage if the ``URLCache.shared`` is not available.
	///   - completion: The completion block to be notified on the main thread once the process is completed.
	func downloadImages(keyPath: KeyPath<Element, String>, storage: URL? = nil, completion: @escaping () -> Void) {
		let group = DispatchGroup()
		
		forEach {
			let url = $0[keyPath: keyPath]
			guard UIImage.loadCache(url: url, storage: storage) == nil else { return }
			group.enter()
			UIImage.download(url: url, storage: storage) { _ in
				group.leave()
			}
		}
		
		group.notify(queue: .main) {
			completion()
		}
	}
	
	/// Loops the array elements taking the `keyPath` of each item and tries to associate a badge with the given property.
	///
	/// - Parameters:
	///   - image: The badge image to be associated.
	///   - keyPath: The `keyPath` which represents the url.
	func associateBadge(_ image: UIImage?, keyPath: KeyPath<Element, String>) {
		forEach { UIImage.associateBadge(image, to: $0[keyPath: keyPath]) }
	}
}
#endif
