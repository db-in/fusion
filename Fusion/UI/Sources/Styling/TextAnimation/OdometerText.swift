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
		let characters = Array(string)
		return characters.enumerated().map { .init(id: characters.count - 1 - $0.offset, character: $0.element) }
	}
}

// MARK: - Type - OdometerDigit

struct OdometerDigit: View {
	
	private static let symbols: [String] = (0...9).map { "\($0)" }
	
	let digit: Int
	let attributes: AttributeContainer
	
	private func glyph(_ value: Int) -> Text {
		Text(AttributedString(Self.symbols[value], attributes: attributes))
	}
	
	var body: some View {
		glyph(0)
			.hidden()
			.overlay(alignment: .top) {
				GeometryReader { proxy in
					VStack(spacing: 0) {
						ForEach(0..<10, id: \.self) { value in
							glyph(value)
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
	private func glyphView(_ glyph: OdometerGlyph, attributes: AttributeContainer) -> some View {
		if let digit = glyph.digit {
			OdometerDigit(digit: digit, attributes: attributes)
				.animation(animation.delay(Double(glyph.id) * stagger), value: digit)
		} else {
			Text(AttributedString(String(glyph.character), attributes: attributes))
		}
	}
	
	var body: some View {
		if segments.hasNumber {
			HStack(alignment: .firstTextBaseline, spacing: 0) {
				Text(segments.prefix)
				ForEach(OdometerGlyph.glyphs(for: segments.number)) { glyph in
					glyphView(glyph, attributes: segments.numberAttributes)
						.transition(.move(edge: .bottom).combined(with: .opacity))
				}
				Text(segments.suffix)
			}
			.accessibilityElement(children: .ignore)
			.accessibilityLabel(segments.template.string)
		} else {
			Text(segments.full)
		}
	}
}

private struct OdometerPreview: View {
	
	@State private var value: Int = 1_284
	
	var body: some View {
		VStack(spacing: 24) {
			OdometerText(segments: .init(NSAttributedString(string: "\(value)", attributes: [.font: UIFont.systemFont(ofSize: 48, weight: .bold)])),
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
