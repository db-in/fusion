//
//  Created by Diney Bomfim on 11/13/26.
//

#if canImport(UIKit)
import XCTest
import UIKit
@testable import Fusion

// MARK: - Type -

final class ImagePipelinePerformanceTests : PerformanceTestCase {
	
// MARK: - Properties
	
	private let urls = (0..<20).map { "https://benchmark.fusion.test/images/\($0).png" }
	
	private lazy var smallPNG = Self.pngData(width: 64, height: 64)
	
	private lazy var largePNG = Self.pngData(width: 1_024, height: 1_024)
	
// MARK: - Protected Methods
	
	private static func pngData(width: Int, height: Int) -> Data {
		let format = UIGraphicsImageRendererFormat()
		format.scale = 1
		let size = CGSize(width: width, height: height)
		return UIGraphicsImageRenderer(size: size, format: format).image { context in
			UIColor.systemTeal.setFill()
			context.fill(.init(origin: .zero, size: size))
			UIColor.systemOrange.setFill()
			context.fill(.init(x: 0, y: 0, width: width / 2, height: height / 2))
		}.pngData() ?? Data()
	}
	
	private func seedURLCache(with data: Data) {
		urls.forEach { url in
			guard let response = HTTPURLResponse(url: url.toURL, statusCode: 200, httpVersion: nil, headerFields: nil) else { return }
			URLCache.appGroup.storeCachedResponse(.init(response: response, data: data), for: URLRequest(url: url.toURL))
		}
	}
	
	private func seedMemoryCache() {
		guard let image = UIImage(data: smallPNG) else { return }
		urls.forEach { ImagePipeline.shared.cache(image, url: $0) }
	}
	
	override func tearDown() {
		UIImage.flushCache()
		super.tearDown()
	}
	
// MARK: - Exposed Methods
	
	func testURLCacheAppGroupAccess() {
		measureLoop { _ in _ = URLCache.appGroup }
	}
	
	func testMemoryCacheHit() {
		seedMemoryCache()
		measureLoop { _ = UIImage.loadCache(url: urls[$0 % urls.count]) }
	}
	
	func testMemoryCacheMiss() {
		measureLoop { _ = ImagePipeline.shared.cachedImage(url: "https://benchmark.fusion.test/missing/\($0).png") }
	}
	
	func testURLCacheLoadAndDecode() {
		seedURLCache(with: smallPNG)
		measureLoop(iterations: 200) {
			ImagePipeline.shared.removeAll()
			_ = UIImage.loadCache(url: urls[$0 % urls.count])
		}
	}
	
	func testCorruptCachedImageLoad() {
		seedURLCache(with: Data("not an image".utf8))
		measureLoop(iterations: 200) { _ = UIImage.loadCache(url: urls[$0 % urls.count]) }
	}
	
	func testDecodeFullSize1024() {
		let data = largePNG
		measureLoop(iterations: 20) { _ = ImagePipeline.decode(data, url: "full-\($0).png") }
	}
	
	func testDecodeDownsampled1024To128() {
		let data = largePNG
		measureLoop(iterations: 20) { _ = ImagePipeline.decode(data, url: "thumb-\($0).png", maxPixelSize: 128) }
	}
	
	func testFlushCacheWith20Images() {
		measure(setUp: {
			seedURLCache(with: smallPNG)
			seedMemoryCache()
		}) {
			UIImage.flushCache()
		}
	}
}
#endif
