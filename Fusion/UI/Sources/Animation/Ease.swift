//  
//  Created by Diney Bomfim on 5/1/23.
//

import Foundation

// MARK: - Definitions -

private extension Constant {
	
	static let tween_0_36: FPoint = 0.363636
	static let tween_0_54: FPoint = 0.545454
	static let tween_0_72: FPoint = 0.727272
	static let tween_0_81: FPoint = 0.818181
	static let tween_0_90: FPoint = 0.909090
	static let tween_0_95: FPoint = 0.954545
	static let tween_1_65: FPoint = 1.656565
	static let tween_3_23: FPoint = 3.232323
	static let tween_7_56: FPoint = 7.562525
}

private struct EaseFunction {
	
	static func linear(_ value: FPoint) -> FPoint { value }
	
	static func smoothIn(_ value: FPoint) -> FPoint { value * value * value * value }
	
	static func smoothOut(_ value: FPoint) -> FPoint {
		let delta = value - 1.0
		return delta * delta * delta * (1 - value) + 1.0
	}
	
	static func smoothInOut(_ value: FPoint) -> FPoint {
		if value < 0.5 {
			return 8.0 * value * value * value * value
		} else {
			let delta = (value - 1.0)
			return -8.0 * delta * delta * delta * delta + 1.0
		}
	}
	
	static func strongIn(_ value: FPoint) -> FPoint { value * value }
	
	static func strongOut(_ value: FPoint) -> FPoint { 1.0 - strongIn(1.0 - value) }
	
	static func strongInOut(_ value: FPoint) -> FPoint {
		if value < 0.5 {
			return 0.5 * strongIn(value * 2.0)
		} else {
			return 0.5 * strongOut(value * 2.0 - 1.0) + 0.5
		}
	}
	
	static func elasticIn(_ value: FPoint) -> FPoint {
		guard value != 0.0 && value != 1.0 else { return value }
		return sin(13 * Constant.pi / 2 * value) * pow(2, 10 * (value - 1))
	}
	
	static func elasticOut(_ value: FPoint) -> FPoint {
		guard value != 0.0 && value != 1.0 else { return value }
		return sin(-13 * Constant.pi / 2 * (value + 1)) * pow(2, -10 * value) + 1
	}
	
	static func elasticInOut(_ value: FPoint) -> FPoint {
		guard value != 0.0 && value != 1.0 else { return value }
		if value < 0.5 {
			return 0.5 * elasticIn(value * 2.0)
		} else {
			return 0.5 * elasticOut(value * 2.0 - 1.0) + 0.5
		}
	}
	
	static func bounceIn(_ value: FPoint) -> FPoint { 1.0 - bounceOut(1.0 - value) }
	
	static func bounceOut(_ value: FPoint) -> FPoint {
		guard value != 0.0 && value != 1.0 else { return value }
		var t = value
		
		if t < Constant.tween_0_36 {
			return Constant.tween_7_56 * t * t
		} else if t < Constant.tween_0_72 {
			t -= Constant.tween_0_54
			return Constant.tween_7_56 * t * t + Constant.tween_0_72
		} else if t < Constant.tween_0_90 {
			t -= Constant.tween_0_81
			return Constant.tween_7_56 * t * t + Constant.tween_0_95
		}
		
		t -= Constant.tween_0_95
		return Constant.tween_7_56 * t * t + Constant.tween_0_95
	}
	
	static func bounceInOut(_ value: FPoint) -> FPoint {
		if value < 0.5 {
			return 0.5 * bounceIn(value * 2.0)
		} else {
			return 0.5 * bounceOut(value * 2.0 - 1.0) + 0.5
		}
	}
	
	static func backIn(_ value: FPoint) -> FPoint {
		let t = value
		return t * t * ((Constant.tween_1_65 + 1.0) * t - Constant.tween_1_65)
	}
	
	static func backOut(_ value: FPoint) -> FPoint {
		let t = value - 1.0
		return (t * t * ((Constant.tween_1_65 + 1.0) * t + Constant.tween_1_65) + 1.0)
	}
	
	static func backInOut(_ value: FPoint) -> FPoint {
		var t = value / 0.5
		if t < 1.0 {
			return 0.5 * (t * t * ((Constant.tween_3_23 + 1.0) * t - Constant.tween_3_23))
		}
		t -= 2.0
		return 0.5 * (t * t * ((Constant.tween_3_23 + 1.0) * t + Constant.tween_3_23) + 2.0)
	}
}

