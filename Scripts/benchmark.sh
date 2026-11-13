#!/bin/bash
set -euo pipefail

if [ -z "${FUSION_CLEAN_ENV:-}" ] && { [ -n "${XCODE_VERSION_ACTUAL:-}" ] || [ -n "${ACTION:-}" ]; }; then
	CLEAN_ENV=(
		HOME="${HOME}"
		USER="${USER:-}"
		PATH="${PATH}"
		LANG="${LANG:-en_US.UTF-8}"
		TMPDIR="${TMPDIR:-/tmp}"
		FUSION_RUNNER=xcode
		FUSION_CLEAN_ENV=1
	)
	if [ -n "${DEVELOPER_DIR:-}" ]; then
		CLEAN_ENV+=(DEVELOPER_DIR="${DEVELOPER_DIR}")
	fi
	exec env -i "${CLEAN_ENV[@]}" /bin/bash "$0" "$@"
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BENCH="${ROOT}/Benchmarks"
REPORT_DIR="${BENCH}/Report"
HISTORY_TSV="${BENCH}/history.tsv"
HISTORY_MD="${BENCH}/HISTORY.md"
REPORT_HTML="${BENCH}/report.html"
BASELINE_TSV="${BENCH}/Baselines/2.1.1-M4Pro.tsv"
BASELINE_MD="${BENCH}/Baselines/2.1.1-M4Pro.md"
BASELINE_RUN="2.1.1-M4Pro"
RESULTS_DIR="${BENCH}/Results"
LIVE_DIR="${BENCH}/.live"
LIVE_JS="${LIVE_DIR}/live.js"
LIVE_EVENTS="${LIVE_DIR}/events.ndjson"
LIVE_STATE="${LIVE_DIR}/state.env"
FIXTURES_DIR="${ROOT}/Scripts/fixtures"
DEVICE="iPhone 17"
OS_VERSION=""
COOLDOWN=20
OPEN_REPORT=1
REPORT_ONLY=0
SIMULATE=0
SIMULATE_SPEED=1
FIXTURE=""
FUSION_RUNNER="${FUSION_RUNNER:-command}"
APPEND_HISTORY=1
CHILD_PID=""
RUN_DIR=""
RESULTS=""
OPERATIONS=""
LIVE_LAST_FLUSH=0
LIVE_OPS_CACHE=""

PHASE_IDS=(build-macos cooldown-macos measure-macos build-ios cooldown-ios measure-ios parse report)
PHASE_LABELS=("Build macOS" "Cooldown" "Measure macOS" "Build iOS" "Cooldown" "Measure iOS" "Parse" "Report")

while [ $# -gt 0 ]; do
	case "$1" in
		--device) DEVICE="$2"; shift 2 ;;
		--os) OS_VERSION="$2"; shift 2 ;;
		--cooldown) COOLDOWN="$2"; shift 2 ;;
		--no-open) OPEN_REPORT=0; shift ;;
		--report-only) REPORT_ONLY=1; shift ;;
		--simulate)
			SIMULATE=1
			if [ $# -gt 1 ] && [[ "$2" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
				SIMULATE_SPEED="$2"
				shift 2
			else
				shift
			fi
			;;
		--fixture) FIXTURE="$2"; shift 2 ;;
		-h|--help)
			echo "Usage: Scripts/benchmark.sh [--report-only] [--simulate [speed]] [--fixture running|cooldown|done|failed|cancelled] [--no-open] [--device name] [--os version] [--cooldown secs]"
			echo "Runs Fusion benchmarks, streams live progress to report.html, appends HISTORY.md."
			exit 0
			;;
		*) echo "Unknown option: $1"; exit 1 ;;
	esac
done

mkdir -p "${BENCH}/Baselines" "$LIVE_DIR"

COMMIT="$(git -C "$ROOT" rev-parse --short HEAD 2>/dev/null || echo unknown)"
DIRTY=0
if [ -n "$(git -C "$ROOT" status --porcelain 2>/dev/null || true)" ]; then
	COMMIT="${COMMIT}-dirty"
	DIRTY=1
fi
STAMP="$(date +%Y%m%d-%H%M%S)"
RUN_ID="${STAMP}-${COMMIT}"
if [ "$SIMULATE" = "1" ]; then
	RUN_ID="simulate-${STAMP}"
fi

now_ms() {
	perl -MTime::HiRes=time -e 'printf "%d\n", int(time * 1000)' 2>/dev/null || echo $(( $(date +%s) * 1000 ))
}

json_escape() {
	local s="$1"
	s="${s//\\/\\\\}"
	s="${s//\"/\\\"}"
	s="${s//$'\n'/\\n}"
	s="${s//$'\r'/}"
	s="${s//$'\t'/\\t}"
	printf '%s' "$s"
}

awk_escape() {
	local s="$1"
	s="${s//\\/\\\\}"
	s="${s//&/\\&}"
	printf '%s' "$s"
}

ops_for_test() {
	local test="$1"
	case "$test" in
		*FlushPendingWritesWith50*|*FlushCacheWith20*) echo 1 ;;
		*JSONDecodeArrayOf500*|*DecodeFullSize*|*DecodeDownsampled*) echo 20 ;;
		*Keychain*|*URLCacheLoad*|*Corrupt*|*Solid*|*Tinted*|*Resized*) echo 200 ;;
		*FilteredByText*) echo 50 ;;
		*UniqueOf1000*|*SizeThatFits*|*TextBounding*) echo 500 ;;
		*FlushPendingWritesWhenIdle*) echo 1000 ;;
		*) echo 2000 ;;
	esac
}

metric_key() {
	case "$1" in
		"Clock Monotonic Time, s") echo time ;;
		"CPU Time, s") echo cpu ;;
		"CPU Instructions Retired, kI") echo instructions ;;
		"CPU Cycles, kC") echo cycles ;;
		"Memory Physical, kB") echo memory ;;
		"Memory Peak Physical, kB") echo peak ;;
		"Disk Logical Writes, kB") echo disk ;;
		*) echo "" ;;
	esac
}

ensure_history_header() {
	if [ ! -f "$HISTORY_TSV" ]; then
		printf "run_id\tdate\tcommit\tplatform\tsuite\ttest\tops\ttime_ns\tcpu_ns\tinstructions\tcycles\tmemory_kb\tpeak_kb\tdisk_kb\n" > "$HISTORY_TSV"
	fi
}

prepare_run_dir() {
	RUN_DIR="${RESULTS_DIR}/${RUN_ID}"
	RESULTS="${RUN_DIR}/results.tsv"
	OPERATIONS="${RUN_DIR}/operations.tsv"
	mkdir -p "$RUN_DIR"
	printf "platform\tsuite\ttest\tmetric\taverage\tstddev_percent\tsamples\n" > "$RESULTS"
	: > "$OPERATIONS"
}

