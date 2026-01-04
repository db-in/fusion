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
		guard cached else { return .init(rootView: self).background(.clear) }
		return InMemoryCache.getOrSet(key: "Host-\(Self.self)", newValue: .init(rootView: self).transparent) ?? .init(rootView: self).transparent
	}
	
	/// Presents the view over the window.
	func presentOverWindow(preferredHeight: CGFloat = UIScreen.main.bounds.height) {
		uiHost(cached: false).presentOverWindow(preferredHeight: preferredHeight)
	}
	
	/// Manages the hide state of the native navigation bar.
	///
	/// - Parameter value: Hides the bar if `true` and unhides if value is `false`. The default value is `true`.
	/// - Returns: The same view, with a modified navigation bar property
	@ViewBuilder func hideNavigationBar(_ value: Bool = true) -> some View {
		if #available(iOS 16.0, *) {
			toolbar(value ? .hidden : .visible, for: .navigationBar)
		} else {
			navigationBarHidden(value)
		}
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
	
	var suiColor: SwiftUI.Color {
		let ciColor = CIColor(color: self)
		return Color(.sRGB, red: ciColor.red, green: ciColor.green, blue: ciColor.blue, opacity: ciColor.alpha)
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
	private let content: ((Image) -> Content)?
	private let placeholder: (() -> Placeholder)?
	
	@State private var image: UIImage?
	
	public init(_ url: String?, storage: URL? = nil, content: ((Image) -> Content)? = nil, placeholder: (() -> Placeholder)? = nil) {
		self.url = url
		self.storage = storage
		self.content = content
		self.placeholder = placeholder
	}
	
	public var body: some View {
		Group {
			if let image = image {
				content?(Image(uiImage: image))
			} else {
				placeholder?()
			}
		}
		.onAppear {
			UIImage.loadOrDownload(url: url ?? "", allowsBadge: true, storage: storage) { loadedImage, fromCache in
				self.image = loadedImage
			}
		}
	}
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
