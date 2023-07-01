//
//  Banner.swift
//  Fusion
//
//  Created by DINEY B ALVES on 6/28/23.
//

#if canImport(UIKit) && canImport(SwiftUI)
import UIKit
import SwiftUI

struct Banner: View {
	
	private let fullImageURL: String?
	private let link: String?
	@State private var image: UIImage? = nil
	
	init(fullImageURL: String? = nil, link: String? = nil) {
		self.fullImageURL = fullImageURL
		self.link = link
		update()
	}
	
	private func update() {
		UIImage.load(fullImageURL, for: self, at: \.image)
	}
	
	var body: some View {
		Image(uiImage: image ?? UIImage())
			.resizable()
			.aspectRatio(contentMode: .fill)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Color.clear)
			.onAppear {
				update()
			}
	}
}

struct Banner_Previews: PreviewProvider {
	static var previews: some View {
		Banner(fullImageURL: "https://thispersondoesnotexist.com/", link: "")
	}
}
#endif
