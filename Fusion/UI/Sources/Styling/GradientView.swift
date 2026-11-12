//
//  Created by Diney Bomfim on 7/26/23.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Type -

/// Convenience view that encpsulates the ``UIView.make(gradient:start:end:type:)`` and makes it automatically redrawable and adaptable.
open class GradientView : UIView {

// MARK: - Properties
	
	open var colors: [UIColor] = [] { didSet { buildUI() } }
	open var start: CGPoint = .init(x: 0, y: 0) { didSet { buildUI() } }
	open var end: CGPoint = .init(x: 0, y: 1) { didSet { buildUI() } }
	open var type: CAGradientLayerType = .axial { didSet { buildUI() } }
	
	private var builtRect: CGRect?
	private var builtStyle: UIUserInterfaceStyle?
	
	private var gradientRect: CGRect { layer.maskPath?.boundingBox ?? bounds }

// MARK: - Constructors

	public convenience init(colors: [UIColor] = []) {
		self.init(frame: .zero)
		self.colors = colors
	}
	
// MARK: - Protected Methods

	private func buildUI() {
		builtRect = gradientRect
		builtStyle = traitCollection.userInterfaceStyle
		make(gradient: colors, start: start, end: end, type: type)
	}
	
// MARK: - Exposed Methods

// MARK: - Overridden Methods
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		guard builtRect != gradientRect || builtStyle != traitCollection.userInterfaceStyle else { return }
		buildUI()
	}
}
#endif
