const Lens = (() => {
	const lens = $("#lens");
	const body = $("#lens-body");
	let target = null, pinned = false;

	$("#lens-ticks").innerHTML = Array.from({ length: 60 }, (_, i) => {
		const a = (i / 60) * Math.PI * 2, long = i % 15 === 0, r1 = long ? 85 : 92, r2 = 98;
		return `<line x1="${(100 + Math.cos(a) * r1).toFixed(2)}" y1="${(100 + Math.sin(a) * r1).toFixed(2)}" x2="${(100 + Math.cos(a) * r2).toFixed(2)}" y2="${(100 + Math.sin(a) * r2).toFixed(2)}"${long ? " class=\"long\"" : ""}/>`;
	}).join("");

	function content() {
		if (!target) return "";
		const fmt = METRICS[State.metric].fmt;
		if (target.kind === "hub") {
			const list = Model.list(State.platform);
			const total = list.reduce((s, i) => s + (Model.value(i, State.run, "time") || 0), 0);
			return `<small>${esc(State.platform)}</small><b>Fusion</b><span class="big">${list.length}</span><div class="row"><span>tests</span><span>${esc(Model.suites(State.platform).length)} suites</span></div><div class="row"><span>Σ ${esc(fmtNs(total))} / op</span></div>`;
		}
		if (target.kind === "suite") {
			const list = Model.list(State.platform).filter(i => i.suite === target.suite);
			const deltas = list.map(i => Model.stat(i).delta);
			const med = median(deltas);
			return `<small>Suite</small><b>${esc(suiteInfo(target.suite).label)}</b><span class="big">${list.length}</span><div class="row"><span>tests</span><span class="pill ${statusOf(med)}">${esc(fmtDelta(med))}</span></div><div class="row"><span>${esc(suiteInfo(target.suite).tags.join(" · "))}</span></div>`;
		}
		const item = Model.items.get(target.key);
		if (!item) return "";
		const s = Model.stat(item);
		const value = Number.isFinite(s.current) ? fmt(s.current) : "waiting";
		return `<small>${esc(item.info.feature)}</small><b>${esc(item.name)}</b><span class="big">${esc(value)}</span>
			<div class="row"><span class="pill ${s.status}">${esc(fmtDelta(s.delta))}</span><span>vs base</span></div>
			<div class="row"><em>best ${esc(fmt(s.best))}</em><strong>worst ${esc(fmt(s.worst))}</strong></div>
			${pinned ? `<button type="button" data-open="${esc(item.key)}">Open deep dive</button>` : ""}`;
	}

	function place() {
		if (!target) return;
		const p = Stage.nodeScreen(target.id);
		if (!p) { hide(); return; }
		const size = lens.offsetWidth || 230;
		const dx = p.x - p.w / 2, dy = p.y - p.h / 2, len = Math.hypot(dx, dy) || 1;
		const push = target.kind === "test" ? -(size / 2 + p.r + 8) : 0;
		let x = p.x + (dx / len) * push - size / 2;
		let y = p.y + (dy / len) * push - size / 2;
		x = Math.max(6, Math.min(p.w - size - 6, x));
		y = Math.max(6, Math.min(p.h - size - 6, y));
		lens.style.transform = `translate(${x}px, ${y}px)`;
	}

	function loop() {
		if (lens.hidden) return;
		place();
		requestAnimationFrame(loop);
	}

	function show(next, isPinned) {
		if (!next) {
			if (!pinned || isPinned) hide();
			return;
		}
		if (pinned && !isPinned) return;
		target = next;
		pinned = isPinned;
		lens.classList.toggle("pinned", pinned);
		body.innerHTML = content();
		const wasHidden = lens.hidden;
		lens.hidden = false;
		lens.classList.remove("open");
		void lens.offsetWidth;
		lens.classList.add("open");
		if (wasHidden) requestAnimationFrame(loop);
	}

	function hide() {
		target = null;
		pinned = false;
		lens.hidden = true;
		Stage.unpin();
	}

	body.addEventListener("click", e => {
		const b = e.target.closest("[data-open]");
		if (b) Bus.emit("select", { key: b.dataset.open, open: true });
	});

	return {
		show, hide,
		refresh() { if (target) body.innerHTML = content(); }
	};
})();
