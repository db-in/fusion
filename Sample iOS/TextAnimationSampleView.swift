//
//  Created by Diney Bomfim.
//

import Fusion
import SwiftUI

private struct TextAnimationSample: Identifiable {
	
	let id: String
	let style: TextAnimationStyle
	
	static let all: [TextAnimationSample] = [
		.init(id: "Counting", style: .counting),
		.init(id: "Native", style: .native),
		.init(id: "Odometer", style: .odometer()),
		.init(id: "Scramble", style: .scramble),
		.init(id: "Wave", style: .wave(amplitude: 10))
	]
}

struct TextAnimationSampleView: View {
	
	@State private var value: Double = 1_250
	@State private var duration: Double = 0.8
	@State private var easeIndex: Int = Ease.allCases.firstIndex(of: .smoothOut) ?? 0
	
	private var ease: Ease { Ease.allCases[easeIndex] }
	
	private var controls: some View {
		VStack(alignment: .leading, spacing: 8) {
			HStack(spacing: 6) {
				Button("-10k") { value = max(0, value - 10_000) }
				Button("-1k") { value = max(0, value - 1_000) }
				Button("-1") { value = max(0, value - 1) }
				Button("+1") { value += 1 }
				Button("+1k") { value += 1_000 }
				Button("+10k") { value += 10_000 }
				Button("Rnd") { value = Double(Int.random(in: 0...99_999)) }
			}
			.buttonStyle(.bordered)
			.controlSize(.small)
			
			HStack(spacing: 8) {
				Text("\(duration.toString(decimals: 1, locale: .preferredLocale))s")
					.font(.caption.monospacedDigit())
					.foregroundStyle(.secondary)
					.frame(width: 36, alignment: .leading)
				Slider(value: $duration, in: 0.2...3)
				Picker("Ease", selection: $easeIndex) {
					ForEach(Ease.allCases.indices, id: \.self) { index in
						Text(String(describing: Ease.allCases[index])).tag(index)
					}
				}
				.labelsHidden()
				.frame(maxWidth: 120)
			}
		}
		.padding(.horizontal)
		.padding(.vertical, 10)
		.background(.bar)
	}
	
	var body: some View {
		ScrollView {
			LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
				ForEach(TextAnimationSample.all) { sample in
					TextAnimationRow(title: sample.id, style: sample.style, value: value, duration: duration, ease: ease)
						.padding(.horizontal)
						.padding(.vertical, 10)
					Divider()
						.padding(.leading, 84)
				}
			}
			.padding(.top, 4)
		}
		.safeAreaInset(edge: .top, spacing: 0) {
			controls
		}
		.navigationTitle("Text animation")
		.navigationBarTitleDisplayMode(.inline)
	}
}

#Preview("Text animation gallery") {
	NavigationStack {
		TextAnimationSampleView()
	}
}
