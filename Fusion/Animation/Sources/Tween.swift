//
//  Created by Diney Bomfim on 5/2/23.
//

import Foundation

// MARK: - Definitions -

extension Dictionary where Key == ReferenceWritableKeyPath<UIView, CGFloat>, Value == CGFloat {
	
	func merge(with other: Self, target: UIView?) -> [Key: [Value]] {
		var combined: [Key: [Value]] = [:]
		guard let validTarget = target else { return combined }
		
		forEach {
			combined[$0.key] = [$0.value, validTarget[keyPath: $0.key]]
		}
		
		other.forEach {
			if combined[$0.key] == nil {
				combined[$0.key] = [validTarget[keyPath: $0.key], $0.value]
			} else {
				combined[$0.key]?[1] = $0.value
			}
		}
		
		return combined
	}
}

public struct TweenOption {
	
	public enum State {
		case current
		case end
	}
	
	public enum Repetition {
		case loop
		case mirrorValues
		case mirrorValuesAndEase
	}
	
	public var name: String?
	public var ease: Ease
	public var delay: FPoint
	public var isPaused: Bool
	public var isReversed: Bool
	public var isRelative: Bool
	public var repetition: TweenOption.Repetition?
	public var repetitionCount: UInt32
	public var repetitionDelay: FPoint
	public var endState: TweenOption.State
	public var delegate: TweenDelegate?
	
	public init(name: String? = nil,
				ease: Ease = .linear,
				delay: FPoint = 0,
				isPaused: Bool = false,
				isReversed: Bool = false,
				isRelative: Bool = false,
				repetition: TweenOption.Repetition? = nil,
				repetitionCount: UInt32 = .max,
				repetitionDelay: FPoint = 0,
				endState: TweenOption.State = .current,
				delegate: TweenDelegate? = nil) {
		self.name = name
		self.ease = ease
		self.delay = delay
		self.isPaused = isPaused
		self.isReversed = isReversed
		self.isRelative = isRelative
		self.repetition = repetition
		self.repetitionCount = repetitionCount
		self.repetitionDelay = repetitionDelay
		self.endState = endState
		self.delegate = delegate
	}
}

public protocol TweenDelegate {
	func tweenWillStart(_ tween: Tween)
	func tweenWillRepeat(_ tween: Tween)
	func tweenWillFinish(_ tween: Tween)
	func tweenDidStart(_ tween: Tween)
	func tweenDidRepeat(_ tween: Tween)
	func tweenDidFinish(_ tween: Tween)
}

public extension TweenDelegate {
	public func tweenWillStart(_ tween: Tween) { }
	public func tweenWillRepeat(_ tween: Tween) { }
	public func tweenWillFinish(_ tween: Tween) { }
	public func tweenDidStart(_ tween: Tween) { }
	public func tweenDidRepeat(_ tween: Tween) { }
	public func tweenDidFinish(_ tween: Tween) { }
}

// MARK: - Type -

public class Tween {
	
// MARK: - Properties
	
	private static var tweens: Set<Tween> = []
	private static let tweensQueue: DispatchQueue = .init(label: "tween.\(UUID().uuidString)", attributes: .concurrent)
	
	private var allValues: [ReferenceWritableKeyPath<UIView, CGFloat> : [CGFloat]] = [:]

	public let identifier: String = UUID().uuidString
	public var duration: FPoint
	public var options: TweenOption
	public var fromValues: [ReferenceWritableKeyPath<UIView, CGFloat> : CGFloat]
	public var toValues: [ReferenceWritableKeyPath<UIView, CGFloat> : CGFloat]
	
	public private(set) var target: UIView?
	public private(set) var isReady: Bool = true
	public private(set) var isMirrored: Bool = false
	public private(set) var deltaTime: FPoint = 0
	public private(set) var beginTime: FPoint = 0
	public private(set) var currentTime: FPoint = 0
	public private(set) var lastTime: FPoint = 0
	public private(set) var idleTime: FPoint = 0
	public private(set) var currentCycle: UInt32 = 0
	
	
	public var isPaused: Bool {
		get { options.isPaused }
		set {
			guard options.isPaused != newValue else { return }
			
			if lastTime == 0.0 || newValue {
				lastTime = CFAbsoluteTimeGetCurrent()
			}
			
			if !newValue {
				idleTime += CFAbsoluteTimeGetCurrent() - lastTime
			}
			
			options.isPaused = newValue
		}
	}
	
// MARK: - Constructors
	
