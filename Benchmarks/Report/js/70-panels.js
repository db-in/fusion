const Tip = (() => {
	const tip = $("#tip");
	return {
		show(html, x, y) {
			tip.innerHTML = html;
			tip.hidden = false;
			const w = tip.offsetWidth, h = tip.offsetHeight;
			tip.style.left = `${Math.min(window.innerWidth - w - 8, x + 14)}px`;
			tip.style.top = `${Math.max(8, y - h - 10)}px`;
		},
		hide() { tip.hidden = true; }
	};
})();

const Panels = (() => {
	const HEAT_METRICS = ["time", "cpu", "instructions", "cycles", "peak", "disk"];
	const METHODS = [
		{ k: "Clock", c: "--accent", id: "XCTClockMetric", text: "Monotonic wall time for the whole loop, divided by the number of operations. Includes waiting, I/O and scheduling. The secondary gate fails above +25%." },
		{ k: "CPU", c: "--teal", id: "XCTCPUMetric", text: "CPU time, instructions retired and cycles. Instructions are the most stable signal across runs, so they are the primary gate: more than +10% is a regression." },
		{ k: "Instructions", c: "--violet", id: "instructions_retired", text: "Count of retired instructions per op. Independent of clock speed and thermal state, so it is comparable between machines with the same architecture." },
		{ k: "Memory", c: "--pink", id: "XCTMemoryMetric", text: "Peak physical memory of the test process during the measured block, and the physical delta. Peak is cumulative for the process, so read it as a ceiling." },
		{ k: "Storage", c: "--gold", id: "XCTStorageMetric", text: "Logical disk writes in kB during the block. Non-zero values point at persistence or cache traffic inside a hot path." }
	];
	const summaryState = { sort: "ratio", dir: -1, suite: "" };

	function hoverable(container, describe) {
		container.onmousemove = e => {
			const t = e.target.closest("[data-key]");
			if (!t) return Tip.hide();
			const html = describe(t);
			if (html) Tip.show(html, e.clientX, e.clientY); else Tip.hide();
		};
		container.onmouseleave = () => Tip.hide();
		container.onclick = e => {
			const t = e.target.closest("[data-key]");
			if (t) { Tip.hide(); Bus.emit("select", { key: t.dataset.key, open: true }); }
		};
	}

	function loopNs(item, run) {
		const row = item.runs.get(run);
		const per = row?.time;
		if (!Number.isFinite(per)) return null;
		const ops = row.ops > 0 ? row.ops : 1;
		return per * ops;
	}

	function summary() {
		const base = Model.baselineRun;
		const run = State.run;
		const hint = $("#summary-hint");
		if (hint) {
			hint.textContent = run === base
				? "Showing the baseline against itself. Pick another run to see Original → Final."
				: `Baseline (${shortRun(base)}) → ${shortRun(run)}. Times are one measured loop (ops × wall time/op).`;
		}
		const suites = Model.suites(State.platform);
		if (summaryState.suite && !suites.includes(summaryState.suite)) summaryState.suite = "";
		const rows = Model.list(State.platform).map(i => {
			const original = loopNs(i, base);
			const final = loopNs(i, run);
			const ops = i.runs.get(run)?.ops || i.runs.get(base)?.ops || null;
			const ratio = Number.isFinite(original) && Number.isFinite(final) && final > 0 ? original / final : null;
			const label = i.info?.feature || i.info?.measures || i.name;
			const change = fmtSpeedup(original, final);
			const cls = !Number.isFinite(ratio) || (ratio >= 0.95 && ratio <= 1.05) || change === "unchanged" ? "flat"
				: change.includes("faster") || change === "cached" ? "good"
				: change.includes("slower") ? "bad" : "flat";
			return { i, label, suite: i.suite, ops, original, final, ratio, change, cls };
		}).filter(r => (Number.isFinite(r.original) || Number.isFinite(r.final)) && (!summaryState.suite || r.suite === summaryState.suite));
		const dir = summaryState.dir;
		const key = summaryState.sort;
		rows.sort((a, b) => {
			const av = key === "label" ? a.label : key === "original" ? (a.original ?? -1) : key === "final" ? (a.final ?? -1) : (a.ratio ?? -1);
			const bv = key === "label" ? b.label : key === "original" ? (b.original ?? -1) : key === "final" ? (b.final ?? -1) : (b.ratio ?? -1);
			if (typeof av === "string") return av.localeCompare(bv) * dir;
			return (av - bv) * dir || a.label.localeCompare(b.label);
		});
		const box = $("#summary");
		const mark = col => summaryState.sort === col ? (summaryState.dir > 0 ? " ↑" : " ↓") : "";
		const tags = `<div class="summary-tags"><button type="button" class="summary-tag${!summaryState.suite ? " on" : ""}" data-suite="">All</button>${suites.map(s => {
			const info = suiteInfo(s);
			return `<button type="button" class="summary-tag${summaryState.suite === s ? " on" : ""}" data-suite="${esc(s)}" style="--tag:${suiteColor(s)}">${esc(info.label)}</button>`;
		}).join("")}</div>`;
		if (!rows.length) {
			box.innerHTML = `${tags}<p class="summary-empty">No timed results for ${esc(State.platform)}${summaryState.suite ? ` · ${esc(suiteInfo(summaryState.suite).label)}` : ""} yet.</p>`;
		} else {
			box.innerHTML = `${tags}<table class="summary-table"><thead><tr>
				<th data-sort="label">Path${mark("label")}</th>
				<th data-sort="original">Original${mark("original")}</th>
				<th data-sort="final">Final${mark("final")}</th>
				<th data-sort="ratio">Change${mark("ratio")}</th>
			</tr></thead><tbody>${rows.map(r => {
				const opsNote = r.ops ? `${r.ops.toLocaleString("en-US")} ops / iteration` : "";
				const suite = suiteInfo(r.suite).label;
				return `<tr data-key="${esc(r.i.key)}"><td class="path">${esc(r.label)}<small>${esc(suite)}${opsNote ? ` · ${esc(opsNote)}` : ""}</small></td><td class="num">${esc(fmtSec(r.original))}</td><td class="num">${esc(fmtSec(r.final))}</td><td class="change ${r.cls}">${esc(r.change)}</td></tr>`;
			}).join("")}</tbody></table>`;
		}
		box.onclick = e => {
			const tag = e.target.closest("[data-suite]");
			if (tag) {
				summaryState.suite = tag.dataset.suite || "";
				summary();
				return;
			}
			const th = e.target.closest("th[data-sort]");
			if (th) {
				const col = th.dataset.sort;
				if (summaryState.sort === col) summaryState.dir *= -1;
				else {
					summaryState.sort = col;
					summaryState.dir = col === "label" ? 1 : -1;
				}
				summary();
				return;
			}
			const row = e.target.closest("tr[data-key]");
			if (row) { Tip.hide(); Bus.emit("select", { key: row.dataset.key, open: true }); }
		};
		box.onmousemove = e => {
			const t = e.target.closest("tr[data-key]");
			if (!t) return Tip.hide();
			const item = Model.items.get(t.dataset.key);
			if (!item) return Tip.hide();
			const s = Model.stat(item, "time");
			Tip.show(`<b>${esc(item.name)}</b><br>${esc(item.info?.measures || "")}<br>${esc(fmtNs(s.base))} → ${esc(fmtNs(s.current))} / op`, e.clientX, e.clientY);
		};
		box.onmouseleave = () => Tip.hide();
	}

	function range() {
		const fmt = METRICS[State.metric].fmt;
		const X = ratio => Math.max(0, Math.min(100, ((Math.log2(ratio) + 1) / 2) * 100));
		const rows = Model.list(State.platform).map(i => ({ i, s: Model.stat(i) }))
			.sort((a, b) => Math.abs(b.s.delta ?? 0) - Math.abs(a.s.delta ?? 0) || a.i.name.localeCompare(b.i.name));
		const axis = [0.5, 0.71, 1, 1.41, 2].map(r => `<span style="left:${X(r)}%">${r === 1 ? "base" : `${fixed(r, 2)}×`}</span>`).join("");
		$("#range").innerHTML = `<div class="range-axis"><span></span><div>${axis}</div><span></span></div>` + rows.map(({ i, s }, n) => {
			const b = s.base;
			const band = b ? `<span class="band" style="left:${X(s.best / b)}%;width:${Math.max(0.8, X(s.worst / b) - X(s.best / b))}%;animation-delay:${Math.min(n * 18, 500)}ms"></span>` : "";
			const cur = b && Number.isFinite(s.current) ? `<span class="cur ${s.status}" style="left:${X(s.current / b)}%"></span>` : "";
			return `<button class="range-row" type="button" data-key="${esc(i.key)}"><span>${esc(i.name)}</span><span class="track">${band}<span class="base" style="left:${X(1)}%"></span>${cur}</span><span class="pill ${s.status}">${esc(fmtDelta(s.delta))}</span></button>`;
		}).join("");
		hoverable($("#range"), t => {
			const i = Model.items.get(t.dataset.key), s = Model.stat(i);
			return `<b>${esc(i.name)}</b><span>base ${esc(fmt(s.base))} · best ${esc(fmt(s.best))} · worst ${esc(fmt(s.worst))} · current ${esc(fmt(s.current))}</span>`;
		});
	}

	function donuts() {
		const C = 2 * Math.PI * 38;
		$("#donuts").innerHTML = Model.suites(State.platform).map((s, n) => {
			const list = Model.list(State.platform).filter(i => i.suite === s).map(i => Model.stat(i).status);
			const good = list.filter(x => x === "good").length, bad = list.filter(x => x === "bad").length, flat = list.length - good - bad;
			let offset = 0;
			const arc = (count, color) => {
				const len = (count / list.length) * C;
				const out = count ? `<circle class="arc" cx="46" cy="46" r="38" stroke="${color}" stroke-dasharray="${len} ${C - len}" stroke-dashoffset="${-offset}"/>` : "";
				offset += len;
				return out;
			};
			return `<button class="donut" type="button" data-suite="${esc(s)}" style="animation:dm-in .5s ${n * 80}ms backwards">
				<span class="donut-wrap"><svg viewBox="0 0 92 92"><circle cx="46" cy="46" r="38" stroke="var(--line)"/>${arc(good, "var(--ok)")}${arc(flat, suiteColor(s))}${arc(bad, "var(--bad)")}</svg><span>${list.length}</span></span>
				<b>${esc(suiteInfo(s).label)}</b><small>${good} faster · ${flat} flat · ${bad} slower</small></button>`;
		}).join("");
		$("#donuts").onclick = e => {
			const d = e.target.closest("[data-suite]");
			if (!d) return;
			Grid.open();
			$("#grid-filter").value = d.dataset.suite;
			Grid.render();
		};
	}

	function parity() {
		const [a, b] = ["macOS", "iOS"];
		const pairs = Model.list(a).map(i => ({ i, j: Model.items.get(`${b}|${i.suite}|${i.test}`) })).filter(x => x.j)
			.map(x => ({ ...x, x: Model.value(x.i, State.run, State.metric) ?? Model.stat(x.i).base, y: Model.value(x.j, State.run, State.metric) ?? Model.stat(x.j).base }))
			.filter(p => p.x > 0 && p.y > 0);
		if (!pairs.length) {
			$("#parity").innerHTML = `<p style="color:var(--ink-3)">Needs both platforms in the same run.</p>`;
			return;
		}
		const fmt = METRICS[State.metric].fmt;
		const all = pairs.flatMap(p => [p.x, p.y]);
		const lo = Math.floor(Math.log10(Math.min(...all))), hi = Math.ceil(Math.log10(Math.max(...all)));
		const S = 300, P = 36;
		const T = v => P + ((Math.log10(v) - lo) / (hi - lo || 1)) * (S - P - 8);
		const Y = v => S - T(v) + P - 8;
		let grid = "";
		for (let e = lo; e <= hi; e++) {
			const v = Math.pow(10, e);
			grid += `<line class="grid" x1="${T(v)}" x2="${T(v)}" y1="8" y2="${S - P + 8}"/><line class="grid" x1="${P}" x2="${S}" y1="${Y(v)}" y2="${Y(v)}"/><text x="${T(v)}" y="${S - P + 22}" text-anchor="middle">${esc(fmt(v))}</text><text x="${P - 4}" y="${Y(v) + 3}" text-anchor="end">${esc(fmt(v))}</text>`;
		}
		const v0 = Math.pow(10, lo), v1 = Math.pow(10, hi);
		$("#parity").innerHTML = `<svg viewBox="0 0 ${S} ${S}">${grid}
			<line class="diag" x1="${T(v0)}" y1="${Y(v0)}" x2="${T(v1)}" y2="${Y(v1)}"/>
			<text x="${S - 4}" y="${S - P + 34}" text-anchor="end">${a} →</text>
			<text x="4" y="12">↑ ${b}</text>
			${pairs.map((p, n) => `<circle class="pt" data-key="${esc((State.platform === b ? p.j : p.i).key)}" cx="${T(p.x)}" cy="${Y(p.y)}" r="${State.selected === p.i.key || State.selected === p.j.key ? 7 : 4.5}" fill="${suiteColor(p.i.suite)}" stroke="${State.selected === p.i.key || State.selected === p.j.key ? "var(--accent)" : "var(--bg)"}" stroke-width="1.5" style="animation:dm-in .4s ${n * 12}ms backwards"/>`).join("")}
		</svg>`;
		hoverable($("#parity"), t => {
			const it = Model.items.get(t.dataset.key);
			const p = pairs.find(x => x.i.key === t.dataset.key || x.j.key === t.dataset.key);
			return p ? `<b>${esc(it.name)}</b><span>${a} ${esc(fmt(p.x))} · ${b} ${esc(fmt(p.y))} · ${fixed(p.y / p.x, 2)}×</span>` : "";
		});
	}

	function heat() {
		const list = Model.list(State.platform);
		const deltaMode = State.run !== Model.baselineRun;
		$("#heat-title").textContent = deltaMode ? "Change heatmap" : "Cost heatmap";
		$("#heat-hint").textContent = deltaMode ? "Change vs baseline for every metric. Green is cheaper, red is more expensive." : "Share of cost per metric, log scale. Brighter cells are the heaviest tests for that metric.";
		const max = {}, min = {};
		HEAT_METRICS.forEach(m => {
			const v = list.map(i => Model.value(i, State.run, m)).filter(x => x > 0);
			max[m] = Math.max(...v, 1);
			min[m] = Math.min(...v, max[m]);
		});
		const cell = (i, m, n) => {
			const v = Model.value(i, State.run, m);
			let bg = "var(--line)";
			if (deltaMode) {
				const d = Model.stat(i, m).delta;
				if (Number.isFinite(d)) {
					const k = Math.min(1, Math.abs(d) / 30);
					bg = `color-mix(in srgb, ${d > 0 ? "var(--bad)" : "var(--ok)"} ${Math.round(12 + k * 78)}%, transparent)`;
				}
			} else if (v > 0) {
				const k = max[m] > min[m] ? (Math.log(v) - Math.log(min[m])) / (Math.log(max[m]) - Math.log(min[m])) : 1;
				bg = `color-mix(in srgb, var(--accent) ${Math.round(8 + k * 82)}%, transparent)`;
			}
			return `<span class="c" data-key="${esc(i.key)}" data-m="${m}" style="background:${bg};animation-delay:${Math.min(n * 6, 600)}ms">${esc(ALL_METRICS[m].fmt(v))}</span>`;
		};
		let n = 0;
		$("#heat").innerHTML = `<div class="heat-grid" style="grid-template-columns:minmax(150px,1.6fr) repeat(${HEAT_METRICS.length}, minmax(52px,1fr))"><span></span>${HEAT_METRICS.map(m => `<span class="h">${esc(ALL_METRICS[m].label)}</span>`).join("")}${Model.suites(State.platform).map(s => `<span class="suite" style="color:${suiteColor(s)}">${esc(suiteInfo(s).label)}</span>${list.filter(i => i.suite === s).map(i => `<button class="n" type="button" data-key="${esc(i.key)}">${esc(i.name)}</button>${HEAT_METRICS.map(m => cell(i, m, n++)).join("")}`).join("")}`).join("")}</div>`;
		hoverable($("#heat"), t => {
			if (!t.dataset.m) return "";
			const i = Model.items.get(t.dataset.key), m = t.dataset.m, s = Model.stat(i, m);
			return `<b>${esc(i.name)} · ${esc(ALL_METRICS[m].long)}</b><span>${esc(ALL_METRICS[m].fmt(s.current))} · ${esc(fmtDelta(s.delta))} vs base</span>`;
		});
	}

	function method() {
		const box = $("#method");
		if (box.dataset.ready) return;
		box.dataset.ready = "1";
		box.innerHTML = METHODS.map((m, n) => `<div class="card" style="animation-delay:${n * 70}ms"><h3><i style="background:var(${m.c})">${m.k[0]}</i>${m.k}</h3><p>${m.text}</p><code>${m.id}</code></div>`).join("")
			+ `<div class="card" style="animation-delay:${METHODS.length * 70}ms"><h3><i style="background:var(--ok)">5</i>Iterations</h3><p>Each test runs its loop 5 times. RSD (relative standard deviation) above 10% marks a noisy test whose deltas need a second run before you trust them.</p><code>XCTMeasureOptions.iterationCount = 5</code></div>`;
	}

	function render() {
		summary();
		range();
		donuts();
		parity();
		heat();
		method();
	}

	return { render };
})();
