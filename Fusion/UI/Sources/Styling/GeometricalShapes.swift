//
//  Created by Diney Bomfim on 8/24/23.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Extension - UIBezierPath

public extension UIBezierPath {
	
// MARK: - Constructors
	
	/// Creates a smooth bezier path around a rectangle with specified corner radii and edge offsets.
	///
	/// - Parameters:
	///   - rect: The rectangle to create the path around.
	///   - corners: The corner radii for each corner.
	///   - edges: The edge offsets for each edge.
	///   - overBounds: Whether to extend the path beyond the rectangle bounds.
	convenience init(smooth rect: CGRect, corners: RectCorners, edges: RectEdges, overBounds: Bool = true) {
		self.init()
		
		let increment = overBounds ? edges * 0.5 : .zero
		let point1 = CGPoint(x: rect.minX + corners.topLeft + edges.left, y: rect.minY + edges.top)
		let point2 = CGPoint(x: rect.midX, y: rect.minY - increment.top)
		let point3 = CGPoint(x: rect.maxX - corners.topRight - edges.right, y: rect.minY + edges.top)
		let point4 = CGPoint(x: rect.maxX - edges.right, y: corners.topRight + edges.top)
		let point5 = CGPoint(x: rect.maxX + increment.right, y: rect.midY)
		let point6 = CGPoint(x: rect.maxX - edges.right, y: rect.maxY - corners.bottomRight - edges.bottom)
		let point7 = CGPoint(x: rect.maxX - corners.bottomRight - edges.right, y: rect.maxY - edges.bottom)
		let point8 = CGPoint(x: rect.midX, y: rect.maxY + increment.bottom)
		let point9 = CGPoint(x: rect.minX + corners.bottomLeft + edges.left, y: rect.maxY - edges.bottom)
		let point10 = CGPoint(x: rect.minX + edges.left, y: rect.maxY - corners.bottomLeft - edges.bottom)
		let point11 = CGPoint(x: rect.minX - increment.left, y: rect.midY)
		let point12 = CGPoint(x: rect.minX + edges.left, y: rect.minY + corners.topLeft + edges.top)
		let lineA1 = Line(start: point1, end: point2)
		let lineA2 = Line(start: point2, end: point3)
		let lineB1 = Line(start: point4, end: point5)
		let lineB2 = Line(start: point5, end: point6)
		let lineC1 = Line(start: point7, end: point8)
		let lineC2 = Line(start: point8, end: point9)
		let lineD1 = Line(start: point10, end: point11)
		let lineD2 = Line(start: point11, end: point12)

		move(to: point1)
		addQuadCurve(to: point3, controlPoint: point2)
		addQuadCurve(to: point4, controlPoint: lineA2.intersection(of: lineB1) ?? Line(start: point3, end: point4).center)
		addQuadCurve(to: point6, controlPoint: point5)
		addQuadCurve(to: point7, controlPoint: lineB2.intersection(of: lineC1) ?? Line(start: point6, end: point7).center)
		addQuadCurve(to: point9, controlPoint: point8)
		addQuadCurve(to: point10, controlPoint: lineC2.intersection(of: lineD1) ?? Line(start: point9, end: point10).center)
		addQuadCurve(to: point12, controlPoint: point11)
		addQuadCurve(to: point1, controlPoint: lineD2.intersection(of: lineA1) ?? Line(start: point12, end: point1).center)
		
		close()
	}
}
#endif
