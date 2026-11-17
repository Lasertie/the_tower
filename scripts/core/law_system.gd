## Les Lois de la Tour (autoload "LawSystem") : un seul moteur pour tous les étages empilés.
extends Node





signal law_observed(law: FloorLaw)
signal exploit_used(law: FloorLaw, exploit: LawExploit)

var _floors: Dictionary = {}   # n -> {y0, y1, laws}
var observed: Dictionary = {}  # law id -> true
var used_exploits: Dictionary = {}  # exploit id -> true

func clear_floors() -> void:
	_floors.clear()

func reset() -> void:
	clear_floors()
	observed.clear()
	used_exploits.clear()

func register_floor(n: int, y0: float, height: float, laws: Array) -> void:
	_floors[n] = {"y0": y0, "y1": y0 + height + 1.0, "laws": laws}

func floor_at(y: float) -> int:
	for n in _floors:
		if y >= _floors[n].y0 - 0.5 and y < _floors[n].y1 - 0.5:
			return n
	return 0

func laws_of(n: int) -> Array:
	return _floors[n].laws if _floors.has(n) else []

func find_law(id: StringName) -> FloorLaw:
	for n in _floors:
		for l in _floors[n].laws:
			if l.id == id:
				return l
	return null

func find_exploit_by_id(id: StringName) -> LawExploit:
	for n in _floors:
		for l in _floors[n].laws:
			var e: LawExploit = l.get_exploit(id)
			if e:
				return e
	return null

func _context(body: Node) -> Dictionary:
	var ctx: Dictionary = body.law_context() if body.has_method("law_context") else {}
	ctx["hour"] = GameClock.get_hour()
	return ctx

func observe(law: FloorLaw) -> void:
	if not observed.has(String(law.id)):
		observed[String(law.id)] = true
		law_observed.emit(law)

func note_exploit(law: FloorLaw, exploit_id: StringName) -> void:
	if exploit_id != &"" and not used_exploits.has(String(exploit_id)):
		used_exploits[String(exploit_id)] = true
		exploit_used.emit(law, law.get_exploit(exploit_id))

## Échelle de gravité subie par un corps (joueur ou monstre) selon l'étage où il se trouve.
func gravity_scale_for(body: Node3D) -> float:
	var n := floor_at(body.global_position.y + 0.9)
	var hour := GameClock.get_hour()
	for law in laws_of(n):
		if law.effect == FloorLaw.Effect.GRAVITY_INVERT and law.is_active(hour):
			var ex: StringName = law.find_exploit(_context(body))
			if ex == &"":
				if body is Player:
					observe(law)
				return -1.0
			if body is Player:
				note_exploit(law, ex)
	return 1.0

## Nombre de sentinelles éveillées à portée : quelqu'un « surveille »-t-il cet endroit ?
func watchers_near(pos: Vector3, radius: float) -> int:
	var n := 0
	for s in get_tree().get_nodes_in_group("sentinels"):
		if s.process_mode != Node.PROCESS_MODE_DISABLED and s.is_watching() \
				and s.global_position.distance_to(pos) <= radius:
			n += 1
	return n

func sealed_exit_law(n: int) -> FloorLaw:
	for law in laws_of(n):
		if law.effect == FloorLaw.Effect.SEALED_EXIT:
			return law
	return null

func to_dict() -> Dictionary:
	return {"observed": observed.keys(), "exploits": used_exploits.keys()}

func from_dict(d: Dictionary) -> void:
	observed.clear()
	used_exploits.clear()
	for k in d.get("observed", []):
		observed[String(k)] = true
	for k in d.get("exploits", []):
		used_exploits[String(k)] = true
