const Log = (() => {
	const box = $("#log");
	const MAX = 120;
	const ICONS = { started: "▶", measured: "●", ops: "∑", phase: "◆", error: "✕", info: "·" };

	function time(t) {
		const d = new Date(t || Date.now());
		return d.toLocaleTimeString(undefined, { hour12: false });
	}

	function line(kind, html, t) {
		const empty = $(".log-empty", box);
		if (empty) empty.remove();
		const row = el("div", `log-row ${kind}`, `<time>${time(t)}</time><i>${ICONS[kind] || "·"}</i><span>${html}</span>`);
		box.prepend(row);
		while (box.children.length > MAX) box.lastElementChild.remove();
	}

	function event(e) {
		const name = `<b>${esc(shortName(e.test || ""))}</b>`;
		if (e.kind === "started") line("started", `${esc(e.platform)} ${name} started`, e.t);
		else if (e.kind === "ops") line("ops", `${name} loops ${esc(e.ops)} ops per iteration`, e.t);
		else if (e.kind === "measured") {
			const m = ALL_METRICS[e.metric];
			if (!m) return;
			line("measured", `${name} ${esc(m.label.toLowerCase())} ${esc(m.fmt(e.value))}${e.rsd != null ? ` ±${esc(fixed(e.rsd, 1))}%` : ""}`, e.t);
		}
	}

	function phase(label, state, t) {
		line(state === "failed" ? "error" : "phase", `${esc(label)} <b>${esc(state)}</b>`, t);
	}

	function idle() {
		const run = State.run;
		const rows = Model.list(State.platform).filter(i => i.runs.has(run)).slice(0, 40);
		box.innerHTML = rows.length
			? rows.map(i => `<div class="log-row measured"><time>${esc(run === Model.baselineRun ? "base" : shortRun(run).slice(0, 11))}</time><i>●</i><span><b>${esc(i.name)}</b> ${esc(fmtNs(Model.value(i, run, "time")))} · ${esc(fmtNum(Model.value(i, run, "instructions")))} instr</span></div>`).join("")
			: `<div class="log-empty">Nothing recorded for this run yet.</div>`;
		$("#log-hint").textContent = `Recorded results for ${shortRun(run)}. Live runs and replays stream here.`;
	}

	function reset(hint) {
		box.innerHTML = `<div class="log-empty">Waiting for the runner…</div>`;
		$("#log-hint").textContent = hint;
	}

	return { event, phase, line, idle, reset };
})();