live_phase_label() {
	local id="$1" i
	for i in "${!PHASE_IDS[@]}"; do
		if [ "${PHASE_IDS[$i]}" = "$id" ]; then
			echo "${PHASE_LABELS[$i]}"
			return
		fi
	done
	echo "$id"
}

live_init() {
	mkdir -p "$LIVE_DIR"
	: > "$LIVE_EVENTS"
	local started
	started="$(now_ms)"
	{
		echo "version=1"
		echo "run=${RUN_ID}"
		echo "runner=${FUSION_RUNNER}"
		echo "state=starting"
		echo "startedAt=${started}"
		echo "updatedAt=${started}"
		echo "cooldownEndsAt="
		echo "phase="
		echo "error="
		echo "env_model="
		echo "env_cpu="
		echo "env_cores="
		echo "env_memoryGB="
		echo "env_macos="
		echo "env_xcode="
		echo "env_swift="
		echo "env_power="
		echo "env_thermal="
		echo "env_iosDevice="
		echo "expected_macOS=$(awk -F'\t' 'NR>1 && $4=="macOS"{c[$6]=1} END{print length(c)+0}' "$HISTORY_TSV" 2>/dev/null || echo 0)"
		echo "expected_iOS=$(awk -F'\t' 'NR>1 && $4=="iOS"{c[$6]=1} END{print length(c)+0}' "$HISTORY_TSV" 2>/dev/null || echo 0)"
		for id in "${PHASE_IDS[@]}"; do
			echo "phase_${id}=pending"
			echo "phase_${id}_started="
			echo "phase_${id}_ended="
		done
	} > "$LIVE_STATE"
	LIVE_OPS_CACHE=""
	LIVE_LAST_FLUSH=0
	live_flush
}

live_set() {
	local key="$1" value="$2"
	if grep -q "^${key}=" "$LIVE_STATE" 2>/dev/null; then
		local tmp="${LIVE_STATE}.tmp"
		awk -F= -v k="$key" -v v="$value" 'BEGIN{OFS="="} $1==k{$0=k"="v} {print}' "$LIVE_STATE" > "$tmp"
		cat "$tmp" > "$LIVE_STATE"
		rm -f "$tmp"
	else
		echo "${key}=${value}" >> "$LIVE_STATE"
	fi
}

live_get() {
	local key="$1"
	awk -F= -v k="$key" '$1==k{print substr($0,index($0,"=")+1); exit}' "$LIVE_STATE" 2>/dev/null || true
}

live_phase() {
	local id="$1" state="$2"
	local t
	t="$(now_ms)"
	live_set "phase_${id}" "$state"
	if [ "$state" = "running" ]; then
		live_set "phase_${id}_started" "$t"
		live_set "phase" "$id"
		live_set "state" "running"
	elif [ "$state" = "done" ] || [ "$state" = "failed" ] || [ "$state" = "skipped" ]; then
		live_set "phase_${id}_ended" "$t"
	fi
	live_set "updatedAt" "$t"
	live_flush
}

live_event() {
	echo "$1" >> "$LIVE_EVENTS"
}

live_env_from_file() {
	local file="$1"
	[ -f "$file" ] || return 0
	while IFS= read -r line || [ -n "$line" ]; do
		case "$line" in
			model:*) live_set env_model "${line#model: }" ;;
			cpu:*) live_set env_cpu "${line#cpu: }" ;;
			cores:*) live_set env_cores "${line#cores: }" ;;
			memory_gb:*) live_set env_memoryGB "${line#memory_gb: }" ;;
			macos:*) live_set env_macos "${line#macos: }" ;;
			xcode:*) live_set env_xcode "${line#xcode: }" ;;
			swift:*) live_set env_swift "${line#swift: }" ;;
			power:*) live_set env_power "${line#power: }" ;;
			thermal:*) live_set env_thermal "${line#thermal: }" ;;
			ios_device:*) live_set env_iosDevice "${line#ios_device: }" ;;
		esac
	done < "$file"
}

live_finish() {
	local state="$1"
	local err="${2:-}"
	live_set "state" "$state"
	live_set "error" "$err"
	live_set "updatedAt" "$(now_ms)"
	live_set "cooldownEndsAt" ""
	live_flush
}

live_flush() {
	local tmp="${LIVE_JS}.tmp"
	LIVE_LAST_FLUSH="$(now_ms)"
	awk -v events_file="$LIVE_EVENTS" -v updated="$LIVE_LAST_FLUSH" '
	BEGIN {
		labels["build-macos"]="Build macOS"
		labels["cooldown-macos"]="Cooldown"
		labels["measure-macos"]="Measure macOS"
		labels["build-ios"]="Build iOS"
		labels["cooldown-ios"]="Cooldown"
		labels["measure-ios"]="Measure iOS"
		labels["parse"]="Parse"
		labels["report"]="Report"
		order="build-macos cooldown-macos measure-macos build-ios cooldown-ios measure-ios parse report"
		n = split(order, ids, " ")
	}
	{
		i = index($0, "=")
		if (i > 0) kv[substr($0,1,i-1)] = substr($0, i+1)
	}
	function esc(s,   t) {
		t = s
		gsub(/\\/, "\\\\", t)
		gsub(/"/, "\\\"", t)
		return t
	}
	function num_or_null(v) { return (v == "" ? "null" : v) }
	function str_or_null(v) { return (v == "" ? "null" : "\"" esc(v) "\"") }
	END {
		print "window.fusionLive({"
		printf "  version: 1, run: \"%s\", runner: \"%s\",\n", esc(kv["run"]), esc(kv["runner"])
		printf "  state: \"%s\",\n", esc(kv["state"])
		printf "  startedAt: %s, updatedAt: %s, cooldownEndsAt: %s,\n", kv["startedAt"]+0, updated, num_or_null(kv["cooldownEndsAt"])
		printf "  phase: %s,\n", str_or_null(kv["phase"])
		printf "  phases: ["
		for (i = 1; i <= n; i++) {
			id = ids[i]
			if (i > 1) printf ", "
			printf "{ id: \"%s\", label: \"%s\", state: \"%s\", startedAt: %s, endedAt: %s }", id, labels[id], (kv["phase_" id] == "" ? "pending" : kv["phase_" id]), num_or_null(kv["phase_" id "_started"]), num_or_null(kv["phase_" id "_ended"])
		}
		print "],"
		printf "  expected: { macOS: %s, iOS: %s },\n", kv["expected_macOS"]+0, kv["expected_iOS"]+0
		printf "  env: { model: \"%s\", cpu: \"%s\", cores: \"%s\", memoryGB: \"%s\", macos: \"%s\", xcode: \"%s\", swift: \"%s\", power: \"%s\", thermal: \"%s\", iosDevice: \"%s\" },\n", esc(kv["env_model"]), esc(kv["env_cpu"]), esc(kv["env_cores"]), esc(kv["env_memoryGB"]), esc(kv["env_macos"]), esc(kv["env_xcode"]), esc(kv["env_swift"]), esc(kv["env_power"]), esc(kv["env_thermal"]), esc(kv["env_iosDevice"])
		print "  events: ["
		if ((getline line < events_file) > 0) {
			print "    " line
			while ((getline line < events_file) > 0) print "    ," line
			close(events_file)
		}
		print "  ],"
		if (kv["error"] != "") printf "  error: \"%s\"\n", esc(kv["error"])
		else print "  error: null"
		print "})"
	}' "$LIVE_STATE" > "$tmp"
	mv -f "$tmp" "$LIVE_JS"
}

