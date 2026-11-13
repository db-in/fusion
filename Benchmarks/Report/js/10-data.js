const CATALOG = {
	testNumberToString: {
		feature: "Numeric formatting",
		measures: "Double.toString(decimals:locale:roundingMode:)",
		how: "2,000 iterations formatting a changing Double with 2 decimals in en_US.",
		why: "Used in prices, counters and any on-screen number. Must stay cheap on scroll and tick paths."
	},
	testConvertedDigitsToLocale: {
		feature: "Locale digit conversion",
		measures: "String.convertedDigitsToLocale(_:)",
		how: "2,000 conversions of decimal strings into Arabic-Indic digits for ar_SA.",
		why: "RTL and locale-correct numerals without paying NumberFormatter on every glyph."
	},
	testDateToStringWithFormat: {
		feature: "Date formatting",
		measures: "Date.toString(format:)",
		how: "2,000 format passes with yyyy-MM-dd HH:mm on shifting dates.",
		why: "Common UI date rendering; formatter cache must keep this near a microsecond."
	},
	testUTCDateParsing: {
		feature: "UTC date parsing",
		measures: "DateFormatter.date(from:)",
		how: "2,000 parses of ISO-like UTC strings with fractional seconds.",
		why: "Usually the dominant cost inside JSON decode for dated payloads."
	},
	testUTCDateFormatting: {
		feature: "UTC date formatting",
		measures: "DateFormatter.string(from:)",
		how: "2,000 UTC string encodings of shifting dates.",
		why: "Wire format / logging path; should stay formatter-cached."
	},
	testTimeUnits: {
		feature: "Duration breakdown",
		measures: "Int.toTimeUnits()",
		how: "2,000 conversions of integers into time unit components.",
		why: "Timers and media remaining-time labels."
	},
	testAppGroupURL: {
		feature: "App group path",
		measures: "FileManager.default.appGroup",
		how: "2,000 lookups of the resolved app-group (or Debug) directory.",
		why: "Every file-backed storage and image cache roots here."
	},
	testSilentLoggerWithoutSaving: {
		feature: "Logger hot path",
		measures: "Logger.silent.log(basic:full:save:)",
		how: "2,000 no-op-style log calls with save: false.",
		why: "Logging must not tax release builds when persistence is off."
	},
	testAbsentKeyReads: {
		feature: "Storage miss",
		measures: "DataManageable.value(forKey:) on absent keys",
		how: "2,000 reads across 20 missing file-storage keys.",
		why: "Misses should stay cheap and must not poison the cache with false hits."
	},
	testPresentKeyColdReads: {
		feature: "Storage cold hit",
		measures: "File-backed value(forKey:) after flushing memory cache",
		how: "2,000 reads that force disk/decode by clearing InMemoryCache per iteration.",
		why: "Cold start and widget/extension reads after flushPendingWrites()."
	},
	testFileStorageWrites: {
		feature: "File storage write",
		measures: "IndexedFileStorage.set(_:forKey:)",
		how: "2,000 writes across 20 keys (async persistence path).",
		why: "Write coalescing and key tracking must not stall the caller."
	},
	testPreferredLocale: {
		feature: "Preferred locale",
		measures: "Locale.preferredLocale",
		how: "2,000 preferred-locale resolutions.",
		why: "Formatting and localization entry point; must be cached."
	},
	testLocalized: {
		feature: "Localization lookup",
		measures: "String.localized()",
		how: "2,000 lookups rotating across 50 keys.",
		why: "Table loading and nocache behavior for UI strings."
	},
	testColorHex: {
		feature: "SwiftUI Color(hex:)",
		measures: "Color(hex:)",
		how: "2,000 hex parses into SwiftUI Color.",
		why: "Design-token and remote-theme parsing."
	},
	testJSONEncode: {
		feature: "JSON encode",
		measures: "Encodable.data via JSONEncoder.standard",
		how: "2,000 encodes of a small Codable with a Date.",
		why: "REST bodies and file persistence encode path."
	},
	testJSONDecode: {
		feature: "JSON decode",
		measures: "Decodable.load(data:) via JSONDecoder.standard",
		how: "2,000 decodes of one small dated object.",
		why: "Most of this cost is date parsing; tracks API payload intake."
	},
	testJSONDecodeArrayOf500: {
		feature: "JSON decode (batch)",
		measures: "[Codable].load(data:) for 500 items",
		how: "20 decodes of a 500-element array.",
		why: "List endpoints and bulk sync."
	},
	testAnyCodableKeyPathMap: {
		feature: "AnyCodable mapping",
		measures: "AnyCodable.map(to:keyPath:)",
		how: "2,000 key-path maps into a small Codable.",
		why: "Dynamic JSON / heterogeneous payloads."
	},
	testSHA256OfOneKilobyte: {
		feature: "SHA-256",
		measures: "Data.sha256()",
		how: "2,000 digests of a 1 KB buffer.",
		why: "Integrity checks and cache keys."
	},
	testHMACSHA256: {
		feature: "HMAC-SHA256",
		measures: "String.hmacSHA256(key:)",
		how: "2,000 HMACs of short messages.",
		why: "Request signing and token material."
	},
	testBase64Encode: {
		feature: "Base64 encode",
		measures: "String.encryptBase64",
		how: "2,000 Base64 encodings of short payloads.",
		why: "Transport and file wrappers."
	},
	testRegexReplacing: {
		feature: "Regex replace",
		measures: "String.replacing(regex:with:)",
		how: "2,000 digit-masking replaces.",
		why: "Sanitization and light parsing helpers."
	},
	testContainsCharacters: {
		feature: "Fuzzy contains",
		measures: "String.containsCharacters(_:)",
		how: "2,000 unordered character searches.",
		why: "Search-as-you-type filters."
	},
	testUniqueOf1000: {
		feature: "Array.unique",
		measures: "Sequence.unique()",
		how: "200 passes over 1,000 ints with duplicates.",
		why: "Deduping lists without allocating twice carelessly."
	},
	testFilteredByTextOf1000: {
		feature: "Multi-field filter",
		measures: "Array.filtered(by:fields:)",
		how: "50 filters over 1,000 rows and 2 string fields.",
		why: "In-memory search UIs."
	},
	testThreadSafeRead: {
		feature: "ThreadSafe read",
		measures: "ThreadSafe.wrappedValue get",
		how: "2,000 locked reads.",
		why: "Baseline lock cost for Fusion’s concurrency primitive."
	},
	testThreadSafeMutate: {
		feature: "ThreadSafe mutate",
		measures: "ThreadSafe.mutate",
		how: "2,000 locked increments.",
		why: "Contended updates without GCD barriers."
	},
	testInMemoryCacheGetOrSet: {
		feature: "InMemoryCache",
		measures: "InMemoryCache.getOrSet(key:newValue:)",
		how: "2,000 get-or-set ops over 100 keys.",
		why: "Process-wide memoization for storage and formatters."
	},
	testStateStorageSetAndRead: {
		feature: "StateStorage",
		measures: "In-memory DataManageable set + get",
		how: "2,000 set/get pairs across 50 keys.",
		why: "Ephemeral app state and bind fan-out source."
	},
	testKeychainWriteAndRead: {
		feature: "Keychain",
		measures: "Keychain subscript set + get",
		how: "100 write/read pairs across 10 keys.",
		why: "Secrets path; disk amplification shows up in storage metric."
	},
	testFlushPendingWritesWhenIdle: {
		feature: "Flush idle",
		measures: "StoragePersistence.flushPendingWrites() with empty queue",
		how: "1,000 idle flushes including key-tracking sync.",
		why: "Must stay near free so lifecycle hooks are safe."
	},
	testFlushPendingWritesWith50TrackedFileKeys: {
		feature: "Flush pending file writes",
		measures: "flushPendingWrites() after 50 file-backed sets",
		how: "Setup writes 50 keys; measures one flush (manual start).",
		why: "Widget/extension handoff correctness and cost."
	},
	testSendToTenSubscribers: {
		feature: "DataBindable send",
		measures: "send(forKey:value:) to 10 subscribers",
		how: "2,000 sends after binding 10 cancellables.",
		why: "UI refresh fan-out cost."
	},
	testEaseCalculate: {
		feature: "Easing math",
		measures: "Ease.calculate(_:_:_:)",
		how: "2,000 easing evaluations across all Ease cases.",
		why: "Per-frame tween math."
	},
	testURLCacheAppGroupAccess: {
		feature: "URLCache.appGroup",
		measures: "URLCache.appGroup getter",
		how: "2,000 accesses of the shared app-group URLCache instance.",
		why: "Must return one instance (isDirectory: true keying)."
	},
	testMemoryCacheHit: {
		feature: "Image memory hit",
		measures: "UIImage.loadCache / ImagePipeline memory cache",
		how: "Seeds 20 images, then 2,000 hits.",
		why: "Scroll performance for already-seen assets."
	},
	testMemoryCacheMiss: {
		feature: "Image memory miss",
		measures: "ImagePipeline.cachedImage on missing URLs",
		how: "2,000 misses.",
		why: "Miss path must not allocate or lock heavily."
	},
	testURLCacheLoadAndDecode: {
		feature: "URLCache → decode",
		measures: "loadCache after clearing memory, reading URLCache",
		how: "200 loads of 64 px PNGs from URLCache with memory cleared each time.",
		why: "Disk-cache warm path for the image pipeline."
	},
	testCorruptCachedImageLoad: {
		feature: "Corrupt cache recovery",
		measures: "loadCache on undecodable cached bytes",
		how: "200 loads of non-image bodies stored in URLCache.",
		why: "Failed decode must return nil without poisoning UI."
	},
	testDecodeFullSize1024: {
		feature: "Full image decode",
		measures: "ImagePipeline.decode without maxPixelSize",
		how: "20 decodes of a 1024×1024 PNG.",
		why: "Peak memory baseline for large assets."
	},
	testDecodeDownsampled1024To128: {
		feature: "Downsampled decode",
		measures: "ImagePipeline.decode(..., maxPixelSize: 128)",
		how: "20 thumbnail decodes of a 1024×1024 PNG.",
		why: "Should trade a bit of CPU for much lower peak RAM."
	},
	testFlushCacheWith20Images: {
		feature: "flushCache",
		measures: "UIImage.flushCache()",
		how: "Seeds 20 memory + URLCache entries; measures one flush.",
		why: "Must clear memory and URLCache without deleting open SQLite files unsafely."
	},
	testColorInterpolation: {
		feature: "Color interpolation",
		measures: "UIColor.interpolated(toColor:percentage:)",
		how: "2,000 blends from red to blue.",
		why: "Theme transitions and tween color channels."
	},
	testColorDarker: {
		feature: "Color darker",
		measures: "UIColor.darker(by:)",
		how: "2,000 darken adjustments.",
		why: "Pressed / elevated state colors."
	},
	testSolidImage32: {
		feature: "Solid image",
		measures: "UIImage.solid(color:size:)",
		how: "200 renders of 32×32 solid images.",
		why: "Placeholder and shape generation."
	},
	testTintedImage128: {
		feature: "Image tint",
		measures: "UIImage.tinted(_:)",
		how: "200 tints of a 128×128 image.",
		why: "Template icon recoloring."
	},
	testResizedImage128To64: {
		feature: "Image resize",
		measures: "UIImage.resized(to:)",
		how: "200 resizes from 128 to 64.",
		why: "Manual thumbnailing outside the pipeline."
	},
	testStyledText: {
		feature: "Text styling",
		measures: "String.styled(font:color:)",
		how: "2,000 attributed-string builds.",
		why: "Label / TextConvertible rendering."
	},
	testTextBoundingSize: {
		feature: "Text bounds",
		measures: "styled(...).boundingSize(width:)",
		how: "500 bounding-rect calculations at width 200.",
		why: "Layout measurement for rich text."
	},
	testSizeThatFits: {
		feature: "sizeThatFits",
		measures: "String.sizeThatFits(font:width:)",
		how: "500 size measurements at width 200.",
		why: "UILabel-style fitting without a view."
	}
};

