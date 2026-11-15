const Settings = (() => {
	const SPIN_KEY = "benchmarks-orbit-spin";
	let spin = false;
	let button = null;
	let pop = null;

	function apply() {
		if (!button || !pop) return;
		const toggle = pop.querySelector("[data-toggle=spin]");
		if (toggle) toggle.setAttribute("aria-checked", String(spin));
		button.dataset.count = spin ? "1" : "";
		if (typeof Stage !== "undefined") Stage.setSpin(spin);
	}

	function open() {
		pop.hidden = false;
		const rect = button.getBoundingClientRect();
		const width = pop.offsetWidth || 280;
		const left = Math.min(Math.max(8, rect.right - width), innerWidth - width - 8);
		pop.style.top = `${Math.round(rect.bottom + 8)}px`;
		pop.style.left = `${Math.round(Math.max(8, left))}px`;
		pop.style.right = "auto";
		pop.style.maxHeight = `${Math.round(innerHeight - rect.bottom - 16)}px`;
	}

	function close() {
		if (pop) pop.hidden = true;
	}

	function init() {
		button = $("#settings-btn");
		pop = $("#settings-pop");
		if (!button || !pop) return;
		try { spin = localStorage.getItem(SPIN_KEY) === "1"; } catch {}
		pop.innerHTML = `
			<div class="sp-head"><h3>Display</h3><button type="button" class="sp-close" data-close aria-label="Close settings"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18"/></svg></button></div>
			<div class="sp-toggles">
				<button type="button" class="sp-toggle" role="switch" data-toggle="spin" aria-checked="false">
					<span><b>Spin orbit</b><small>Suites and tests drift around the hub</small></span>
					<i aria-hidden="true"></i>
				</button>
			</div>`;
		button.addEventListener("click", e => {
			e.stopPropagation();
			if (pop.hidden) open();
			else close();
		});
		pop.addEventListener("click", e => {
			e.stopPropagation();
			if (e.target.closest("[data-close]")) { close(); return; }
			if (!e.target.closest("[data-toggle=spin]")) return;
			spin = !spin;
			try { localStorage.setItem(SPIN_KEY, spin ? "1" : "0"); } catch {}
			apply();
		});
		document.addEventListener("click", () => close());
		document.addEventListener("keydown", e => {
			if (e.key === "Escape" && pop && !pop.hidden) {
				e.stopImmediatePropagation();
				close();
			}
		}, true);
		apply();
	}

	return { init, close };
})();