live_flush_maybe() {
	local force="${1:-0}"
	local t interval=500
	t="$(now_ms)"
	if [ "$SIMULATE" = "1" ]; then
		interval=2000
	fi
	if [ "$force" = "1" ] || [ $(( t - LIVE_LAST_FLUSH )) -ge "$interval" ]; then
		live_flush
	fi
}

per_op_value() {
	local metric="$1" raw="$2" ops="$3"
	case "$metric" in
		time|cpu)
			awk -v v="$raw" -v n="$ops" 'BEGIN{ if (n<=0) n=1; printf "%.0f", v * 1e9 / n }'
			;;
		instructions|cycles)
			awk -v v="$raw" -v n="$ops" 'BEGIN{ if (n<=0) n=1; printf "%.0f", v * 1e3 / n }'
			;;
		*)
			awk -v v="$raw" 'BEGIN{ printf "%.0f", v + 0 }'
			;;
	esac
}

per_op_samples() {
	local metric="$1" samples="$2" ops="$3"
	local out="" IFS=',' part raw val first=1
	samples="${samples// /}"
	for part in $samples; do
		[ -n "$part" ] || continue
		raw="$part"
		val="$(per_op_value "$metric" "$raw" "$ops")"
		if [ "$first" = "1" ]; then
			out="$val"
			first=0
		else
			out="${out}, ${val}"
		fi
	done
	printf '%s' "$out"
}

