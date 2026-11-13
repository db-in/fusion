const Drawer = (() => {
	const drawer = $("#drawer");
	const scrim = $("#scrim");
	const ICON = {
		prev: `<svg viewBox="0 0 16 16"><path d="M10 3 5 8l5 5"/></svg>`,
		next: `<svg viewBox="0 0 16 16"><path d="m6 3 5 5-5 5"/></svg>`,
		close: `<svg viewBox="0 0 16 16"><path d="M4 4l8 8M12 4l-8 8"/></svg>`,
		swap: `<svg viewBox="0 0 16 16"><path d="M3 5h9l-2.5-2.5M13 11H4l2.5 2.5"/></svg>`
	};

	function gauge(s, fmt) {
		const w = 460, pos = Math.max(0, Math.min(1, s.position || 0)), x = 20 + pos * (w - 40);
		const basePos = Number.isFinite(s.base) && s.worst > s.best ? Math.max(0, Math.min(1, (s.base - s.best) / (s.worst - s.best))) : null;
		return `<svg viewBox="0 0 ${w} 58">
			<defs><linearGradient id="g-range" x1="0" x2="1"><stop offset="0" stop-color="var(--teal)"/><stop offset="1" stop-color="var(--warn)"/></linearGradient></defs>
			<rect x="20" y="22" width="${w - 40}" height="10" rx="5" fill="url(#g-range)" opacity=".55"/>
			${basePos != null ? `<line x1="${20 + basePos * (w - 40)}" x2="${20 + basePos * (w - 40)}" y1="16" y2="38" stroke="var(--ink-2)" stroke-width="2"/>` : ""}
			<circle cx="${x}" cy="27" r="8" fill="var(--accent)" stroke="var(--bg)" stroke-width="3"><animate attributeName="cx" from="20" to="${x}" dur=".8s" calcMode="spline" keySplines=".2 .8 .2 1" keyTimes="0;1"/></circle>
			<text x="20" y="52">best ${esc(fmt(s.best))}</text>
			<text x="${w - 20}" y="52" text-anchor="end">worst ${esc(fmt(s.worst))}</text>
			<text x="${x}" y="12" text-anchor="middle" style="fill:var(--accent)">${(pos * 100).toFixed(0)}%</text>
		</svg>`;
	}

	function historyChart(item, s, fmt) {
		const pts = s.points;
		const w = 460, h = 150, l = 50, r = 12, t = 12, b = 26;
		if (!pts.length) return "";
		const vals = pts.map(p => p.v).concat(Number.isFinite(s.base) ? [s.base] : []);
		let lo = Math.min(...vals), hi = Math.max(...vals);
		if (hi === lo) { lo *= 0.9; hi *= 1.1; }
		const pad = (hi - lo) * 0.15;
		lo -= pad; hi += pad;
		const X = i => (pts.length === 1 ? (l + w - r) / 2 : l + (i / (pts.length - 1)) * (w - l - r));
		const Y = v => t + (1 - (v - lo) / (hi - lo)) * (h - t - b);
		const line = pts.map((p, i) => `${i ? "L" : "M"}${X(i).toFixed(1)},${Y(p.v).toFixed(1)}`).join("");
		const band = Number.isFinite(s.best) ? `<rect x="${l}" y="${Y(s.worst)}" width="${w - l - r}" height="${Math.max(1, Y(s.best) - Y(s.worst))}" fill="var(--teal)" opacity=".08"/>` : "";
		const base = Number.isFinite(s.base) ? `<line x1="${l}" x2="${w - r}" y1="${Y(s.base)}" y2="${Y(s.base)}" stroke="var(--ink-2)" stroke-dasharray="5 5"/><text x="${w - r}" y="${Y(s.base) - 4}" text-anchor="end">baseline</text>` : "";
		const ticks = [lo + pad, (lo + hi) / 2, hi - pad].map(v => `<text x="${l - 6}" y="${Y(v) + 3}" text-anchor="end">${esc(fmt(v))}</text>`).join("");
		const dots = pts.map((p, i) => `<circle cx="${X(i)}" cy="${Y(p.v)}" r="${p.run === State.run ? 5 : 3.5}" fill="${p.run === State.run ? "var(--accent)" : p.run === s.bestRun ? "var(--teal)" : p.run === s.worstRun ? "var(--warn)" : "var(--ink-2)"}"><title>${esc(p.run)} · ${esc(fmt(p.v))}</title></circle>`).join("");
		const len = pts.length > 1 ? 1000 : 0;
		return `<svg viewBox="0 0 ${w} ${h}">${band}${base}${ticks}
			<path d="${line}" fill="none" stroke="var(--accent)" stroke-width="2" stroke-linejoin="round" style="stroke-dasharray:${len};stroke-dashoffset:${len}"><animate attributeName="stroke-dashoffset" from="${len}" to="0" dur="1s" fill="freeze"/></path>
			${dots}<text x="${l}" y="${h - 6}">${esc(shortRun(pts[0].run))}</text>${pts.length > 1 ? `<text x="${w - r}" y="${h - 6}" text-anchor="end">${esc(shortRun(pts[pts.length - 1].run))}</text>` : ""}</svg>`;
	}

	function samples(item, fmt) {
		const sm = Model.sample(item, State.run, State.metric);
		if (!sm || !sm.samples?.length) return `<p style="color:var(--ink-3);font-size:12px;margin:0">No per-iteration samples recorded for this run.</p>`;
		const v = sm.samples, lo = Math.min(...v), hi = Math.max(...v), span = hi - lo || 1, w = 380;
		const mean = v.reduce((a, b) => a + b, 0) / v.length;
		const X = x => 14 + ((x - lo) / span) * (w - 28);
		const rsd = sm.rsd;
		const cls = rsd == null ? "" : rsd > 10 ? "bad" : rsd < 3 ? "good" : "";
		return `<div class="samples-strip"><svg viewBox="0 0 ${w} 44"><line x1="14" x2="${w - 14}" y1="22" y2="22" stroke="var(--line-2)"/><line x1="${X(mean)}" x2="${X(mean)}" y1="10" y2="34" stroke="var(--accent)" stroke-dasharray="3 3"/>${v.map((x, i) => `<circle cx="${X(x)}" cy="22" r="6" fill="var(--teal)" opacity=".8" style="animation:dm-in .4s ${i * 80}ms backwards"><title>#${i + 1} · ${esc(fmt(x))}</title></circle>`).join("")}<text x="14" y="42" style="fill:var(--ink-3);font:10px var(--font-mono)">${esc(fmt(lo))}</text><text x="${w - 14}" y="42" text-anchor="end" style="fill:var(--ink-3);font:10px var(--font-mono)">${esc(fmt(hi))}</text></svg><span class="pill ${cls}">RSD ${rsd == null ? "—" : fixed(rsd, 1) + "%"}</span></div>`;
	}

	function table(item) {
		return `<table class="metrics-table"><thead><tr><th>Metric</th><th>Baseline</th><th>Best</th><th>Worst</th><th>Current</th><th>Δ</th></tr></thead><tbody>${Object.entries(ALL_METRICS).map(([k, m]) => {
			const s = Model.stat(item, k);
			return `<tr><td>${esc(m.long)}</td><td>${esc(m.fmt(s.base))}</td><td>${esc(m.fmt(s.best))}</td><td>${esc(m.fmt(s.worst))}</td><td>${esc(m.fmt(s.current))}</td><td><span class="pill ${k === "memory" ? "" : s.status}">${esc(fmtDelta(s.delta))}</span></td></tr>`;
		}).join("")}</tbody></table>`;
	}

	function render() {
		const item = Model.items.get(State.selected);
		if (!item) { close(); return; }
		const list = Model.list(item.platform);
		const idx = list.findIndex(i => i.key === item.key);
		const other = Model.platforms().find(p => p !== item.platform && Model.items.has(`${p}|${item.suite}|${item.test}`));
		const m = METRICS[State.metric], fmt = m.fmt, s = Model.stat(item);
		const ops = item.runs.get(State.run)?.ops ?? item.runs.get(Model.baselineRun)?.ops;
		drawer.innerHTML = `
			<div class="drawer-nav">
				<button class="icon-btn" type="button" data-nav="-1" title="Previous test (←)">${ICON.prev}</button>
				<button class="icon-btn" type="button" data-nav="1" title="Next test (→)">${ICON.next}</button>
				${other ? `<button class="chip" type="button" data-swap="${esc(other)}">${ICON.swap.replace("<svg", "<svg style=\"width:12px;height:12px;fill:none;stroke:currentColor;stroke-width:1.6\"")} ${esc(other)}</button>` : ""}
				<span class="spacer"></span>
				<span class="chip mono">${idx + 1} / ${list.length}</span>
				<button class="icon-btn" type="button" data-close title="Close (Esc)">${ICON.close}</button>
			</div>
			<div class="drawer-title">
				<small><i style="background:${suiteColor(item.suite)}"></i>${esc(suiteInfo(item.suite).label)} · ${esc(item.platform)} · ${esc(m.long)}</small>
				<h2>${esc(item.name)}</h2>
				<p>${esc(item.info.measures)}</p>
			</div>
			<div class="numbers">
				<div class="num base"><small>Baseline</small><b>${esc(fmt(s.base))}</b><em>${esc(Model.baselineRun)}</em></div>
				<div class="num best" style="animation-delay:60ms"><small>Best</small><b>${esc(fmt(s.best))}</b><em>${esc(shortRun(s.bestRun))}</em></div>
				<div class="num worst" style="animation-delay:120ms"><small>Worst</small><b>${esc(fmt(s.worst))}</b><em>${esc(shortRun(s.worstRun))}</em></div>
				<div class="num cur" style="animation-delay:180ms"><small>Current</small><b>${esc(fmt(s.current))}</b><em><span class="pill ${s.status}">${esc(fmtDelta(s.delta))}</span></em></div>
			</div>
			<div><div class="section-title"><span>Where current sits</span><span>best → worst</span></div><div class="gauge">${gauge(s, fmt)}</div></div>
			<div><div class="section-title"><span>History · ${s.points.length} run${s.points.length === 1 ? "" : "s"}</span><span>band = best to worst</span></div><div class="chart">${historyChart(item, s, fmt)}</div></div>
			<div><div class="section-title"><span>5 iterations · ${esc(shortRun(State.run))}</span><span>${ops ? `${ops} ops per iteration` : ""}</span></div>${samples(item, fmt)}</div>
			<div><div class="section-title"><span>All metrics</span><span>per op</span></div>${table(item)}</div>
			<div class="explainer">
				<div><small>What it measures</small><p>${esc(item.info.feature)}: <code>${esc(item.info.measures)}</code></p></div>
				<div><small>How</small><p>${esc(item.info.how)}</p></div>
				<div><small>Why it matters</small><p>${esc(item.info.why)}</p></div>
				<div class="tags">${item.info.tags.map(t => `<span class="tag">${esc(t)}</span>`).join("")}<span class="tag mono">${esc(item.test)}</span></div>
			</div>`;
	}

	function open() {
		if (!State.selected) return;
		drawer.hidden = false;
		scrim.hidden = false;
		render();
		drawer.scrollTop = 0;
	}

	function close() {
		drawer.hidden = true;
		if (!Grid.isOpen()) scrim.hidden = true;
	}

	function move(step) {
		const item = Model.items.get(State.selected);
		if (!item) return;
		const list = Model.list(item.platform);
		const i = (list.findIndex(x => x.key === item.key) + step + list.length) % list.length;
		Bus.emit("select", { key: list[i].key, open: true });
	}

	drawer.addEventListener("click", e => {
		const nav = e.target.closest("[data-nav]");
		if (nav) return move(Number(nav.dataset.nav));
		if (e.target.closest("[data-close]")) return Bus.emit("select", { key: null });
		const swap = e.target.closest("[data-swap]");
		if (swap) {
			const item = Model.items.get(State.selected);
			State.follow = false;
			State.selected = `${swap.dataset.swap}|${item.suite}|${item.test}`;
			Header.setPlatform(swap.dataset.swap);
		}
	});
	scrim.addEventListener("click", () => {
		Grid.close();
		if (!drawer.hidden) Bus.emit("select", { key: null });
	});

	return { open, close, render, move, isOpen: () => !drawer.hidden };
})();
