//
//  Created by Diney Bomfim on 11/12/26.
//

#if canImport(UIKit)
import UIKit
import Testing
import LocalServer
@testable import Fusion

extension FusionSuite {
	
	@Suite
	struct ImagePipelineTests {
		
		init() {
			ServerMock.startLocalServer()
		}
		
		private static func pngData(width: Int, height: Int, color: UIColor = .systemRed) -> Data {
			let format = UIGraphicsImageRendererFormat()
			format.scale = 1
			let size = CGSize(width: width, height: height)
			return UIGraphicsImageRenderer(size: size, format: format).image { context in
				color.setFill()
				context.fill(.init(origin: .zero, size: size))
			}.pngData() ?? Data()
		}
		
		private func routeImage(width: Int = 64, height: Int = 32, status: Int = 200) -> (url: String, requests: ThreadSafe<Int>) {
			let url = "\(MockEndpoint.host)/images/\(UUID().uuidString).png"
			let requests = ThreadSafe(wrappedValue: 0)
			let data = Self.pngData(width: width, height: height)
			(StubServer.instance as? StubServer)?.route([.GET], url: url) { _, _ in
				requests.mutate { $0 += 1 }
				return StubResponse(data: data).withStatusCode(status)
			}
			return (url, requests)
		}
		
		private func waitUntil(timeout: TimeInterval = 3, _ condition: () async -> Bool) async {
			let deadline = Date().addingTimeInterval(timeout)
			while await !condition() && Date() < deadline {
				try? await Task.sleep(nanoseconds: 10_000_000)
			}
		}
		
		@Test
		func image_WithConcurrentRequestsForTheSameURL_ShouldDownloadOnce() async {
			let route = routeImage()
			let pipeline = ImagePipeline.shared
			
			async let first = pipeline.image(url: route.url)
			async let second = pipeline.image(url: route.url)
			async let third = pipeline.image(url: route.url)
			let images = await [first, second, third]
			
			#expect(images.allSatisfy { $0 != nil })
			#expect(route.requests.wrappedValue == 1)
			#expect(await pipeline.inFlightCount == 0)
		}
		
		@Test
		func image_WithNotFoundResponse_ShouldReturnNilAndNotCacheTheBody() async {
			let route = routeImage(status: 404)
			let pipeline = ImagePipeline.shared
			
			let first = await pipeline.image(url: route.url)
			let second = await pipeline.image(url: route.url)
			
			#expect(first == nil)
			#expect(second == nil)
			#expect(URLCache.appGroup.cachedResponse(for: URLRequest(url: route.url.toURL)) == nil)
			#expect(route.requests.wrappedValue == 2)
		}
		
		@Test
		func image_WithDifferentURLs_ShouldLoadEachImageWithItsOwnIdentifier() async throws {
			let first = routeImage()
			let second = routeImage()
			let pipeline = ImagePipeline.shared
			
			let firstImage = try #require(await pipeline.image(url: first.url))
			let secondImage = try #require(await pipeline.image(url: second.url))
			
			#expect(firstImage !== secondImage)
			#expect(firstImage.accessibilityIdentifier == first.url)
			#expect(secondImage.accessibilityIdentifier == second.url)
		}
		
		@Test
		func image_WhenTheWaitingTaskIsCancelled_ShouldStillWarmTheCache() async {
			let route = routeImage()
			let pipeline = ImagePipeline.shared
			
			let task = Task { await pipeline.image(url: route.url) }
			task.cancel()
			_ = await task.value
			await waitUntil { pipeline.cachedImage(url: route.url) != nil }
			
			#expect(pipeline.cachedImage(url: route.url) != nil)
			#expect(route.requests.wrappedValue == 1)
		}
		
		@Test
		func image_WithMaxPixelSize_ShouldDownsampleAndKeepThePointSize() async throws {
			let route = routeImage(width: 400, height: 200)
			let pipeline = ImagePipeline.shared
			
			let image = try #require(await pipeline.image(url: route.url, maxPixelSize: 100))
			let cgImage = try #require(image.cgImage)
			
			#expect(max(cgImage.width, cgImage.height) == 100)
			#expect(image.size == CGSize(width: 400, height: 200))
			#expect(pipeline.cached(url: route.url, maxPixelSize: 100) === image)
		}
		
		@Test
		func image_WithMaxPixelSizeLargerThanTheImage_ShouldNotUpscale() async throws {
			let route = routeImage(width: 40, height: 20)
			
			let image = try #require(await ImagePipeline.shared.image(url: route.url, maxPixelSize: 1000))
			let cgImage = try #require(image.cgImage)
			
			#expect(cgImage.width == 40)
			#expect(image.size == CGSize(width: 40, height: 20))
		}
		