number_or_null() {
	if [[ "$1" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
		printf '%s' "$1"
	else
		printf 'null'
	fi
}

RE_STARTED="Test Case '-\[[A-Za-z0-9_]+\.([A-Za-z0-9_]+) (test[A-Za-z0-9_]+)\]' started"
RE_STARTED_SWIFT="Test [Cc]ase '([A-Za-z0-9_]+)\.(test[A-Za-z0-9_]+)\(\)' started"
RE_OPS='\[Benchmark\] ([A-Za-z0-9_]+) .*(test[A-Za-z0-9_]+)\] operations: ([0-9]+)'
RE_MEASURED="\[[A-Za-z0-9_]+\.([A-Za-z0-9_]+) (test[A-Za-z0-9_]+)\]' measured \[([^]]+)\] average: (-?[0-9.]+), relative standard deviation: ([^%]+)%, values: \[([^]]*)\]"

stream_log() {
	local platform="$1"
	local log="$2"
	local line suite test metric_name metric avg rsd samples ops_n key val sample_list
	: > "$log"
	while IFS= read -r line || [ -n "$line" ]; do
		printf '%s\n' "$line"
		printf '%s\n' "$line" >> "$log"
		if [[ "$line" =~ $RE_STARTED ]] || [[ "$line" =~ $RE_STARTED_SWIFT ]]; then
			suite="${BASH_REMATCH[1]}"
			test="${BASH_REMATCH[2]}"
			live_event "{ t: $(now_ms), kind: \"started\", platform: \"${platform}\", suite: \"${suite}\", test: \"${test}\" }"
			live_flush_maybe 1
		elif [[ "$line" =~ $RE_OPS ]]; then
			suite="${BASH_REMATCH[1]}"
			test="${BASH_REMATCH[2]}"
			ops_n="${BASH_REMATCH[3]}"
			LIVE_OPS_CACHE="${platform}|${suite}|${test}=${ops_n};${LIVE_OPS_CACHE}"
			if [ -n "$OPERATIONS" ]; then
				printf '%s\t%s\t%s\t%s\n' "$platform" "$suite" "$test" "$ops_n" >> "$OPERATIONS"
			fi
			live_event "{ t: $(now_ms), kind: \"ops\", platform: \"${platform}\", suite: \"${suite}\", test: \"${test}\", ops: ${ops_n} }"
			live_flush_maybe 0
		elif [[ "$line" =~ $RE_MEASURED ]]; then
			suite="${BASH_REMATCH[1]}"
			test="${BASH_REMATCH[2]}"
			metric_name="${BASH_REMATCH[3]}"
			avg="${BASH_REMATCH[4]}"
			rsd="${BASH_REMATCH[5]}"
			samples="${BASH_REMATCH[6]}"
			metric="$(metric_key "$metric_name")"
			if [ -n "$metric" ]; then
				ops_n="$(ops_for_test "$test")"
				if [[ "$LIVE_OPS_CACHE" == *"${platform}|${suite}|${test}="* ]]; then
					ops_n="$(printf '%s' "$LIVE_OPS_CACHE" | sed -n "s/.*${platform}|${suite}|${test}=\\([0-9]*\\).*/\\1/p" | head -n1)"
					[ -n "$ops_n" ] || ops_n="$(ops_for_test "$test")"
				fi
				val="$(per_op_value "$metric" "$avg" "$ops_n")"
				sample_list="$(per_op_samples "$metric" "$samples" "$ops_n")"
				live_event "{ t: $(now_ms), kind: \"measured\", platform: \"${platform}\", suite: \"${suite}\", test: \"${test}\", metric: \"${metric}\", value: ${val}, rsd: $(number_or_null "$rsd"), samples: [${sample_list}] }"
				if [ -n "$RESULTS" ]; then
					printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$platform" "$suite" "$test" "$metric_name" "$avg" "$rsd" "$samples" >> "$RESULTS"
				fi
				live_flush_maybe 0
			fi
		fi
	done
}

write_environment() {
	{
		echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
		echo "commit: $(git -C "$ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
		echo "branch: $(git -C "$ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
		echo "dirty: $([ "$DIRTY" = "1" ] && echo yes || echo no)"
		echo "model: $(sysctl -n hw.model 2>/dev/null || echo unknown)"
		echo "cpu: $(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo unknown)"
		echo "cores: $(sysctl -n hw.physicalcpu 2>/dev/null || echo ?) physical, $(sysctl -n hw.logicalcpu 2>/dev/null || echo ?) logical"
		echo "memory_gb: $(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1073741824 ))"
		echo "macos: $(sw_vers -productVersion 2>/dev/null) ($(sw_vers -buildVersion 2>/dev/null))"
		echo "xcode: $(xcodebuild -version 2>/dev/null | tr '\n' ' ')"
		echo "swift: $(swift --version 2>/dev/null | head -n 1)"
		echo "power: $(pmset -g batt 2>/dev/null | head -n 1)"
		echo "thermal: $(pmset -g therm 2>/dev/null | tr '\n' ' ')"
		echo "ios_device: ${DEVICE} ${OS_VERSION:-latest}"
		echo "runner: ${FUSION_RUNNER}"
	} > "${RUN_DIR}/environment.txt"
	live_env_from_file "${RUN_DIR}/environment.txt"
	live_flush
}

parse_log() {
	local platform="$1"
	local log="$2"
	[ -f "$log" ] || return 0
	if [ ! -s "$RESULTS" ] || ! grep -q $'\t'"$platform"$'\t' "$RESULTS" 2>/dev/null; then
		sed -nE "s/.*\[[A-Za-z0-9_]+\.([A-Za-z0-9_]+) (test[A-Za-z0-9_]+)\]' measured \[([^]]+)\] average: -?[0-9.]+, relative standard deviation: ([^%]+)%, values: \[([^]]*)\].*/\1	\2	\3	\4	\5/p" "$log" |
		awk -F'\t' -v platform="$platform" 'BEGIN { OFS = "\t" } {
			count = split($5, values, ", ")
			sum = 0
			for (i = 1; i <= count; i++) sum += values[i]
			printf "%s\t%s\t%s\t%s\t%.9g\t%s\t%s\n", platform, $1, $2, $3, (count ? sum / count : 0), $4, $5
		}' >> "$RESULTS"
	fi
	if [ ! -s "$OPERATIONS" ] || ! grep -q "^${platform}"$'\t' "$OPERATIONS" 2>/dev/null; then
		sed -nE "s/.*\[Benchmark\] ([A-Za-z0-9_]+) .*(test[A-Za-z0-9_]+)\] operations: ([0-9]+).*/${platform}	\1	\2	\3/p" "$log" >> "$OPERATIONS"
	fi
}

cooldown() {
	local phase_id="$1"
	local ends
	live_phase "$phase_id" running
	ends=$(( $(now_ms) + COOLDOWN * 1000 ))
	live_set cooldownEndsAt "$ends"
	live_flush
	echo "--- Cooling down for ${COOLDOWN}s ---"
	run_child sleep "$COOLDOWN"
	live_set cooldownEndsAt ""
	live_phase "$phase_id" done
}

run_child() {
	local rc=0
	"$@" &
	CHILD_PID=$!
	wait "$CHILD_PID" || rc=$?
	CHILD_PID=""
	return "$rc"
}

kill_tree() {
	local pid="$1" child
	for child in $(pgrep -P "$pid" 2>/dev/null); do
		kill_tree "$child"
	done
	kill -TERM "$pid" 2>/dev/null || true
}

build_macos() {
	cd "$ROOT" && swift build -c release --build-tests -Xswiftc -enable-testing
}

measure_macos() {
	(cd "$ROOT" && swift test -c release --skip-build --filter PerformanceTests) | stream_log "macOS" "$1"
}

run_macos() {
	live_phase build-macos running
	echo "--- Building macOS ---"
	xcrun simctl shutdown all >/dev/null 2>&1 || true
	run_child build_macos || {
		live_phase build-macos failed
		echo "error: Benchmarks: build-macos failed (see build log above)"
		return 1
	}
	live_phase build-macos done
	cooldown cooldown-macos
	live_phase measure-macos running
	echo "--- Running macOS benchmarks ---"
	local log="${RUN_DIR}/macos.log"
	local rc=0
	run_child measure_macos "$log" || rc=$?
	parse_log "macOS" "$log"
	if [ "$rc" -ne 0 ]; then
		live_phase measure-macos failed
		echo "error: Benchmarks: measure-macos failed (see ${log})"
		return "$rc"
	fi
	live_phase measure-macos done
}

ios_arguments() {
	local destination="platform=iOS Simulator,name=${DEVICE}"
	if [ -n "$OS_VERSION" ]; then
		destination="${destination},OS=${OS_VERSION}"
	fi
	IOS_ARGUMENTS=(
		-workspace Fusion.xcworkspace
		-scheme "Sample iOS"
		-testPlan FusionBenchmarks
		-configuration Release
		-destination "$destination"
		-derivedDataPath "${ROOT}/.build/BenchmarkDerivedData"
		ENABLE_TESTABILITY=YES
	)
}

build_ios() {
	cd "$ROOT" && xcodebuild build-for-testing "${IOS_ARGUMENTS[@]}"
}

measure_ios() {
	(cd "$ROOT" && xcodebuild test-without-building "${IOS_ARGUMENTS[@]}" -resultBundlePath "${RUN_DIR}/ios.xcresult") | stream_log "iOS" "$1"
}

run_ios() {
	live_phase build-ios running
	echo "--- Building iOS ---"
	local log="${RUN_DIR}/ios.log"
	ios_arguments
	run_child build_ios || {
		live_phase build-ios failed
		echo "error: Benchmarks: build-ios failed (see build log above)"
		return 1
	}
	live_phase build-ios done
	cooldown cooldown-ios
	live_phase measure-ios running
	echo "--- Running iOS benchmarks ---"
	local rc=0
	run_child measure_ios "$log" || rc=$?
	parse_log "iOS" "$log"
	if [ "$rc" -ne 0 ]; then
		live_phase measure-ios failed
		echo "error: Benchmarks: measure-ios failed (see ${log})"
		return "$rc"
	fi
	live_phase measure-ios done
}

append_history() {
	local date_iso
	date_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
	awk -F'\t' -v run_id="$RUN_ID" -v date_iso="$date_iso" -v commit="$COMMIT" '
	FILENAME == ARGV[1] { ops[$1 SUBSEP $2 SUBSEP $3] = $4; next }
	FNR == 1 { next }
	{
		key = $1 SUBSEP $2 SUBSEP $3
		value[key SUBSEP $4] = $5
		if (!(key in seen)) { seen[key] = 1; order[++rows] = key }
	}
	function num(key, metric,   raw) {
		raw = value[key SUBSEP metric]
		return raw == "" ? "" : raw + 0
	}
	END {
		for (i = 1; i <= rows; i++) {
			key = order[i]
			split(key, p, SUBSEP)
			n = ops[key] == "" ? 1 : ops[key] + 0
			time = num(key, "Clock Monotonic Time, s")
			cpu = num(key, "CPU Time, s")
			instr = num(key, "CPU Instructions Retired, kI")
			cycles = num(key, "CPU Cycles, kC")
			mem = num(key, "Memory Physical, kB")
			peak = num(key, "Memory Peak Physical, kB")
			disk = num(key, "Disk Logical Writes, kB")
			printf "%s\t%s\t%s\t%s\t%s\t%s\t%d\t%.0f\t%.0f\t%.0f\t%.0f\t%.0f\t%.0f\t%.0f\n",
				run_id, date_iso, commit, p[1], p[2], p[3], n,
				(time == "" ? 0 : time * 1e9 / n),
				(cpu == "" ? 0 : cpu * 1e9 / n),
				(instr == "" ? 0 : instr * 1e3 / n),
				(cycles == "" ? 0 : cycles * 1e3 / n),
				(mem == "" ? 0 : mem),
				(peak == "" ? 0 : peak),
				(disk == "" ? 0 : disk)
		}
	}' "$OPERATIONS" "$RESULTS" >> "$HISTORY_TSV"

	{
		echo
		echo "## ${RUN_ID}"
		echo
		echo '```'
		cat "${RUN_DIR}/environment.txt"
		echo '```'
		echo
		echo "| Platform | Suite | Test | Time/op (ns) | Instructions/op | Peak (kB) |"
		echo "|---|---|---|---:|---:|---:|"
		awk -F'\t' -v run_id="$RUN_ID" 'NR > 1 && $1 == run_id {
			printf "| %s | %s | %s | %s | %s | %s |\n", $4, $5, $6, $8, $10, $13
		}' "$HISTORY_TSV"
	} >> "$HISTORY_MD"
}

