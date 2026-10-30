extends RefCounted

# Landing/dash pulses must not truncate hurt, heavy-hit or victory feedback.
const PULSES: Dictionary = {
	"hit": Vector3(0.20, 0.25, 0.065), "heavy_hit": Vector3(0.4, 0.5, 0.10),
	"hurt": Vector3(0.65, 0.8, 0.18), "dash": Vector3(0.12, 0.2, 0.055),
	"evade": Vector3(0.25, 0.35, 0.09), "land": Vector3(0.07, 0.12, 0.04),
	"success": Vector3(0.35, 0.45, 0.25)
}
const PRIORITIES: Dictionary = {"land": 0, "dash": 1, "hit": 2, "heavy_hit": 3, "evade": 3, "hurt": 4, "success": 5}
var remaining: float = 0.0
var priority: int = -1
var active_kind: String = ""

func advance(delta: float) -> void:
	remaining = maxf(0.0, remaining - delta)
	if remaining <= 0:
		clear()

func request(kind: String) -> Vector3:
	var requested: int = PRIORITIES.get(kind, 2)
	if remaining > 0 and requested < priority:
		return Vector3.ZERO
	var values: Vector3 = PULSES.get(kind, Vector3(0.15, 0.2, 0.06))
	priority = requested
	remaining = values.z
	active_kind = kind
	return values

func clear() -> void:
	remaining = 0
	priority = -1
	active_kind = ""
