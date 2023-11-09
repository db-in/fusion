//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit)
import UIKit

// MARK: - Extension - UIImage

public extension UIImage {
	
// MARK: - Properties
	
	static let photoPlaceholder: UIImage = .anyImageNonTrait(named: "photo")
	
	static let starFilled: UIImage = .anyImageNonTrait(named: "star.fill")
	
	/// Returns the image with `alwaysOriginal` rendering mode.
	var original: UIImage { withRenderingMode(.alwaysOriginal) }
	
	/// Returns the image with `alwaysTemplate` rendering mode.
	var template: UIImage { withRenderingMode(.alwaysTemplate) }
	
// MARK: - Constructors

// MARK: - Protected Methods
	
	private static func inAnyBundle(_ named: String) -> UIImage? {
		Bundle.allAvailable.firstMap { .init(named: named, in: $0, with: nil) } ?? .init(systemName: named)?.template
	}
	
	private static func image(named: String, bundle: Bundle) -> UIImage? {
		.init(named: named, in: bundle, with: nil) ?? .inAnyBundle(named)
	}
	
// MARK: - Exposed Methods
	
	/// Returns an image object with the specified name and style from any available bundle. If there are multiple bundles with the same
	/// valid image name, only the first is returned with application bundles as priority over frameworks.
	///
	/// - Parameters:
	///   - named: The name of the image resource.
	///   - allowCache: Indicates if cache can be used to optimize loading. The default value is `true`.
	///   - bundleHint: A given bundle to be the first try for the given resource. Default is `main`.
	/// - Returns: An image object, if available; otherwise, a system image or an empty image.
	static func anyImageNonTrait(named: String, allowCache: Bool = true, bundleHint: Bundle = .main) -> UIImage {
		guard allowCache else { return image(named: named, bundle: bundleHint) ?? .init() }
		return InMemoryCache.getOrSet(key: "\(Self.self)\(named)", newValue: image(named: named, bundle: bundleHint)) ?? .init()
	}
}
#endif

#if canImport(UIKit) && !os(watchOS)
public extension UIImage {
	
 // MARK: - Protected Methods
	 
	 private static func inAnyBundle(_ named: String, trait: UITraitCollection) -> UIImage? {
		 Bundle.allAvailable.firstMap { .init(named: named, in: $0, compatibleWith: trait) } ?? .init(systemName: named)?.template
	 }
	 
	 private static func image(named: String, bundle: Bundle, trait: UITraitCollection) -> UIImage? {
		 .init(named: named, in: bundle, compatibleWith: trait) ?? .inAnyBundle(named, trait: trait)
	 }
	 
 // MARK: - Exposed Methods
	 
	 /// Returns an image object with the specified name and style from any available bundle. If there are multiple bundles with the same
	 /// valid image name, only the first is returned with application bundles as priority over frameworks.
	 ///
	 /// - Parameters:
	 ///   - named: The name of the image resource.
	 ///   - allowCache: Indicates if cache can be used to optimize loading. The default value is `true`.
	 ///   - bundleHint: A given bundle to be the first try for the given resource. Default is `main`.
	 ///   - trait: A given `UITraitCollection`. Default is ``.preferredLocale``.
	 /// - Returns: An image object, if available; otherwise, a system image or an empty image.
	 static func anyImage(named: String,
						  allowCache: Bool = true,
						  bundleHint: Bundle = .main,
						  trait: UITraitCollection = .preferredLocaleDirection) -> UIImage {
		 guard allowCache else { return image(named: named, bundle: bundleHint, trait: trait) ?? .init() }
		 return InMemoryCache.getOrSet(key: "\(Self.self)\(named)", newValue: image(named: named, bundle: bundleHint, trait: trait)) ?? .init()
	 }
	
// MARK: - Exposed Methods
	
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
		context?.setFillColor(color.cgResolved())
		context?.fillPath()
		
		let image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return image ?? UIImage()
	}
	
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
			cgContext.setFillColor(color.cgResolved())
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
	func shaped(with color: UIColor,
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
		image.tinted(tintColor).shaped(with: backgroundColor, shapeSize: shapeSize, iconSize: iconSize, cornerRadius: shapeSize.width * 0.5)
	}
	
	/// Returns a gausian blurred version of the image on all its dimension.
	///
	/// - Parameter radius: The radius of the gaussian blur effect. The default value is 5.0
	/// - Returns: The blurred new image.
	func gaussianBlur(radius: CGFloat = 5.0) -> UIImage {
		guard let ciImage = CIImage(image: self) else { return self }
		let filter = CIFilter(name: "CIGaussianBlur")!
		filter.setValue(ciImage, forKey: kCIInputImageKey)
		filter.setValue(radius, forKey: kCIInputRadiusKey)
		guard let outputCIImage = filter.outputImage else { return self }
		let context = CIContext(options: nil)
		guard let cgImage = context.createCGImage(outputCIImage, from: outputCIImage.extent) else { return self }
		return UIImage(cgImage: cgImage, scale: self.scale, orientation: self.imageOrientation)
	}
}

// MARK: - Extension - UITraitCollection

public extension UITraitCollection {
	
	/// Returns the current preferred locale direction.
	static var preferredLocaleDirection: Self { .init(layoutDirection: Locale.preferredLocale.isRTL ? .rightToLeft : .leftToRight) }
}
#endif
