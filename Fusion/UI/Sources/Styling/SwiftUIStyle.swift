//
//  Created by Diney Bomfim on 6/30/23.
//

#if canImport(UIKit) && canImport(SwiftUI) && !os(watchOS)
import UIKit
import SwiftUI

// MARK: - Extension - UIView

public extension EdgeInsets {
	
	var vertical: CGFloat { top + bottom }
	var horizontal: CGFloat { leading + trailing }
	var flipped: EdgeInsets { EdgeInsets(top: bottom, leading: trailing, bottom: top, trailing: leading) }
	var finite: EdgeInsets { .init(top: top.finite, leading: leading.finite, bottom: bottom.finite, trailing: trailing.finite) }
	init(all: CGFloat) { self.init(top: all, leading: all, bottom: all, trailing: all) }
	init(horizontal: CGFloat = 0, vertical: CGFloat = 0) { self.init(top:vertical, leading: horizontal, bottom: vertical, trailing: horizontal) }
	static var zero: Self { .init(all: 0) }
	static func + (lhs: Self, rhs: Self) -> Self {
		.init(top: lhs.top + rhs.top, leading: lhs.leading + rhs.leading, bottom: lhs.bottom + rhs.bottom, trailing: lhs.trailing + rhs.trailing)
	}
}

// MARK: - Extension - UIView

public extension UIView {
	
	func uiSnapshot() -> Image {
		Image(size: frame.size) { self }
	}
	
	func uiSnapshot(theme: UIUserInterfaceStyle) -> Image {
		Image(size: frame.size) {
			self.interfaceStyle = theme
			return self
		}
	}
	
	func modifier<T: ViewModifier>(_ modifier: T) -> UIView {
		ZStack {
			UIKitView { self }
		}
		.frame(idealWidth: frame.width, maxWidth: .infinity, idealHeight: frame.height, maxHeight: .infinity, alignment: .center)
		.modifier(modifier)
		.uiHost(cached: false).view
	}
}

// MARK: - Extension - UIViewController

public extension UIViewController {

	/// Returns a view controller with a clear background.
	var transparent: Self { background(.clear) }
	
	/// Measures the root view with ``UIView/sizeThatFits(_:)`` using the key window width and unconstrained height,
	/// then assigns the result to ``preferredContentSize`` when the height is positive and not ``UIView/noIntrinsicMetric``.
	///
	/// - Returns: The same view controller for chaining.
	var autoSized: Self {
//		let screenWidth = UIWindow.keyFrame.width
//		let fittingSize = view.sizeThatFits(CGSize(width: screenWidth, height: .greatestFiniteMagnitude))
//		
//		if fittingSize.height > 0 && fittingSize.height != UIView.noIntrinsicMetric {
//			preferredContentSize = fittingSize
//		}
		
		return self
	}
	
	/// Sets the background color of the view controller.
	///
	/// - Parameter color: The color to set.
	/// - Returns: The view controller with the background color set.
	func background(_ color: UIColor) -> Self {
		view.backgroundColor = color
		return self
	}
}

// MARK: - Extension - View

public extension View {
	
	/// Returns a consistent persistent cached `UIView` from a SwiftUI view.
	/// To use non-cached version, use ``uiHost(cached:).view`` instead.
	/// This routine discards the original UIHostingController, making the view fully independent.
	var uiView: UIView {
		InMemoryCache.getOrSet(key: "View-\(Self.self)", newValue: UIHostingController(rootView: self).transparent.view) ?? .init()
	}
	
	/// Returns a UIHostingController encapsulating the current SwiftUI view and caching it if caching is enabled.
	/// - Parameter cached: Defines if cache will be generated for this host.
	/// - Returns: An UIHostingController for this view.
	func uiHost(cached: Bool = true) -> UIHostingController<Self> {
		guard cached else { return .init(rootView: self).autoSized.background(.clear) }
		return InMemoryCache.getOrSet(key: "Host-\(Self.self)", newValue: .init(rootView: self).autoSized.transparent) ?? .init(rootView: self).autoSized.transparent
	}
	
