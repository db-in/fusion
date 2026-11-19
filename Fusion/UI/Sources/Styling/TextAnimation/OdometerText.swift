//
//  Created by Diney Bomfim.
//

#if canImport(UIKit) && canImport(SwiftUI) && !os(watchOS)
import SwiftUI

// MARK: - Type - OdometerGlyph

struct OdometerGlyph: Identifiable, Equatable {
	
	let id: Int
	let character: Character
	
	var digit: Int? { character.wholeNumberValue }
	
	static func glyphs(for string: String) -> [OdometerGlyph] {
		let count = string.count
		var result: [OdometerGlyph] = []
		result.reserveCapacity(count)
		var index = 0
		for character in string {
			result.append(.init(id: count - 1 - index, character: character))
			index += 1
		}
		return result
	}
}

// MARK: - Type - OdometerDigit

struct OdometerDigit: View {
	
	let digit: Int
	let runs: [AttributedString]
	
	var body: some View {
		Text(runs[0])
			.hidden()
			.overlay(alignment: .top) {
				GeometryReader { proxy in
					VStack(spacing: 0) {
						ForEach(0..<10, id: \.self) { value in
							Text(runs[value])
								.frame(width: proxy.size.width, height: proxy.size.height)
						}
					}
					.offset(y: -CGFloat(digit) * proxy.size.height)
				}
			}
			.clipped()
	}
}

// MARK: - Type - OdometerText

struct OdometerText: View {
	
	let segments: TextAnimationSegments
	let animation: Animation
	let stagger: Double
	
	@ViewBuilder
	private func glyphView(_ glyph: OdometerGlyph) -> some View {
		if let digit = glyph.digit {
			OdometerDigit(digit: digit, runs: segments.digitRuns)
				.animation(animation.delay(Double(glyph.id) * stagger), value: digit)
		} else {
			Text(AttributedString(String(glyph.character), attributes: segments.numberAttributes))
		}
	}
	
	var body: some View {
		if segments.hasNumber {
			HStack(alignment: .firstTextBaseline, spacing: 0) {
				Text(segments.prefix)
				ForEach(segments.glyphs) { glyph in
					glyphView(glyph)
						.transition(.move(edge: .bottom).combined(with: .opacity))
				}
				Text(segments.suffix)
			}
			.accessibilityElement(children: .ignore)
			.accessibilityLabel(segments.string)
		} else {
			Text(segments.full)
		}
	}
}

private struct OdometerPreview: View {
	
	@State private var value: Int = 1_284
	
	var body: some View {
		VStack(spacing: 24) {
			OdometerText(segments: .init(NSAttributedString(string: "\(value)", attributes: [.font: UIFont.systemFont(ofSize: 48, weight: .bold)]), includeDigitRuns: true),
						 animation: Ease.backOut.animation(duration: 0.6),
						 stagger: 0.05)
			Button("Random") {
				withAnimation { value = Int.random(in: 0...99_999) }
			}
			.buttonStyle(.borderedProminent)
		}
	}
}

#Preview("Odometer text") {
	OdometerPreview()
}
#endif