const METRICS = {
	time: { label: "Time", long: "Wall time per op", fmt: fmtNs },
	instructions: { label: "Instructions", long: "Instructions per op", fmt: fmtNum },
	cpu: { label: "CPU", long: "CPU time per op", fmt: fmtNs },
	peak: { label: "Peak", long: "Peak physical memory", fmt: fmtKB }
};

const ALL_METRICS = {
	...METRICS,
	cycles: { label: "Cycles", long: "CPU cycles per op", fmt: fmtNum },
	memory: { label: "Memory", long: "Physical memory delta", fmt: fmtKB },
	disk: { label: "Disk", long: "Logical disk writes", fmt: fmtKB }
};

const SUITES = {
	CorePerformanceTests: { label: "Core", color: "--teal", tags: ["foundation", "codable", "concurrency"] },
	HotPathPerformanceTests: { label: "Hot path", color: "--accent", tags: ["formatting", "storage", "localization"] },
	ImagePipelinePerformanceTests: { label: "Image pipeline", color: "--pink", tags: ["images", "cache", "decode"] },
	UIPerformanceTests: { label: "UI", color: "--violet", tags: ["drawing", "text", "color"] }
};

function suiteInfo(suite) {
	return SUITES[suite] || { label: suite.replace(/PerformanceTests$/, ""), color: "--gold", tags: [] };
}

