(() => {
  const t = Date.now();
  const phase = (id, label, state, start, end) => ({ id, label, state, startedAt: start == null ? null : t - start, endedAt: end == null ? null : t - end });
  window.fusionLive({
    version: 1, run: "fixture-running", runner: "command",
    state: "running",
    startedAt: t - 240000, updatedAt: t, cooldownEndsAt: null,
    phase: "measure-macos",
    phases: [
      phase("build-macos", "Build macOS", "done", 240000, 150000),
      phase("cooldown-macos", "Cooldown", "done", 150000, 130000),
      phase("measure-macos", "Measure macOS", "running", 130000, null),
      phase("build-ios", "Build iOS", "pending", null, null),
      phase("cooldown-ios", "Cooldown", "pending", null, null),
      phase("measure-ios", "Measure iOS", "pending", null, null),
      phase("parse", "Parse", "pending", null, null),
      phase("report", "Report", "pending", null, null)
    ],
    expected: { macOS: 34, iOS: 50 },
    env: { model: "Mac16,8", cpu: "Apple M4 Pro", cores: "12 physical, 12 logical", memoryGB: "24", macos: "27.0.1 (26A434)", xcode: "Xcode 27.2 Build version 27B52", swift: "Apple Swift version 6.4.2", power: "Now drawing from 'AC Power'", thermal: "No thermal warning level has been recorded", iosDevice: "iPhone 17 latest" },
    events: [
      { t: t - 9000, kind: "started", platform: "macOS", suite: "CorePerformanceTests", test: "testBase64Encode" },
      { t: t - 8990, kind: "ops", platform: "macOS", suite: "CorePerformanceTests", test: "testBase64Encode", ops: 2000 },
      { t: t - 8000, kind: "measured", platform: "macOS", suite: "CorePerformanceTests", test: "testBase64Encode", metric: "time", value: 73, rsd: 1.473, samples: [74, 71, 74, 73, 73] },
      { t: t - 7990, kind: "measured", platform: "macOS", suite: "CorePerformanceTests", test: "testBase64Encode", metric: "instructions", value: 3352, rsd: 0.758, samples: [3380, 3340, 3344, 3382, 3315] },
      { t: t - 7980, kind: "measured", platform: "macOS", suite: "CorePerformanceTests", test: "testBase64Encode", metric: "peak", value: 13213, rsd: 0.061, samples: [13223, 13223, 13206, 13206, 13206] },
      { t: t - 6000, kind: "started", platform: "macOS", suite: "CorePerformanceTests", test: "testJSONDecode" },
      { t: t - 5990, kind: "ops", platform: "macOS", suite: "CorePerformanceTests", test: "testJSONDecode", ops: 2000 },
      { t: t - 4000, kind: "measured", platform: "macOS", suite: "CorePerformanceTests", test: "testJSONDecode", metric: "time", value: 53229, rsd: 3.056, samples: [51000, 52000, 53000, 54000, 56145] },
      { t: t - 3990, kind: "measured", platform: "macOS", suite: "CorePerformanceTests", test: "testJSONDecode", metric: "instructions", value: 921293, rsd: 0.9, samples: [915000, 920000, 921000, 925000, 925465] },
      { t: t - 1000, kind: "started", platform: "macOS", suite: "CorePerformanceTests", test: "testJSONEncode" },
      { t: t - 990, kind: "ops", platform: "macOS", suite: "CorePerformanceTests", test: "testJSONEncode", ops: 2000 }
    ],
    error: null
  });
})();
