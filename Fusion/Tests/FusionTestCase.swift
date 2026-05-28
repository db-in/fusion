//
//  Created by Diney Bomfim on 5/28/26.
//

import Foundation
@testable import Fusion

private final class FusionTestBundleToken {}

enum FusionTestCase {
	static func configureBundles() {
		let testBundle = Bundle(for: FusionTestBundleToken.self)
		guard !Bundle.hints.contains(where: { $0.bundleURL == testBundle.bundleURL }) else { return }
		Bundle.hints.insert(testBundle, at: 0)
	}
}