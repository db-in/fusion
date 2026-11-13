# Fusion Benchmarks

## Run

Pick one:

1. Double-click **`Run Benchmarks.command`**
2. In Xcode: scheme **Benchmarks** → **⌘B**

The dashboard opens as soon as the run starts and streams it live: builds, cooldowns, every test as it is measured. When the run finishes, the page reloads with the new history. Pressing Stop in Xcode, or Ctrl-C in Terminal, cancels the run without touching the history.

## Where results live

| File | What it is |
|---|---|
| [`report.html`](report.html) | Dashboard: orbit of every test, deep dive per test (Baseline · Best · Worst · Current), live runner, light/dark |
| [`HISTORY.md`](HISTORY.md) | Incremental log of every run |
| [`history.tsv`](history.tsv) | Machine-readable history behind Best / Worst |
| [`Baselines/2.1.1-M4Pro.md`](Baselines/2.1.1-M4Pro.md) | Pinned baseline |
| `Results/<run>/` | Raw logs for a single run |
| `.live/live.js` | Progress of the current run, polled by the dashboard (git-ignored) |

Always Release. macOS + iOS Simulator.

## Dashboard

The dashboard source lives in [`Report/`](Report): `index.html`, `styles.css` and `js/*.js`. `Scripts/benchmark.sh` inlines them, together with the history, into a single `report.html` that works straight from disk with no server.

Keyboard: `/` or `T` opens the test grid, arrows move, Enter opens the deep dive, Esc closes.

## Script options

| Command | What it does |
|---|---|
| `Scripts/benchmark.sh --report-only` | Re-renders `report.html` from the existing history |
| `Scripts/benchmark.sh --simulate [speed]` | Replays the baseline as a fake live run, without building or touching the history |
| `Scripts/benchmark.sh --fixture <state>` | Loads a static live state: `running`, `cooldown`, `done`, `failed` or `cancelled` |
| `--no-open` | Doesn't open the browser |
| `--device <name>`, `--os <version>` | iOS Simulator to run on |
| `--cooldown <secs>` | Rest between build and measure |