warn_regressions() {
	[ -f "$BASELINE_TSV" ] || return 0
	awk -F'\t' -v run_id="$RUN_ID" '
	FILENAME == ARGV[1] && FNR > 1 {
		key = $1 SUBSEP $2 SUBSEP $3
		if ($4 == "CPU Instructions Retired, kI") base_i[key] = $5 + 0
		if ($4 == "Clock Monotonic Time, s") base_t[key] = $5 + 0
		next
	}
	FILENAME == ARGV[2] && FNR > 1 {
		ops[$1 SUBSEP $2 SUBSEP $3] = $4 + 0
		next
	}
	FNR == 1 { next }
	{
		key = $1 SUBSEP $2 SUBSEP $3
		value[key SUBSEP $4] = $5 + 0
	}
	END {
		for (key in value) {}
		for (key in base_i) {
			split(key, p, SUBSEP)
			n = ops[key]; if (n <= 0) n = 1
			cur_i = value[key SUBSEP "CPU Instructions Retired, kI"]
			if (cur_i == "") continue
			cur = cur_i * 1e3 / n
			base = base_i[key] * 1e3 / n
			if (base <= 0) continue
			pct = (cur - base) / base * 100
			if (pct > 10)
				printf "warning: %s %s instructions %+.1f%% vs baseline\n", p[1], p[3], pct
		}
		for (key in base_t) {
			split(key, p, SUBSEP)
			n = ops[key]; if (n <= 0) n = 1
			cur_t = value[key SUBSEP "Clock Monotonic Time, s"]
			if (cur_t == "") continue
			cur = cur_t * 1e9 / n
			base = base_t[key] * 1e9 / n
			if (base <= 0) continue
			pct = (cur - base) / base * 100
			if (pct > 25)
				printf "warning: %s %s time %+.1f%% vs baseline\n", p[1], p[3], pct
		}
	}' "$BASELINE_TSV" "$OPERATIONS" "$RESULTS" || true
}

seed_baseline_into_history() {
	[ -f "$BASELINE_TSV" ] || return 0
	ensure_history_header
	if ! grep -q "^${BASELINE_RUN}"$'\t' "$HISTORY_TSV" 2>/dev/null; then
		awk -F'\t' -v run="$BASELINE_RUN" '
		FNR == 1 { next }
		{
			key = $1 SUBSEP $2 SUBSEP $3
			value[key SUBSEP $4] = $5
			if (!(key in seen)) { seen[key] = 1; order[++rows] = key }
		}
		function num(key, metric,   raw) {
			raw = value[key SUBSEP metric]
			return raw == "" ? 0 : raw + 0
		}
		function ops_for(test) {
			if (test ~ /FlushPendingWritesWith50|FlushCacheWith20/) return 1
			if (test ~ /JSONDecodeArrayOf500|DecodeFullSize|DecodeDownsampled/) return 20
			if (test ~ /Keychain|URLCacheLoad|Corrupt|Solid|Tinted|Resized/) return 200
			if (test ~ /FilteredByText/) return 50
			if (test ~ /UniqueOf1000|SizeThatFits|TextBounding/) return 500
			if (test ~ /FlushPendingWritesWhenIdle/) return 1000
			return 2000
		}
		END {
			for (i = 1; i <= rows; i++) {
				key = order[i]
				split(key, p, SUBSEP)
				n = ops_for(p[3])
				time = num(key, "Clock Monotonic Time, s")
				cpu = num(key, "CPU Time, s")
				instr = num(key, "CPU Instructions Retired, kI")
				cycles = num(key, "CPU Cycles, kC")
				mem = num(key, "Memory Physical, kB")
				peak = num(key, "Memory Peak Physical, kB")
				disk = num(key, "Disk Logical Writes, kB")
				printf "%s\t2026-11-13T06:45:36Z\t2.1.1\t%s\t%s\t%s\t%d\t%.0f\t%.0f\t%.0f\t%.0f\t%.0f\t%.0f\t%.0f\n",
					run, p[1], p[2], p[3], n,
					time * 1e9 / n, cpu * 1e9 / n, instr * 1e3 / n, cycles * 1e3 / n, mem, peak, disk
			}
		}' "$BASELINE_TSV" >> "$HISTORY_TSV"
	fi

	if [ ! -f "$HISTORY_MD" ]; then
		printf "# Fusion Benchmark History\n\nEvery run appends below. Compare across runs in [report.html](report.html).\n" > "$HISTORY_MD"
	fi
	if ! grep -q "^## ${BASELINE_RUN}$" "$HISTORY_MD" 2>/dev/null; then
		{
			echo
			echo "## ${BASELINE_RUN}"
			echo
			echo "Seeded baseline (Apple M4 Pro). Full table: [Baselines/2.1.1-M4Pro.md](Baselines/2.1.1-M4Pro.md)."
			echo
			echo "| Platform | Suite | Test | Time/op (ns) | Instructions/op | Peak (kB) |"
			echo "|---|---|---|---:|---:|---:|"
			awk -F'\t' -v run="$BASELINE_RUN" '$1 == run {
				printf "| %s | %s | %s | %s | %s | %s |\n", $4, $5, $6, $8, $10, $13
			}' "$HISTORY_TSV"
		} >> "$HISTORY_MD"
	fi
}

