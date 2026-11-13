(() => {
  const t = Date.now();
  const phase = (id, label, state, start, end) => ({ id, label, state, startedAt: start == null ? null : t - start, endedAt: end == null ? null : t - end });
  window.fusionLive({
    version: 1, run: "fixture-cooldown", runner: "xcode",
    state: "running",
    startedAt: t - 600000, updatedAt: t, cooldownEndsAt: t + 15000,
    phase: "cooldown-ios",
    phases: [
      phase("build-macos", "Build macOS", "done", 600000, 510000),
      phase("cooldown-macos", "Cooldown", "done", 510000, 490000),
      phase("measure-macos", "Measure macOS", "done", 490000, 200000),
      phase("build-ios", "Build iOS", "done", 200000, 5000),
      phase("cooldown-ios", "Cooldown", "running", 5000, null),
      phase("measure-ios", "Measure iOS", "pending", null, null),
      phase("parse", "Parse", "pending", null, null),
      phase("report", "Report", "pending", null, null)
    ],
    expected: { macOS: 34, iOS: 50 },
    env: { model: "Mac16,8", cpu: "Apple M4 Pro", cores: "12 physical, 12 logical", memoryGB: "24", macos: "27.0.1 (26A434)", xcode: "Xcode 27.2 Build version 27B52", swift: "Apple Swift version 6.4.2", power: "Now drawing from 'AC Power'", thermal: "No thermal warning level has been recorded", iosDevice: "iPhone 17 latest" },
    events: [],
    error: null
  });
})();