	/// Initializes a Tween instance with a target, duration, options, and values.
	///
	/// - Parameters:
	///   - target: The tween target which will have its values changed.
	///   - duration: The duration in seconds.
	///   - options: The tween options. See ``TweenKey``.
	///   - fromValues: A dictionary defining the values from where the tween will start. If none is provided, the current values will be used.
	///   - toValues: A dictionary defining the values to where the ween will end.
	@discardableResult public init(target: UIView,
				duration: FPoint,
				options: TweenOption = .init(),
				fromValues: [ReferenceWritableKeyPath<UIView, CGFloat> : CGFloat] = [:],
				toValues: [ReferenceWritableKeyPath<UIView, CGFloat> : CGFloat] = [:]) {
		self.target = target
		self.duration = duration
		self.options = options
		self.fromValues = fromValues
		self.toValues = toValues
		
		startTween()
	}
	
// MARK: - Protected Methods
	
	private func startTween() {
		isReady = false
		currentCycle = 0
		resetTime()
		
		Self.tweensQueue.sync(flags: .barrier) {
			Self.tweens.insert(self)
		}
		
		TimerControl.shared.addItem(key: identifier, queue: .global(qos: .background)) {
			self.timerCallBack()
		}
	}
	
	private func resetTime() {
		beginTime = 0.0
		currentTime = 0.0
		idleTime = CFAbsoluteTimeGetCurrent()
	}
	
	private func finishCycle() {
		resetTime()
		currentCycle += 1
		
		guard currentCycle <= options.repetitionCount else {
			stopTween(option: options.endState ?? .current)
			return
		}
		
		switch options.repetition {
		case .mirrorValues:
			isMirrored.toggle()
			setTargetValues(reverting: true, revertEase: false)
		case .mirrorValuesAndEase:
			isMirrored.toggle()
			setTargetValues(reverting: true, revertEase: true)
		default:
			break
		}
	}
	
	private func setTargetValues(reverting: Bool, revertEase: Bool) {
		DispatchQueue.asyncMainIfNeeded {
			self.updateTargetValues(reverting: reverting, revertEase: revertEase)
		}
	}
	
	private func updateTargetValues(reverting: Bool, revertEase: Bool) {
		if !isReady {
			isReady = true
			
			let allKeys = fromValues.merge(with: toValues, target: target)
			let isRelative = options.isRelative
			
			allKeys.forEach {
				let originalValue = target?[keyPath: $0.key] ?? 0
				let fromValue = isRelative ? originalValue + $0.value[0] : $0.value[0]
				let toValue = isRelative ? originalValue + $0.value[1] : $0.value[1]
				let inValue = reverting ? toValue : fromValue
				let outValue = reverting ? fromValue - toValue : toValue - fromValue
				
				target?[keyPath: $0.key] = inValue
				allValues[$0.key] = [inValue, outValue]
			}
		} else {
			allValues.forEach {
				let fromValue = $0.value[0]
				let toValue = $0.value[1]
				let inValue = fromValue + toValue
				let outValue = -toValue
				
				allValues[$0.key] = [inValue, outValue]
			}
		}
		
		if revertEase {
			options.ease = options.ease.reversed
		}
	}
	
	private func preUpdateValues() {
		let delegate = options.delegate
		
		if deltaTime == 0.0 {
			if currentCycle == 0 {
				delegate?.tweenWillStart(self)
				if !isReady {
					setTargetValues(reverting: options.isReversed, revertEase: false)
				}
			} else {
				delegate?.tweenWillRepeat(self)
			}
		} else if deltaTime == duration && currentCycle >= options.repetitionCount {
			delegate?.tweenWillFinish(self)
		}
	}
	
	private func postUpdateValues() {
		let delegate = options.delegate
		
		if deltaTime == 0.0 && currentCycle == 0 {
			delegate?.tweenDidStart(self)
		} else if deltaTime == duration {
			if currentCycle >= options.repetitionCount {
				delegate?.tweenDidFinish(self)
			} else if currentCycle > 0 {
				delegate?.tweenDidRepeat(self)
			}
			
			finishCycle()
		}
	}
	
