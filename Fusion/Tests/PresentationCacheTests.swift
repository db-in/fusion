//
//  Created by Diney Bomfim on 11/12/26.
//

import Foundation
import Testing
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(UIKit)
import UIKit
#endif
@testable import Fusion

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct PresentationCacheTests {
		
		@Test
		func catalog_WithAMiss_ShouldLoadOnceUntilTheHintsChange() {
			let key = "catalog-\(UUID().uuidString)"
			let loads = ThreadSafe(wrappedValue: 0)
			let load: () -> String? = { loads.mutate { $0 += 1 }; return nil }
			
			#expect(InMemoryCache.getOrLoadCatalog(key: key, load: load) == nil)
			#expect(InMemoryCache.getOrLoadCatalog(key: key, load: load) == nil)
			#expect(loads.wrappedValue == 1)
			
			Bundle.registering(.main)
			#expect(InMemoryCache.getOrLoadCatalog(key: key, load: load) == nil)
			#expect(loads.wrappedValue == 2)
			InMemoryCache.flush(key: key)
		}
		
		@Test
		func catalog_WithAHit_ShouldKeepTheValue() {
			let key = "catalog-\(UUID().uuidString)"
			let loads = ThreadSafe(wrappedValue: 0)
			let load: () -> String? = { loads.mutate { $0 += 1 }; return "found" }
			
			#expect(InMemoryCache.getOrLoadCatalog(key: key, load: load) == "found")
			Bundle.registering(.main)
			#expect(InMemoryCache.getOrLoadCatalog(key: key, load: load) == "found")
			#expect(loads.wrappedValue == 1)
			InMemoryCache.flush(key: key)
		}
		
#if canImport(SwiftUI)
		@Test
		func colorHex_WhenRepeated_ShouldReturnTheSameColor() {
			#expect(Color(hex: "#123456") == Color(hex: "#123456"))
			#expect(Color(hex: "0x123456") == Color(red: Double(0x12) / 255, green: Double(0x34) / 255, blue: Double(0x56) / 255, opacity: 1))
			#expect(Color(hex: "#12345680") == Color(red: Double(0x12) / 255, green: Double(0x34) / 255, blue: Double(0x56) / 255, opacity: Double(0x80) / 255))
			#expect(Color(hex: "invalid") == .black)
			#expect(Color(hex: nil) == .black)
		}
#endif
		
#if canImport(UIKit) && !os(watchOS)
		@Test
		func anyColor_WithAMissingName_ShouldCacheTheMiss() {
			let name = "missing-\(UUID().uuidString)"
			#expect(UIColor.anyColor(named: name) == .black)
			#expect(InMemoryCache.getRaw(key: "UIColor-\(name)") is CatalogMiss)
			#expect(UIColor.anyColor(named: name) == .black)
			InMemoryCache.flush(key: "UIColor-\(name)")
		}
		
		@Test
		func anyImage_WithAMissingName_ShouldCacheTheMiss() {
			let name = "missing-\(UUID().uuidString)"
			#expect(UIImage.anyImage(named: name).size == .zero)
			#expect(InMemoryCache.getRaw(key: "UIImage-\(name)") is CatalogMiss)
			#expect(UIImage.anyImageNonTrait(named: name).size == .zero)
			InMemoryCache.flush(key: "UIImage-\(name)")
		}
		
		@Test
		func monospacedDigit_ForTheSameFont_ShouldReturnTheSameInstance() {
			let font = UIFont.systemFont(ofSize: 17)
			let first = font.monospacedDigit
			#expect(first === font.monospacedDigit)
			#expect(first.pointSize == 17)
			#expect(first !== UIFont.systemFont(ofSize: 18).monospacedDigit)
			#expect(first !== font.bold.monospacedDigit)
		}
		
		@Test
		func suiColor_WithDynamicColor_ShouldFollowTheInterfaceStyle() {
			let dynamic = UIColor { $0.userInterfaceStyle == .dark ? .white : .black }
			var light: Color?
			var dark: Color?
			UITraitCollection(userInterfaceStyle: .light).performAsCurrent { light = dynamic.suiColor }
			UITraitCollection(userInterfaceStyle: .dark).performAsCurrent { dark = dynamic.suiColor }
			#expect(light != dark)
			UITraitCollection(userInterfaceStyle: .dark).performAsCurrent { #expect(dynamic.suiColor == dark) }
			#expect(UIColor.red.suiColor == UIColor.red.suiColor)
		}
		
		@Test @MainActor
		func gradientView_WithTheSameBounds_ShouldNotRebuildOnLayout() {
			let view = GradientView(colors: [.red, .blue])
			view.frame = .init(x: 0, y: 0, width: 100, height: 100)
			view.layoutIfNeeded()
			let first = view.layer.sublayers?.first { $0 is CAGradientLayer }
			
			view.setNeedsLayout()
			view.layoutIfNeeded()
			#expect(view.layer.sublayers?.first { $0 is CAGradientLayer } === first)
			
			view.frame = .init(x: 0, y: 0, width: 200, height: 100)
			view.layoutIfNeeded()
			let resized = view.layer.sublayers?.first { $0 is CAGradientLayer }
			#expect(resized !== first)
			#expect(resized?.frame.width == 200)
			
			view.colors = [.green, .yellow]
			#expect(view.layer.sublayers?.first { $0 is CAGradientLayer } !== resized)
		}
		
		@Test
		func loaderControl_ShouldKeyObjectsByIdentity() {
			let first = UIImageView()
			let second = UIImageView()
			#expect(LoaderControl.key(for: first) == LoaderControl.key(for: first))
			#expect(LoaderControl.key(for: first) != LoaderControl.key(for: second))
			#expect(LoaderControl.key(for: "value") == LoaderControl.key(for: "value"))
		}
		
		@Test
		func readImageData_WithALegacyKey_ShouldReadAndMigrateIt() throws {
			let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ImageKeys-\(UUID().uuidString)")
			try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
			defer { try? FileManager.default.removeItem(at: folder) }
			let key = "https://example.com/image.png"
			let data = Data([1, 2, 3])
			try data.write(to: folder.legacyImageFileURL(withKey: key))
			
			#expect(folder.readImageData(withKey: key) == data)
			#expect(FileManager.default.fileExists(atPath: folder.imageFileURL(withKey: key).path))
			#expect(!FileManager.default.fileExists(atPath: folder.legacyImageFileURL(withKey: key).path))
			#expect(folder.readImageData(withKey: key) == data)
		}
		
		@Test
		func writeImage_ShouldUseTheSHA256Key() throws {
			let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ImageKeys-\(UUID().uuidString)")
			try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
			defer { try? FileManager.default.removeItem(at: folder) }
			let key = "https://example.com/other.png"
			
			folder.writeImage(data: Data([9]), withKey: key)
			#expect(folder.imageFileURL(withKey: key).lastPathComponent == "image-\(key.sha256)")
			#expect(folder.readImageData(withKey: key) == Data([9]))
		}
#endif
	}
}
