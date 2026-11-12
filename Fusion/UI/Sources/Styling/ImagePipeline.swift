//
//  Created by Diney Bomfim on 11/12/26.
//

#if canImport(UIKit)
import UIKit
import ImageIO

// MARK: - Extension - UIImage Cost

extension UIImage {
	
	var memoryCost: Int {
		if let frames = images, !frames.isEmpty {
			return frames.reduce(0) { $0 + $1.memoryCost }
		}
		
		guard let cgImage else { return Int(size.width * size.height * scale * scale * 4) }
		return cgImage.bytesPerRow * cgImage.height
	}
}

// MARK: - Type - ImagePipeline

actor ImagePipeline {
	
// MARK: - Properties
	
	static let shared: ImagePipeline = .init()
	
	static let memoryCostLimit: Int = 128 * 1024 * 1024
	
	nonisolated let memory: NSCache<NSString, UIImage> = {
		let cache = NSCache<NSString, UIImage>()
		cache.totalCostLimit = memoryCostLimit
		return cache
	}()
	
	private let badges = ThreadSafe<(generation: Int, images: [String : UIImage])>(wrappedValue: (0, [:]))
	
	private var inFlight: [String : Task<UIImage?, Never>] = [:]
	
// MARK: - Protected Methods
	
	private static func memoryKey(url: String, maxPixelSize: CGFloat?) -> String {
		guard let pixels = validPixelSize(maxPixelSize) else { return url }
		return "\(url)#\(Int(pixels.rounded(.up)))"
	}
	
	private static func validPixelSize(_ maxPixelSize: CGFloat?) -> CGFloat? {
		guard let maxPixelSize, maxPixelSize.isFinite, maxPixelSize > 0 else { return nil }
		return maxPixelSize
	}
	
	private nonisolated func store(_ image: UIImage, forKey key: String) {
		memory.setObject(image, forKey: key as NSString, cost: image.memoryCost)
	}
	
	private func finish(_ task: Task<UIImage?, Never>, key: String) {
		guard inFlight[key] == task else { return }
		inFlight[key] = nil
	}
	
	private static func download(url: String, storage: URL?) async -> Data? {
		let request = URLRequest(url: url.toURL)
		
		guard
			let (data, response) = try? await URLSession.shared.data(for: request),
			!data.isEmpty
		else { return nil }
		
		if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
			return nil
		}
		
		URLCache.appGroup.storeCachedResponse(.init(response: response, data: data), for: request)
		storage?.writeImage(data: data, withKey: url)
		return data
	}
	
	private static func downsample(_ data: Data, maxPixelSize: CGFloat) -> UIImage? {
		let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
		
		guard
			let source = CGImageSourceCreateWithData(data as CFData, sourceOptions),
			CGImageSourceGetCount(source) > 0,
			let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString : Any],
			let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
			let height = properties[kCGImagePropertyPixelHeight] as? CGFloat
		else { return nil }
		
		let originalMax = max(width, height)
		let targetMax = min(maxPixelSize, originalMax)
		let thumbnailOptions = [
			kCGImageSourceCreateThumbnailFromImageAlways: true,
			kCGImageSourceShouldCacheImmediately: true,
			kCGImageSourceCreateThumbnailWithTransform: true,
			kCGImageSourceThumbnailMaxPixelSize: targetMax
		] as CFDictionary
		
		guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions) else { return nil }
		let thumbnailMax = CGFloat(max(thumbnail.width, thumbnail.height))
		let scale = thumbnailMax > 0 ? thumbnailMax / originalMax : 1
		return UIImage(cgImage: thumbnail, scale: scale, orientation: .up)
	}
	
	private static func decodedFullSize(_ data: Data) -> UIImage? {
		guard let image = UIImage(data: data) else { return nil }
#if os(watchOS)
		return image
#else
		return image.preparingForDisplay() ?? image
#endif
	}
	