	/// Presents the view over the window.
	/// - Parameter style: The modal presentation style to use.
	/// - Parameter from: The side of the screen to present the view from.
	/// - Parameter preferredHeight: The preferred height of the view.
	func presentOverWindow(style: UIModalPresentationStyle = .none, from side: UIRectEdge = .bottom, preferredHeight: CGFloat? = nil) {
		var height = CGFloat(600)
#if !os(visionOS)
		height = UIScreen.main.bounds.height
#endif
		uiHost(cached: false).presentOverWindow(style: style, from: side, preferredHeight: preferredHeight ?? height)
	}
	
	/// Manages the hide state of the native navigation bar.
	///
	/// - Parameter value: Hides the bar if `true` and unhides if value is `false`. The default value is `true`.
	/// - Returns: The same view, with a modified navigation bar property
	func hideNavigationBar(_ value: Bool = true) -> some View {
		toolbar(value ? .hidden : .visible, for: .navigationBar)
	}
}

// MARK: - Type - UIKitView

public struct UIKitView<T : UIView>: UIViewRepresentable {
	
// MARK: - Properties
	
	public let view: T
	
// MARK: - Constructors
	
	public init(_ builder: @escaping () -> T) { view = builder() }
	
// MARK: - Exposed Methods
	
	public func makeUIView(context: Context) -> UIView { view }
	
	public func updateUIView(_ view: UIView, context: Context) { view.superview?.setConstraintsFitting(child: view) }
}

// MARK: - Type - UIKitViewController

public struct UIKitViewController<T : UIViewController>: UIViewControllerRepresentable {
	
	public let viewController: T

	public init(_ builder: @escaping () -> T) { viewController = builder() }

// MARK: - UIViewControllerRepresentable
	
	public func makeUIViewController(context: Context) -> T { viewController }

	public func updateUIViewController(_ uiViewController: T, context: UIViewControllerRepresentableContext<UIKitViewController<T>>) { return }
}

// MARK: - Extension - Image

public extension Image {
	
	init<T : UIView>(size: CGSize, snapshot: @escaping () -> T) {
		let view = snapshot()
		view.frame = .init(origin: .zero, size: size)
		self.init(uiImage: view.snapshot)
	}
}

// MARK: - Extension - UIImage

public extension UIImage {
	
	var suiImage: SwiftUI.Image { .init(uiImage: self) }
}

// MARK: - Extension - UIColor

public extension UIColor {
	
	private struct SUIColorKey : Hashable {
		let color: UIColor
		let style: Int
		let contrast: Int
	}
	
	private static let suiColorLimit: Int = 512
	
	private static let suiColorCache = ThreadSafe<[SUIColorKey : SwiftUI.Color]>(wrappedValue: [:])
	
	var suiColor: SwiftUI.Color {
		let traits = UITraitCollection.current
		let key = SUIColorKey(color: self, style: traits.userInterfaceStyle.rawValue, contrast: traits.accessibilityContrast.rawValue)
		if let cached = Self.suiColorCache.mutate({ $0[key] }) { return cached }
		let ciColor = CIColor(color: self)
		let color = Color(.sRGB, red: ciColor.red, green: ciColor.green, blue: ciColor.blue, opacity: ciColor.alpha)
		Self.suiColorCache.mutate {
			if $0.count >= Self.suiColorLimit { $0.removeAll(keepingCapacity: true) }
			$0[key] = color
		}
		return color
	}
}

// MARK: - Extension - UIFont

public extension UIFont {
	
	var suiFont: SwiftUI.Font { .init(self as CTFont) }
}

// MARK: - Extension - Font

public extension Font {
	
