//
//  Created by Diney Bomfim on 11/12/26.
//

#if canImport(UIKit) && canImport(SwiftUI) && !os(watchOS)
import UIKit
import SwiftUI

// MARK: - Type - AnimatedImageView

struct AnimatedImageView: UIViewRepresentable {
	
	let image: UIImage
	
	func makeUIView(context: Context) -> UIImageView {
		let imageView = UIImageView(image: image)
		imageView.contentMode = .scaleAspectFit
		imageView.clipsToBounds = true
		imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
		return imageView
	}
	
	func updateUIView(_ imageView: UIImageView, context: Context) {
		if imageView.image !== image {
			imageView.image = image
		}
		imageView.superview?.setConstraintsFitting(child: imageView)
	}
}

#Preview("Animated Image") {
	let frames: [UIImage] = [UIColor.systemRed, .systemGreen, .systemBlue].map { color in
		UIGraphicsImageRenderer(size: .init(width: 80, height: 80)).image { context in
			color.setFill()
			context.fill(.init(x: 0, y: 0, width: 80, height: 80))
		}
	}
	
	return AnimatedImageView(image: UIImage.animatedImage(with: frames, duration: 1.2) ?? frames[0])
		.frame(width: 80, height: 80)
}
#endif