history_json() {
	awk -F'\t' '
	NR == 1 { next }
	{
		gsub(/\\/, "\\\\", $6)
		gsub(/"/, "\\\"", $6)
		printf "{\"run\":\"%s\",\"date\":\"%s\",\"commit\":\"%s\",\"platform\":\"%s\",\"suite\":\"%s\",\"test\":\"%s\",\"ops\":%s,\"time\":%s,\"cpu\":%s,\"instructions\":%s,\"cycles\":%s,\"memory\":%s,\"peak\":%s,\"disk\":%s},\n",
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14
	}' "$HISTORY_TSV"
}

baseline_json() {
	[ -f "$BASELINE_TSV" ] || return 0
	awk -F'\t' '
	FNR == 1 { next }
	{
		key = $1 SUBSEP $2 SUBSEP $3
		value[key SUBSEP $4] = $5
		if (!(key in seen)) { seen[key] = 1; order[++rows] = key }
	}
	function num(key, metric,   raw) {
		raw = value[key SUBSEP metric]
		return raw == "" ? 0 : raw + 0
	}
	function ops_for(test) {
		if (test ~ /FlushPendingWritesWith50|FlushCacheWith20/) return 1
		if (test ~ /JSONDecodeArrayOf500|DecodeFullSize|DecodeDownsampled/) return 20
		if (test ~ /Keychain|URLCacheLoad|Corrupt|Solid|Tinted|Resized/) return 200
		if (test ~ /FilteredByText/) return 50
		if (test ~ /UniqueOf1000|SizeThatFits|TextBounding/) return 500
		if (test ~ /FlushPendingWritesWhenIdle/) return 1000
		return 2000
	}
	END {
		for (i = 1; i <= rows; i++) {
			key = order[i]
			split(key, p, SUBSEP)
			n = ops_for(p[3])
			time = num(key, "Clock Monotonic Time, s") * 1e9 / n
			cpu = num(key, "CPU Time, s") * 1e9 / n
			instr = num(key, "CPU Instructions Retired, kI") * 1e3 / n
			peak = num(key, "Memory Peak Physical, kB")
			printf "{\"platform\":\"%s\",\"suite\":\"%s\",\"test\":\"%s\",\"time\":%.0f,\"cpu\":%.0f,\"instructions\":%.0f,\"peak\":%.0f},\n", p[1], p[2], p[3], time, cpu, instr, peak
		}
	}' "$BASELINE_TSV"
}

env_field() {
	local file="$1" key="$2"
	awk -F': ' -v k="$key" '$1==k{print substr($0,index($0,": ")+2); exit}' "$file" 2>/dev/null || true
}

run_in_history() {
	grep -q "^${1}"$'\t' "$HISTORY_TSV"
}

