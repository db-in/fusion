//
//  Created by Diney Bomfim on 7/2/23.
//

#if canImport(UIKit)
import UIKit

// MARK: - Extension - URL UIImage Manager

extension URL {
	
	func imageFileURL(withKey: String) -> URL {
		appendingPathComponent("image-\(withKey.sha256)")
	}
	
	func legacyImageFileURL(withKey: String) -> URL {
		appendingPathComponent("image-\(withKey.hash.description)")
	}
	
	func readImageData(withKey: String) -> Data? {
		let url = imageFileURL(withKey: withKey)
		if let data = try? Data(contentsOf: url) { return data }
		let legacy = legacyImageFileURL(withKey: withKey)
		guard let data = try? Data(contentsOf: legacy) else { return nil }
		if (try? data.write(to: url)) != nil {
			try? FileManager.default.removeItem(at: legacy)
		}
		return data
	}
	
	func writeImage(data: Data, withKey: String) {
		try? data.write(to: imageFileURL(withKey: withKey))
	}
	
	func flushImageCache() {
		guard let files = try? FileManager.default.contentsOfDirectory(at: self, includingPropertiesForKeys: nil) else { return }

		files.forEach {
			guard $0.lastPathComponent.hasPrefix("image-") else { return }
			try? FileManager.default.removeItem(at: $0)
		}
	}
}

public typealias ImageDownloadCallback = (UIImage?) -> Void

public typealias ImageLoadOrDownloadCallback = (UIImage?, Bool) -> Void

// MARK: - Extension - UIImage Loader

public extension UIImage {

// MARK: - Properties
	
	static var memoryCacheLimit: Int {
		get { ImagePipeline.shared.memory.totalCostLimit }
		set { ImagePipeline.shared.memory.totalCostLimit = newValue }
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
		let canvasSize = CGSize(width: size.width + scaledSize.width * 0.25, height: size.height + scaledSize.height * 0.25)
		let drawing = {
			self.draw(in: CGRect(origin: .init(x: scaledSize.width * 0.25, y: scaledSize.height * 0.25), size: self.size))
			image.draw(in: scaledRect, blendMode: .normal, alpha: 1)
		}
		
#if os(watchOS)
		UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
		defer { UIGraphicsEndImageContext() }
		drawing()
		return UIGraphicsGetImageFromCurrentImageContext() ?? self
#else
		let format = UIGraphicsImageRendererFormat.preferred()
		format.scale = scale
		let newImage = UIGraphicsImageRenderer(size: canvasSize, format: format).image { _ in drawing() }
		newImage.accessibilityIdentifier = accessibilityIdentifier
		return newImage
#endif
	}
	
	/// This function can associate and dissociate a badge images to be placed on top of the original images when indicated in the loading functions.
	///
	/// - Parameters:
	///   - image: The badge image.
	///   - to: The url which will be used to load the original image later on.
	static func associateBadge(_ image: UIImage?, to: String) {
		ImagePipeline.shared.associateBadge(image, to: to)
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
		guard !url.isEmpty else { return nil }
		let pipeline = ImagePipeline.shared
		if let image = pipeline.cached(url: url, allowsBadge: allowsBadge) { return image }
		guard let data = ImagePipeline.cachedData(url: url, storage: storage) else { return nil }
		
		guard let image = ImagePipeline.decode(data, url: url) else {
			ImagePipeline.removeCachedData(url: url)
			return nil
		}
		
		pipeline.cache(image, url: url)
		return pipeline.resolve(image, url: url, allowsBadge: allowsBadge)
	}
	
	/// Forces the download of a given url and caches it locally. This methods triggers the ``loadCache(url:allowsBadge:storage:)`` once
	/// the download is completed.
	///
	/// - Parameters:
	///   - url: The url.
	///   - allowsBadge: Indicates if associated badges are allowed.
	///   - storage: A fallback storage to be used. This storage will receive a copy of the cache when cache is available.
	///   - completion: The completion in which the final image will be sent to.
	static func download(url: String, allowsBadge: Bool = true, storage: URL? = nil, then completion: ImageDownloadCallback? = nil) {
		guard !url.isEmpty else {
			asyncMain { completion?(nil) }
			return
		}
		
		Task.detached(priority: .userInitiated) {
			let image = await ImagePipeline.shared.image(url: url, allowsBadge: allowsBadge, storage: storage, reload: true)
			asyncMain { completion?(image) }
		}
	}
	
	/// Attempts to load an image from cache. If unavailable, it downloads and caches it.
	/// This method returns whether the image came from cache or network.
	///
	/// - Parameters:
	///   - url: The URL string of the image.
	///   - allowsBadge: Indicates if associated badges are allowed.
	///   - storage: A fallback storage to be used. This storage will receive a copy of the cache when cache is available.
	///   - completion: The closure with the final `UIImage` and a Boolean indicating if it was loaded from cache.
	static func loadOrDownload(url: String, allowsBadge: Bool = true, storage: URL? = nil, then completion: ImageLoadOrDownloadCallback? = nil) {
		if let image = loadCache(url: url, allowsBadge: allowsBadge, storage: storage) {
			completion?(image, true)
			return
		}
		download(url: url, allowsBadge: allowsBadge, storage: storage) { completion?($0, false) }
	}
	
	/// Removes all the current cached images.
	/// - Parameter storage: An alternative storage used to cache.
	static func flushCache(storage: URL? = nil) {
		URLCache.appGroup.removeAllCachedResponses()
		storage?.flushImageCache()
		ImagePipeline.shared.removeAll()
	}
}

// MARK: - Extension - String Image Loader

public extension String {
	
	/// Convenient helper to download an image if needed, using the existing UIImage loading infrastructure.
	/// This method attempts to load from cache first, then downloads if not available.
	///
	/// - Parameters:
	///   - allowsBadge: Indicates if associated badges are allowed (default: true).
	///   - storage: A fallback storage to be used (default: nil).
	///   - completion: The closure with the final `UIImage` and a Boolean indicating if it was loaded from cache.
	func downloadImageIfNeeded(allowsBadge: Bool = true, storage: URL? = nil, then completion: ImageLoadOrDownloadCallback? = nil) {
		UIImage.loadOrDownload(url: self, allowsBadge: allowsBadge, storage: storage, then: completion)
	}
	
	/// Convenient helper to load an image from cache only.
	///
	/// - Parameters:
	///   - allowsBadge: Indicates if associated badges are allowed (default: true).
	///   - storage: A fallback storage to be used (default: nil).
	/// - Returns: The cached `UIImage` if available, nil otherwise.
	func loadCachedImage(allowsBadge: Bool = true, storage: URL? = nil) -> UIImage? {
		UIImage.loadCache(url: self, allowsBadge: allowsBadge, storage: storage)
	}
	
	/// Convenient helper to force download an image.
	///
	/// - Parameters:
	///   - allowsBadge: Indicates if associated badges are allowed (default: true).
	///   - storage: A fallback storage to be used (default: nil).
	///   - completion: The closure with the final `UIImage`.
	func downloadImage(allowsBadge: Bool = true, storage: URL? = nil, then completion: ImageDownloadCallback? = nil) {
		UIImage.download(url: self, allowsBadge: allowsBadge, storage: storage, then: completion)
	}
}
#endif
