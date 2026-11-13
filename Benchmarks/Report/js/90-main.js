const App = (() => {
	let ready = false;

	function readHash() {
		const params = new URLSearchParams(location.hash.slice(1).replace(/&?live&?/, "&"));
		const metric = params.get("metric");
		if (metric && METRICS[metric]) State.metric = metric;
		const test = params.get("test");
		if (test && Model.items.has(test)) {
			State.selected = test;
			State.platform = Model.items.get(test).platform;
		}
	}

	function writeHash() {
		const parts = [];
		if (/live/.test(location.hash)) parts.push("live");
		if (State.metric !== "time") parts.push(`metric=${State.metric}`);
		if (State.selected) parts.push(`test=${encodeURIComponent(State.selected)}`);
		const next = parts.length ? `#${parts.join("&")}` : location.pathname + location.search;
		window.history.replaceState(null, "", next);
	}

	function defaults() {
		const platforms = Model.platforms();
		State.platform = platforms.slice().sort((a, b) => Model.list(b).length - Model.list(a).length)[0] || "macOS";
		State.run = Model.latestRun();
	}

	function render(heavy = true) {
		if (!ready) return;
		if (!Model.list(State.platform).length && Model.platforms().length) State.platform = Model.platforms()[0];
		Header.render();
		Stage.setData();
		Lens.refresh();
		Rail.render();
		Desk.render();
		if (heavy) {
			Ticker.render();
			Panels.render();
			if (!Live.isActive() && !Live.isReplaying()) Log.idle();
		}
		if (Grid.isOpen()) Grid.render();
		if (Drawer.isOpen()) Drawer.render();
		const meta = Model.meta.get(State.run);
		$("#foot-meta").textContent = `${Model.runIds.length} run${Model.runIds.length === 1 ? "" : "s"} · ${Model.items.size} test rows${meta?.commit ? ` · ${String(meta.commit).slice(0, 10)}${meta.dirty ? " (dirty)" : ""}` : ""}`;
	}

	function typing(e) {
		return /^(INPUT|TEXTAREA|SELECT)$/.test(e.target.tagName);
	}

	document.addEventListener("keydown", e => {
		if (e.metaKey || e.ctrlKey || e.altKey) return;
		if (e.key === "Escape") {
			if (Grid.isOpen()) Grid.close();
			else if (Drawer.isOpen()) Bus.emit("select", { key: null });
			else Lens.hide();
			return;
		}
		if (typing(e)) return;
		if (e.key === "/" || e.key === "t" || e.key === "T") {
			e.preventDefault();
			Grid.open();
		} else if (Drawer.isOpen() && !Grid.isOpen() && (e.key === "ArrowLeft" || e.key === "ArrowRight")) {
			e.preventDefault();
			Drawer.move(e.key === "ArrowLeft" ? -1 : 1);
		}
	});

	Bus.on("change", () => { render(true); writeHash(); });
	Bus.on("render", ({ heavy }) => render(heavy));
	Bus.on("theme", () => render(true));
	Bus.on("select", ({ key, open }) => {
		State.selected = key && Model.items.has(key) ? key : null;
		const item = State.selected && Model.items.get(State.selected);
		if (item && item.platform !== State.platform) {
			State.platform = item.platform;
			State.follow = false;
		}
		if (!State.selected) {
			Drawer.close();
			Lens.hide();
		}
		render(true);
		if (State.selected && open) Drawer.open();
		writeHash();
	});

	function start() {
		defaults();
		readHash();
		Theme.init();
		ready = true;
		Stage.start();
		render(true);
		if (State.selected) Drawer.open();
		Live.start();
	}

	return { start, render };
})();

App.start();
