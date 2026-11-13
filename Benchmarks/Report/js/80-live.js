const Live = (() => {
	const STALE_MS = 10 * 60 * 1000;
	const ACTIVE = ["starting", "running"];
	const wanted = /live/.test(location.hash);
	let script = null, timer = null, loaded = false;
	let run = null, seen = 0, watched = false, phases = {}, reloading = false;
	let replay = null, refresh = null, lastPanels = 0, lastSeen = "";

	function poll() {
		script?.remove();
		script = document.createElement("script");
		script.src = `.live/live.js?t=${Date.now()}`;
		script.onerror = () => {
			if (!loaded && !wanted) clearInterval(timer);
		};
		document.head.appendChild(script);
	}

	function measuredCount(id) {
		let n = 0;
		Model.items.forEach(i => { if (Number.isFinite(i.runs.get(id)?.time)) n++; });
		return n;
	}

	function phaseLabel(snap) {
		return PHASES.find(p => p.id === snap.phase)?.label || "Preparing";
	}

	function headerInfo() {
		if (replay) {
			return { state: "replay", detail: `${shortRun(replay.source)} · ${replay.done}/${replay.total}`, done: replay.done, total: replay.total };
		}
		const snap = State.live;
		if (!snap) {
			return { state: "idle", detail: `${shortRun(State.run)} · ${Model.runIds.length} run${Model.runIds.length === 1 ? "" : "s"}`, done: 0, total: 0 };
		}
		const total = (snap.expected?.macOS || 0) + (snap.expected?.iOS || 0);
		const cooling = ACTIVE.includes(snap.state) && /^cooldown/.test(snap.phase || "");
		const detail = ACTIVE.includes(snap.state) ? `${phaseLabel(snap)} · ${ago(Date.now() - snap.startedAt).replace(" ago", "")}` : `${shortRun(snap.run)} · ${ago(Date.now() - snap.updatedAt)}`;
		return { state: cooling ? "cooldown" : snap.state, detail, done: measuredCount(snap.run), total };
	}

	function schedule() {
		if (refresh) return;
		refresh = setTimeout(() => {
			refresh = null;
			const heavy = Date.now() - lastPanels > 1500;
			if (heavy) lastPanels = Date.now();
			Bus.emit("render", { heavy });
		}, 250);
	}

	function apply(e, animate) {
		if (!e || !e.platform || !e.test) return;
		const item = Model.liveRow(run, e.platform, e.suite, e.test, e.kind === "measured" ? e.metric : null, e.value);
		if (e.kind === "ops") item.runs.get(run).ops = e.ops;
		if (e.kind === "measured") Model.liveSample(item, run, e.metric, e.rsd, e.samples);
		if (!animate) return;
		if (e.kind === "started" && State.follow && e.platform !== State.platform) {
			State.platform = e.platform;
			Bus.emit("change");
		}
		Log.event(e);
		if (e.kind === "started") setTimeout(() => Stage.pulse(item.key), 60);
		if (e.kind === "measured" && e.metric === State.metric) setTimeout(() => Stage.flash(item.key), 60);
	}

	function trackPhases(snap, animate) {
		(snap.phases || []).forEach(p => {
			if (phases[p.id] !== p.state && animate && p.state !== "pending") Log.phase(p.label, p.state, p.endedAt || p.startedAt);
			phases[p.id] = p.state;
		});
		if (snap.error && phases.__error !== snap.error) {
			phases.__error = snap.error;
			if (animate) Log.line("error", esc(snap.error));
		}
	}

	function begin(snap) {
		run = snap.run;
		seen = 0;
		phases = {};
		State.follow = true;
		State.run = run;
		if (!Model.meta.has(run)) Model.meta.set(run, { run, runner: snap.runner, ...snap.env });
		Log.reset(ACTIVE.includes(snap.state) ? "Streaming from .live/live.js." : "Last streamed run.");
	}

	function receive(snap) {
		loaded = true;
		if (!snap || reloading) return;
		const fresh = Date.now() - (snap.updatedAt || 0) < STALE_MS;
		const active = ACTIVE.includes(snap.state) && fresh;
		if (replay && !active) return;
		if (replay) stopReplay();
		const changed = `${snap.run}|${snap.state}` !== lastSeen;
		lastSeen = `${snap.run}|${snap.state}`;
		if (!fresh || (snap.state === "done" && !watched && snap.run !== run)) {
			if (State.live) {
				State.live = null;
				Bus.emit("change");
			}
			Header.live(headerInfo());
			if (snap.state === "done" && fresh) Header.live({ state: "done", detail: `${shortRun(snap.run)} · ${ago(Date.now() - snap.updatedAt)}`, done: 0, total: 0 });
			return;
		}
		if (snap.run !== run) begin(snap);
		if (active) watched = true;
		State.live = snap;
		const events = snap.events || [];
		const recent = Date.now() - 4000;
		for (let i = seen; i < events.length; i++) apply(events[i], seen > 0 || events[i].t > recent);
		const grew = events.length !== seen;
		seen = events.length;
		trackPhases(snap, true);
		Header.live(headerInfo());
		if (grew || ACTIVE.includes(snap.state)) schedule();
		if (snap.state === "done" && watched) {
			reloading = true;
			Log.line("phase", "Run complete, reloading with the new history…");
			setTimeout(() => location.reload(), 1500);
		} else if (!active && changed) {
			Bus.emit("change");
		}
	}

	function events(item, source) {
		const out = [];
		const r = item.runs.get(source);
		const base = { platform: item.platform, suite: item.suite, test: item.test };
		out.push({ ...base, kind: "started" });
		if (r.ops) out.push({ ...base, kind: "ops", ops: r.ops });
		Object.keys(ALL_METRICS).forEach(m => {
			if (!Number.isFinite(r[m])) return;
			const sm = Model.sample(item, source, m);
			out.push({ ...base, kind: "measured", metric: m, value: r[m], rsd: sm?.rsd ?? null, samples: sm?.samples || [] });
		});
		return out;
	}

	function startReplay() {
		if (replay || (State.live && ACTIVE.includes(State.live.state))) return;
		const source = State.run;
		const order = ["macOS", "iOS"];
		const items = Model.list().filter(i => i.runs.has(source)).sort((a, b) => order.indexOf(a.platform) - order.indexOf(b.platform));
		if (!items.length) return;
		const id = `replay-${source}`;
		replay = { source, id, done: 0, total: items.length, timers: [], previousRun: source, previousLive: State.live };
		run = id;
		Model.meta.set(id, { ...Model.meta.get(source), run: id, runner: "replay" });
		Log.reset(`Replaying ${shortRun(source)}.`);
		const step = Math.max(80, 20000 / items.length);
		const t0 = Date.now();
		const snap = {
			run: id, runner: "replay", state: "running", startedAt: t0, updatedAt: t0, phase: "build-macos", expected: {}, env: Model.meta.get(source) || {}, error: null,
			phases: PHASES.map(p => ({ id: p.id, label: p.label, state: "pending", startedAt: null, endedAt: null }))
		};
		const setPhase = (pid, st) => {
			const p = snap.phases.find(x => x.id === pid);
			if (!p) return;
			p.state = st;
			if (st === "running") { p.startedAt = Date.now(); snap.phase = pid; }
			else p.endedAt = Date.now();
			Log.phase(p.label, st);
		};
		State.live = snap;
		State.run = id;
		State.follow = true;
		Model.liveRow(id, items[0].platform, items[0].suite, items[0].test);
		Bus.emit("change");
		["build-macos", "cooldown-macos"].forEach(p => { setPhase(p, "running"); setPhase(p, "done"); });
		setPhase("measure-macos", "running");
		items.forEach((item, n) => {
			replay.timers.push(setTimeout(() => {
				if (item.platform === "iOS" && snap.phase === "measure-macos") {
					setPhase("measure-macos", "done");
					["build-ios", "cooldown-ios"].forEach(p => { setPhase(p, "running"); setPhase(p, "done"); });
					setPhase("measure-ios", "running");
				}
				events(item, source).forEach((e, k) => replay.timers.push(setTimeout(() => apply({ ...e, t: Date.now() }, true), k * Math.min(40, step / 10))));
				replay.done = n + 1;
				snap.updatedAt = Date.now();
				Header.live(headerInfo());
				schedule();
			}, 400 + n * step));
		});
		replay.timers.push(setTimeout(() => {
			setPhase(snap.phase, "done");
			["parse", "report"].forEach(p => { setPhase(p, "running"); setPhase(p, "done"); });
			snap.state = "done";
			Header.live({ state: "done", detail: `Replay of ${shortRun(source)} finished`, done: replay.total, total: replay.total });
			replay.timers.push(setTimeout(stopReplay, 2500));
		}, 600 + items.length * step));
	}

	function stopReplay() {
		if (!replay) return;
		replay.timers.forEach(clearTimeout);
		Model.dropRun(replay.id);
		Model.meta.delete(replay.id);
		State.run = replay.previousRun;
		State.live = replay.previousLive;
		replay = null;
		run = null;
		seen = 0;
		Log.idle();
		Bus.emit("change");
		Header.live(headerInfo());
	}

	window.fusionLive = receive;

	$("#replay").addEventListener("click", () => (replay ? stopReplay() : startReplay()));

	return {
		start() {
			Header.live(headerInfo());
			poll();
			timer = setInterval(poll, 1000);
			setInterval(() => Header.live(headerInfo()), 5000);
		},
		isActive: () => !!State.live && ACTIVE.includes(State.live.state),
		isReplaying: () => !!replay,
		stopReplay
	};
})();
