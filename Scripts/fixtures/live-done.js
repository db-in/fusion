(() => {
  const t = Date.now();
  const phase = (id, label, start, end) => ({ id, label, state: "done", startedAt: t - start, endedAt: t - end });
  window.fusionLive({
    version: 1, run: "fixture-done", runner: "command",
    state: "done",
    startedAt: t - 1200000, updatedAt: t, cooldownEndsAt: null,
    phase: "report",
    phases: [
      phase("build-macos", "Build macOS", 1200000, 1110000),
      phase("cooldown-macos", "Cooldown", 1110000, 1090000),
      phase("measure-macos", "Measure macOS", 1090000, 800000),
      phase("build-ios", "Build iOS", 800000, 600000),
      phase("cooldown-ios", "Cooldown", 600000, 580000),
      phase("measure-ios", "Measure iOS", 580000, 4000),
      phase("parse", "Parse", 4000, 2000),
      phase("report", "Report", 2000, 0)
    ],
    expected: { macOS: 34, iOS: 50 },
    env: { model: "Mac16,8", cpu: "Apple M4 Pro", cores: "12 physical, 12 logical", memoryGB: "24", macos: "27.0.1 (26A434)", xcode: "Xcode 27.2 Build version 27B52", swift: "Apple Swift version 6.4.2", power: "Now drawing from 'AC Power'", thermal: "No thermal warning level has been recorded", iosDevice: "iPhone 17 latest" },
    events: [],
    error: null
  });
})();
