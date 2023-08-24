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
	///
	///		                2
	///		       1        +        3
	/// 	        +---------------+
	///		    12 /                 \ 4
	///		      +                   +
	///		11 +  |                   |   + 5
	///		      +                   +
	///		    10 \                 / 6
	///		        +---------------+
	///		       9        +        7
	///	                    8
	///
	/// - Parameters:
	///   - rect: The rectangle to create the path around.
	///   - corners: The corner radii for each corner.
	///   - edges: The edge offsets for each edge.
	///   - aspectToFit: Defines if the aspect will set to fit inside the given rect. The default is `true`.
	convenience init(smooth rect: CGRect, corners: RectCorners, edges: RectEdges, aspectToFit: Bool = true) {
		self.init()
		
		let point1 = CGPoint(x: rect.minX + corners.topLeft, y: rect.minY)
		let point2 = CGPoint(x: rect.midX, y: rect.minY - edges.top)
		let point3 = CGPoint(x: rect.maxX - corners.topRight, y: rect.minY)
		let point4 = CGPoint(x: rect.maxX, y: corners.topRight)
		let point5 = CGPoint(x: rect.maxX + edges.right, y: rect.midY)
		let point6 = CGPoint(x: rect.maxX, y: rect.maxY - corners.bottomRight)
		let point7 = CGPoint(x: rect.maxX - corners.bottomRight, y: rect.maxY)
		let point8 = CGPoint(x: rect.midX, y: rect.maxY + edges.bottom)
		let point9 = CGPoint(x: rect.minX + corners.bottomLeft, y: rect.maxY)
		let point10 = CGPoint(x: rect.minX, y: rect.maxY - corners.bottomLeft)
		let point11 = CGPoint(x: rect.minX - edges.left, y: rect.midY)
		let point12 = CGPoint(x: rect.minX, y: rect.minY + corners.topLeft)
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
		
		guard aspectToFit else { return }
		fit(into: bounds)
	}
	
// MARK: - Exposed Methods
	
	@discardableResult func fit(into rect: CGRect) -> Self {
		scale(toFit: rect).center(into: rect)
	}
	
	@discardableResult func scale(toFit rect: CGRect) -> Self {
		let box = cgPath.boundingBox
		guard box.width != 0 && box.height != 0 else { return self }
		let scaleFactor = min(rect.width / box.width, rect.height / box.height)
		apply(.init(scaleX: scaleFactor, y: scaleFactor))
		return self
	}
	
	@discardableResult func center(into rect: CGRect) -> Self {
		let box = cgPath.boundingBox
		let translationX = rect.midX - box.midX
		let translationY = rect.midY - box.midY
		apply(.init(translationX: translationX, y: translationY))
		return self
	}
}
#endif

//extension CGRect {
//	var center: CGPoint { .init(x: size.width * 0.5, y: size.height * 0.5) }
//}
//
//extension CGPoint {
//	func vector(to p1:CGPoint) -> CGVector { .init(dx: p1.x - x, dy: p1.y - y) }
//}
//
//extension UIBezierPath {
//
//	func moveCenter(to: CGPoint) -> Self {
//		let bound  = cgPath.boundingBox
//		let center = bounds.center
//		let zeroedTo = CGPoint(x: to.x-bound.origin.x, y: to.y-bound.origin.y)
//		let vector = center.vector(to: zeroedTo)
//		offset(to: CGSize(width: vector.dx, height: vector.dy))
//		return self
//	}
//
//	func offset(to offset:CGSize) -> Self {
//		let t = CGAffineTransform(translationX: offset.width, y: offset.height)
//		applyCentered(transform: t)
//		return self
//	}
//
//	func fit(into: CGRect) -> Self {
//		let bounds = cgPath.boundingBox
//		let sw = into.size.width / bounds.width
//		let sh = into.size.height / bounds.height
//		let factor = min(sw, max(sh, 0.0))
//		return scale(x: factor, y: factor)
//	}
//
//	func scale(x: CGFloat, y:CGFloat) -> Self {
//		let scale = CGAffineTransform(scaleX: x, y: y)
//		applyCentered(transform: scale)
//		return self
//	}
//
//	func applyCentered(transform: @autoclosure () -> CGAffineTransform) -> Self {
//		let bound  = cgPath.boundingBox
//		let center = CGPoint(x: bound.midX, y: bound.midY)
//		var xform  = CGAffineTransform.identity
//
//		xform = xform.concatenating(.init(translationX: -center.x, y: -center.y))
//		xform = xform.concatenating(transform())
//		xform = xform.concatenating(.init(translationX: center.x, y: center.y))
//		apply(xform)
//
//		return self
//	}
//}
