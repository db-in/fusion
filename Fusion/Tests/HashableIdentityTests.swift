//
//  Created by Diney Bomfim on 11/12/26.
//

import Foundation
import Testing
#if canImport(UIKit) && !os(watchOS)
import UIKit
#endif
@testable import Fusion

// MARK: - Type -

extension FusionSuite {
	
	@Suite
	struct HashableIdentityTests {
		
		@Test
		func countryInfo_Identifiable_ShouldExposeAStableId() {
			let country = CountryInfo(code: "US")
			#expect(country.id == country.hashValue)
			#expect(country.id == CountryInfo(code: "US").id)
			#expect(Set([country, CountryInfo(code: "US"), CountryInfo(code: "GB")]).count == 2)
		}
		
#if canImport(UIKit) && !os(watchOS)
		@Test
		func tween_Equality_ShouldUseTheIdentifier() {
			let view = UIView()
			let first = Tween(view, duration: 1.0)
			let second = Tween(view, duration: 1.0)
			#expect(first == first)
			#expect(first != second)
			#expect(Set([first, first, second]).count == 2)
			#expect(first.hashValue == first.hashValue)
			first.stopTween()
			second.stopTween()
		}
		
		@Test
		func controlAction_EqualityAndIdentity_ShouldUseTheVisibleFields() {
			let first = ControlAction(title: "Buy", selected: true)
			let same = ControlAction(title: "Buy", selected: true)
			let different = ControlAction(title: "Sell", selected: true)
			
			#expect(first == same)
			#expect(first != different)
			#expect(first.id == same.id)
			#expect(first.id != different.id)
			#expect(Set([first, same, different]).count == 2)
		}
		
		@Test
		func userFlow_Equality_ShouldUseTheIdentifier() {
			let first = UserFlow("Main", bundle: .main)
			let same = UserFlow("Main", bundle: .main)
			let different = UserFlow("Other", bundle: .main)
			
			#expect(first == same)
			#expect(first != different)
			#expect(Set([first, same, different]).count == 2)
		}
#endif
	}
}
