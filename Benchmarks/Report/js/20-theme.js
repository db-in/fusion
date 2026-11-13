const Theme = (() => {
	const KEY = "fusion-bench-theme";
	const root = document.documentElement;
	const media = matchMedia("(prefers-color-scheme: light)");
	const button = $("#theme");

	function stored() {
		try { return localStorage.getItem(KEY); } catch { return null; }
	}

	function current() {
		return root.dataset.theme || (media.matches ? "light" : "dark");
	}

	function apply(mode, save) {
		if (mode === "light" || mode === "dark") root.dataset.theme = mode;
		else delete root.dataset.theme;
		if (save) {
			try { localStorage.setItem(KEY, mode); } catch {}
		}
		const now = current();
		button.dataset.mode = now;
		button.setAttribute("aria-label", now === "dark" ? "Switch to light theme" : "Switch to dark theme");
		button.title = stored() ? `${now} theme (saved)` : `${now} theme (following the system)`;
		Bus.emit("theme", now);
	}

	button.addEventListener("click", () => {
		button.classList.remove("press");
		void button.offsetWidth;
		button.classList.add("press");
		setTimeout(() => button.classList.remove("press"), 450);
		apply(current() === "dark" ? "light" : "dark", true);
	});

	media.addEventListener("change", () => {
		if (!stored()) apply(null, false);
	});

	return { init: () => apply(stored(), false), current };
})();
