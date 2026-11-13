const Grid = (() => {
	const pop = $("#grid");
	const scrim = $("#scrim");
	const body = $("#grid-body");
	const filter = $("#grid-filter");
	let focus = 0;

	function spark(item) {
		const v = Model.series(item, State.metric).map(p => p.v);
		if (v.length < 2) return `<svg viewBox="0 0 160 22" preserveAspectRatio="none"><path d="M2,11L158,11" style="stroke:var(--line-2);stroke-dasharray:3 4"/><circle cx="158" cy="11" r="2.5"/></svg>`;
		return `<svg viewBox="0 0 160 22" preserveAspectRatio="none"><path d="${sparkPath(v, 160, 22)}"/></svg>`;
	}

	function render() {
		const q = filter.value.trim().toLowerCase();
		const fmt = METRICS[State.metric].fmt;
		const list = Model.list(State.platform).filter(i => !q || `${i.test} ${i.name} ${i.info.feature} ${i.suite} ${i.info.tags.join(" ")}`.toLowerCase().includes(q));
		if (!list.length) {
			body.innerHTML = `<div class="grid-empty">No test matches “${esc(filter.value)}”.</div>`;
			return;
		}
		let n = 0;
		body.innerHTML = Model.suites(State.platform).map(s => {
			const members = list.filter(i => i.suite === s);
			if (!members.length) return "";
			return `<div class="grid-suite"><i style="background:${suiteColor(s)};box-shadow:0 0 8px ${suiteColor(s)}"></i>${esc(suiteInfo(s).label)}<span>${members.length}</span></div><div class="tiles">${members.map(i => {
				const st = Model.stat(i);
				return `<button class="tile ${st.status}" type="button" data-key="${esc(i.key)}" aria-selected="${i.key === State.selected}" style="animation-delay:${Math.min(n++ * 14, 600)}ms">
					<b>${esc(i.name)}</b><small>${esc(i.info.feature)}</small>${spark(i)}
					<span class="foot"><span class="val">${esc(fmt(st.current ?? st.base))}</span><span class="pill ${st.status}">${esc(fmtDelta(st.delta))}</span></span>
				</button>`;
			}).join("")}</div>`;
		}).join("");
		focus = Math.min(focus, list.length - 1);
		markFocus();
	}

	function tiles() {
		return $$(".tile", body);
	}

	function markFocus() {
		tiles().forEach((t, i) => t.classList.toggle("focus", i === focus));
		tiles()[focus]?.scrollIntoView({ block: "nearest" });
	}

	function columns() {
		const t = tiles();
		if (t.length < 2) return 1;
		const top = t[0].offsetTop;
		const n = t.findIndex(x => x.offsetTop !== top);
		return n < 0 ? t.length : n;
	}

	function open() {
		if (!pop.hidden) return;
		Ticker.close();
		const t = Model.list(State.platform);
		focus = Math.max(0, t.findIndex(i => i.key === State.selected));
		pop.hidden = false;
		scrim.hidden = false;
		render();
		filter.focus();
		filter.select();
	}

	function close() {
		pop.hidden = true;
		if ($("#drawer").hidden) scrim.hidden = true;
	}

	function choose(key) {
		close();
		Bus.emit("select", { key, open: !!key });
	}

	filter.addEventListener("input", () => { focus = 0; render(); });
	body.addEventListener("click", e => {
		const t = e.target.closest(".tile");
		if (t) choose(t.dataset.key);
	});
	$("#grid-all").addEventListener("click", () => choose(null));
	$("#picker").addEventListener("click", open);
	pop.addEventListener("keydown", e => {
		const t = tiles();
		if (e.key === "Escape") { e.preventDefault(); close(); return; }
		if (e.key === "Enter") { e.preventDefault(); if (t[focus]) choose(t[focus].dataset.key); return; }
		const step = { ArrowRight: 1, ArrowLeft: -1, ArrowDown: columns(), ArrowUp: -columns() }[e.key];
		if (step && t.length) {
			e.preventDefault();
			focus = Math.max(0, Math.min(t.length - 1, focus + step));
			markFocus();
		}
	});

	return { open, close, render, isOpen: () => !pop.hidden };
})();