	fileprivate func updateTargetValues() {
		preUpdateValues()
		allValues.forEach {
			target?[keyPath: $0.key] = options.ease.easingFunction($0.value[0], $0.value[1], deltaTime, duration)
		}
		postUpdateValues()
	}
	
	private func timerCallBack() {
		guard target != nil else {
			stopTween(option: .current)
			return
		}
		
		guard !isPaused else { return }
		
		idleTime += TimerControl.shared.backgroundTime
		currentTime = CFAbsoluteTimeGetCurrent() - idleTime
		
		let delay = currentCycle == 0 ? options.delay : options.repetitionDelay
		guard delay <= currentTime else { return }
		
		beginTime = (beginTime == 0.0) ? currentTime : beginTime
		deltaTime = min(currentTime - beginTime, duration)
		
		DispatchQueue.asyncMainIfNeeded {
			self.updateTargetValues()
		}
	}
	
// MARK: - Exposed Methods
	
	public func restartTween() {
		resetTime()
		
		if isMirrored {
			setTargetValues(reverting: true, revertEase: options.repetition == .mirrorValuesAndEase)
			isMirrored = false
		}
		
		DispatchQueue.asyncMainIfNeeded {
			self.allValues.forEach {
				self.target?[keyPath: $0.key] = $0.value[0]
			}
		}
		
		currentCycle = 0
	}
	
	public func stopTween(option: TweenOption.State = .current) {
		
		switch option {
		case .end:
			if isMirrored {
				setTargetValues(reverting: true, revertEase: options.repetition == .mirrorValuesAndEase)
				isMirrored = false
			}
			
			if allValues.isEmpty {
				setTargetValues(reverting: options.isReversed, revertEase: false)
			}
			
			DispatchQueue.asyncMainIfNeeded {
				self.allValues.forEach {
					self.target?[keyPath: $0.key] = $0.value[0] + $0.value[1]
				}
			}
		default:
			break
		}
		
		Self.tweensQueue.sync(flags: .barrier) {
			Self.tweens.remove(self)
		}
		
		TimerControl.shared.removeItem(key: identifier)
	}
}

// MARK: - Extension - Tween (Hashable)

extension Tween : Hashable {
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(identifier)
	}
	
	public static func == (lhs: Tween, rhs: Tween) -> Bool {
		lhs.identifier == rhs.identifier
	}
}

// MARK: - Extension - Tween

public extension Tween {

	/// Returns all Tweens instances with the informed target.
	///
	/// - Parameter target: The target of the tween you are looking for.
	/// - Returns: The related Tween instance or nil if not found.
	static func tweens(withTarget target: UIView) -> [Tween] {
		return tweensQueue.sync(flags: .barrier) {
			tweens.filter { $0.target == target }
		}
	}
	
	/// Returns a Tween instance with the informed name.
	///
	/// - Parameter name: The name of the tween you are looking for.
	/// - Returns: The related Tween instance or nil if not found.
	static func tweens(withName name: String) -> [Tween] {
		return tweensQueue.sync(flags: .barrier) {
			tweens.filter { $0.options.name == name }
		}
	}
	
	/// Acts as ``stopTween()`` method, but working for all tweens of a specific target.
	///
	/// - Parameters:
	///   - option: The type of the stopping. The tween can stop at the very current moment with the current state.
	///    The finished state will send the target to the final state in the current tween loop.
	///   - target: The target which has tweens you want to remove.
	static func stopTweens(option: TweenOption.State = .current, withTarget target: UIView) {
		tweens(withTarget: target).forEach { $0.stopTween(option: option) }
	}
	
	/// Acts as ``stopTween()`` method, but working for all tweens with a specific name.
	///
	/// - Parameters:
	///   - option: The type of the stopping. The tween can stop at the very current moment with the current state.
	///    The finished state will send the target to the final state in the current tween loop.
	///   - name: The name of the tweens you want to remove.
	static func stopTweens(option: TweenOption.State = .current, withName name: String) {
		tweens(withName: name).forEach { $0.stopTween(option: option) }
	}
}
