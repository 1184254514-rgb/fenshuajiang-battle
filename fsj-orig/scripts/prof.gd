class_name Prof
## Tiny frame-section timer for the perf tests: Prof.add(key, t0_usec) accumulates and returns now (Claude)
static var totals: Dictionary = {}
static var counts: Dictionary = {}

static func add(key: String, t0: int) -> int:
	var now := Time.get_ticks_usec()
	totals[key] = int(totals.get(key, 0)) + (now - t0)
	counts[key] = int(counts.get(key, 0)) + 1
	return now
