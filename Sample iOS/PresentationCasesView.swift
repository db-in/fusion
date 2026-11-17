//
//  Created by Diney Bomfim.
//

import Fusion
import SwiftUI
import UIKit

private func dismissTop() {
	UIWindow.topViewController?.dismiss(animated: true)
}

private let loremText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer posuere erat a ante venenatis dapibus posuere velit aliquet. Vestibulum id ligula porta felis euismod semper."

private struct CaseSheet<Content: View>: View {
	
	let title: String
	var background: Color = Color(uiColor: .systemBackground)
	var ignoresSafeArea: Bool = true
	var fillsHeight: Bool = false
	@ViewBuilder let content: () -> Content
	
	var body: some View {
		VStack(spacing: 16) {
			Capsule()
				.fill(Color.secondary.opacity(0.4))
				.frame(width: 36, height: 5)
				.padding(.top, 8)
			
			Text(title)
				.font(.system(.headline))
			
			content()
			
			Button("Close", action: dismissTop)
				.buttonStyle(.borderedProminent)
				.frame(maxWidth: .infinity)
		}
		.padding(.horizontal)
		.padding(.bottom)
		.frame(maxWidth: .infinity, maxHeight: fillsHeight ? .infinity : nil, alignment: .top)
		.background(background.ignoresSafeArea(edges: ignoresSafeArea ? .all : []))
	}
}

private struct CaseRows: View {
	
	let count: Int
	
	var body: some View {
		ForEach(0..<count, id: \.self) { index in
			HStack {
				Circle()
					.fill(Color.accentColor.opacity(0.3))
					.frame(width: 32, height: 32)
				Text("Row \(index + 1)")
				Spacer()
			}
		}
	}
}

private struct TextFieldCase: View {
	
	let isScrollable: Bool
	@State private var text: String = ""
	@FocusState private var isFocused: Bool
	
	var body: some View {
		CaseSheet(title: isScrollable ? "TextField in ScrollView" : "TextField, no scroll") {
			if isScrollable {
				ScrollView {
					field
				}
			} else {
				field
			}
		}
		.onAppear { isFocused = true }
	}
	
	private var field: some View {
		VStack(alignment: .trailing, spacing: 4) {
			TextField("Name", text: $text)
				.focused($isFocused)
				.padding(12)
				.background(RoundedRectangle(cornerRadius: 10).stroke(Color.orange))
			Text("\(text.count)/30")
				.font(.caption)
				.foregroundStyle(.secondary)
		}
		.padding(.vertical, 2)
	}
}

private struct GrowingCase: View {
	
	@State private var rows: Int = 1
	@State private var hasError: Bool = false
	
	var body: some View {
		CaseSheet(title: "Growing content") {
			CaseRows(count: rows)
			
			if hasError {
				Text(loremText)
					.font(.system(.footnote))
					.foregroundStyle(.red)
			}
			
			HStack {
				Button("Add row") { withAnimation { rows += 1 } }
				Button("Remove row") { withAnimation { rows = max(0, rows - 1) } }
				Button("Toggle error") { withAnimation { hasError.toggle() } }
			}
			.buttonStyle(.bordered)
		}
	}
}

private final class AutoLayoutCaseController : UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .systemBackground
		
		let title = UILabel()
		title.text = "UIKit Auto Layout"
		title.font = .preferredFont(forTextStyle: .headline)
		
		let body = UILabel()
		body.text = loremText
		body.numberOfLines = 0
		
		let button = UIButton(configuration: .borderedProminent(), primaryAction: UIAction(title: "Close") { _ in dismissTop() })
		let stack = UIStackView(arrangedSubviews: [title, body, button])
		stack.axis = .vertical
		stack.spacing = 16
		stack.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(stack)
		
		NSLayoutConstraint.activate([
			stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
			stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
			stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
			stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
		])
	}
}

struct PresentationCasesView: View {
	
