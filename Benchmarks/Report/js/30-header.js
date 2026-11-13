const Header = (() => {
	const platforms = $("#platforms");
	const metrics = $("#metrics");
	const pickerLabel = $("#picker-label");
	const bar = $("#livebar");
	const ring = $("#live-ring-fg");
	const STATE_TEXT = { idle: "Report", starting: "Starting", running: "Live", building: "Building", cooldown: "Cooling", done: "Done", failed: "Failed", cancelled: "Cancelled", replay: "Replay" };
	let lastPlatforms = "", lastMetrics = "";

	function segment(container, options, selected, onPick, cacheKey) {
		const key = `${selected}|${options.map(o => `${o.id}:${o.label}:${o.count ?? ""}`).join(",")}`;
		if (key === cacheKey.value && container.children.length) {
			$$("button", container).forEach(b => b.setAttribute("aria-selected", b.dataset.id === selected ? "true" : "false"));
			requestAnimationFrame(() => moveThumb(container));
			return key;
		}
		cacheKey.value = key;
		container.innerHTML = options.map(o => `<button type="button" role="tab" data-id="${esc(o.id)}" aria-selected="${o.id === selected}">${esc(o.label)}${o.count != null ? `<small>${o.count}</small>` : ""}</button>`).join("") + `<span class="seg-thumb"></span>`;
		container.onclick = e => {
			const b = e.target.closest("button");
			if (b && b.dataset.id !== selected) onPick(b.dataset.id);
		};
		requestAnimationFrame(() => moveThumb(container));
		return key;
	}

	function moveThumb(container) {
		const on = $("[aria-selected=true]", container), thumb = $(".seg-thumb", container);
		if (!on || !thumb) return;
		thumb.style.left = on.offsetLeft + "px";
		thumb.style.width = on.offsetWidth + "px";
	}

	function render() {
		const pCache = { value: lastPlatforms }, mCache = { value: lastMetrics };
		lastPlatforms = segment(platforms, Model.platforms().map(p => ({ id: p, label: p, count: Model.list(p).length })), State.platform, p => {
			State.follow = false;
			setPlatform(p);
		}, pCache);
		lastMetrics = segment(metrics, Object.entries(METRICS).map(([id, m]) => ({ id, label: m.label })), State.metric, m => {
			State.metric = m;
			Bus.emit("change");
		}, mCache);
		const item = State.selected && Model.items.get(State.selected);
		pickerLabel.textContent = item ? `${item.name} · ${item.platform}` : `All tests · ${Model.list(State.platform).length}`;
	}

	function setPlatform(p) {
		if (p === State.platform) return;
		State.platform = p;
		const item = State.selected && Model.items.get(State.selected);
		if (item && item.platform !== p) {
			const twin = Model.items.get(`${p}|${item.suite}|${item.test}`);
			State.selected = twin ? twin.key : null;
		}
		Bus.emit("change");
	}

	function live(info) {
		bar.dataset.state = info.state;
		$("#live-state").textContent = STATE_TEXT[info.state] || info.state;
		$("#live-run").textContent = info.detail || "—";
		const pct = info.total ? Math.min(100, (info.done / info.total) * 100) : info.state === "done" ? 100 : 0;
		ring.style.strokeDasharray = `${pct} 100`;
		ring.style.stroke = info.state === "failed" ? "var(--bad)" : info.state === "cancelled" ? "var(--warn)" : info.state === "building" ? "var(--accent)" : "var(--ok)";
		$("#live-count").textContent = info.total ? `${info.done}/${info.total}` : "—";
	}

	window.addEventListener("resize", () => { moveThumb(platforms); moveThumb(metrics); });

	return { render, live, setPlatform };
})();
