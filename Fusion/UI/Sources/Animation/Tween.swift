//
//  Created by Diney Bomfim on 5/2/23.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

// MARK: - Definitions -

extension Dictionary where Key == String, Value == CGFloat {
	func merge(with other: Self, target: Tween.Target? = nil) -> [Key: [Value]] {
		var combined: [Key: [Value]] = [:]
		
		forEach {
			combined[$0.key] = [$0.value, target?[$0.key] ?? 0]
		}
		
		other.forEach {
			if combined[$0.key] == nil {
				combined[$0.key] = [target?[$0.key] ?? 0, $0.value]
			} else {
				combined[$0.key]?[1] = $0.value
			}
		}
		
		return combined
	}
}

public protocol TweenDelegate {
	func tween(_ tween: Tween, values: [String : CGFloat])
}

public extension TweenDelegate {
	func tween(_ tween: Tween, values: [String : CGFloat]) { }
}

public typealias TweenCallback = (Tween, [String : CGFloat]) -> Void

// MARK: - Type -

public class Tween {
	
	class Target {
		weak var view: UIView?
		let keyPathMap: [String : ReferenceWritableKeyPath<UIView, CGFloat>]
		
		subscript(_ key: String) -> CGFloat {
			get {
				guard let keyPath = keyPathMap[key] else { return 0 }
				return view?[keyPath: keyPath] ?? 0
			}
			set {
				guard let keyPath = keyPathMap[key] else { return }
				view?[keyPath: keyPath] = newValue
			}
		}
		
		init(view: UIView, paths: [[ReferenceWritableKeyPath<UIView, CGFloat> : CGFloat]]) {
			self.view = view
			self.keyPathMap = paths.reduce(into: [:]) { result, pathDict in pathDict.keys.forEach { result["\($0)"] = $0 } }
		}
	}
	
	public enum State {
		case starting
		case repeating
		case updating
		case ending
	}
	
	public enum Behavior {
		case current
		case final
	}
	
	public enum Repetition {
		case loop
		case mirrorValues
		case mirrorValuesAndEase
	}
	
	public struct Option {
		public var name: String?
		public var ease: Ease
		public var delay: FPoint
		public var isPaused: Bool
		public var isReversed: Bool
		public var isRelative: Bool
		public var repetition: Tween.Repetition?
		public var repetitionCount: UInt32
		public var repetitionDelay: FPoint
		public var endState: Tween.Behavior
		public var delegate: TweenDelegate?
		
		public init(name: String? = nil,
					ease: Ease = .linear,
					delay: FPoint = 0,
					isPaused: Bool = false,
					isReversed: Bool = false,
					isRelative: Bool = false,
					repetition: Tween.Repetition? = nil,
					repetitionCount: UInt32 = 0,
					repetitionDelay: FPoint = 0,
					endState: Tween.Behavior = .current,
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
	
// MARK: - Properties
	
	private var target: Target?
	private var callback: TweenCallback?
	private var allValues: [String : [CGFloat]] = [:]
	private static var tweens: Set<Tween> = []
	
	@ThreadSafe
	private static var tweensQueue: DispatchQueue = .init(label: "tween.\(UUID().uuidString)", attributes: .concurrent)

	public let identifier: String = UUID().uuidString
	public var duration: FPoint
	public var options: Option
	public var fromValues: [String : CGFloat]
	public var toValues: [String : CGFloat]
	public var targetView: UIView? { target?.view }
	public private(set) var isReady: Bool = true
	public private(set) var isMirrored: Bool = false
	public private(set) var deltaTime: FPoint = 0
	public private(set) var beginTime: FPoint = 0
	public private(set) var currentTime: FPoint = 0
	public private(set) var lastTime: FPoint = 0
	public private(set) var idleTime: FPoint = 0
	public private(set) var currentCycle: UInt32 = 0
	
	public var currentState: State {
		switch (deltaTime, currentCycle) {
		case (0.0, 0):
			return .starting
		case (0.0, _):
			return .repeating
		case (duration, let cycle) where cycle > 0:
			return .repeating
		case (duration, let cycle) where cycle >= options.repetitionCount:
			return .ending
		default:
			return .updating
		}
	}
	
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
	///   - options: The tween options. See ``TweenOption``.
	///   - fromValues: A dictionary defining the values from where the tween will start. If none is provided, the current values will be used.
	///   - toValues: A dictionary defining the values to where the ween will end.
	@discardableResult public init(_ targetView: UIView,
								   duration: FPoint,
								   options: Option = .init(),
								   fromValues: [ReferenceWritableKeyPath<UIView, CGFloat> : CGFloat] = [:],
								   toValues: [ReferenceWritableKeyPath<UIView, CGFloat> : CGFloat] = [:]) {
		self.duration = duration
		self.options = options
		self.target = .init(view: targetView, paths: [fromValues, toValues])
		self.fromValues = fromValues.reduce(into: [:]) { $0["\($1.key)"] = $1.value }
		self.toValues = toValues.reduce(into: [:]) { $0["\($1.key)"] = $1.value }
		startTween()
	}
	
	@discardableResult public init(duration: FPoint,
								   options: Option = .init(),
								   fromValues: [String : CGFloat] = [:],
								   toValues: [String : CGFloat] = [:],
								   callback: TweenCallback? = nil) {
		self.duration = duration
		self.options = options
		self.callback = callback
		self.fromValues = fromValues
		self.toValues = toValues
		startTween()
	}
	
// MARK: - Protected Methods
	
	private func startTween() {
		isReady = false
		currentCycle = 0
		resetTime()
		Self.tweens.insert(self)
		updateTargetValues()
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
			stopTween(option: options.endState)
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
				let originalValue = target?[$0.key] ?? 0
				let fromValue = isRelative ? originalValue + $0.value[0] : $0.value[0]
				let toValue = isRelative ? originalValue + $0.value[1] : $0.value[1]
				let inValue = reverting ? toValue : fromValue
				let outValue = reverting ? fromValue - toValue : toValue - fromValue
				
				target?[$0.key] = inValue
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
		guard currentState == .starting && !isReady else { return }
		setTargetValues(reverting: options.isReversed, revertEase: false)
	}
	
	private func postUpdateValues() {
		guard currentState != .starting && deltaTime == duration else { return }
		finishCycle()
	}
	
	private func updateTargetValues() {
		preUpdateValues()
		var currentValues: [String : CGFloat] = [:]
		allValues.forEach {
			let value = options.ease.calculate($0.value[0], $0.value[1], deltaTime, duration)
			currentValues[$0.key] = value
			target?[$0.key] = value
		}
		options.delegate?.tween(self, values: currentValues)
		callback?(self, currentValues)
		postUpdateValues()
	}
	
	private func timerCallBack() {
		if target != nil && target?.view == nil {
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
				self.target?[$0.key] = $0.value[0]
			}
		}
		
		currentCycle = 0
	}
	
