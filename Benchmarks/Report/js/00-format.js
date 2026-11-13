const $ = (selector, root = document) => root.querySelector(selector);
const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
const reduceMotion = matchMedia("(prefers-reduced-motion: reduce)");

function esc(value) {
	return String(value ?? "").replace(/[&<>"']/g, c => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", "\"": "&quot;", "'": "&#39;" }[c]));
}

function cssVar(name) {
	return getComputedStyle(document.documentElement).getPropertyValue(name).trim() || "#888";
}

function fixed(n, digits) {
	const v = Number(n.toFixed(digits));
	return String(v);
}

function fmtNum(n) {
	if (n == null || !Number.isFinite(n)) return "—";
	const a = Math.abs(n);
	if (a >= 1e9) return fixed(n / 1e9, 2) + "G";
	if (a >= 1e6) return fixed(n / 1e6, 2) + "M";
	if (a >= 1e4) return fixed(n / 1e3, 1) + "k";
	if (a >= 100) return String(Math.round(n));
	return fixed(n, 1);
}

function fmtNs(n) {
	if (n == null || !Number.isFinite(n)) return "—";
	const a = Math.abs(n);
	if (a >= 1e9) return fixed(n / 1e9, 2) + " s";
	if (a >= 1e6) return fixed(n / 1e6, a >= 1e8 ? 0 : 2) + " ms";
	if (a >= 1e3) return fixed(n / 1e3, a >= 1e5 ? 0 : 1) + " µs";
	return Math.round(n) + " ns";
}

function fmtKB(n) {
	if (n == null || !Number.isFinite(n)) return "—";
	const a = Math.abs(n);
	if (a >= 1048576) return fixed(n / 1048576, 2) + " GB";
	if (a >= 1024) return fixed(n / 1024, 1) + " MB";
	return Math.round(n) + " kB";
}

function fmtDelta(d) {
	if (d == null || !Number.isFinite(d)) return "—";
	if (Math.abs(d) < 0.05) return "±0%";
	return (d > 0 ? "+" : "−") + fixed(Math.abs(d), Math.abs(d) >= 100 ? 0 : 1) + "%";
}

function statusOf(d) {
	if (d == null || !Number.isFinite(d)) return "none";
	if (d > 5) return "bad";
	if (d < -5) return "good";
	return "flat";
}

function ago(ms) {
	const s = Math.max(0, Math.round(ms / 1000));
	if (s < 5) return "just now";
	if (s < 60) return s + "s ago";
	if (s < 3600) return Math.floor(s / 60) + "m ago";
	if (s < 86400) return Math.floor(s / 3600) + "h ago";
	return Math.floor(s / 86400) + "d ago";
}

function clock(seconds) {
	const s = Math.max(0, Math.ceil(seconds));
	return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
}

function shortName(test) {
	return test.replace(/^test/, "")
		.replace(/([a-z0-9])([A-Z])/g, "$1 $2")
		.replace(/([A-Z]+)([A-Z][a-z])/g, "$1 $2")
		.replace(/([a-zA-Z])(\d)/g, "$1 $2");
}

function shortRun(run) {
	if (!run) return "—";
	const m = run.match(/^(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})\d{2}-(.+)$/);
	return m ? `${m[2]}/${m[3]} ${m[4]}:${m[5]} · ${m[6].replace(/-dirty$/, "*")}` : run;
}

function median(values) {
	const v = values.filter(Number.isFinite).sort((a, b) => a - b);
	if (!v.length) return null;
	const mid = Math.floor(v.length / 2);
	return v.length % 2 ? v[mid] : (v[mid - 1] + v[mid]) / 2;
}

function geomean(values) {
	const v = values.filter(x => Number.isFinite(x) && x > 0);
	if (!v.length) return null;
	return Math.exp(v.reduce((s, x) => s + Math.log(x), 0) / v.length);
}

function el(tag, className, html) {
	const node = document.createElement(tag);
	if (className) node.className = className;
	if (html != null) node.innerHTML = html;
	return node;
}

function sparkPath(values, w, h, pad = 2) {
	const v = values.filter(Number.isFinite);
	if (!v.length) return "";
	const lo = Math.min(...v), hi = Math.max(...v), span = hi - lo || 1;
	const step = v.length > 1 ? (w - pad * 2) / (v.length - 1) : 0;
	return v.map((x, i) => `${i ? "L" : "M"}${(pad + i * step).toFixed(1)},${(h - pad - ((x - lo) / span) * (h - pad * 2)).toFixed(1)}`).join("");
}

function countUp(node, to, format, duration = 700) {
	const from = Number(node.dataset.value ?? 0);
	node.dataset.value = to;
	if (reduceMotion.matches || !Number.isFinite(from) || from === to) { node.textContent = format(to); return; }
	const start = performance.now();
	const step = now => {
		const t = Math.min(1, (now - start) / duration), e = 1 - Math.pow(1 - t, 3);
		node.textContent = format(from + (to - from) * e);
		if (t < 1) requestAnimationFrame(step);
	};
	requestAnimationFrame(step);
}
