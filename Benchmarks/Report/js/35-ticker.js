const Ticker = (() => {
	const belt = $("#ticker-belt");
	const pop = $("#ticker-pop");
	const tag = $("#ticker-tag");
	let items = [];

	function pick(list, score, wantMax) {
		let best = null, bestScore = null;
		list.forEach(x => {
			const s = score(x);
			if (!Number.isFinite(s)) return;
			if (bestScore == null || (wantMax ? s > bestScore : s < bestScore)) { best = x; bestScore = s; }
		});
		return best ? { item: best, score: bestScore } : null;
	}

	function compute() {
		const list = Model.list(State.platform);
		const fmt = METRICS[State.metric].fmt;
		const out = [];
		const win = pick(list, i => Model.stat(i).delta, false);
		const loss = pick(list, i => Model.stat(i).delta, true);
		if (win && win.score < -0.5) out.push({ label: "Biggest win", item: win.item, value: fmtDelta(win.score), cls: "good" });
		if (loss && loss.score > 0.5) out.push({ label: "Biggest regression", item: loss.item, value: fmtDelta(loss.score), cls: "bad" });
		if (!out.length) out.push({ label: "Versus baseline", text: State.run === Model.baselineRun ? "Showing the baseline run itself" : "No test moved more than 0.5%" });
		const cheap = pick(list, i => Model.value(i, State.run, "time"), false);
		if (cheap) out.push({ label: "Cheapest op", item: cheap.item, value: fmtNs(cheap.score) });
		const costly = pick(list, i => Model.value(i, State.run, "time"), true);
		if (costly) out.push({ label: "Most expensive op", item: costly.item, value: fmtNs(costly.score) });
		const heavy = pick(list, i => Model.value(i, State.run, "peak"), true);
		if (heavy) out.push({ label: "Heaviest memory", item: heavy.item, value: fmtKB(heavy.score) });
		const noisy = pick(list, i => Model.sample(i, State.run, State.metric)?.rsd, true);
		if (noisy) out.push({ label: "Noisiest", item: noisy.item, value: `±${fixed(noisy.score, 1)}%`, cls: noisy.score > 10 ? "bad" : "" });
		const others = Model.platforms().filter(p => p !== State.platform);
		if (others.length) {
			const gap = pick(list, i => {
				const twin = Model.items.get(`${others[0]}|${i.suite}|${i.test}`);
				const a = Model.value(i, State.run, State.metric), b = twin && Model.value(twin, State.run, State.metric);
				return a > 0 && b > 0 ? Math.abs(Math.log(a / b)) : NaN;
			}, true);
			if (gap) {
				const twin = Model.items.get(`${others[0]}|${gap.item.suite}|${gap.item.test}`);
				const ratio = Model.value(gap.item, State.run, State.metric) / Model.value(twin, State.run, State.metric);
				out.push({ label: `Widest ${State.platform} vs ${others[0]} gap`, item: gap.item, value: `${fixed(ratio, ratio < 10 ? 2 : 0)}×` });
			}
		}
		out.push({ label: "Selected run", text: `${shortRun(State.run)} · ${list.length} tests · ${METRICS[State.metric].long} ${fmt === fmtNs ? "(lower is better)" : ""}`.trim() });
		return out;
	}

	function html(x, i) {
		const body = x.item ? `<b>${esc(x.item.name)}</b>${x.value ? `<span class="pill ${x.cls || ""}">${esc(x.value)}</span>` : ""}` : `<b>${esc(x.text)}</b>`;
		return `<button class="tick-item" type="button" data-i="${i}"><i>${esc(x.label)}</i>${body}</button>`;
	}

	function render() {
		items = compute();
		const row = items.map(html).join("");
		belt.innerHTML = row + row;
		belt.style.animationDuration = `${Math.max(30, items.length * 9)}s`;
		if (!pop.hidden) openPop();
	}

	function openPop() {
		const r = tag.getBoundingClientRect();
		pop.style.left = `${r.left}px`;
		pop.style.top = `${r.bottom + window.scrollY + 8}px`;
		pop.innerHTML = items.map((x, i) => `<button type="button" data-i="${i}"><i>${esc(x.label)}</i><span>${esc(x.item ? x.item.name : x.text)}</span>${x.value ? `<span class="pill ${x.cls || ""}">${esc(x.value)}</span>` : "<span></span>"}</button>`).join("");
		pop.hidden = false;
	}

	function activate(e) {
		const b = e.target.closest("[data-i]");
		if (!b) return;
		const x = items[Number(b.dataset.i)];
		pop.hidden = true;
		if (x?.item) Bus.emit("select", { key: x.item.key, open: true });
	}

	belt.addEventListener("click", activate);
	pop.addEventListener("click", activate);
	tag.addEventListener("click", e => {
		e.stopPropagation();
		if (pop.hidden) openPop(); else pop.hidden = true;
	});
	document.addEventListener("click", e => {
		if (!pop.hidden && !pop.contains(e.target)) pop.hidden = true;
	});

	return { render, close: () => { pop.hidden = true; } };
})();
