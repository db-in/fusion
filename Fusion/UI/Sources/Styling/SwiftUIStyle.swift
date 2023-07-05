//
//  Created by Diney Bomfim on 6/30/23.
//

#if canImport(UIKit) && canImport(SwiftUI) && !os(watchOS)
import UIKit
import SwiftUI

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
}

// MARK: - Extension - View

public extension View {
	
	var uiView: UIView {
		guard let view = UIHostingController(rootView: self).view else { return .init() }
		view.backgroundColor = .clear
		return view
	}
}

// MARK: - Type - UIViewPreview

struct UIViewPreview<T : UIView>: UIViewRepresentable {
	
// MARK: - Properties
	
	let view: T
	
// MARK: - Constructors
	
	init(_ builder: @escaping () -> T) {
		view = builder()
	}
	
// MARK: - Protected Methods

// MARK: - Exposed Methods
	
	func makeUIView(context: Context) -> UIView {
		return view
	}
	
	func updateUIView(_ view: UIView, context: Context) {
		view.superview?.setConstraintsFitting(child: view)
	}
}

// MARK: - Type - UIViewControllerPreview

struct UIViewControllerPreview<T : UIViewController>: UIViewControllerRepresentable {
	
	let viewController: T

	init(_ builder: @escaping () -> T) {
		viewController = builder()
	}

	// MARK: - UIViewControllerRepresentable
	func makeUIViewController(context: Context) -> T {
		viewController
	}

	func updateUIViewController(_ uiViewController: T, context: UIViewControllerRepresentableContext<UIViewControllerPreview<T>>) {
		return
	}
}

// MARK: - Extension - Image

public extension Image {
	
	init<T : UIView>(size: CGSize, snapshot: @escaping () -> T) {
		let view = snapshot()
		view.frame = .init(origin: .zero, size: size)
		self.init(uiImage: view.snapshot)
	}
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
#endif
