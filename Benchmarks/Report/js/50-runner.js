const PHASES = [
	{ id: "build-macos", label: "Build macOS", hint: "swift build -c release" },
	{ id: "cooldown-macos", label: "Cooldown", hint: "let the CPU settle" },
	{ id: "measure-macos", label: "Measure macOS", hint: "swift test, 5 iterations" },
	{ id: "build-ios", label: "Build iOS", hint: "xcodebuild build-for-testing" },
	{ id: "cooldown-ios", label: "Cooldown", hint: "let the CPU settle" },
	{ id: "measure-ios", label: "Measure iOS", hint: "test-without-building" },
	{ id: "parse", label: "Parse", hint: "per-op history rows" },
	{ id: "report", label: "Report", hint: "render report.html" }
];

const Rail = (() => {
	const rail = $("#rail");
	let last = "";

	function render() {
		const runs = Model.runIds.slice();
		const scored = runs.filter(r => r !== Model.baselineRun && r !== State.live?.run)
			.map(r => ({ r, s: Model.runScore(r, State.platform, State.metric) }))
			.filter(x => Number.isFinite(x.s));
		const best = scored.length > 1 ? scored.reduce((a, b) => (b.s < a.s ? b : a)).r : null;
		const worst = scored.length > 1 ? scored.reduce((a, b) => (b.s > a.s ? b : a)).r : null;
		const ordered = runs.slice().reverse();
		const animate = !last;
		const html = `<h3>Runs · ${runs.length}</h3><div class="rail-list">${ordered.map((r, i) => {
			const meta = Model.meta.get(r);
			const isBase = r === Model.baselineRun, isLive = r === State.live?.run;
			const liveState = isLive ? State.live.state : null;
			const liveLabel = liveState === "failed" ? "Failed" : liveState === "cancelled" ? "Cancelled" : liveState === "done" ? "Done" : "Live";
			const score = isBase ? null : Model.runScore(r, State.platform, State.metric);
			const delta = Number.isFinite(score) ? (score - 1) * 100 : null;
			const tags = [isBase ? `<span class="tag base">Baseline</span>` : "", isLive ? `<span class="tag live ${esc(liveState || "")}">${liveLabel}</span>` : "", r === best ? `<span class="tag best">Best</span>` : "", r === worst ? `<span class="tag worst">Worst</span>` : ""].join("");
			const when = meta?.date ? new Date(meta.date) : null;
			const motion = animate ? `animation-delay:${i * 40}ms` : "animation:none";
			return `<button class="run${isBase ? " base" : ""}${isLive ? " live" : ""}" type="button" data-run="${esc(r)}" aria-current="${r === State.run}" style="${motion}">
				<b>${esc(isBase ? r : shortRun(r))}</b>
				<small>${esc(when ? when.toLocaleDateString(undefined, { month: "short", day: "numeric" }) + " · " + when.toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit" }) : liveLabel === "Live" ? "in progress" : liveLabel.toLowerCase())}${delta != null ? ` · ${esc(fmtDelta(delta))}` : ""}</small>
				${tags ? `<span class="tags">${tags}</span>` : ""}
			</button>`;
		}).join("")}</div><p class="rail-note">Pick a run to compare it against the pinned baseline. Best and worst use the geometric mean of ${esc(METRICS[State.metric].label.toLowerCase())} ratios.</p>`;
		if (html === last) return;
		last = html;
		rail.innerHTML = html;
	}

	rail.addEventListener("click", e => {
		const b = e.target.closest("[data-run]");
		if (!b || b.dataset.run === State.run) return;
		State.run = b.dataset.run;
		Bus.emit("change");
	});

	return { render };
})();

const Desk = (() => {
	const desk = $("#desk");
	let timer = null, last = "";

	function machine(env, run) {
		if (!env) return `<div class="machine"><h3>Machine</h3><b>Unknown machine</b></div>`;
		const thermal = /warning level has been recorded/i.test(env.thermal || "") || !env.thermal ? "Thermal nominal" : env.thermal;
		const onBattery = /battery/i.test(env.power || "");
		return `<div class="machine"><h3>Machine</h3><b>${esc(env.cpu || env.model || "Mac")}</b>
			<div class="chip-row">
				<span class="chip">${esc(env.model || "?")}</span>
				<span class="chip">${esc(String(env.cores || "").replace(" physical, ", "P / ").replace(" logical", "L"))}</span>
				<span class="chip">${esc(env.memoryGB)} GB</span>
				<span class="chip">macOS ${esc(String(env.macos || "").split(" ")[0])}</span>
				<span class="chip">${esc(String(env.xcode || "").replace(/ Build version.*/, ""))}</span>
				<span class="chip">${esc(env.iosDevice || "")}</span>
				<span class="chip${onBattery ? " warn" : ""}">${onBattery ? "On battery" : "AC power"}</span>
				<span class="chip${thermal === "Thermal nominal" ? "" : " warn"}">${esc(thermal)}</span>
			</div>
			${run ? `<small class="mono" style="color:var(--ink-3)">${esc(run)}</small>` : ""}</div>`;
	}

	function phaseState(live, id) {
		if (!live) return "done";
		return live.phases?.find(p => p.id === id)?.state || "pending";
	}

	function duration(live, id) {
		const p = live?.phases?.find(x => x.id === id);
		if (!p?.startedAt) return "";
		const end = p.endedAt || Date.now();
		return clock((end - p.startedAt) / 1000);
	}

	function cooldown(live) {
		if (!live || !live.cooldownEndsAt || !/^cooldown/.test(live.phase || "")) return "";
		const left = (live.cooldownEndsAt - Date.now()) / 1000;
		if (left <= 0) return "";
		const total = Math.max(left, ((live.cooldownEndsAt - (live.phases.find(p => p.id === live.phase)?.startedAt || Date.now())) / 1000) || 20);
		const pct = Math.max(0, Math.min(100, (left / total) * 100));
		return `<div class="cool"><svg viewBox="0 0 54 54"><circle cx="27" cy="27" r="23"/><circle cx="27" cy="27" r="23" pathLength="100" style="stroke-dasharray:${pct.toFixed(1)} 100"/></svg><div><b>${clock(left)}</b><small>Cooling down so thermals and caches settle before measuring.</small></div></div>`;
	}

	function runner(kind) {
		if (kind === "xcode") return `<div class="note">Started from <b>Xcode ⌘B</b> on the <b>Benchmarks</b> scheme. Press Stop in Xcode to cancel.</div>`;
		if (kind === "command") return `<div class="note">Started from <b>Run Benchmarks.command</b>. Press Ctrl-C in Terminal to cancel.</div>`;
		if (kind === "replay") return `<div class="note">This is a <b>replay</b> of a recorded run, animated from its saved results.</div>`;
		return `<div class="note">Start a run with <b>Run Benchmarks.command</b> or <b>⌘B</b> on the <b>Benchmarks</b> scheme. This page opens and streams it live.</div>`;
	}

	function gates() {
		const list = Model.list(State.platform);
		const check = (metric, limit) => {
			const rows = list.map(i => {
				const v = Model.value(i, State.run, metric), b = Model.value(i, Model.baselineRun, metric);
				return Number.isFinite(v) && b ? ((v - b) / b) * 100 : null;
			}).filter(x => x != null);
			const failed = rows.filter(d => d > limit).length;
			return { failed, total: rows.length, pass: rows.length ? (rows.length - failed) / rows.length : 1 };
		};
		const g = [
			{ label: "Instructions", limit: 10, kind: "Primary", ...check("instructions", 10) },
			{ label: "Wall time", limit: 25, kind: "Secondary", ...check("time", 25) }
		];
		return `<div class="gates"><h3>Regression gates · ${esc(State.platform)}</h3>${g.map(x => `<div class="gate"><span>${x.kind} · ${x.label} &gt; +${x.limit}%</span><div class="bar"><span style="width:${(x.pass * 100).toFixed(0)}%;background:${x.failed ? "var(--bad)" : "var(--ok)"}"></span></div><b>${x.failed ? `${x.failed} over` : "pass"}</b></div>`).join("")}</div>`;
	}

	function markup(live) {
		const env = live?.env && Object.keys(live.env).length ? live.env : Model.meta.get(State.run) || Model.meta.get(Model.baselineRun);
		const steps = PHASES.map((p, i) => {
			const st = phaseState(live, p.id);
			return `<div class="step" data-state="${st}" style="animation-delay:${i * 30}ms"><i></i><span>${esc(p.label)}<br><small>${esc(p.hint)}</small></span><small>${live ? esc(duration(live, p.id)) : ""}</small></div>`;
		}).join("");
		return `
			${machine(env, live?.run || State.run)}
			<div><h3>Pipeline${live ? ` · ${esc(live.state)}` : " · completed run"}</h3><div class="pipeline">${steps}</div></div>
			${cooldown(live)}
			${live?.error ? `<div class="error">${esc(live.error)}</div>` : ""}
			${runner(live?.runner || Model.meta.get(State.run)?.runner || null)}
			<details class="explain"><summary>How the runner works</summary><ol>
				<li>Builds the macOS tests in Release with testability, then rests for a cooldown.</li>
				<li>Runs every <code>*PerformanceTests</code> case: 5 measured iterations of a fixed loop, timed by XCTest clock, CPU, memory and storage metrics.</li>
				<li>Repeats on the iOS Simulator with the <code>FusionBenchmarks</code> test plan.</li>
				<li>Divides every metric by the operations in the loop, so each number is the cost of one call.</li>
				<li>Appends a row per test to <code>history.tsv</code> and <code>HISTORY.md</code>, then re-renders this page.</li>
				<li>Streams progress to <code>.live/live.js</code>, which this page polls once a second.</li>
			</ol></details>
			${gates()}`;
	}

	function fingerprint(live) {
		const env = live?.env && Object.keys(live.env).length ? live.env : Model.meta.get(State.run) || Model.meta.get(Model.baselineRun);
		const phases = (live?.phases || []).map(p => `${p.id}:${p.state}`).join(",");
		const g = gates();
		return `${live?.run || State.run}|${live?.state || ""}|${live?.phase || ""}|${phases}|${live?.error || ""}|${!!live?.cooldownEndsAt}|${live?.runner || ""}|${env?.cpu || ""}|${State.platform}|${State.metric}|${g}`;
	}

	function render() {
		const live = State.live;
		const key = fingerprint(live);
		if (key === last) {
			arm(live);
			return;
		}
		const first = !last;
		last = key;
		desk.innerHTML = markup(live);
		if (!first) $$(".step, .gate .bar span, .cool", desk).forEach(n => { n.style.animation = "none"; });
		arm(live);
	}

	function arm(live) {
		clearInterval(timer);
		timer = null;
		if (live && ["starting", "running"].includes(live.state)) timer = setInterval(tick, 1000);
	}

	function tick() {
		const live = State.live;
		if (!live) return;
		$$(".step", desk).forEach((s, i) => {
			const st = phaseState(live, PHASES[i].id);
			if (s.dataset.state !== st) s.dataset.state = st;
			const d = s.lastElementChild;
			if (d && st === "running") d.textContent = duration(live, PHASES[i].id);
		});
		const title = $("h3", desk);
		if (title && title.textContent.startsWith("Pipeline")) title.textContent = `Pipeline · ${live.state}`;
		const old = $(".cool", desk), next = cooldown(live);
		if (old && next) {
			const tmp = el("div", null, next).firstElementChild;
			old.querySelector("b").textContent = tmp.querySelector("b").textContent;
			old.querySelector("circle + circle").style.strokeDasharray = tmp.querySelector("circle + circle").style.strokeDasharray;
		} else if (old && !next) old.remove();
		else if (!old && next) {
			const note = $(".note", desk);
			const node = el("div", null, next).firstElementChild;
			if (note) note.before(node);
			else desk.append(node);
		}
	}

	return { render };
})();
