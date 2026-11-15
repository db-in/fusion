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
			const tags = [
				isBase ? `<span class="tag base" title="Pinned comparison baseline (oldest run in history)">Baseline</span>` : "",
				isLive ? `<span class="tag live ${esc(liveState || "")}" title="Run currently streaming from the Benchmarks scheme">${liveLabel}</span>` : "",
				r === best ? `<span class="tag best" title="Best score for the selected metric among finished runs">Best</span>` : "",
				r === worst ? `<span class="tag worst" title="Worst score for the selected metric among finished runs">Worst</span>` : ""
			].join("");
			const when = meta?.date ? new Date(meta.date) : null;
			const motion = animate ? `animation-delay:${i * 40}ms` : "animation:none";
			const whenLabel = when
				? when.toLocaleDateString(undefined, { month: "short", day: "numeric" }) + " · " + when.toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit" })
				: (liveLabel === "Live" ? "in progress" : liveLabel.toLowerCase());
			return `<button class="run${isBase ? " base" : ""}${isLive ? " live" : ""}" type="button" data-run="${esc(r)}" aria-current="${r === State.run}" style="${motion}" title="${esc(r)}">
				<b>${esc(isBase ? r : shortRun(r))}</b>
				<small>${esc(whenLabel)}${delta != null ? ` · ${esc(fmtDelta(delta))}` : ""}</small>
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

	function known(v) {
		const s = String(v ?? "").trim();
		return s && !/^(\?|unknown|0)$/i.test(s) && !/^\?\s*physical/i.test(s) ? s : "";
	}

	function chip(text, title, warn = false) {
		return text ? `<span class="chip${warn ? " warn" : ""}" title="${esc(title)}">${esc(text)}</span>` : "";
	}

	function machine(env, run) {
		const e = env || {};
		const cpu = known(e.cpu), model = known(e.model), cores = known(e.cores), memory = known(e.memoryGB);
		const macos = known(e.macos), xcode = known(e.xcode), device = known(String(e.iosDevice || "").replace(/\s+latest$/, ""));
		const power = known(e.power), thermalRaw = known(e.thermal);
		const onBattery = /battery/i.test(power);
		const thermal = thermalRaw ? (/warning level has been recorded/i.test(thermalRaw) ? "Thermal nominal" : thermalRaw) : "";
		const title = cpu || model || "Unknown machine";
		const chips = [
			cpu && model ? chip(model, `Hardware model identifier · ${cpu}`) : "",
			chip(cores.replace(" physical, ", "P / ").replace(" logical", "L"), cores.replace(" physical, ", " physical cores / ").replace(/ logical$/, " logical cores")),
			chip(memory ? `${memory} GB` : "", "System memory"),
			chip(macos ? `macOS ${macos.split(" ")[0]}` : "", `macOS ${macos}`),
			chip(xcode.replace(/ Build version.*/, ""), xcode),
			chip(device, "Simulator or device destination used for this run"),
			power ? chip(onBattery ? "On battery" : "AC power", onBattery ? "Running on battery — thermals and clocks may throttle performance" : "Plugged into AC power — preferred for stable benchmarks", onBattery) : "",
			chip(thermal, `${thermalRaw}${thermal === "Thermal nominal" ? " — OK for performance runs" : ""}`, thermal && thermal !== "Thermal nominal")
		].join("");
		return `<div class="machine"><h3>Machine</h3><b title="${esc(title)}">${esc(title)}</b>
			${chips ? `<div class="chip-row">${chips}</div>` : ""}
			${run ? `<small class="mono" style="color:var(--ink-3)" title="${esc(run)}">${esc(shortRun(run))}</small>` : ""}</div>`;
	}

	function envFor(live) {
		const base = Model.meta.get(State.run) || Model.meta.get(Model.baselineRun) || {};
		const fresh = Object.fromEntries(Object.entries(live?.env || {}).filter(([, v]) => known(v)));
		const merged = { ...base, ...fresh };
		return Object.values(merged).some(known) ? merged : null;
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

	function isBuild(id) {
		return /^build-/.test(id || "");
	}

	function clip(text, n = 40) {
		const s = String(text || "");
		return s.length > n ? `${s.slice(0, Math.max(1, n - 1))}…` : s;
	}

	function stepHint(p, live, st) {
		if (st === "running" && /^measure-/.test(p.id)) {
			const t = live?.tests;
			if (t && (t.total || t.passed || t.failed)) {
				const done = (t.passed || 0) + (t.failed || 0) + (t.skipped || 0);
				return `${done}/${t.total || "?"} · ${t.passed || 0} passed · ${t.failed || 0} failed`;
			}
		}
		return p.hint || "";
	}

	function stepCurrent(p, live, st) {
		if (st !== "running" || !/^measure-/.test(p.id)) return "";
		return String(live?.tests?.current || "");
	}

	function stepLabelHtml(p, live, st) {
		const hint = stepHint(p, live, st);
		const cur = stepCurrent(p, live, st);
		const more = cur
			? `<details class="step-more"><summary><span>${esc(clip(cur))}</span></summary><code>${esc(cur)}</code></details>`
			: "";
		return `${esc(p.label)}<br><small class="step-hint">${esc(hint)}</small>${more}`;
	}

	function syncStepBody(node, p, live, st) {
		const span = node.querySelector(":scope > span");
		if (!span) return;
		const hint = span.querySelector(":scope > .step-hint");
		const nextHint = stepHint(p, live, st);
		if (hint) {
			if (hint.textContent !== nextHint) hint.textContent = nextHint;
		} else {
			span.innerHTML = stepLabelHtml(p, live, st);
			return;
		}
		const cur = stepCurrent(p, live, st);
		let more = span.querySelector(":scope > .step-more");
		if (!cur) {
			if (more) more.remove();
			return;
		}
		if (!more) {
			more = document.createElement("details");
			more.className = "step-more";
			more.innerHTML = `<summary><span></span></summary><code></code>`;
			span.append(more);
		}
		const label = more.querySelector("summary > span");
		const code = more.querySelector("code");
		const short = clip(cur);
		if (label && label.textContent !== short) label.textContent = short;
		if (code && code.textContent !== cur) code.textContent = cur;
	}

	function buildingBanner(live) {
		if (!live || !["starting", "running"].includes(live.state) || !isBuild(live.phase)) return "";
		const step = PHASES.find(p => p.id === live.phase);
		const elapsed = duration(live, live.phase) || "0:00";
		return `<div class="building" data-banner="build" data-phase="${esc(live.phase)}"><div class="building-bar" aria-hidden="true"></div><div class="building-copy"><b>Building</b><small>${esc(step?.label || live.phase)} · ${esc(elapsed)}</small></div><span class="building-spin" aria-hidden="true"></span></div>`;
	}

	function patchBuilding(node, html) {
		const next = el("div", null, html).firstElementChild;
		if (!next) return;
		const samePhase = node.getAttribute("data-phase") === next.getAttribute("data-phase");
		if (!samePhase) {
			node.replaceWith(next);
			return;
		}
		const copy = node.querySelector(".building-copy");
		const nextCopy = next.querySelector(".building-copy");
		if (!copy || !nextCopy) {
			node.replaceWith(next);
			return;
		}
		const b = copy.querySelector(":scope > b");
		const nb = nextCopy.querySelector(":scope > b");
		if (b && nb && b.textContent !== nb.textContent) b.textContent = nb.textContent;
		const small = copy.querySelector(":scope > small");
		const ns = nextCopy.querySelector(":scope > small");
		if (small && ns && small.textContent !== ns.textContent) small.textContent = ns.textContent;
	}

	function syncBanners(live) {
		const pipe = $(".pipeline-block", desk) || $(".pipeline", desk)?.parentElement;
		const html = buildingBanner(live);
		$$(".building[data-banner]:not([data-banner='build'])", desk).forEach(n => n.remove());
		const cur = $(`.building[data-banner="build"]`, desk);
		if (!html) {
			if (cur) cur.remove();
			return;
		}
		if (cur) {
			patchBuilding(cur, html);
			return;
		}
		const node = el("div", null, html).firstElementChild;
		if (!node) return;
		if (pipe) pipe.after(node);
		else desk.prepend(node);
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
		return `<div class="gates"><h3 title="Regression thresholds for the selected platform">Regression gates · ${esc(State.platform)}</h3>${g.map(x => {
			const tip = `${x.label}: tests more than +${x.limit}% vs baseline count as over · ${x.failed ? `${x.failed} over the limit` : "all within limit"}`;
			return `<div class="gate" title="${esc(tip)}"><span>${x.kind} · ${x.label} &gt; +${x.limit}%</span><div class="bar"><span style="width:${(x.pass * 100).toFixed(0)}%;background:${x.failed ? "var(--bad)" : "var(--ok)"}"></span></div><b>${x.failed ? `${x.failed} over` : "pass"}</b></div>`;
		}).join("")}</div>`;
	}

	function markup(live) {
		const env = envFor(live);
		const steps = PHASES.map((p, i) => {
			const st = phaseState(live, p.id);
			const active = st === "running";
			return `<div class="step${active ? " building-step" : ""}" data-state="${st}" data-id="${esc(p.id)}" style="animation-delay:${i * 30}ms"><i></i><span>${stepLabelHtml(p, live, st)}</span><small>${live ? esc(duration(live, p.id)) : ""}</small>${active ? `<div class="step-progress" aria-hidden="true"><span></span></div>` : ""}</div>`;
		}).join("");
		return `
			${machine(env, live?.run || State.run)}
			<div class="pipeline-block"><h3>Pipeline${live ? ` · ${esc(live.state)}` : " · completed run"}</h3><div class="pipeline">${steps}</div></div>
			${buildingBanner(live)}
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
		const env = envFor(live);
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
		if (!first) $$(".step, .gate .bar span, .cool, .building", desk).forEach(n => { n.style.animation = "none"; });
		arm(live);
	}

	function arm(live) {
		const need = !!(live && ["starting", "running"].includes(live.state));
		if (!need) {
			clearInterval(timer);
			timer = null;
			return;
		}
		if (!timer) timer = setInterval(tick, 1000);
	}

	function tick() {
		const live = State.live;
		if (!live) return;
		$$(".step", desk).forEach(s => {
			const id = s.dataset.id;
			if (!id) return;
			const p = PHASES.find(x => x.id === id);
			if (!p) return;
			const st = phaseState(live, id);
			if (s.dataset.state !== st) s.dataset.state = st;
			const active = st === "running";
			s.classList.toggle("building-step", active);
			let prog = s.querySelector(":scope > .step-progress");
			if (active && !prog) {
				prog = document.createElement("div");
				prog.className = "step-progress";
				prog.setAttribute("aria-hidden", "true");
				prog.innerHTML = "<span></span>";
				s.append(prog);
			} else if (!active && prog) {
				prog.remove();
			}
			syncStepBody(s, p, live, st);
			const d = [...s.querySelectorAll(":scope > small")].pop();
			if (d && d.tagName === "SMALL" && active) d.textContent = duration(live, id);
		});
		const title = $(".pipeline-block > h3", desk) || $("h3", desk);
		if (title && title.textContent.startsWith("Pipeline")) title.textContent = `Pipeline · ${live.state}`;
		syncBanners(live);
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