public typealias Easing = (_ value: FPoint) -> FPoint

// MARK: - Type -

public enum Ease : Equatable, CaseIterable {
	
	case linear
	case smoothIn
	case smoothOut
	case smoothInOut
	case strongIn
	case strongOut
	case strongInOut
	case elasticIn
	case elasticOut
	case elasticInOut
	case bounceIn
	case bounceOut
	case bounceInOut
	case backIn
	case backOut
	case backInOut
	case custom(Easing)
	
	public var easingFunction: Easing {
		switch self {
		case .linear:
			return EaseFunction.linear
		case .smoothIn:
			return EaseFunction.smoothIn
		case .smoothOut:
			return EaseFunction.smoothOut
		case .smoothInOut:
			return EaseFunction.smoothInOut
		case .strongIn:
			return EaseFunction.strongIn
		case .strongOut:
			return EaseFunction.strongOut
		case .strongInOut:
			return EaseFunction.strongInOut
		case .elasticIn:
			return EaseFunction.elasticIn
		case .elasticOut:
			return EaseFunction.elasticOut
		case .elasticInOut:
			return EaseFunction.elasticInOut
		case .bounceIn:
			return EaseFunction.bounceIn
		case .bounceOut:
			return EaseFunction.bounceOut
		case .bounceInOut:
			return EaseFunction.bounceInOut
		case .backIn:
			return EaseFunction.backIn
		case .backOut:
			return EaseFunction.backOut
		case .backInOut:
			return EaseFunction.backInOut
		case .custom(let easing):
			return easing
		}
	}
	
	public var reversed: Ease {
		switch self {
		case .smoothIn:
			return .smoothOut
		case .smoothOut:
			return .smoothIn
		case .strongIn:
			return .strongOut
		case .strongOut:
			return .strongIn
		case .elasticIn:
			return .elasticOut
		case .elasticOut:
			return .elasticIn
		case .bounceIn:
			return .bounceOut
		case .bounceOut:
			return .bounceIn
		case .backIn:
			return .backOut
		case .backOut:
			return .backIn
		default:
			return self
		}
	}
	
	/// Calculates the value at a specific point in time using a time-based approach.
	///
	/// - Parameters:
	///   - begin: The initial value.
	///   - change: The change in value.
	///   - time: The current time.
	///   - duration: The duration of the change.
	///
	/// - Returns: The calculated value at the given time using the easing function.
	public func calculate(_ begin: FPoint, _ change: FPoint, _ time: FPoint, _ duration: FPoint) -> FPoint {
		calculate(begin, change, time / duration)
	}

	/// Calculates the value at a specific percentage of the change using a percentage-based approach.
	///
	/// - Parameters:
	///   - begin: The initial value.
	///   - change: The change in value.
	///   - percentage: The progress percentage (0.0 to 1.0).
	///
	/// - Returns: The calculated value at the given percentage using the easing function.
	public func calculate(_ begin: FPoint, _ change: FPoint, _ percentage: FPoint) -> FPoint {
		change * easingFunction(percentage) + begin
	}
	
	public static var allCases: [Ease] = [.linear,
										  .smoothIn, .smoothOut, .smoothInOut,
										  .strongIn, .strongOut, .strongInOut,
										  .elasticIn, .elasticOut, .elasticInOut,
										  .bounceIn, .bounceOut, .bounceInOut,
										  .backIn, .backOut, .backInOut]
	
	public static func == (lhs: Self, rhs: Self) -> Bool {
		switch (lhs, rhs) {
		case (.linear, .linear),
			(.smoothIn, .smoothIn), (.smoothOut, .smoothOut), (.smoothInOut, .smoothInOut),
			(.strongIn, .strongIn), (.strongOut, .strongOut), (.strongInOut, .strongInOut),
			(.elasticIn, .elasticIn), (.elasticOut, .elasticOut), (.elasticInOut, .elasticInOut),
			(.bounceIn, .bounceIn), (.bounceOut, .bounceOut), (.bounceInOut, .bounceInOut),
			(.backIn, .backIn), (.backOut, .backOut), (.backInOut, .backInOut):
			return true
		default:
			return false
		}
	}
}