		@Test
		func image_WhenCachedOnDisk_ShouldNotDownloadAgainAfterMemoryIsCleared() async {
			let route = routeImage()
			let pipeline = ImagePipeline.shared
			
			_ = await pipeline.image(url: route.url)
			let request = URLRequest(url: route.url.toURL)
			await waitUntil { URLCache.appGroup.cachedResponse(for: request) != nil }
			pipeline.removeAll()
			let image = await pipeline.image(url: route.url)
			
			#expect(image != nil)
			#expect(route.requests.wrappedValue == 1)
		}
		
		@Test
		func loadCache_AfterDownload_ShouldReturnTheImageFromMemory() async {
			let route = routeImage()
			
			let downloaded: UIImage? = await withCheckedContinuation { continuation in
				UIImage.download(url: route.url) { continuation.resume(returning: $0) }
			}
			
			#expect(downloaded != nil)
			#expect(ImagePipeline.shared.cachedImage(url: route.url) != nil)
			#expect(UIImage.loadCache(url: route.url) === downloaded)
		}
		
		@Test
		func loadOrDownload_WithCachedImage_ShouldReportFromCache() async {
			let route = routeImage()
			_ = await ImagePipeline.shared.image(url: route.url)
			
			let (image, fromCache): (UIImage?, Bool) = await withCheckedContinuation { continuation in
				UIImage.loadOrDownload(url: route.url) { continuation.resume(returning: ($0, $1)) }
			}
			
			#expect(image != nil)
			#expect(fromCache)
			#expect(route.requests.wrappedValue == 1)
		}
		
		@Test
		func memoryCacheLimit_WhenChanged_ShouldUpdateTheLiveCache() {
			let original = UIImage.memoryCacheLimit
			defer { UIImage.memoryCacheLimit = original }
			
			#expect(original == ImagePipeline.memoryCostLimit)
			UIImage.memoryCacheLimit = original * 2
			#expect(ImagePipeline.shared.memory.totalCostLimit == original * 2)
		}
		
		@Test
		func flushCache_ShouldClearMemoryAndDiskCaches() async {
			let route = routeImage()
			_ = await ImagePipeline.shared.image(url: route.url)
			let request = URLRequest(url: route.url.toURL)
			await waitUntil { URLCache.appGroup.cachedResponse(for: request) != nil }
			
			UIImage.flushCache()
			await waitUntil { URLCache.appGroup.cachedResponse(for: request) == nil }
			
			#expect(ImagePipeline.shared.cachedImage(url: route.url) == nil)
			#expect(URLCache.appGroup.cachedResponse(for: request) == nil)
			#expect(UIImage.loadCache(url: route.url) == nil)
		}
		
		@Test
		func associateBadge_ShouldDrawTheBadgeOnceAndRefreshWhenChanged() async throws {
			let route = routeImage()
			let badge = UIImage(data: Self.pngData(width: 8, height: 8, color: .systemBlue))
			UIImage.associateBadge(badge, to: route.url)
			defer { UIImage.associateBadge(nil, to: route.url) }
			
			let plain = try #require(await ImagePipeline.shared.image(url: route.url, allowsBadge: false))
			let first = try #require(UIImage.loadCache(url: route.url))
			let second = try #require(UIImage.loadCache(url: route.url))
			
			#expect(first === second)
			#expect(first !== plain)
			#expect(first.size.width > plain.size.width)
			
			UIImage.associateBadge(nil, to: route.url)
			#expect(UIImage.loadCache(url: route.url) === plain)
		}
		
		@Test
		func load_WithImageConvertibleURL_ShouldAssignTheImageOnMain() async {
			let route = routeImage()
			let imageView = await UIImageView()
			
			await MainActor.run { route.url.load(on: imageView, at: \.image) }
			await waitUntil { await MainActor.run { imageView.image != nil } }
			
			#expect(await imageView.image?.accessibilityIdentifier == route.url)
		}
		
		@Test
		func cachedData_WithUndecodableCachedBody_ShouldBeRemoved() async throws {
			let url = "\(MockEndpoint.host)/images/\(UUID().uuidString).png"
			let request = URLRequest(url: url.toURL)
			let response = try #require(HTTPURLResponse(url: url.toURL, statusCode: 200, httpVersion: nil, headerFields: nil))
			URLCache.appGroup.storeCachedResponse(.init(response: response, data: Data("not an image".utf8)), for: request)
			
			#expect(UIImage.loadCache(url: url) == nil)
			await waitUntil { URLCache.appGroup.cachedResponse(for: request) == nil }
			#expect(URLCache.appGroup.cachedResponse(for: request) == nil)
		}
	}
}
#endif
