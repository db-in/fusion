//
//  Created by Diney Bomfim on 11/4/26.
//

import Foundation
import Testing
@testable import Fusion

@Suite(.serialized)
struct FusionSuite {}

func awaitResponse<T>(_ body: (@escaping Response<T>) -> Void) async -> (Result<T, Error>, URLResponse?) {
	await withCheckedContinuation { continuation in
		body { result, response in
			continuation.resume(returning: (result, response))
		}
	}
}
