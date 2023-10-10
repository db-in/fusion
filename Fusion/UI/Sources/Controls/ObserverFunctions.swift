//
//  Created by Diney Bomfim on 5/3/23.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Definitions -

public struct KeyPathName {
	
	public static var viewFrame: String = #keyPath(UIView.frame)
	public static var layerBounds: String = #keyPath(UIView.layer.bounds)
	public static var clipsToBounds: String = #keyPath(UIView.clipsToBounds)
	public static var layerPosition: String = #keyPath(UIView.layer.position)
	public static var scrollOffset: String = #keyPath(UIScrollView.contentOffset)
}

// MARK: - Extension - UIScrollView

public extension UIScrollView {

// MARK: - Properties

	private static var observerKey: UInt8 = 1

	private var hasObserver: Bool {
		get { objc_getAssociatedObject(self, &Self.observerKey) as? Bool ?? false }
		set { objc_setAssociatedObject(self, &Self.observerKey, newValue, .OBJC_ASSOCIATION_ASSIGN) }
	}

// MARK: - Exposed Methods

	func addObserverOnce(forKeyPath keyPath: String, notifyAt: NSObject? = nil, options: NSKeyValueObservingOptions = [.new]) {
		guard !hasObserver else { return }
		hasObserver = true
		addObserver(notifyAt ?? self, forKeyPath: keyPath, options: options, context: nil)
	}
}

// MARK: - Extension - UINavigationBar

public extension UINavigationBar {

// MARK: - Properties

	private static var observersKey: UInt8 = 1
	
	private var hasObserver: Bool {
		get { objc_getAssociatedObject(self, &Self.observersKey) as? Bool ?? false }
		set { objc_setAssociatedObject(self, &Self.observersKey, newValue, .OBJC_ASSOCIATION_ASSIGN) }
	}
	
// MARK: - Exposed Methods
	
	func addObserverOnce(forKeyPath keyPath: String, notifyAt: NSObject? = nil, options: NSKeyValueObservingOptions = [.new]) {
		guard !hasObserver else { return }
		hasObserver = true
		addObserver(notifyAt ?? self, forKeyPath: keyPath, options: options, context: nil)
	}
}
#endif
