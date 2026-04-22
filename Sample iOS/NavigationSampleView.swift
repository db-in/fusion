//
//  NavigationSampleView.swift
//  Sample iOS
//

import Fusion
import SwiftUI
import UIKit

struct NavigationSampleView: View {
	var body: some View {
		List {
			Section {
				Button("Push presentation") {
					presentPushSample()
				}
				Button("Modal presentation") {
					presentModalSample()
				}
				Button("Modal (preferred height)") {
					presentModalPreferredHeightSample()
				}
				Button("Modal (very long content)") {
					presentLongModalSample()
				}
				Button("Fullscreen presentation") {
					presentFullscreenSample()
				}
			}
		}
		.navigationTitle("Navigation")
	}
}

private func presentPushSample() {
	let flow = UserFlow { _ in
		PushModalSampleContent().uiHost(cached: false)
	}
	flow.startAsPush()
}

private func presentModalSample() {
	let flow = UserFlow { _ in
		SheetModalSampleContent().uiHost(cached: false)
	}
	flow.startAsModal(withNavigation: true, style: .none)
}

private func presentFullscreenSample() {
	let flow = UserFlow { _ in
		FullscreenModalSampleContent().uiHost(cached: false)
	}
	flow.startAsModal(withNavigation: false, style: .fullScreen)
}

private func presentModalPreferredHeightSample() {
	PreferredHeightSheetContent()
		.presentOverWindow(style: .none, preferredHeight: 360)
}

private func presentLongModalSample() {
	let flow = UserFlow { _ in
		LongSheetModalSampleContent().uiHost(cached: false)
	}
	flow.startAsModal(withNavigation: true, style: .none)
}

struct PushModalSampleContent: View {
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("Push")
				.font(.system(size: 17, weight: .semibold))
			Text("Compact height — single block of text to see how push lays out minimal content.")
				.font(.system(size: 15, weight: .regular))
				.foregroundStyle(.secondary)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 12)
				.fill(Color(UIColor.systemTeal).opacity(0.15))
		)
		.padding()
		.navigationTitle("Push (short)")
		.navigationBarTitleDisplayMode(.inline)
		.background(.white)
	}
}

struct SheetModalSampleContent: View {
	var body: some View {
//		ScrollView {
//			VStack(alignment: .leading, spacing: 16) {
//				Text("Modal (medium)")
//					.font(.system(size: 22, weight: .bold))
//				ForEach(0..<5, id: \.self) { index in
//					HStack {
//						Circle()
//							.fill(Color.accentColor.opacity(0.3))
//							.frame(width: 36, height: 36)
//						VStack(alignment: .leading, spacing: 4) {
//							Text("Row item \(index + 1)")
//								.font(.system(size: 17, weight: .medium))
//							Text("Placeholder detail text for variable row height assessment.")
//								.font(.system(size: 12, weight: .regular))
//								.foregroundStyle(.secondary)
//						}
//						Spacer()
//					}
//					.padding(.vertical, 4)
//				}
//			}
//		}
//		.frame(maxWidth: .infinity, alignment: .leading)
//		.padding()
//		.navigationTitle("Modal (medium)")
//		.navigationBarTitleDisplayMode(.inline)
//		.background(.white)
		ScrollView {
			VStack(alignment: .leading, spacing: 16) {
				Text("Modal (medium)")
					.font(.system(size: 22, weight: .bold))
				ForEach(0..<5, id: \.self) { index in
					HStack {
						Circle()
							.fill(Color.accentColor.opacity(0.3))
							.frame(width: 36, height: 36)
						VStack(alignment: .leading, spacing: 4) {
							Text("Row item \(index + 1)")
								.font(.system(size: 17, weight: .medium))
							Text("Placeholder detail text for variable row height assessment.")
								.font(.system(size: 12, weight: .regular))
								.foregroundStyle(.secondary)
						}
						Spacer()
					}
					.padding(.vertical, 4)
				}
			}
			
			Spacer()
			
			Button("Dismiss") {
				print("Button")
			}
		}
		.frame(maxWidth: .infinity, alignment: .leading)
		.padding()
		.navigationTitle("Modal (medium)")
		.navigationBarTitleDisplayMode(.inline)
		.background(.white)
	}
}

struct PreferredHeightSheetContent: View {
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		NavigationView {
			VStack(alignment: .leading, spacing: 12) {
				Text("Preferred height")
					.font(.system(size: 22, weight: .bold))
				Text("This sheet is presented with preferredContentSize height (360pt) via View.presentOverWindow(style:preferredHeight:).")
					.font(.system(size: 15, weight: .regular))
					.foregroundStyle(.secondary)
				Spacer(minLength: 0)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
			.padding()
			.background(.white)
			.navigationTitle("Preferred height")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Done") {
						dismiss()
					}
				}
			}
		}
	}
}

struct LongSheetModalSampleContent: View {
	var body: some View {
		ScrollView {
			VStack(alignment: .leading, spacing: 14) {
				Text("Very long modal")
					.font(.system(size: 22, weight: .bold))
				ForEach(0..<80, id: \.self) { index in
					VStack(alignment: .leading, spacing: 6) {
						Text("Block \(index + 1)")
							.font(.system(size: 17, weight: .semibold))
						Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer posuere erat a ante venenatis dapibus posuere velit aliquet. Vestibulum id ligula porta felis euismod semper. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.")
							.font(.system(size: 15, weight: .regular))
							.foregroundStyle(.secondary)
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					.padding()
					.background(
						RoundedRectangle(cornerRadius: 8)
							.fill(Color(UIColor.secondarySystemBackground))
					)
				}
			}
			.padding()
		}
		.background(.white)
		.navigationTitle("Long content")
		.navigationBarTitleDisplayMode(.inline)
	}
}

struct FullscreenModalSampleContent: View {
	@Environment(\.dismiss) private var dismiss
	
	var body: some View {
		VStack(spacing: 0) {
			HStack {
				Spacer(minLength: 0)
				Button {
					dismiss()
				} label: {
					Text("Close")
						.font(.system(size: 17, weight: .semibold))
						.frame(minWidth: 72, minHeight: 44)
				}
				.buttonStyle(.borderedProminent)
			}
			.padding(.horizontal, 16)
			.padding(.vertical, 12)
			.background(Color(uiColor: .secondarySystemBackground))
			ScrollView {
				VStack(alignment: .leading, spacing: 20) {
					Text("Fullscreen")
						.font(.system(size: 34, weight: .bold))
					ForEach(0..<24, id: \.self) { index in
						VStack(alignment: .leading, spacing: 8) {
							Text("Section \(index + 1)")
								.font(.system(size: 17, weight: .semibold))
							Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.")
								.font(.system(size: 17, weight: .regular))
								.foregroundStyle(.secondary)
						}
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding()
						.background(
							RoundedRectangle(cornerRadius: 10)
								.fill(Color(uiColor: .secondarySystemBackground))
						)
					}
				}
				.padding()
			}
		}
		.background(.white)
	}
}

#Preview {
	NavigationView {
		NavigationSampleView()
	}
}

#Preview("Sheet modal") {
	NavigationView {
		SheetModalSampleContent()
	}
}
