//
//  Created by Diney Bomfim.
//

#if canImport(UIKit) && canImport(SwiftUI) && !os(watchOS)
import SwiftUI

// MARK: - Type - WaveNumberAttribute

@available(iOS 18.0, tvOS 18.0, visionOS 2.0, *)
struct WaveNumberAttribute: TextAttribute { }

// MARK: - Type - WaveTextRenderer

@available(iOS 18.0, tvOS 18.0, visionOS 2.0, *)
struct WaveTextRenderer: TextRenderer, Animatable {
	
	var cycle: Double
	let amplitude: CGFloat
	let glyphCount: Int
	
	var animatableData: Double {
		get { cycle }
		set { cycle = newValue }
	}
	
	static func offset(index: Int, total: Int, progress: Double, amplitude: CGFloat) -> CGFloat {
		guard total > 0, progress > 0 else { return 0 }
		let local = min(max(progress * 2 - Double(index) / Double(total), 0), 1)
		return -amplitude * CGFloat(sin(local * .pi))
	}
	
	func draw(layout: Text.Layout, in context: inout GraphicsContext) {
		let progress = cycle - cycle.rounded(.down)
		guard progress > 0, glyphCount > 0 else {
			for line in layout { context.draw(line) }
			return
		}
		
		var index = 0
		for line in layout {
			for run in line {
				guard run[WaveNumberAttribute.self] != nil else {
					context.draw(run)
					continue
				}
				
				for slice in run {
					var copy = context
					copy.translateBy(x: 0, y: Self.offset(index: index, total: glyphCount, progress: progress, amplitude: amplitude))
					copy.draw(slice)
					index += 1
				}
			}
		}
	}
}

// MARK: - Type - WaveText

@available(iOS 18.0, tvOS 18.0, visionOS 2.0, *)
struct WaveText: View {
	
	let segments: TextAnimationSegments
	let amplitude: CGFloat
	let cycle: Double
	
	private var composed: Text {
		guard segments.hasNumber else { return Text(segments.full) }
		let number = Text(AttributedString(segments.number, attributes: segments.numberAttributes)).customAttribute(WaveNumberAttribute())
		return Text(segments.prefix) + number + Text(segments.suffix)
	}
	
	var body: some View {
		composed
			.textRenderer(WaveTextRenderer(cycle: cycle, amplitude: amplitude, glyphCount: segments.digitCount))
			.accessibilityLabel(segments.string)
	}
}

@available(iOS 18.0, tvOS 18.0, visionOS 2.0, *)
private struct WavePreview: View {
	
	@State private var value: Int = 4_210
	@State private var cycle: Double = 0
	
	var body: some View {
		VStack(spacing: 24) {
			WaveText(segments: .init(NSAttributedString(string: "Score \(value) pts", attributes: [.font: UIFont.systemFont(ofSize: 36, weight: .heavy)])),
					 amplitude: 12,
					 cycle: cycle)
			Button("Random") {
				value = Int.random(in: 1_000...9_999)
				withAnimation(.smooth(duration: 0.8)) { cycle += 1 }
			}
			.buttonStyle(.borderedProminent)
		}
	}
}

@available(iOS 18.0, tvOS 18.0, visionOS 2.0, *)
#Preview("Wave text") {
	WavePreview()
}
#endif