function suiteColor(suite) {
	return cssVar(suiteInfo(suite).color);
}

function catalog(test, suite) {
	const entry = CATALOG[test] || {
		feature: shortName(test),
		measures: "Fusion hot path",
		how: "XCTest measure with clock, CPU, memory and storage metrics in Release.",
		why: "Tracks regressions on a framework entry point."
	};
	return { ...entry, tags: entry.tags || suiteInfo(suite || "").tags };
}

const State = { platform: null, metric: "time", run: null, selected: null, live: null, follow: true };

const Bus = {
	handlers: {},
	on(name, fn) { (this.handlers[name] ||= []).push(fn); },
	emit(name, payload) { (this.handlers[name] || []).forEach(fn => fn(payload)); }
};

const Model = (() => {
	const items = new Map();
	const runIds = [];
	const meta = new Map(INPUT.runs.map(r => [r.run, r]));
	const samples = new Map();
	const keyOf = r => `${r.platform}|${r.suite}|${r.test}`;

	function addRow(row) {
		const key = keyOf(row);
		let item = items.get(key);
		if (!item) {
			item = { key, platform: row.platform, suite: row.suite, test: row.test, name: shortName(row.test), info: catalog(row.test, row.suite), runs: new Map() };
			items.set(key, item);
		}
		if (!runIds.includes(row.run)) runIds.push(row.run);
		item.runs.set(row.run, { ...item.runs.get(row.run), ...row });
		return item;
	}

	INPUT.history.forEach(addRow);
	INPUT.samples.forEach(s => samples.set(`${keyOf(s)}|${s.run}|${s.metric}`, s));
	INPUT.baseline.forEach(b => {
		const item = items.get(keyOf(b));
		if (item) item.baseline = b;
	});

	const baselineRun = runIds[0] || null;
	const platforms = () => [...new Set([...items.values()].map(i => i.platform))].sort();
	const list = platform => [...items.values()].filter(i => !platform || i.platform === platform)
		.sort((a, b) => a.suite.localeCompare(b.suite) || a.test.localeCompare(b.test));
	const suites = platform => [...new Set(list(platform).map(i => i.suite))];
	const latestRun = () => runIds[runIds.length - 1] || null;
	const value = (item, run, metric) => item?.runs.get(run)?.[metric];

	function series(item, metric) {
		return runIds.filter(r => item.runs.has(r) && Number.isFinite(item.runs.get(r)[metric])).map(r => ({ run: r, v: item.runs.get(r)[metric] }));
	}

	function stat(item, metric = State.metric, run = State.run) {
		const points = series(item, metric).filter(p => p.run !== State.live?.run || p.run === run);
		const base = value(item, baselineRun, metric) ?? item.baseline?.[metric] ?? points[0]?.v;
		const current = value(item, run, metric);
		let best = null, worst = null;
		points.forEach(p => {
			if (!best || p.v < best.v) best = p;
			if (!worst || p.v > worst.v) worst = p;
		});
		const delta = Number.isFinite(current) && base ? ((current - base) / base) * 100 : null;
		const span = worst && best ? worst.v - best.v : 0;
		return {
			base, current, delta,
			best: best?.v, bestRun: best?.run, worst: worst?.v, worstRun: worst?.run,
			position: Number.isFinite(current) && span > 0 ? (current - best.v) / span : 0,
			status: Number.isFinite(current) ? statusOf(delta) : "none",
			points
		};
	}

	function sample(item, run, metric) {
		return samples.get(`${item.key}|${run}|${metric}`) || null;
	}

	function runScore(run, platform, metric) {
		const ratios = list(platform).map(i => {
			const v = value(i, run, metric), b = value(i, baselineRun, metric);
			return Number.isFinite(v) && b ? v / b : null;
		});
		return geomean(ratios);
	}

	function liveRow(run, platform, suite, test, metric, v) {
		const item = addRow({ run, platform, suite, test, date: new Date().toISOString(), commit: "live" });
		if (metric) item.runs.get(run)[metric] = v;
		if (metric) samples.delete(`${item.key}|${run}|${metric}`);
		return item;
	}

	function liveSample(item, run, metric, rsd, values) {
		samples.set(`${item.key}|${run}|${metric}`, { run, metric, rsd, samples: values || [] });
	}

	function dropRun(run) {
		const i = runIds.indexOf(run);
		if (i >= 0) runIds.splice(i, 1);
		items.forEach((item, key) => {
			item.runs.delete(run);
			if (!item.runs.size) items.delete(key);
		});
	}

	return { items, runIds, meta, baselineRun, platforms, list, suites, latestRun, value, series, stat, sample, runScore, liveRow, liveSample, dropRun, keyOf };
})();