	public func stopTween(option: Tween.Behavior = .current) {
		
		switch option {
		case .final:
			if isMirrored {
				setTargetValues(reverting: true, revertEase: options.repetition == .mirrorValuesAndEase)
				isMirrored = false
			}
			
			if allValues.isEmpty {
				setTargetValues(reverting: options.isReversed, revertEase: false)
			}
			
			DispatchQueue.asyncMainIfNeeded {
				self.allValues.forEach {
					self.target?[$0.key] = $0.value[0] + $0.value[1]
				}
			}
		default:
			break
		}
		
		_ = Self.tweensQueue.sync(flags: .barrier) {
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
}

// MARK: - Extension - Tween

public extension Tween {

	/// Returns all Tweens instances with the informed target.
	///
	/// - Parameter target: The target of the tween you are looking for.
	/// - Returns: The related Tween instance or nil if not found.
	static func tweens(withTarget target: UIView) -> [Tween] {
		return tweensQueue.sync(flags: .barrier) {
			tweens.filter { $0.targetView == target }
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
	static func stopTweens(option: Tween.Behavior = .current, withTarget target: UIView) {
		tweens(withTarget: target).forEach { $0.stopTween(option: option) }
	}
	
	/// Acts as ``stopTween()`` method, but working for all tweens with a specific name.
	///
	/// - Parameters:
	///   - option: The type of the stopping. The tween can stop at the very current moment with the current state.
	///    The finished state will send the target to the final state in the current tween loop.
	///   - name: The name of the tweens you want to remove.
	static func stopTweens(option: Tween.Behavior = .current, withName name: String) {
		tweens(withName: name).forEach { $0.stopTween(option: option) }
	}
}

extension Tween.State: CustomStringConvertible {
	
	public var description: String {
		switch self {
		case .starting: return "starting 🟢"
		case .updating: return "updating ⚡️"
		case .repeating: return "repeating 🔄"
		case .ending: return "ending 🏁"
		}
	}
}

extension Tween.Behavior: CustomStringConvertible {
	
	public var description: String {
		switch self {
		case .current: return "current ⏺️"
		case .final: return "final 🎯"
		}
	}
}

extension Tween.Repetition: CustomStringConvertible {
	
	public var description: String {
		switch self {
		case .loop: return "loop 🔁"
		case .mirrorValues: return "mirror 🪞"
		case .mirrorValuesAndEase: return "mirrorWithEase ✨"
		}
	}
}

extension Tween : CustomStringConvertible {
	
	public var description: String {
		let address = "\(Unmanaged.passUnretained(self).toOpaque())"
		let name = options.name.map { " name = '\($0)'" } ?? ""
		let target = targetView.map { String(describing: type(of: $0)) } ?? "callback"
		let progress = duration > 0 ? Int((deltaTime / duration) * 100) : 0
		let components = [
			"ease = \(options.ease) 📈",
			"state = \(currentState)",
			"duration = \(String(format: "%.2f", duration))s ⏱️",
			"\(isPaused ? "paused ⏸️" : "running ▶️") = \(String(format: "%.2f", deltaTime))s (\(progress)%)",
			"cycle = \(currentCycle)/\(options.repetitionCount == .max ? "∞" : "\(options.repetitionCount)") 🔄",
			"endState = \(options.endState)",
			options.delay > 0 ? "delay = \(String(format: "%.2f", options.delay))s ⏲️" : nil,
			options.repetitionDelay > 0 ? "repeatDelay = \(String(format: "%.2f", options.repetitionDelay))s ⌛️" : nil,
			options.isReversed ? "reversed ◀️" : nil,
			options.isRelative ? "relative 🔗" : nil,
			"repetition = \(options.repetition?.description ?? "none")"
		].compactMap { $0 }
		
		let values = allValues.map { key, values in
			"\(key): \(String(format: "%.2f", values[0])) → \(String(format: "%.2f", values[0] + values[1]))"
		}.joined(separator: "; ")
		
		return "<Tween: \(address)\(name) target=\(target); \(components.joined(separator: "; ")); values = {\(values)}>"
	}
}
#endif
