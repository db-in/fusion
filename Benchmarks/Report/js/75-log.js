const Log = (() => {
	const box = $("#log");
	const filter = $("#log-filter");
	const count = $("#log-count");
	const MAX = 200;
	const state = { sort: "name", dir: 1, q: "", mode: "idle", entries: [] };

	function stamp(t) {
		const d = new Date(t || Date.now());
		return {
			label: d.toLocaleTimeString(undefined, { hour12: false }),
			key: d.getTime()
		};
	}

	function match(row, q) {
		if (!q) return true;
		const hay = `${row.name || ""} ${row.suite || ""} ${row.suiteLabel || ""} ${row.kind || ""} ${row.detail || ""} ${row.when || ""}`.toLowerCase();
		return hay.includes(q);
	}

	function sorted(rows) {
		const dir = state.dir;
		const key = state.sort;
		return rows.slice().sort((a, b) => {
			let av, bv;
			if (key === "name") { av = a.name || ""; bv = b.name || ""; }
			else if (key === "time") { av = a.time ?? -1; bv = b.time ?? -1; }
			else if (key === "instr") { av = a.instr ?? -1; bv = b.instr ?? -1; }
			else if (key === "kind") { av = a.kind || ""; bv = b.kind || ""; }
			else if (key === "suite") { av = a.suiteLabel || ""; bv = b.suiteLabel || ""; }
			else if (key === "detail") { av = a.detail || ""; bv = b.detail || ""; }
			else { av = a.whenKey ?? 0; bv = b.whenKey ?? 0; }
			if (typeof av === "string") return av.localeCompare(bv) * dir || (a.whenKey - b.whenKey) * dir;
			return (av - bv) * dir || (a.name || "").localeCompare(b.name || "");
		});
	}

	function mark(col) {
		return state.sort === col ? (state.dir > 0 ? " ↑" : " ↓") : "";
	}

	function paint() {
		const q = state.q.trim().toLowerCase();
		const rows = sorted(state.entries.filter(r => match(r, q)));
		if (count) count.textContent = `${rows.length}${q ? ` / ${state.entries.length}` : ""}`;
		if (!state.entries.length) {
			box.innerHTML = `<div class="log-empty">${state.mode === "live" ? "Waiting for the runner…" : "Nothing recorded for this run yet."}</div>`;
			return;
		}
		if (!rows.length) {
			box.innerHTML = `<div class="log-empty">No rows match “${esc(state.q.trim())}”.</div>`;
			return;
		}
		const liveCols = state.mode === "live";
		box.innerHTML = `<table class="log-table"><thead><tr>
			<th data-sort="when">When${mark("when")}</th>
			${liveCols ? `<th data-sort="kind">Kind${mark("kind")}</th>` : ""}
			<th data-sort="name">Test${mark("name")}</th>
			<th data-sort="time">Time${mark("time")}</th>
			<th data-sort="instr">Instructions${mark("instr")}</th>
			${liveCols ? `<th data-sort="detail">Detail${mark("detail")}</th>` : `<th data-sort="suite">Suite${mark("suite")}</th>`}
		</tr></thead><tbody>${rows.map(r => {
			const detail = liveCols ? (r.detail || "") : (r.suiteLabel || "");
			const keyAttr = r.key ? ` data-key="${esc(r.key)}"` : "";
			return `<tr class="${esc(r.kind || "")}"${keyAttr}>
				<td class="when">${esc(r.when)}</td>
				${liveCols ? `<td class="kind"><i></i>${esc(r.kind || "")}</td>` : ""}
				<td class="name">${r.name ? `<b>${esc(r.name)}</b>` : "—"}</td>
				<td class="num">${esc(Number.isFinite(r.time) ? fmtNs(r.time) : "—")}</td>
				<td class="num">${esc(Number.isFinite(r.instr) ? fmtNum(r.instr) : "—")}</td>
				<td class="detail">${esc(detail)}</td>
			</tr>`;
		}).join("")}</tbody></table>`;
	}

	function push(entry) {
		state.mode = "live";
		state.entries.unshift(entry);
		while (state.entries.length > MAX) state.entries.pop();
		paint();
	}

	function event(e) {
		const t = stamp(e.t);
		const name = shortName(e.test || "");
		const key = e.platform && e.suite && e.test ? `${e.platform}|${e.suite}|${e.test}` : "";
		const suiteLabel = e.suite ? suiteInfo(e.suite).label : "";
		if (e.kind === "started") {
			push({ when: t.label, whenKey: t.key, kind: "started", name, key, suite: e.suite, suiteLabel, detail: `${e.platform} started`, time: null, instr: null });
		} else if (e.kind === "ops") {
			push({ when: t.label, whenKey: t.key, kind: "ops", name, key, suite: e.suite, suiteLabel, detail: `${e.ops} ops / iteration`, time: null, instr: null });
		} else if (e.kind === "measured") {
			const m = ALL_METRICS[e.metric];
			if (!m) return;
			const detail = `${m.label}${e.rsd != null ? ` ±${fixed(e.rsd, 1)}%` : ""}`;
			push({
				when: t.label,
				whenKey: t.key,
				kind: "measured",
				name,
				key,
				suite: e.suite,
				suiteLabel,
				detail,
				time: e.metric === "time" ? e.value : null,
				instr: e.metric === "instructions" ? e.value : null
			});
		}
	}

	function phase(label, st, t) {
		const s = stamp(t);
		push({ when: s.label, whenKey: s.key, kind: st === "failed" ? "error" : "phase", name: "", key: "", suite: "", suiteLabel: "", detail: `${label} ${st}`, time: null, instr: null });
	}

	function line(kind, html, t) {
		const s = stamp(t);
		const tmp = el("span", "", html);
		push({ when: s.label, whenKey: s.key, kind: kind || "info", name: "", key: "", suite: "", suiteLabel: "", detail: tmp.textContent || "", time: null, instr: null });
	}

	function idle() {
		const run = State.run;
		const whenLabel = run === Model.baselineRun ? "base" : shortRun(run).slice(0, 11);
		const whenKey = Model.meta.get(run)?.date ? new Date(Model.meta.get(run).date).getTime() : 0;
		state.mode = "idle";
		state.entries = Model.list(State.platform).filter(i => i.runs.has(run)).map(i => ({
			when: whenLabel,
			whenKey,
			kind: "measured",
			name: i.name,
			key: i.key,
			suite: i.suite,
			suiteLabel: suiteInfo(i.suite).label,
			detail: "",
			time: Model.value(i, run, "time"),
			instr: Model.value(i, run, "instructions")
		}));
		$("#log-hint").textContent = `Recorded results for ${shortRun(run)}. Live runs and replays stream here.`;
		paint();
	}

	function reset(hint) {
		state.mode = "live";
		state.entries = [];
		$("#log-hint").textContent = hint;
		paint();
	}

	if (filter) {
		filter.addEventListener("input", () => {
			state.q = filter.value;
			paint();
		});
	}

	box.addEventListener("click", e => {
		const th = e.target.closest("th[data-sort]");
		if (th) {
			const col = th.dataset.sort;
			if (state.sort === col) state.dir *= -1;
			else {
				state.sort = col;
				state.dir = col === "name" || col === "kind" || col === "suite" || col === "detail" ? 1 : -1;
			}
			paint();
			return;
		}
		const row = e.target.closest("tr[data-key]");
		if (row) Bus.emit("select", { key: row.dataset.key, open: true });
	});

	return { event, phase, line, idle, reset };
})();
