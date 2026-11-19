# Performance requirements

Performance is a feature of Fusion, not a polish step. Every API that can run on the main thread is held to a budget, and every hot path is measured. This document is the contract for anyone changing the framework, including AI agents.

## The main thread is sacred

The main thread renders frames. At 120 Hz a frame has **8.3 ms** for everything: the app's own work, layout, SwiftUI diffing, and drawing. Fusion is a dependency, so it gets a tiny slice of that, shared by every label, cell, and animation on screen at once.

Anything that can run on the main thread must be treated as if it runs **inside a frame, many times, on the slowest supported device**. That includes:

- SwiftUI `body`, view modifiers, `Animatable` / `TextRenderer` / `Shape` drawing.
- UIKit `layoutSubviews`, `draw(_:)`, `cellForRow`, `sizeThatFits`, and any setter that triggers them.
- `Tween` / display-link ticks, delegates, and callbacks dispatched to main.
- Anything `@MainActor`, or called from any of the above.

## Budgets

Per call, per instance, Release, measured with the Benchmarks suite:

| Where it runs | Budget | Examples |
|---|---|---|
| Every frame (tick, draw, animating `body`) | **≤ 5 µs**, no avoidable allocation | Tween tick, counting/scramble frame, renderer `draw` |
| Once per interaction or value change | **≤ 50 µs** | Parsing a new value, preparing an animation, cache lookups |
| Once per screen or view appearance | **≤ 1 ms** | Building a view model, first layout |
| Anything slower | **off the main thread** | Disk, network, JSON, image decode, hashing, large formatting batches |

A budget is a ceiling, not a target. If something can be 10x cheaper with reasonable code, make it 10x cheaper.

## Rules

### Measure, don't guess
- Every hot path has a benchmark in a `*PerformanceTests` suite. A new main-thread feature ships with its benchmark.
- Optimize with before and after numbers from the same machine and configuration. Put both in the PR.
- Regression gates: **instructions retired +10%** fails (primary, stable across runs), **wall time +25%** fails (secondary).

### Do work once, not per frame
- Parse, convert, detect, and format-setup when the input changes, then keep the result. Per-frame code only does the part that actually changes.
- Never convert `NSAttributedString` to `AttributedString`, compile a regex, create a formatter, load a font, or build a lookup table inside a frame. Cache them as `static let` or precompute them on change.
- Cache by input. If the same input can arrive twice, the second call should be a lookup.

### Allocate nothing you don't need
- No intermediate arrays in draw or tick loops (`flatMap`, `filter`, `map` chains). Use plain loops and counters.
- `reserveCapacity` when the final size is known. Prefer static tables over building strings or arrays per call.
- Prefer value types and stack storage. Avoid boxing, existentials, and `AnyView` in hot paths.

### Let the system animate
- Prefer animations SwiftUI or Core Animation interpolate themselves (`contentTransition`, `Animatable`, `animatableData`, `TextRenderer`, `CALayer` animations). They do not re-run `body` per frame.
- When state must change per frame (for example, a tween), make the state as small as possible and keep the derived view cheap.
- Keep identity stable (`ForEach` ids, `.task(id:)`) so SwiftUI updates instead of rebuilding.
- Keep `body` pure and cheap: no I/O, no parsing, no logging, no conversions.

### Keep heavy work off main
- Disk, network, decoding, hashing, and large formatting batches run in the background and hop to main only to publish the result.
- Never block main on a lock held by background work. Coalesce writes.

### Reach further when needed
If the standard approach cannot meet the budget, use a better technique: split work into precomputed segments, move work to render-time renderers, use lookup tables, downsample before decoding, use incremental or lazy evaluation, use SIMD or `Accelerate`, or go lower level (Core Text, Core Animation, Metal). Document why in the PR, with numbers.

## Case study: `textAnimated`

The counting and scramble styles rebuild the label on every tween tick, up to 120 times per second per label. Numbers below are helper costs measured with `measureLoop` (iPhone simulator, Release), per operation.

| Benchmark | First cut | After segment split | After quantized skip |
|---|---:|---:|---:|
| Counting frame (every digit changes) | ~15.3 µs / ~288k instr | ~5.0 µs / ~96k instr | ~5.0 µs / ~96k instr |
| Counting frame (same visible digits) | (same as above) | (same as above) | **~0.5 µs / ~11k instr** |
| Scramble frame | ~15.3 µs / ~290k instr | ~5.0 µs / ~96k instr | ~5.0 µs / ~96k instr |
| Prepare (once per value change) | ~2.9 µs | ~20 µs | ~21 µs |
| Odometer glyph split | ~0.5 µs / ~16k instr | ~0.5 µs / ~16k instr | **~0.25 µs / ~9k instr** |

What changed:
1. **Segment split** — convert the template once per value change into prefix, number style, and suffix. Frames only build the number run.
2. **Quantized skip** — counting compares a truncated numeric key before calling `NumberFormatter` or rebuilding `AttributedString`. Real tweens spend many frames on the same visible digits; those frames drop well under the 5 µs budget.
3. **Odometer prep** — glyph lists and digit `AttributedString`s are built once on change (digit runs only for the odometer style). Body no longer reallocates them.
4. **Wave** — `Text + Text` instead of localized interpolation; glyph count is passed into the renderer so draw does one pass.

## Adding a benchmark

1. Add a `test...` method to the matching suite in `Fusion/Tests/*PerformanceTests.swift` using `measureLoop` (2,000 iterations by default). Measure exactly the code that runs in production, not a copy of it.
2. Add an entry to `CATALOG` in [`Benchmarks/Report/js/10-data.js`](Benchmarks/Report/js/10-data.js) explaining what it measures, how, and why it matters.
3. New suites must be listed in `FusionBenchmarks.xctestplan`.
4. Run the **Benchmarks** scheme and keep [`Benchmarks/report.html`](Benchmarks/report.html) honest. See [Benchmarks/README.md](Benchmarks/README.md).
