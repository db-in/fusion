//
//  Created by Diney Bomfim on 8/24/23.
//

import Foundation

// MARK: - Type - RectEdges

/// Represents the edges of a rectangle with individual values for each side.
public struct RectEdges {
	
// MARK: - Properties
	
	/// The value for the top edge.
	public var top: CGFloat
	
	/// The value for the left edge.
	public var left: CGFloat
	
	/// The value for the bottom edge.
	public var bottom: CGFloat
	
	/// The value for the right edge.
	public var right: CGFloat
	
	/// Safer RTL compatible edges.
	public var rtlSafe: Self { Locale.preferredLocale.isRTL ? .init(top: top, left: right, bottom: bottom, right: left) : self }
	
	/// Creates a `RectEdges` with all edges set to zero.
	public static var zero: Self { .init(all: 0) }
	
// MARK: - Constructors
	
	/// Initializes a `RectEdges` instance with individual edge values.
	/// - Parameters:
	///   - top: The value for the top edge.
	///   - left: The value for the left edge.
	///   - bottom: The value for the bottom edge.
	///   - right: The value for the right edge.
	public init(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) {
		self.top = top
		self.left = left
		self.bottom = bottom
		self.right = right
	}
	
	/// Initializes a `RectEdges` instance with the same value for horizontal edges (left/right) and vertical edges (top/bottom).
	/// - Parameters:
	///   - horizontal: The horizontal edges' value.
	///   - vertical: The vertical edges' value.
	public init(horizontal: CGFloat = 0, vertical: CGFloat = 0) {
		self.init(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
	}
	
	/// Initializes a `RectEdges` instance with the same value for all edges.
	/// - Parameter all: The value for all edges.
	public init(all: CGFloat) {
		self.init(top: all, left: all, bottom: all, right: all)
	}
	
// MARK: - Exposed Methods
	
	/// Multiplies the edge values of a `RectEdges` instance by a scalar.
	/// - Parameters:
	///   - lhs: The `RectEdges` instance.
	///   - rhs: The scalar value.
	/// - Returns: A new `RectEdges` instance with scaled edge values.
	public static func * (lhs: Self, rhs: CGFloat) -> Self {
		.init(top: lhs.top * rhs, left: lhs.left * rhs, bottom: lhs.bottom * rhs, right: lhs.right * rhs)
	}
}

// MARK: - Type - RectCorners

/// Represents the corner radii of a rectangle with individual values for each corner.
public struct RectCorners {
	
// MARK: - Properties
	
	/// The value for the top-left corner.
	public var topLeft: CGFloat
	
	/// The value for the top-right corner.
	public var topRight: CGFloat
	
	/// The value for the bottom-left corner.
	public var bottomLeft: CGFloat
	
	/// The value for the bottom-right corner.
	public var bottomRight: CGFloat
	
	/// Safer RTL compatible corners.
	public var rtlSafe: Self { Locale.preferredLocale.isRTL ? .init(topLeft: topRight, topRight: topLeft, bottomLeft: bottomRight, bottomRight: bottomLeft) : self }
	
	/// Creates a `RectCorners` with all edges set to zero.
	public static var zero: Self { .init(all: 0) }
	
// MARK: - Constructors
	
	/// Initializes a `RectCorners` instance with individual corner radii values.
	/// - Parameters:
	///   - topLeft: The value for the top-left corner.
	///   - topRight: The value for the top-right corner.
	///   - bottomLeft: The value for the bottom-left corner.
	///   - bottomRight: The value for the bottom-right corner.
	public init(topLeft: CGFloat = 0, topRight: CGFloat = 0, bottomLeft: CGFloat = 0, bottomRight: CGFloat = 0) {
		self.topLeft = topLeft
		self.topRight = topRight
		self.bottomLeft = bottomLeft
		self.bottomRight = bottomRight
	}
	
	/// Initializes a `RectCorners` instance with the same value for all corners.
	/// - Parameter all: The value for all corners.
	public init(all: CGFloat) {
		self.init(topLeft: all, topRight: all, bottomLeft: all, bottomRight: all)
	}
}

// MARK: - Type - Line

/// Represents a line segment with a start and an end point.
public struct Line {
		
// MARK: - Properties
	
	/// The starting point of the line.
	public let start: CGPoint
	
	/// The ending point of the line.
	public let end: CGPoint
	
	/// Calculates the center point of the line segment.
	public var center: CGPoint { .init(x: (start.x + end.x) * 0.5, y: (start.y + end.y) * 0.5) }
	
	/// Creates a `Line` at zero point.
	public static var zero: Self { .init(start: .init(x: 0, y: 0), end: .init(x: 0, y: 0)) }
	
// MARK: - Constructors
	
	/// Initializes a `Line` instance with given start and end points.
	/// - Parameters:
	///   - start: The starting point of the line.
	///   - end: The ending point of the line.
	public init(start: CGPoint, end: CGPoint) {
		self.start = start
		self.end = end
	}
	
// MARK: - Exposed Methods
	
	/// Calculates the intersection point of two lines.
	/// - Parameter line: The other line.
	/// - Returns: The intersection point, if it exists.
	public func intersection(of line: Line) -> CGPoint? {
		let cross1 = start * end
		let cross2 = line.start * line.end
		let subtract1 = start - end
		let subtract2 = line.start - line.end
		let determinant = subtract1.x * subtract2.y - subtract1.y * subtract2.x
		guard determinant != 0 else { return nil }
		let x = (cross1 * subtract2.x - subtract1.x * cross2) / determinant
		let y = (cross1 * subtract2.y - subtract1.y * cross2) / determinant
		return .init(x: x, y: y)
	}
}
