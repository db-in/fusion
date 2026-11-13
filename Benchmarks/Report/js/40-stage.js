const Stage = (() => {
	const host = $("#stage");
	const canvas = $("#orbit");
	const ctx = canvas.getContext("2d");
	const nodes = new Map();
	const particles = [];
	const ripples = [];
	const sprites = new Map();
	const MAX_PARTICLES = 520;
	let W = 1, H = 1, DPR = 1, cx = 0, cy = 0, rx = 1, ry = 1;
	let hoverId = null, pinnedId = null, palette = {}, last = performance.now();

	function readPalette() {
		palette = { ink: cssVar("--ink"), ink2: cssVar("--ink-2"), ink3: cssVar("--ink-3"), line: cssVar("--line"), line2: cssVar("--line-2"), accent: cssVar("--accent"), ok: cssVar("--ok"), bad: cssVar("--bad"), bg: cssVar("--bg") };
		sprites.clear();
	}

	function rgba(color, alpha) {
		const c = color.trim();
		if (c.startsWith("#")) {
			const h = c.length === 4 ? c.slice(1).split("").map(x => x + x).join("") : c.slice(1, 7);
			const n = parseInt(h, 16);
			return `rgba(${n >> 16},${(n >> 8) & 255},${n & 255},${alpha})`;
		}
		const m = c.match(/[\d.]+/g);
		return m ? `rgba(${m[0]},${m[1]},${m[2]},${alpha})` : c;
	}

	function sprite(color) {
		if (sprites.has(color)) return sprites.get(color);
		const size = 64, c = document.createElement("canvas");
		c.width = c.height = size;
		const g = c.getContext("2d"), grad = g.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
		grad.addColorStop(0, rgba(color, 1));
		grad.addColorStop(0.25, rgba(color, 0.55));
		grad.addColorStop(1, rgba(color, 0));
		g.fillStyle = grad;
		g.fillRect(0, 0, size, size);
		sprites.set(color, c);
		return c;
	}

	function resize() {
		const r = host.getBoundingClientRect();
		DPR = Math.min(2, window.devicePixelRatio || 1);
		W = Math.max(1, r.width);
		H = Math.max(1, r.height);
		canvas.width = Math.round(W * DPR);
		canvas.height = Math.round(H * DPR);
		cx = W / 2;
		cy = H / 2 + 6;
		const margin = W > 760 ? 175 : 40;
		rx = Math.max(120, Math.min(W / 2 - margin, H * 0.5));
		ry = Math.max(110, Math.min(H / 2 - margin * 0.62, rx * 0.88));
		layout();
	}

	function ensure(id, props) {
		let n = nodes.get(id);
		if (!n) {
			n = { id, x: cx, y: cy, r: 0, alpha: 0, pulse: 0, flash: 0, phase: Math.random() * Math.PI * 2, ...props };
			nodes.set(id, n);
		}
		Object.assign(n, props);
		return n;
	}

	function colorFor(n) {
		if (n.kind === "hub") return palette.accent;
		if (n.kind === "suite") return suiteColor(n.suite);
		if (n.status === "good") return palette.ok;
		if (n.status === "bad") return palette.bad;
		return suiteColor(n.suite);
	}

	function setData() {
		const list = Model.list(State.platform);
		const suites = Model.suites(State.platform);
		const wanted = new Set(["hub"]);
		const values = list.map(i => Model.value(i, State.run, State.metric) ?? Model.stat(i).base).filter(v => v > 0);
		const lo = Math.log10(Math.min(...values, 1e9)), hi = Math.log10(Math.max(...values, 1));
		ensure("hub", { kind: "hub", label: "Fusion" });
		suites.forEach(s => {
			wanted.add("suite:" + s);
			ensure("suite:" + s, { kind: "suite", suite: s, label: suiteInfo(s).label, count: list.filter(i => i.suite === s).length });
		});
		list.forEach(i => {
			const st = Model.stat(i);
			const v = Number.isFinite(st.current) ? st.current : st.base;
			const norm = v > 0 && hi > lo ? (Math.log10(v) - lo) / (hi - lo) : 0.5;
			wanted.add(i.key);
			ensure(i.key, { kind: "test", key: i.key, suite: i.suite, label: i.name, status: st.status, measured: Number.isFinite(st.current), size: 3.5 + norm * 9, rate: v > 0 ? Math.max(0.08, Math.min(1.3, 1.5 - Math.log10(v) / 5.5)) : 0.2 });
		});
		[...nodes.keys()].forEach(id => { if (!wanted.has(id)) nodes.delete(id); });
		layout();
		renderOverlays();
	}

	function layout() {
		const suites = [...nodes.values()].filter(n => n.kind === "suite");
		const tests = [...nodes.values()].filter(n => n.kind === "test");
		const gap = 2.2;
		const slots = tests.length + suites.length * gap;
		let cursor = gap / 2;
		const hub = nodes.get("hub");
		if (hub) { hub.tx = cx; hub.ty = cy; hub.tr = Math.max(18, Math.min(W, H) * 0.045); }
		suites.forEach(s => {
			const members = tests.filter(t => t.suite === s.suite).sort((a, b) => a.label.localeCompare(b.label));
			const start = cursor;
			members.forEach(t => {
				t.angle = -Math.PI / 2 + ((cursor + 0.5) / slots) * Math.PI * 2;
				t.tx = cx + Math.cos(t.angle) * rx;
				t.ty = cy + Math.sin(t.angle) * ry;
				t.tr = t.size;
				cursor += 1;
			});
			s.angle = -Math.PI / 2 + (((start + cursor) / 2) / slots) * Math.PI * 2;
			s.arc0 = -Math.PI / 2 + (start / slots) * Math.PI * 2;
			s.arc1 = -Math.PI / 2 + (cursor / slots) * Math.PI * 2;
			s.tx = cx + Math.cos(s.angle) * rx * 0.46;
			s.ty = cy + Math.sin(s.angle) * ry * 0.46;
			s.tr = 8 + Math.sqrt(s.count) * 1.6;
			cursor += gap;
		});
	}

	function related(id) {
		if (!id) return null;
		const n = nodes.get(id);
		if (!n) return null;
		const set = new Set([id, "hub"]);
		if (n.kind === "test") set.add("suite:" + n.suite);
		nodes.forEach(m => { if (n.kind !== "hub" && m.suite === n.suite) set.add(m.id); });
		if (n.kind === "hub") nodes.forEach(m => set.add(m.id));
		return set;
	}

	const ease = t => (t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2);

	function wobble(n) {
		if (reduceMotion.matches || n.kind === "hub") return { x: n.x, y: n.y };
		const t = performance.now();
		return { x: n.x + Math.sin(t / 1700 + n.phase) * 1.6, y: n.y + Math.cos(t / 2100 + n.phase) * 1.6 };
	}

	function spawn(test, burst = false) {
		if (particles.length >= MAX_PARTICLES || reduceMotion.matches || document.hidden) return;
		const suite = nodes.get("suite:" + test.suite);
		if (!suite) return;
		particles.push({ path: ["hub", suite.id, test.id], t: 0, speed: (burst ? 1.4 : 0.55) + Math.random() * 0.5, color: colorFor(test), trail: [], size: burst ? 2.4 : 1.6 });
	}

	function pointOn(p) {
		const seg = Math.min(1, Math.floor(p.t));
		const a = nodes.get(p.path[seg]), b = nodes.get(p.path[seg + 1]);
		if (!a || !b) return null;
		const k = ease(Math.min(1, p.t - seg));
		const pa = wobble(a), pb = wobble(b);
		if (seg === 0) return { x: pa.x + (pb.x - pa.x) * k, y: pa.y + (pb.y - pa.y) * k };
		const mx = (pa.x + pb.x) / 2 + (pa.x - cx) * 0.18, my = (pa.y + pb.y) / 2 + (pa.y - cy) * 0.18;
		const u = 1 - k;
		return { x: u * u * pa.x + 2 * u * k * mx + k * k * pb.x, y: u * u * pa.y + 2 * u * k * my + k * k * pb.y };
	}

	function sphere(x, y, r, color, alpha) {
		ctx.globalAlpha = alpha;
		const g = ctx.createRadialGradient(x - r * 0.35, y - r * 0.4, r * 0.1, x, y, r);
		g.addColorStop(0, "rgba(255,255,255,.85)");
		g.addColorStop(0.35, color);
		g.addColorStop(1, rgba(color, 0.55));
		ctx.fillStyle = g;
		ctx.beginPath();
		ctx.arc(x, y, r, 0, Math.PI * 2);
		ctx.fill();
		ctx.globalAlpha = 1;
	}

	function glow(x, y, r, color, alpha) {
		if (alpha <= 0.01) return;
		ctx.globalAlpha = Math.min(1, alpha);
		ctx.drawImage(sprite(color), x - r, y - r, r * 2, r * 2);
		ctx.globalAlpha = 1;
	}

	function label(n, p, focus, dim) {
		if (n.kind !== "test") return;
		const show = focus || W > 760;
		if (!show) return;
		const a = n.angle, flip = Math.cos(a) < 0;
		ctx.save();
		ctx.translate(p.x + Math.cos(a) * (n.r + 7), p.y + Math.sin(a) * (n.r + 7));
		ctx.rotate(flip ? a + Math.PI : a);
		ctx.textAlign = flip ? "right" : "left";
		ctx.textBaseline = "middle";
		ctx.font = `${focus ? 600 : 500} ${focus ? 12 : 10.5}px "Public Sans", system-ui, sans-serif`;
		ctx.fillStyle = focus ? palette.ink : palette.ink2;
		ctx.globalAlpha = dim ? 0.18 : focus ? 1 : n.measured ? 0.62 : 0.3;
		ctx.fillText(n.label, 0, 0);
		ctx.restore();
	}

	function frame(now) {
		const dt = Math.min(0.05, (now - last) / 1000);
		last = now;
		requestAnimationFrame(frame);
		if (document.hidden) return;
		ctx.setTransform(DPR, 0, 0, DPR, 0, 0);
		ctx.clearRect(0, 0, W, H);
		const focusId = pinnedId || hoverId;
		const rel = related(focusId);
		const k = reduceMotion.matches ? 1 : 1 - Math.pow(0.0015, dt);

		nodes.forEach(n => {
			n.x += (n.tx - n.x) * k;
			n.y += (n.ty - n.y) * k;
			n.r += ((n.tr || 4) * (1 + n.pulse * 0.6) - n.r) * k;
			n.alpha += (1 - n.alpha) * k;
			n.pulse = Math.max(0, n.pulse - dt * 1.2);
			n.flash = Math.max(0, n.flash - dt * 0.9);
		});

		ctx.lineWidth = 1;
		ctx.setLineDash([2, 6]);
		ctx.strokeStyle = palette.line;
		[1, 0.46].forEach(f => {
			ctx.beginPath();
			ctx.ellipse(cx, cy, rx * f, ry * f, 0, 0, Math.PI * 2);
			ctx.stroke();
		});
		ctx.setLineDash([]);

		const hub = nodes.get("hub");
		nodes.forEach(n => {
			if (n.kind !== "suite" || !hub) return;
			const dim = rel && !rel.has(n.id);
			const color = colorFor(n);
			ctx.strokeStyle = rgba(color, dim ? 0.05 : 0.28);
			ctx.lineWidth = 1.2;
			ctx.beginPath();
			ctx.moveTo(hub.x, hub.y);
			ctx.lineTo(n.x, n.y);
			ctx.stroke();
			ctx.strokeStyle = rgba(color, dim ? 0.06 : 0.5);
			ctx.lineWidth = 3;
			ctx.lineCap = "round";
			ctx.beginPath();
			ctx.ellipse(cx, cy, rx + 22, ry + 22, 0, n.arc0 + 0.02, n.arc1 - 0.02);
			ctx.stroke();
			ctx.lineCap = "butt";
		});
		nodes.forEach(n => {
			if (n.kind !== "test") return;
			const s = nodes.get("suite:" + n.suite);
			if (!s) return;
			const dim = rel && !rel.has(n.id);
			const p = wobble(n), q = wobble(s);
			ctx.strokeStyle = rgba(colorFor(n), dim ? 0.03 : n.measured ? 0.13 + n.flash * 0.4 : 0.05);
			ctx.lineWidth = 1;
			ctx.beginPath();
			ctx.moveTo(q.x, q.y);
			ctx.quadraticCurveTo((q.x + p.x) / 2 + (q.x - cx) * 0.18, (q.y + p.y) / 2 + (q.y - cy) * 0.18, p.x, p.y);
			ctx.stroke();
		});

		nodes.forEach(n => {
			if (n.kind === "test" && n.measured && Math.random() < n.rate * dt * 0.55) spawn(n);
		});
		for (let i = particles.length - 1; i >= 0; i--) {
			const p = particles[i];
			p.t += dt * p.speed;
			const pt = p.t < 2 ? pointOn(p) : null;
			if (!pt) { particles.splice(i, 1); continue; }
			p.trail.push(pt);
			if (p.trail.length > 9) p.trail.shift();
			const dim = rel && !rel.has(p.path[2]);
			ctx.strokeStyle = rgba(p.color, dim ? 0.05 : 0.35);
			ctx.lineWidth = p.size;
			ctx.lineCap = "round";
			ctx.beginPath();
			p.trail.forEach((q, j) => (j ? ctx.lineTo(q.x, q.y) : ctx.moveTo(q.x, q.y)));
			ctx.stroke();
			glow(pt.x, pt.y, p.size * 4, p.color, dim ? 0.1 : 0.9);
		}

		for (let i = ripples.length - 1; i >= 0; i--) {
			const r = ripples[i];
			r.t += dt;
			const n = nodes.get(r.id);
			if (!n || r.t > 1.4) { ripples.splice(i, 1); continue; }
			const e = r.t / 1.4;
			ctx.strokeStyle = rgba(r.color, 0.7 * (1 - e));
			ctx.lineWidth = 2;
			ctx.beginPath();
			ctx.arc(n.x, n.y, n.r + 4 + e * 34, 0, Math.PI * 2);
			ctx.stroke();
		}

		const ordered = [...nodes.values()].sort((a, b) => (a.kind === "hub") - (b.kind === "hub"));
		ordered.forEach(n => {
			const p = wobble(n);
			const dim = rel && !rel.has(n.id);
			const color = colorFor(n);
			const alpha = n.alpha * (dim ? 0.22 : n.kind === "test" && !n.measured ? 0.35 : 1);
			glow(p.x, p.y, n.r * (n.kind === "hub" ? 3.4 : 2.8) + n.flash * 26, color, alpha * (0.45 + n.flash * 0.8 + (n.id === focusId ? 0.4 : 0)));
			sphere(p.x, p.y, n.r, color, alpha);
			if (n.id === focusId || n.id === State.selected) {
				ctx.strokeStyle = palette.accent;
				ctx.lineWidth = 1.5;
				ctx.beginPath();
				ctx.arc(p.x, p.y, n.r + 5, 0, Math.PI * 2);
				ctx.stroke();
			}
			label(n, p, n.id === focusId || n.id === State.selected, dim);
		});

		if (hub) {
			ctx.textAlign = "center";
			ctx.textBaseline = "middle";
			ctx.fillStyle = palette.bg;
			ctx.font = `700 ${Math.round(hub.r * 0.5)}px "Bricolage Grotesque", system-ui, sans-serif`;
			ctx.fillText("Fusion", hub.x, hub.y);
			ctx.fillStyle = palette.ink2;
			ctx.font = `600 10px "JetBrains Mono", ui-monospace, monospace`;
			ctx.fillText(`${State.platform} · ${METRICS[State.metric].label}`.toUpperCase(), hub.x, hub.y + hub.r + 16);
			nodes.forEach(n => {
				if (n.kind !== "suite") return;
				const dim = rel && !rel.has(n.id);
				ctx.globalAlpha = dim ? 0.25 : 1;
				ctx.fillStyle = palette.ink;
				ctx.font = `600 11px "Public Sans", system-ui, sans-serif`;
				ctx.fillText(n.label, n.x, n.y + n.r + 13);
				ctx.globalAlpha = 1;
			});
		}
	}

	function hit(x, y) {
		let best = null, bestD = Infinity;
		nodes.forEach(n => {
			const d = Math.hypot(n.x - x, n.y - y);
			if (d < n.r + 9 && d < bestD) { best = n; bestD = d; }
		});
		return best;
	}

	canvas.addEventListener("mousemove", e => {
		const r = canvas.getBoundingClientRect();
		const n = hit(e.clientX - r.left, e.clientY - r.top);
		const id = n ? n.id : null;
		canvas.style.cursor = n && n.kind !== "hub" ? "pointer" : "default";
		if (id === hoverId) return;
		hoverId = id;
		Lens.show(n, false);
	});
	canvas.addEventListener("mouseleave", () => {
		hoverId = null;
		Lens.show(null, false);
	});
	canvas.addEventListener("click", e => {
		const r = canvas.getBoundingClientRect();
		const n = hit(e.clientX - r.left, e.clientY - r.top);
		if (!n || n.kind === "hub") { pinnedId = null; Lens.show(null, true); return; }
		if (n.kind === "suite") { pinnedId = n.id; Lens.show(n, true); return; }
		pinnedId = n.id;
		Lens.show(n, true);
		Bus.emit("select", { key: n.key, open: true });
	});

	function renderOverlays() {
		const list = Model.list(State.platform);
		const stats = list.map(i => ({ i, s: Model.stat(i) }));
		const count = st => stats.filter(x => x.s.status === st).length;
		const suites = Model.suites(State.platform);
		const legend = $("#legend");
		const legendHtml = suites.map(s => `<div class="row" style="color:${suiteColor(s)}"><i class="sw"></i><span style="color:var(--ink-2)">${esc(suiteInfo(s).label)}</span><b>${list.filter(i => i.suite === s).length}</b></div>`).join("")
			+ `<hr><div class="row" style="color:var(--ok)"><i class="sw"></i><span style="color:var(--ink-2)">Faster than baseline</span></div><div class="row" style="color:var(--bad)"><i class="sw"></i><span style="color:var(--ink-2)">Slower than baseline</span></div><div class="row" style="color:var(--ink-3)"><span style="color:var(--ink-3);font-size:11px">Size grows with cost, log scale</span></div>`;
		if (legend.dataset.html !== legendHtml) {
			legend.innerHTML = legendHtml;
			legend.dataset.html = legendHtml;
		}
		const measured = stats.filter(x => x.s.status !== "none");
		const med = median(measured.map(x => x.s.delta));
		const kpis = $("#kpis");
		if (!kpis.dataset.ready) {
			kpis.innerHTML = `<div class="kpi"><b data-k="tests">0</b><small>Measured</small></div><div class="kpi" data-c="med"><b data-k="med">0</b><small>Median vs base</small></div><div class="kpi good"><b data-k="good">0</b><small>Faster</small></div><div class="kpi bad"><b data-k="bad">0</b><small>Slower</small></div>`;
			kpis.dataset.ready = "1";
		}
		countUp($("[data-k=tests]", kpis), measured.length, v => `${Math.round(v)}/${list.length}`);
		countUp($("[data-k=med]", kpis), med ?? 0, v => fmtDelta(v));
		countUp($("[data-k=good]", kpis), count("good"), v => String(Math.round(v)));
		countUp($("[data-k=bad]", kpis), count("bad"), v => String(Math.round(v)));
		$("[data-c=med]", kpis).className = `kpi ${statusOf(med)}`;
		$("#stage-title").textContent = `${State.platform} orbit`;
		$("#stage-sub").textContent = `${METRICS[State.metric].long} · ${shortRun(State.run)} · hover to inspect, click for the deep dive`;
	}

	function nodeScreen(id) {
		const n = nodes.get(id);
		if (!n) return null;
		const p = wobble(n);
		return { x: p.x, y: p.y, r: n.r, w: W, h: H };
	}

	function pulse(key) {
		const n = nodes.get(key);
		if (!n) return;
		n.pulse = 1;
		ripples.push({ id: key, t: 0, color: palette.accent });
		for (let i = 0; i < 6; i++) setTimeout(() => spawn(n, true), i * 70);
	}

	function flash(key) {
		const n = nodes.get(key);
		if (!n) return;
		n.flash = 1;
		ripples.push({ id: key, t: 0, color: colorFor(n) });
		spawn(n, true);
	}

	function unpin() {
		pinnedId = null;
	}

	Bus.on("theme", () => { readPalette(); });
	new ResizeObserver(resize).observe(host);
	readPalette();

	return {
		start() { resize(); requestAnimationFrame(frame); },
		setData, nodeScreen, pulse, flash, unpin, renderOverlays,
		node: id => nodes.get(id)
	};
})();