runs_json() {
	if [ -f "$BASELINE_MD" ]; then
		awk '
		/^```$/ { inblock = !inblock; next }
		inblock {
			if ($0 ~ /^date:/) date = substr($0, 7)
			if ($0 ~ /^commit:/) commit = substr($0, 9)
			if ($0 ~ /^branch:/) branch = substr($0, 9)
			if ($0 ~ /^dirty:/) dirty = substr($0, 8)
			if ($0 ~ /^model:/) model = substr($0, 8)
			if ($0 ~ /^cpu:/) cpu = substr($0, 6)
			if ($0 ~ /^cores:/) cores = substr($0, 8)
			if ($0 ~ /^memory_gb:/) mem = substr($0, 12)
			if ($0 ~ /^macos:/) macos = substr($0, 8)
			if ($0 ~ /^xcode:/) xcode = substr($0, 8)
			if ($0 ~ /^swift:/) swift = substr($0, 8)
			if ($0 ~ /^power:/) power = substr($0, 8)
			if ($0 ~ /^thermal:/) thermal = substr($0, 10)
			if ($0 ~ /^ios_device:/) ios = substr($0, 13)
			if ($0 ~ /^runner:/) runner = substr($0, 9)
		}
		END {
			gsub(/\\/, "\\\\", commit); gsub(/"/, "\\\"", commit)
			gsub(/\\/, "\\\\", cpu); gsub(/"/, "\\\"", cpu)
			gsub(/\\/, "\\\\", xcode); gsub(/"/, "\\\"", xcode)
			gsub(/\\/, "\\\\", swift); gsub(/"/, "\\\"", swift)
			gsub(/\\/, "\\\\", power); gsub(/"/, "\\\"", power)
			gsub(/\\/, "\\\\", thermal); gsub(/"/, "\\\"", thermal)
			if (runner == "") runner = "command"
			printf "{\"run\":\"2.1.1-M4Pro\",\"date\":\"%s\",\"commit\":\"%s\",\"branch\":\"%s\",\"dirty\":%s,\"model\":\"%s\",\"cpu\":\"%s\",\"cores\":\"%s\",\"memoryGB\":%s,\"macos\":\"%s\",\"xcode\":\"%s\",\"swift\":\"%s\",\"power\":\"%s\",\"thermal\":\"%s\",\"iosDevice\":\"%s\",\"runner\":\"%s\"},\n",
				date, commit, branch, (dirty=="yes"?"true":"false"), model, cpu, cores, (mem==""?"0":mem), macos, xcode, swift, power, thermal, ios, runner
		}' "$BASELINE_MD"
	fi
	local dir envf run
	for dir in "$RESULTS_DIR"/*; do
		[ -d "$dir" ] || continue
		envf="${dir}/environment.txt"
		[ -f "$envf" ] || continue
		run="$(basename "$dir")"
		[ "$run" = "$BASELINE_RUN" ] && continue
		run_in_history "$run" || continue
		local_runner="$(env_field "$envf" runner)"
		[ -n "$local_runner" ] || local_runner=command
		local_mem="$(env_field "$envf" memory_gb)"
		[ -n "$local_mem" ] || local_mem=0
		printf '{"run":"%s","date":"%s","commit":"%s","branch":"%s","dirty":%s,"model":"%s","cpu":"%s","cores":"%s","memoryGB":%s,"macos":"%s","xcode":"%s","swift":"%s","power":"%s","thermal":"%s","iosDevice":"%s","runner":"%s"},\n' \
			"$(json_escape "$run")" \
			"$(json_escape "$(env_field "$envf" date)")" \
			"$(json_escape "$(env_field "$envf" commit)")" \
			"$(json_escape "$(env_field "$envf" branch)")" \
			"$([ "$(env_field "$envf" dirty)" = "yes" ] && echo true || echo false)" \
			"$(json_escape "$(env_field "$envf" model)")" \
			"$(json_escape "$(env_field "$envf" cpu)")" \
			"$(json_escape "$(env_field "$envf" cores)")" \
			"$local_mem" \
			"$(json_escape "$(env_field "$envf" macos)")" \
			"$(json_escape "$(env_field "$envf" xcode)")" \
			"$(json_escape "$(env_field "$envf" swift)")" \
			"$(json_escape "$(env_field "$envf" power)")" \
			"$(json_escape "$(env_field "$envf" thermal)")" \
			"$(json_escape "$(env_field "$envf" ios_device)")" \
			"$(json_escape "$local_runner")"
	done
}

samples_from_tsv() {
	local tsv="$1" run="$2" ops_file="${3:-}"
	[ -f "$tsv" ] || return 0
	awk -F'\t' -v run="$run" -v ops_file="$ops_file" '
	BEGIN {
		if (ops_file != "") {
			while ((getline line < ops_file) > 0) {
				n = split(line, a, "\t")
				if (n >= 4) ops[a[1] SUBSEP a[2] SUBSEP a[3]] = a[4] + 0
			}
			close(ops_file)
		}
	}
	function ops_for(test) {
		if (test ~ /FlushPendingWritesWith50|FlushCacheWith20/) return 1
		if (test ~ /JSONDecodeArrayOf500|DecodeFullSize|DecodeDownsampled/) return 20
		if (test ~ /Keychain|URLCacheLoad|Corrupt|Solid|Tinted|Resized/) return 200
		if (test ~ /FilteredByText/) return 50
		if (test ~ /UniqueOf1000|SizeThatFits|TextBounding/) return 500
		if (test ~ /FlushPendingWritesWhenIdle/) return 1000
		return 2000
	}
	function metric_key(name) {
		if (name == "Clock Monotonic Time, s") return "time"
		if (name == "CPU Time, s") return "cpu"
		if (name == "CPU Instructions Retired, kI") return "instructions"
		if (name == "CPU Cycles, kC") return "cycles"
		if (name == "Memory Physical, kB") return "memory"
		if (name == "Memory Peak Physical, kB") return "peak"
		if (name == "Disk Logical Writes, kB") return "disk"
		return ""
	}
	function scale(metric, v, n) {
		if (metric == "time" || metric == "cpu") return v * 1e9 / n
		if (metric == "instructions" || metric == "cycles") return v * 1e3 / n
		return v + 0
	}
	FNR == 1 { next }
	{
		platform = $1; suite = $2; test = $3; name = $4; rsd = $6; samples = $7
		metric = metric_key(name)
		if (metric == "") next
		key = platform SUBSEP suite SUBSEP test
		n = ops[key]
		if (n <= 0) n = ops_for(test)
		count = split(samples, vals, ", ")
		out = ""
		for (i = 1; i <= count; i++) {
			gsub(/^ +| +$/, "", vals[i])
			if (vals[i] == "") continue
			v = scale(metric, vals[i] + 0, n)
			out = out (out == "" ? "" : ", ") sprintf("%.0f", v)
		}
		printf "{\"run\":\"%s\",\"platform\":\"%s\",\"suite\":\"%s\",\"test\":\"%s\",\"metric\":\"%s\",\"rsd\":%s,\"samples\":[%s]},\n",
			run, platform, suite, test, metric, (rsd ~ /^-?[0-9]+(\.[0-9]+)?$/ ? rsd + 0 : "null"), out
	}' "$tsv"
}

samples_json() {
	samples_from_tsv "$BASELINE_TSV" "$BASELINE_RUN"
	local dir
	for dir in "$RESULTS_DIR"/*; do
		[ -d "$dir" ] || continue
		[ -f "${dir}/results.tsv" ] || continue
		run_in_history "$(basename "$dir")" || continue
		samples_from_tsv "${dir}/results.tsv" "$(basename "$dir")" "${dir}/operations.tsv"
	done
}

concat_report_assets() {
	local out="$1"
	cat "${REPORT_DIR}/styles.css" > "${out}/styles.css"
	: > "${out}/scripts.js"
	local f
	for f in "${REPORT_DIR}/js/"*.js; do
		[ -f "$f" ] || continue
		cat "$f" >> "${out}/scripts.js"
		printf '\n' >> "${out}/scripts.js"
	done
}

render_html() {
	local scratch
	scratch="$(mktemp -d "${TMPDIR:-/tmp}/fusion-bench.XXXXXX")"
	concat_report_assets "$scratch"
	history_json > "${scratch}/history.json"
	baseline_json > "${scratch}/baseline.json"
	runs_json > "${scratch}/runs.json"
	samples_json > "${scratch}/samples.json"
	awk -v history_file="${scratch}/history.json" \
		-v baseline_file="${scratch}/baseline.json" \
		-v runs_file="${scratch}/runs.json" \
		-v samples_file="${scratch}/samples.json" '
	function inject(path,   line) {
		while ((getline line < path) > 0) print line
		close(path)
	}
	/__HISTORY_JSON__/ { inject(history_file); next }
	/__BASELINE_JSON__/ { inject(baseline_file); next }
	/__RUNS_JSON__/ { inject(runs_file); next }
	/__SAMPLES_JSON__/ { inject(samples_file); next }
	{ print }
	' "${scratch}/scripts.js" > "${scratch}/scripts.filled.js"
	awk -v styles_file="${scratch}/styles.css" \
		-v scripts_file="${scratch}/scripts.filled.js" '
	function inject(path,   line) {
		while ((getline line < path) > 0) print line
		close(path)
	}
	/__STYLES__/ { inject(styles_file); next }
	/__SCRIPTS__/ { inject(scripts_file); next }
	{ print }
	' "${REPORT_DIR}/index.html" > "$REPORT_HTML"
	rm -rf "$scratch"
}

open_report() {
	[ "$OPEN_REPORT" = "1" ] || return 0
	open "file://${REPORT_HTML}#live"
}

sleep_scaled() {
	local secs
	secs="$(awk -v s="$1" -v sp="$SIMULATE_SPEED" 'BEGIN{ v=s/sp; if (v < 0.001) v=0; printf "%.3f", v }')"
	if [ "$secs" != "0.000" ] && [ "$(awk -v v="$secs" 'BEGIN{print (v>0)?1:0}')" = "1" ]; then
		run_child sleep "$secs"
	fi
}

simulate_emit_platform() {
	local want_platform="$1"
	local platform suite test metric_name metric avg rsd samples val sample_list key ops_n
	local tmp_rows count=0
	tmp_rows="$(mktemp "${TMPDIR:-/tmp}/fusion-sim.XXXXXX")"
	awk -F'\t' -v want="$want_platform" 'FNR>1 && $1==want {print}' "$BASELINE_TSV" > "$tmp_rows"
	while IFS=$'\t' read -r platform suite test metric_name avg rsd samples; do
		metric="$(metric_key "$metric_name")"
		[ -n "$metric" ] || continue
		key="${platform}|${suite}|${test}"
		ops_n="$(ops_for_test "$test")"
		if [[ "$LIVE_OPS_CACHE" != *"${key}="* ]]; then
			LIVE_OPS_CACHE="${key}=${ops_n};${LIVE_OPS_CACHE}"
			live_event "{ t: $(now_ms), kind: \"started\", platform: \"${platform}\", suite: \"${suite}\", test: \"${test}\" }"
			live_event "{ t: $(now_ms), kind: \"ops\", platform: \"${platform}\", suite: \"${suite}\", test: \"${test}\", ops: ${ops_n} }"
			sleep_scaled 0.08
		fi
		val="$(per_op_value "$metric" "$avg" "$ops_n")"
		sample_list="$(per_op_samples "$metric" "$samples" "$ops_n")"
		live_event "{ t: $(now_ms), kind: \"measured\", platform: \"${platform}\", suite: \"${suite}\", test: \"${test}\", metric: \"${metric}\", value: ${val}, rsd: $(number_or_null "$rsd"), samples: [${sample_list}] }"
		count=$((count + 1))
		if [ $((count % 25)) -eq 0 ]; then
			live_flush
		fi
		sleep_scaled 0.02
	done < "$tmp_rows"
	rm -f "$tmp_rows"
	live_flush
}

simulate_run() {
	APPEND_HISTORY=0
	LIVE_OPS_CACHE=""

	live_phase build-macos running
	sleep_scaled 0.4
	live_phase build-macos done
	live_phase cooldown-macos running
	live_set cooldownEndsAt "$(( $(now_ms) + $(awk -v s="$COOLDOWN" -v sp="$SIMULATE_SPEED" 'BEGIN{printf "%d", (s/sp)*1000}') ))"
	live_flush
	sleep_scaled "$(awk -v s="$COOLDOWN" 'BEGIN{printf "%.2f", (s>2?2:s)}')"
	live_set cooldownEndsAt ""
	live_phase cooldown-macos done

	live_phase measure-macos running
	simulate_emit_platform "macOS"
	live_phase measure-macos done

	live_phase build-ios running
	sleep_scaled 0.3
	live_phase build-ios done
	live_phase cooldown-ios running
	live_set cooldownEndsAt "$(( $(now_ms) + $(awk -v s="$COOLDOWN" -v sp="$SIMULATE_SPEED" 'BEGIN{printf "%d", (s/sp)*1000}') ))"
	live_flush
	sleep_scaled "$(awk -v s="$COOLDOWN" 'BEGIN{printf "%.2f", (s>2?2:s)}')"
	live_set cooldownEndsAt ""
	live_phase cooldown-ios done

	live_phase measure-ios running
	simulate_emit_platform "iOS"
	live_phase measure-ios done

	live_phase parse running
	sleep_scaled 0.2
	live_phase parse done
	live_phase report running
	render_html
	live_phase report done
	live_finish done
}

load_fixture() {
	local source="${FIXTURES_DIR}/live-${1}.js"
	if [ ! -f "$source" ]; then
		echo "Unknown fixture: $1 (expected one of: $(ls "$FIXTURES_DIR" | sed -n 's/^live-\(.*\)\.js$/\1/p' | tr '\n' ' '))"
		exit 1
	fi
	mkdir -p "$LIVE_DIR"
	cat "$source" > "${LIVE_JS}.tmp"
	mv -f "${LIVE_JS}.tmp" "$LIVE_JS"
}

LIVE_ACTIVE=0

live_is_open() {
	[ "$LIVE_ACTIVE" = "1" ] || return 1
	case "$(live_get state)" in
		starting|running) return 0 ;;
		*) return 1 ;;
	esac
}

mark_open_phases() {
	local id state
	for id in "${PHASE_IDS[@]}"; do
		state="$(live_get "phase_${id}")"
		if [ "$state" = "running" ]; then
			live_set "phase_${id}" "$1"
			live_set "phase_${id}_ended" "$(now_ms)"
		elif [ "$state" = "pending" ] || [ -z "$state" ]; then
			live_set "phase_${id}" skipped
		fi
	done
}

on_cancel() {
	trap - TERM INT ERR
	APPEND_HISTORY=0
	kill_tree_children
	if live_is_open; then
		mark_open_phases failed
		live_finish cancelled "cancelled"
	fi
	echo "error: Benchmarks: cancelled"
	exit 130
}

kill_tree_children() {
	local child
	for child in $(pgrep -P $$ 2>/dev/null); do
		kill_tree "$child"
	done
}

on_error() {
	local rc=$?
	trap - ERR
	APPEND_HISTORY=0
	local phase
	phase="$(live_get phase 2>/dev/null || echo unknown)"
	if live_is_open; then
		mark_open_phases failed
		live_finish failed "${phase} failed"
	fi
	echo "error: Benchmarks: ${phase:-setup} failed (see ${RUN_DIR:-$RESULTS_DIR})"
	exit "$rc"
}

on_exit() {
	if live_is_open; then
		mark_open_phases failed
		live_finish failed "runner exited unexpectedly"
	fi
}

trap on_cancel TERM INT
trap on_error ERR
trap on_exit EXIT

ensure_history_header
seed_baseline_into_history

if [ -n "$FIXTURE" ]; then
	load_fixture "$FIXTURE"
	render_html
	open_report
	echo "Fixture ${FIXTURE} loaded into ${LIVE_JS}"
	exit 0
fi

echo "=== Fusion Benchmarks ==="

if [ "$REPORT_ONLY" = "1" ]; then
	render_html
	echo
	echo "=== Done ==="
	echo "Report:  ${REPORT_HTML}"
	if [ "$OPEN_REPORT" = "1" ]; then
		open "$REPORT_HTML"
	fi
	exit 0
fi

live_init
LIVE_ACTIVE=1
render_html
open_report

if [ "$SIMULATE" = "1" ]; then
	echo "Simulate: ${RUN_ID} (speed ${SIMULATE_SPEED}x)"
	if [ -f "$BASELINE_MD" ]; then
		local_env="$(mktemp "${TMPDIR:-/tmp}/fusion-env.XXXXXX")"
		awk '/^```$/{c=!c;next} c' "$BASELINE_MD" > "$local_env"
		live_env_from_file "$local_env"
		rm -f "$local_env"
		live_flush
	fi
	simulate_run
else
	echo "Run: ${RUN_ID} (runner: ${FUSION_RUNNER})"
	prepare_run_dir
	write_environment
	run_macos
	run_ios
	live_phase parse running
	warn_regressions
	if [ "$APPEND_HISTORY" = "1" ]; then
		append_history
	fi
	live_phase parse done
	live_phase report running
	render_html
	live_phase report done
	live_finish done
fi

echo
echo "=== Done ==="
echo "History: ${HISTORY_MD}"
echo "Report:  ${REPORT_HTML}"
echo "Live:    ${LIVE_JS}"
