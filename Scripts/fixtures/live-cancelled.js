(() => {
  const t = Date.now();
  const phase = (id, label, state, start, end) => ({ id, label, state, startedAt: start == null ? null : t - start, endedAt: end == null ? null : t - end });
  window.fusionLive({
    version: 1, run: "fixture-cancelled", runner: "xcode",
    state: "cancelled",
    startedAt: t - 400000, updatedAt: t, cooldownEndsAt: null,
    phase: "build-ios",
    phases: [
      phase("build-macos", "Build macOS", "done", 400000, 310000),
      phase("cooldown-macos", "Cooldown", "done", 310000, 290000),
      phase("measure-macos", "Measure macOS", "done", 290000, 60000),
      phase("build-ios", "Build iOS", "failed", 60000, 0),
      phase("cooldown-ios", "Cooldown", "skipped", null, null),
      phase("measure-ios", "Measure iOS", "skipped", null, null),
      phase("parse", "Parse", "skipped", null, null),
      phase("report", "Report", "skipped", null, null)
    ],
    expected: { macOS: 34, iOS: 50 },
    env: { model: "Mac16,8", cpu: "Apple M4 Pro", cores: "12 physical, 12 logical", memoryGB: "24", macos: "27.0.1 (26A434)", xcode: "Xcode 27.2 Build version 27B52", swift: "Apple Swift version 6.4.2", power: "Now drawing from 'AC Power'", thermal: "No thermal warning level has been recorded", iosDevice: "iPhone 17 latest" },
    events: [],
    error: "cancelled"
  });
})();
