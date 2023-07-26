//
//  Created by Diney Bomfim on 7/26/23.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Type -

/// Convenience view that encpsulates the ``UIView.makeGradient(colors:start:end:type:)`` and makes it automatically redrawable and adaptable.
open class GradientView : UIView {

// MARK: - Properties
	
	open var colors: [UIColor] = [] { didSet { buildUI() } }
	open var start: CGPoint = .init(x: 0, y: 0) { didSet { buildUI() } }
	open var end: CGPoint = .init(x: 0, y: 1) { didSet { buildUI() } }
	open var type: CAGradientLayerType = .axial { didSet { buildUI() } }

// MARK: - Constructors

	public convenience init(colors: [UIColor] = []) {
		self.init(frame: .zero)
		self.colors = colors
	}
	
// MARK: - Protected Methods

	private func buildUI() {
		makeGradient(colors: colors)
	}
	
// MARK: - Exposed Methods

// MARK: - Overridden Methods
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		buildUI()
	}
}
#endif
