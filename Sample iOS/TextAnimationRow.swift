//
//  Created by Diney Bomfim.
//

import Fusion
import SwiftUI
import UIKit

struct TextAnimationRow: View {
	
	let title: String
	let style: TextAnimationStyle
	let value: Double
	var duration: Double = 0.8
	var ease: Ease = .smoothOut
	
	private var plain: String { value.toString(decimals: 0, locale: .preferredLocale) }
	
	private var currency: NSAttributedString {
		let amount = value.toString(decimals: 2, locale: .preferredLocale)
		return "$ \(amount)"
			.styled([.foregroundColor: UIColor.secondaryLabel, .font: UIFont.systemFont(ofSize: 13, weight: .medium)])
			.styled([.foregroundColor: UIColor.systemGreen, .font: UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .semibold)], onText: amount)
	}
	
	private var messages: String { "You have \(Int(value)) new messages" }
	
	var body: some View {
		HStack(alignment: .firstTextBaseline, spacing: 12) {
			Text(title)
				.font(.caption.weight(.semibold))
				.foregroundStyle(.secondary)
				.frame(width: 72, alignment: .leading)
			
			VStack(alignment: .leading, spacing: 2) {
				plain
					.textAnimated(style: style, duration: duration, animationCurve: ease)
					.font(.system(size: 18, weight: .semibold, design: .rounded))
					.monospacedDigit()
				
				currency
					.textAnimated(style: style, duration: duration, animationCurve: ease)
				
				messages
					.textAnimated(style: style, duration: duration, animationCurve: ease)
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			
			Spacer(minLength: 0)
		}
		.padding(.vertical, 2)
	}
}

private struct TextAnimationRowPreview: View {
	
	let title: String
	let style: TextAnimationStyle
	@State private var value: Double = 1_250
	
	var body: some View {
		VStack(spacing: 16) {
			TextAnimationRow(title: title, style: style, value: value)
			HStack {
				Button("+1") { value += 1 }
				Button("+1,000") { value += 1_000 }
				Button("Random") { value = Double(Int.random(in: 0...99_999)) }
			}
			.buttonStyle(.bordered)
		}
		.padding()
	}
}

#Preview("Counting") {
	TextAnimationRowPreview(title: "Counting", style: .counting)
}

#Preview("Numeric text") {
	TextAnimationRowPreview(title: "Numeric text", style: .numericText)
}

#Preview("Odometer") {
	TextAnimationRowPreview(title: "Odometer", style: .odometer())
}

#Preview("Scramble") {
	TextAnimationRowPreview(title: "Scramble", style: .scramble)
}

#Preview("Wave") {
	TextAnimationRowPreview(title: "Wave", style: .wave(amplitude: 10))
}
