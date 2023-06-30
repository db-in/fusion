//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit)
import UIKit

// MARK: - Definitions -

// MARK: - Extension - UIImage Catalogue

public extension UIImage {
	
// MARK: - Properties
	
	static let photoPlaceholder: UIImage = .anyImage(named: "photo")
	
	static let starFilled: UIImage = .anyImage(named: "star.fill")
	
	/// Returns the image with `alwaysTemplate` mode.
	var template: UIImage { withRenderingMode(.alwaysTemplate) }
	
// MARK: - Constructors
	
	/// Returns an image object with the specified name and style from any available bundle. If there are multiple bundles with the same
	/// valid image name, only the first is returned with application bundles as priority over frameworks.
	///
	/// - Parameters:
	///   - named: The name of the image resource.
	///   - style: The style of the user interface (optional).
	/// - Returns: An image object, if available; otherwise, a system image or an empty image.
	static func anyImage(named: String, style: UIUserInterfaceStyle? = nil) -> UIImage {
		var trait: UITraitCollection?
		
		if let validStyle = style {
			trait = .init(userInterfaceStyle: validStyle)
		}
		
		let bundleImage = Bundle.allAvailable.firstMap { UIImage(named: named, in: $0, compatibleWith: trait) }
		return bundleImage ?? .init(systemName: named, compatibleWith: trait)?.template ?? .init()
	}

// MARK: - Protected Methods
	
// MARK: - Exposed Methods
	
	/// Tints the image with the specified color.
	///
	/// - Parameter color: The color to tint the image with.
	/// - Returns: A new image with the applied tint color.
	func tinted(_ color: UIColor) -> UIImage {
		guard let graphicImage = cgImage else { return self }
		let rect = CGRect(origin: .zero, size: size)
		let renderer = UIGraphicsImageRenderer(size: rect.size)
		let newImage = renderer.image { context in
			let cgContext = context.cgContext
			cgContext.scaleBy(x: 1.0, y: -1.0)
			cgContext.translateBy(x: 0.0, y: -rect.size.height)
			cgContext.clip(to: rect, mask: graphicImage)
			cgContext.setFillColor(color.cgColor)
			cgContext.fill(rect)
		}
		
		newImage.accessibilityIdentifier = accessibilityIdentifier

		return newImage
	}
	
	/// Resizes the image by adding the specified dimensions to its original size.
	///
	/// - Parameter newSize: The size to add to the original image size.
	/// - Returns: A resized image.
	func resized(by newSize: CGSize) -> UIImage {
		resized(to: .init(width: size.width + newSize.width, height: size.height + newSize.height))
	}
	
	/// Resizes the image to the specified size.
	///
	/// - Parameter newSize: The new size for the image.
	/// - Returns: A resized image.
	func resized(to newSize: CGSize) -> UIImage {
		let renderer = UIGraphicsImageRenderer(size: newSize)
		let image = renderer.image { _ in self.draw(in: CGRect(origin: .zero, size: newSize)) }
		let newImage = image.withRenderingMode(renderingMode)
		
		newImage.accessibilityIdentifier = accessibilityIdentifier
		
		return newImage
	}
	
	/// Creates a new image by combining the original image with a shape background of the specified color.
	///
	/// - Parameters:
	///   - color: The color of the shape background.
	///   - shapeSize: The size of the shape background.
	///   - iconSize: The size of the icon image.
	///   - cornerRadius: The corner radius of the shape background (default: 0).
	///   - borderWidth: The width of the shape background's border (optional).
	///   - borderColor: The color of the shape background's border (optional).
	/// - Returns: A new image with the combined shape and original image.
	func shapped(with color: UIColor,
				 shapeSize: CGSize,
				 iconSize: CGSize,
				 cornerRadius: CGFloat = 0,
				 borderWidth: CGFloat? = nil,
				 borderColor: UIColor? = nil) -> UIImage {
		let view = UIImageView(frame: CGRect(origin: .zero, size: shapeSize))
		
		view.contentMode = .center
		view.cornerRadius = cornerRadius
		view.backgroundColor = color
		view.image = resized(to: iconSize)
		
		if let viewBorderWidth = borderWidth, let viewBorderColor = borderColor {
			view.borderWidth = viewBorderWidth
			view.borderColor = viewBorderColor
		}
		
		let newImage = view.snapshot.withRenderingMode(renderingMode)
		newImage.accessibilityIdentifier = accessibilityIdentifier
		
		return newImage
	}
	