	static var title1: Font = UIFont.title1.suiFont
	static var title2: Font = UIFont.title2.suiFont
	static var title3: Font = UIFont.title3.suiFont
	static var headline: Font = UIFont.headline.suiFont
	static var subheadline: Font = UIFont.subheadline.suiFont
	static var body: Font = UIFont.body.suiFont
	static var callout: Font = UIFont.callout.suiFont
	static var footnote: Font = UIFont.footnote.suiFont
	static var caption1: Font = UIFont.caption1.suiFont
	static var caption2: Font = UIFont.caption2.suiFont
}

// MARK: - Extension - UserFlow

public extension UserFlow {
	
	@ViewBuilder var uiView: some View { UIKitViewController { mapped } }
}

// MARK: - Type - AsyncImageCached

public struct AsyncImageCached<Content: View, Placeholder: View>: View {
	
	private let url: String?
	private let storage: URL?
	private let maxPixelSize: CGFloat
	private let content: ((Image) -> Content)?
	private let placeholder: (() -> Placeholder)?
	
	@State private var image: UIImage?
	
	private var loadKey: String { "\(url ?? "")#\(Int(maxPixelSize))" }
	
	public init(_ url: String?,
				storage: URL? = nil,
				maxPixelSize: CGFloat? = nil,
				content: ((Image) -> Content)? = nil,
				placeholder: (() -> Placeholder)? = nil) {
		let pixels = maxPixelSize ?? ImagePipeline.screenMaxPixelSize
		self.url = url
		self.storage = storage
		self.maxPixelSize = pixels
		self.content = content
		self.placeholder = placeholder
		_image = State(initialValue: ImagePipeline.shared.cached(url: url ?? "", maxPixelSize: pixels))
	}
	
	private func load() async {
		let validURL = url ?? ""
		let pipeline = ImagePipeline.shared
		
		if let cached = pipeline.cached(url: validURL, maxPixelSize: maxPixelSize) {
			if image !== cached { image = cached }
			return
		}
		
		if image?.accessibilityIdentifier != validURL {
			image = nil
		}
		
		let loaded = await pipeline.image(url: validURL, maxPixelSize: maxPixelSize, storage: storage)
		guard !Task.isCancelled else { return }
		image = loaded
	}
	
	public var body: some View {
		Group {
			if let image {
				if image.images != nil {
					AnimatedImageView(image: image)
						.accessibilityIdentifier(image.accessibilityIdentifier ?? "")
				} else {
					content?(Image(uiImage: image))
						.accessibilityIdentifier(image.accessibilityIdentifier ?? "")
				}
			} else {
				placeholder?()
			}
		}
		.task(id: loadKey) {
			await load()
		}
	}
}

#Preview("AsyncImageCached") {
	AsyncImageCached("https://picsum.photos/400/200") { image in
		image
			.resizable()
			.aspectRatio(contentMode: .fill)
	} placeholder: {
		Color.gray.opacity(0.3)
	}
	.frame(width: 300, height: 150)
	.clipped()
}

// MARK: - Type - TextConvertible

public extension TextConvertible {
	
	/// Converts the current TextConvertible to a SwiftUI AttributedString.
	/// This property handles the conversion from NSAttributedString when available,
	/// or creates a new AttributedString from the raw content.
	///
	/// - Returns: An AttributedString suitable for SwiftUI Text views.
	var attributedString: AttributedString { (self as? NSAttributedString).map { .init($0) } ?? .init(content) }
	
	/// Creates a SwiftUI Text view from the current TextConvertible without accessibility identifier.
	/// Use this property when you need a plain Text view without automatic accessibility assignment,
	/// typically for cases where accessibility will be handled manually or is not required.
	///
	/// - Returns: A Text view with the styled content.
	var textWithoutAccessibility: Text { .init(attributedString) }
	
	/// Creates a SwiftUI Text view from the current TextConvertible with automatic accessibility identifier.
	/// The accessibility identifier is automatically set using the original localization key when available.
	/// This follows the same pattern as the UIKit render method for consistent accessibility support.
	///
	/// - Returns: A modified Text view with accessibility identifier applied.
	var text: some View { textWithoutAccessibility.accessibilityIdentifier(content.originalKey ?? "") }
}
#endif
