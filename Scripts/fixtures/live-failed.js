(() => {
  const t = Date.now();
  const phase = (id, label, state, start, end) => ({ id, label, state, startedAt: start == null ? null : t - start, endedAt: end == null ? null : t - end });
  window.fusionLive({
    version: 1, run: "fixture-failed", runner: "xcode",
    state: "failed",
    startedAt: t - 700000, updatedAt: t, cooldownEndsAt: null,
    phase: "measure-ios",
    phases: [
      phase("build-macos", "Build macOS", "done", 700000, 610000),
      phase("cooldown-macos", "Cooldown", "done", 610000, 590000),
      phase("measure-macos", "Measure macOS", "done", 590000, 300000),
      phase("build-ios", "Build iOS", "done", 300000, 120000),
      phase("cooldown-ios", "Cooldown", "done", 120000, 100000),
      phase("measure-ios", "Measure iOS", "failed", 100000, 0),
      phase("parse", "Parse", "skipped", null, null),
      phase("report", "Report", "skipped", null, null)
    ],
    expected: { macOS: 34, iOS: 50 },
    env: { model: "Mac16,8", cpu: "Apple M4 Pro", cores: "12 physical, 12 logical", memoryGB: "24", macos: "27.0.1 (26A434)", xcode: "Xcode 27.2 Build version 27B52", swift: "Apple Swift version 6.4.2", power: "Now drawing from 'AC Power'", thermal: "No thermal warning level has been recorded", iosDevice: "iPhone 17 latest" },
    events: [
      { t: t - 2000, kind: "started", platform: "iOS", suite: "ImagePipelinePerformanceTests", test: "testURLCacheLoadAndDecode" }
    ],
    error: "measure-ios failed"
  });
})();