	var body: some View {
		List {
			Section("Measured SwiftUI") {
				Button("Short text") {
					CaseSheet(title: "Short text") { Text("One single line.") }
						.presentOverWindow()
				}
				Button("Long wrapping text") {
					CaseSheet(title: "Long wrapping text") { Text(loremText + " " + loremText) }
						.presentOverWindow()
				}
				Button("Spacer based layout") {
					CaseSheet(title: "Spacer based layout") {
						Text("Spacer must not stretch the sheet.")
						Spacer()
					}
					.presentOverWindow()
				}
				Button("Full bleed background") {
					CaseSheet(title: "Full bleed background", background: .yellow) {
						Text("Yellow must reach the bottom edge, with no gap under Close.")
					}
					.presentOverWindow()
				}
				Button("Growing content") {
					GrowingCase().presentOverWindow()
				}
			}
			
			Section("ScrollView") {
				Button("Short ScrollView") {
					CaseSheet(title: "Short ScrollView") { ScrollView { CaseRows(count: 3) } }
						.presentOverWindow()
				}
				Button("Long ScrollView") {
					CaseSheet(title: "Long ScrollView") { ScrollView { CaseRows(count: 60) } }
						.presentOverWindow()
				}
				Button("ScrollView with maxHeight infinity") {
					CaseSheet(title: "ScrollView maxHeight infinity") {
						ScrollView { CaseRows(count: 4) }
							.frame(maxHeight: .infinity)
					}
					.presentOverWindow()
				}
				Button("List") {
					CaseSheet(title: "List") {
						List { CaseRows(count: 5) }
							.listStyle(.plain)
					}
					.presentOverWindow()
				}
			}
			
			Section("Keyboard") {
				Button("TextField, no scroll") {
					TextFieldCase(isScrollable: false).presentOverWindow()
				}
				Button("TextField in ScrollView") {
					TextFieldCase(isScrollable: true).presentOverWindow()
				}
			}
			
			Section("Overrides and containers") {
				Button("Height 300, ignoresSafeArea") {
					CaseSheet(title: "Height 300, ignoresSafeArea") { Text("Fixed content height.") }
						.presentOverWindow(preferredHeight: 300)
				}
				Button("Height 300, no ignoresSafeArea") {
					CaseSheet(title: "Height 300, no ignoresSafeArea", ignoresSafeArea: false) { Text("Fixed content height.") }
						.presentOverWindow(preferredHeight: 300)
				}
				Button("Height 300, fills height") {
					CaseSheet(title: "Height 300, fills height", fillsHeight: true) { Text("Fixed content height.") }
						.presentOverWindow(preferredHeight: 300)
				}
				Button("Navigation, ignoresSafeArea") {
					CaseSheet(title: "Navigation, ignoresSafeArea") { Text(loremText) }
						.uiHost(cached: false)
						.embededInNavigation()
						.presentOverWindow()
				}
				Button("Navigation, no ignoresSafeArea") {
					CaseSheet(title: "Navigation, no ignoresSafeArea", ignoresSafeArea: false) { Text(loremText) }
						.uiHost(cached: false)
						.embededInNavigation()
						.presentOverWindow()
				}
				Button("Host via UIKit presentOverWindow") {
					CaseSheet(title: "UIKit path") { Text(loremText) }
						.uiHost(cached: false)
						.presentOverWindow()
				}
				Button("UIKit Auto Layout controller") {
					AutoLayoutCaseController().presentOverWindow()
				}
				Button("Side left") {
					CaseSheet(title: "Left side") { Text(loremText) }
						.presentOverWindow(from: .left)
				}
				Button("Side left, fills height") {
					CaseSheet(title: "Left side", fillsHeight: true) { Text(loremText) }
						.presentOverWindow(from: .left)
				}
				Button("Side right") {
					CaseSheet(title: "Right side") { Text(loremText) }
						.presentOverWindow(from: .right)
				}
				Button("Side right, fills height") {
					CaseSheet(title: "Right side", fillsHeight: true) { Text(loremText) }
						.presentOverWindow(from: .right)
				}
			}
		}
		.navigationTitle("Presentation cases")
	}
}

#Preview("Presentation cases") {
	NavigationStack {
		PresentationCasesView()
	}
}
