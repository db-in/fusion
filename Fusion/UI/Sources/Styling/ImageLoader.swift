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

	@ThreadSafe
	private static var inMemory: [String : UIImage] = [:]
	
	@ThreadSafe
	private static var associated: [String : UIImage] = [:]
	
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
	
	/// Creates an animated UIImage from GIF data with proper frame durations.
	///
	/// - Parameters:
	///   - gifData: The data of the GIF image.
	/// - Returns: An animated UIImage if successful, or nil if there was an error.
	static func images(gifData: Data) -> UIImage? {
#if os(iOS)
		var duration: TimeInterval = 0.0
		
		guard let source = CGImageSourceCreateWithData(gifData as CFData, nil) else { return nil }
		let count = CGImageSourceGetCount(source)
		let images: [UIImage] = (0..<count).compactMap {
			let properties = CGImageSourceCopyPropertiesAtIndex(source, $0, nil) as? [String: Any]
			let gifInfo = properties?[kCGImagePropertyGIFDictionary as String] as? [String: Any]
			let frameDuration = gifInfo?[kCGImagePropertyGIFDelayTime as String] as? Double
			duration += frameDuration ?? 0.1
			guard let image = CGImageSourceCreateImageAtIndex(source, $0, nil) else { return nil }
			return .init(cgImage: image)
		}
		
		return .animatedImage(with: images, duration: duration)
#else
		return .init(data: gifData)
#endif
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
			let image = url.contains(".gif") ? UIImage.images(gifData: data) : UIImage(data: data)
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
	
	/// Removes all the current cached images.
	/// - Parameter storage: An alternative storage used to cache.
	static func flushCache(storage: URL? = nil) {
		URLCache.shared.removeAllCachedResponses()
		storage?.flushImageCache()
		inMemory = [:]
	}
}
#endif