	/// Creates a circular image by tinting the specified image with the given tint color
	/// and shaping it within a circular background.
	///
	/// - Parameters:
	///   - image: The image to be tinted and shaped (default: .starFilled).
	///   - tintColor: The tint color to apply to the image (default: .white).
	///   - backgroundColor: The color of the circular background (default: .red).
	///   - iconSize: The size of the icon image (default: CGSize(width: 12, height: 12)).
	///   - shapeSize: The size of the circular shape background (default: CGSize(width: 20, height: 20)).
	/// - Returns: A new circular image.
	static func circular(_ image: UIImage = .starFilled,
						 tintColor: UIColor = .white,
						 backgroundColor: UIColor = .red,
						 iconSize: CGSize = .init(width: 12, height: 12),
						 shapeSize: CGSize = .init(width: 20, height: 20)) -> UIImage {
		image.tinted(tintColor).shapped(with: backgroundColor, shapeSize: shapeSize, iconSize: iconSize, cornerRadius: shapeSize.width * 0.5)
	}
	
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
		
		newImage.accessibilityIdentifier = accessibilityIdentifier
		
		return newImage
	}
	
	/// Creates a solid color image with the specified color, size, and corner radius.
	///
	/// - Parameters:
	///   - color: The color of the solid image.
	///   - size: The size of the solid image (default: CGSize(width: 1, height: 1)).
	///   - corner: The corner radius of the solid image (default: 0).
	/// - Returns: A solid color image.
	static func solid(color: UIColor, size: CGSize = .init(width: 1, height: 1), corner: CGFloat = 0) -> UIImage {
		
		let rect = CGRect(origin: .zero, size: size)
		UIGraphicsBeginImageContext(rect.size)
		let context = UIGraphicsGetCurrentContext()
		let path = UIBezierPath(roundedRect: .init(origin: .zero, size: size), cornerRadius: corner).cgPath
		
		context?.addPath(path)
		context?.closePath()
		context?.setFillColor(color.cgColor)
		context?.fillPath()
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image ?? UIImage()
	}
	
	/// Creates a gradient image with the specified colors, size, start point, and end point.
	///
	/// - Parameters:
	///   - colors: The colors to use in the gradient.
	///   - size: The size of the gradient image (default: CGSize(width: 1, height: 1)).
	///   - start: The start point of the gradient (default: CGPoint(x: 0, y: 0.5)).
	///   - end: The end point of the gradient (default: CGPoint(x: 1.0, y: 0.5)).
	/// - Returns: A gradient image.
	static func gradient(colors: [UIColor],
						 size: CGSize = .init(width: 1, height: 1),
						 start: CGPoint = .init(x: 0, y: 0.5),
						 end: CGPoint = .init(x: 1.0, y: 0.5)) -> UIImage {
		
		let gradientLayer = CAGradientLayer()
		gradientLayer.frame = CGRect(origin: .zero, size: size)
		gradientLayer.colors = colors.map(\.cgColor)
		gradientLayer.startPoint = start
		gradientLayer.endPoint = end
		
		let rect = CGRect(origin: .zero, size: size)
		UIGraphicsBeginImageContext(rect.size)
		if let context = UIGraphicsGetCurrentContext() {
			gradientLayer.render(in: context)
		}
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image ?? UIImage()
	}
}

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
	static func load<T: AnyObject>(_ source: Any?,
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
		download(url: url, storage: storage) { [weak object] image in
			let finalImage = image ?? placeholder

			if let badge = associated[url], allowsBadge {
				object?[keyPath: at] = finalImage?.addBadge(badge)
			} else {
				object?[keyPath: at] = finalImage
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