// MARK: - Internal Methods
	
	static var screenMaxPixelSize: CGFloat {
#if os(watchOS) || os(visionOS)
		return 2048
#else
		let bounds = UIScreen.main.nativeBounds
		return max(bounds.width, bounds.height)
#endif
	}
	
	static func decode(_ data: Data, url: String, maxPixelSize: CGFloat? = nil) -> UIImage? {
		let image: UIImage?
		
		if url.contains(".gif") {
			image = UIImage.images(gifData: data)
		} else if let pixels = validPixelSize(maxPixelSize), let thumbnail = downsample(data, maxPixelSize: pixels) {
			image = thumbnail
		} else {
			image = decodedFullSize(data)
		}
		
		image?.accessibilityIdentifier = url
		return image
	}
	
	static func cachedData(url: String, storage: URL?) -> Data? {
		let fileURL = url.toURL
		
		if let data = URLCache.appGroup.cachedResponse(for: URLRequest(url: fileURL))?.data {
			storage?.writeImage(data: data, withKey: url)
			return data
		}
		
		if let data = storage?.readImageData(withKey: url) {
			return data
		}
		
		return fileURL.isFileURL ? try? Data(contentsOf: fileURL) : nil
	}
	
	static func removeCachedData(url: String) {
		URLCache.appGroup.removeCachedResponse(for: URLRequest(url: url.toURL))
	}
	
	static func load(url: String, maxPixelSize: CGFloat?, storage: URL?, reload: Bool) async -> UIImage? {
		if !reload, let data = cachedData(url: url, storage: storage) {
			if let image = decode(data, url: url, maxPixelSize: maxPixelSize) { return image }
			removeCachedData(url: url)
		}
		
		guard let data = await download(url: url, storage: storage) else { return nil }
		return decode(data, url: url, maxPixelSize: maxPixelSize)
	}
	
	nonisolated func associateBadge(_ image: UIImage?, to url: String) {
		badges.mutate {
			$0.generation += 1
			$0.images[url] = image
		}
	}
	
	nonisolated func resolve(_ image: UIImage, url: String, allowsBadge: Bool) -> UIImage {
		guard allowsBadge else { return image }
		let snapshot = badges.wrappedValue
		guard let badge = snapshot.images[url] else { return image }
		let key = "\(memoryKeyPrefix(for: image, url: url))#badge-\(snapshot.generation)" as NSString
		if let badged = memory.object(forKey: key) { return badged }
		let badged = image.addBadge(badge)
		memory.setObject(badged, forKey: key, cost: badged.memoryCost)
		return badged
	}
	
	nonisolated private func memoryKeyPrefix(for image: UIImage, url: String) -> String {
		"\(url)#\(Int(image.size.width * image.scale))x\(Int(image.size.height * image.scale))"
	}
	
	nonisolated func cachedImage(url: String, maxPixelSize: CGFloat? = nil) -> UIImage? {
		guard !url.isEmpty else { return nil }
		let key = Self.memoryKey(url: url, maxPixelSize: maxPixelSize)
		return memory.object(forKey: key as NSString) ?? (key == url ? nil : memory.object(forKey: url as NSString))
	}
	
	nonisolated func cached(url: String, maxPixelSize: CGFloat? = nil, allowsBadge: Bool = true) -> UIImage? {
		cachedImage(url: url, maxPixelSize: maxPixelSize).map { resolve($0, url: url, allowsBadge: allowsBadge) }
	}
	
	nonisolated func cache(_ image: UIImage, url: String, maxPixelSize: CGFloat? = nil) {
		store(image, forKey: Self.memoryKey(url: url, maxPixelSize: maxPixelSize))
	}
	
	nonisolated func removeAll() {
		memory.removeAllObjects()
	}
	
	func image(url: String, maxPixelSize: CGFloat? = nil, allowsBadge: Bool = true, storage: URL? = nil, reload: Bool = false) async -> UIImage? {
		guard !url.isEmpty else { return nil }
		let key = Self.memoryKey(url: url, maxPixelSize: maxPixelSize)
		
		if !reload, let image = cachedImage(url: url, maxPixelSize: maxPixelSize) {
			return resolve(image, url: url, allowsBadge: allowsBadge)
		}
		
		let flightKey = reload ? "reload|\(key)" : key
		let task: Task<UIImage?, Never>
		
		if let existing = inFlight[flightKey] {
			task = existing
		} else {
			task = Task.detached(priority: .userInitiated) { [memory] in
				guard let image = await Self.load(url: url, maxPixelSize: maxPixelSize, storage: storage, reload: reload) else { return nil }
				memory.setObject(image, forKey: key as NSString, cost: image.memoryCost)
				return image
			}
			inFlight[flightKey] = task
		}
		
		let image = await task.value
		finish(task, key: flightKey)
		return image.map { resolve($0, url: url, allowsBadge: allowsBadge) }
	}
	
	var inFlightCount: Int { inFlight.count }
}
#endif
