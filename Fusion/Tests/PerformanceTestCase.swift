//
//  Created by Diney Bomfim on 11/13/26.
//

import XCTest

// MARK: - Type -

class PerformanceTestCase : XCTestCase {
	
// MARK: - Properties
	
	static let defaultIterations = 2_000
	
	static let measureCount = 5
	
	var metrics: [XCTMetric] {
		[XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric(), XCTStorageMetric()]
	}
	
// MARK: - Protected Methods
	
	private func options(manuallyStart: Bool) -> XCTMeasureOptions {
		let options = XCTMeasureOptions()
		options.iterationCount = Self.measureCount
		if manuallyStart {
			options.invocationOptions = [.manuallyStart]
		}
		return options
	}
	
	private func reportOperations(_ count: Int) {
		print("[Benchmark] \(type(of: self)) \(name) operations: \(count)")
		fflush(stdout)
	}
	
// MARK: - Exposed Methods
	
	func measureLoop(iterations: Int = defaultIterations, _ work: (Int) -> Void) {
		reportOperations(iterations)
		measure(metrics: metrics, options: options(manuallyStart: false)) {
			for index in 0..<iterations {
				work(index)
			}
		}
	}
	
	func measure(setUp: () -> Void, _ work: () -> Void) {
		reportOperations(1)
		measure(metrics: metrics, options: options(manuallyStart: true)) {
			setUp()
			startMeasuring()
			work()
		}
	}
	
	func drainMainQueue() {
		let drained = expectation(description: "drained")
		DispatchQueue.main.async { drained.fulfill() }
		wait(for: [drained], timeout: 60)
	}
}
