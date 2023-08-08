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

	static func linear(_ begin: FPoint, _ change: FPoint, _ time: FPoint, _ duration: FPoint) -> FPoint {
		return change * time / duration + begin
	}
	
	static func smoothIn(_ begin: FPoint, _ change: FPoint, _ time: FPoint, _ duration: FPoint) -> FPoint {
		let t = time / duration
		return change * t * t + begin
	}
	
	static func smoothOut(_ begin: FPoint, _ change: FPoint, _ time: FPoint, _ duration: FPoint) -> FPoint {
		let t = time / duration
		return -change * t * (t - 2.0) + begin
	}
	
	static func smoothInOut(_ begin: FPoint, _ change: FPoint, _ time: FPoint, _ duration: FPoint) -> FPoint {
		var t = time / (duration * 0.5)
		
		if t < 1.0 {
			return change * 0.5 * t * t + begin
		} else {
			t -= 1.0
		}
		
		return -change * 0.5 * ((t) * (t - 2.0) - 1.0) + begin
	}
	
	static func strongIn(_ begin: FPoint, _ change: FPoint, _ time: FPoint, _ duration: FPoint) -> FPoint {
		if time == 0.0 {
			return begin
		} else if time == duration {
			return begin + change
		}
		return change * pow(2.0, 10.0 * (time / duration - 1.0)) + begin - change * 0.001
	}
	
	static func strongOut(_ begin: FPoint, _ change: FPoint, _ time: FPoint, _ duration: FPoint) -> FPoint {
		let power = -pow(2.0, -10.0 * time / duration) + 1.0
		return (time == duration) ? begin + change : change * FPoint(power) + begin
	}
	
	static func strongInOut(_ begin: FPoint, _ change: FPoint, _ time: FPoint, _ duration: FPoint) -> FPoint {
		if time == 0.0 {
			return begin
		} else if time == duration {
			return begin + change
		} else if time < duration * 0.5 {
			let t = time / (duration * 0.5)
			return change * 0.5 * pow(2.0, 10.0 * (t - 1.0)) + begin
		}
		
		let t = time / (duration * 0.5)
		return change * 0.5 * (-pow(2.0, -10.0 * (t - 1.0)) + 2.0) + begin
	}
	
	static func elasticIn(_ begin: FPoint, _ change: FPoint, _ time: FPoint, _ duration: FPoint) -> FPoint {
		let x = change, y = duration * 0.3, z = y / 4.0, percent = time / duration

		if time == 0.0 {
			return begin
		} else if percent == 1.0 {
			return begin + change
		}

		let t = percent - 1.0
		return -x * pow(2.0, 10.0 * t) * sin((t * duration - z) * Constant.piDouble / y) + begin
	}
	
	static func elasticOut(_ begin: FPoint, _ change: FPoint, _ time: FPoint, _ duration: FPoint) -> FPoint {
		let x = change, y = duration * 0.3, z = y / 4.0, percent = time / duration
		
		if time == 0.0 {
			return begin
		} else if percent == 1.0 {
			return begin + change
		}
		
		return x * pow(2.0, -10.0 * percent) * sin((percent * duration - z) * Constant.piDouble / y) + x + begin
	}
	
	static func elasticInOut(_ begin: FPoint, _ change: FPoint, _ time: FPoint, _ duration: FPoint) -> FPoint {
		var x = change, y = duration * 0.45, z = y / 4.0, powTime: FPoint, percent = time / (duration * 0.5)
		
		if time == 0.0 {
			return begin
		} else if percent == 2.0 {
			return begin + change
		}
		
		if percent < 1.0 {
			let t = percent - 1.0
			powTime = pow(2.0, 10.0 * t)
			return -0.5 * x * powTime * sin((t * duration - z) * Constant.piDouble / y) + begin
		}
		
		let t = percent - 1.0
		powTime = pow(2.0, -10.0 * t)
		return 0.5 * x * powTime * sin((t * duration - z) * Constant.piDouble / y) + change + begin
	}
	
	static func bounceIn(_ begin: FPoint, _ change: FPoint, _ time: FPoint, _ duration: FPoint) -> FPoint {
		return change - bounceOut(0.0, change, duration - time, duration) + begin
	}
	
	static func bounceOut(_ begin: FPoint, _ change: FPoint, _ time: FPoint, _ duration: FPoint) -> FPoint {
		var t = time / duration
		
		if time == 0.0 {
			return begin
		} else if time == duration {
			return begin + change
		} else if t < Constant.tween_0_36 {
			return change * (Constant.tween_7_56 * t * t) + begin
		} else if t < Constant.tween_0_72 {
			t -= Constant.tween_0_54
			return change * (Constant.tween_7_56 * t * t + Constant.tween_0_72) + begin
		} else if t < Constant.tween_0_90 {
			t -= Constant.tween_0_81
			return change * (Constant.tween_7_56 * t * t + Constant.tween_0_95) + begin
		}
		
		t -= Constant.tween_0_95
		return change * (Constant.tween_7_56 * t * t + Constant.tween_0_95) + begin
	}
	
	static func bounceInOut(begin: FPoint, change: FPoint, time: FPoint, duration: FPoint) -> FPoint {
		if time < duration * 0.5 {
			return bounceIn(0.0, change, time * 2.0, duration) * 0.5 + begin
		}
		return bounceOut(0.0, change, time * 2.0 - duration, duration) * 0.5 + change * 0.5 + begin
	}
	
	static func backIn(begin: FPoint, change: FPoint, time: FPoint, duration: FPoint) -> FPoint {
		let t = time / duration
		return change * t * t * ((Constant.tween_1_65 + 1.0) * t - Constant.tween_1_65) + begin
	}
	
	static func backOut(begin: FPoint, change: FPoint, time: FPoint, duration: FPoint) -> FPoint {
		let t = time / duration - 1.0
		return change * (t * t * ((Constant.tween_1_65 + 1.0) * t + Constant.tween_1_65) + 1.0) + begin
	}
	
	static func backInOut(begin: FPoint, change: FPoint, time: FPoint, duration: FPoint) -> FPoint {
		var t = time / (duration * 0.5)
		if t < 1.0 {
			return change * 0.5 * (t * t * ((Constant.tween_3_23 + 1.0) * t - Constant.tween_3_23)) + begin
		}
		t -= 2.0
		return change * 0.5 * (t * t * ((Constant.tween_3_23 + 1.0) * t + Constant.tween_3_23) + 2.0) + begin
	}
}

public typealias Easing = (_ begin: FPoint, _ change: FPoint, _ time: FPoint, _ duration: FPoint) -> FPoint

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
