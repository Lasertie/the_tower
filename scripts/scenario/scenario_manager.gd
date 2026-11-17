## Gestionnaire de progression des scénarios (autoload "ScenarioManager").
extends Node

signal scenario_started(scenario: Scenario)
signal condition_discovered(scenario: Scenario, condition: WinCondition)
signal condition_progressed(scenario: Scenario, condition: WinCondition)
signal scenario_resolved(scenario: Scenario, by: WinCondition)
signal floor_cleared(floor_number: int)

var _scenarios: Dictionary = {}  # StringName -> Scenario
var _pending_save: Dictionary = {}

func reset() -> void:
	_scenarios.clear()
	_pending_save.clear()

func register(scenario: Scenario) -> void:
	_scenarios[scenario.id] = scenario
	if _pending_save.has(String(scenario.id)):
		_restore(scenario, _pending_save[String(scenario.id)])

func get_scenario(id: StringName) -> Scenario:
	return _scenarios.get(id)

func all_scenarios() -> Array:
	var out := _scenarios.values()
	out.sort_custom(func(a, b): return a.floor_number < b.floor_number)
	return out

func start(id: StringName) -> bool:
	var s: Scenario = _scenarios.get(id)
	if s == null or s.state == Scenario.State.RESOLVED:
		return false
	if not WorldFlags.matches(s.requires_flags):
		return false
	if s.state != Scenario.State.ACTIVE:
		s.state = Scenario.State.ACTIVE
		scenario_started.emit(s)
	return true

## Le joueur apprend qu'une piste existe (dialogue, indice...). Jamais pour une faille cachée.
func discover(scenario_id: StringName, cond_id: StringName) -> void:
	var s: Scenario = _scenarios.get(scenario_id)
	var c: WinCondition = s.get_condition(cond_id) if s else null
	if c == null or c.discovered:
		return
	c.discovered = true
	condition_discovered.emit(s, c)

## Point d'entrée unique pour le gameplay : "le joueur a fait avancer cette condition".
func report(scenario_id: StringName, cond_id: StringName, amount := 1) -> void:
	var s: Scenario = _scenarios.get(scenario_id)
	if s == null or s.state != Scenario.State.ACTIVE:
		return
	var c := s.get_condition(cond_id)
	if c == null:
		return
	c.progress += amount
	if not c.discovered and not c.hidden:
		discover(scenario_id, cond_id)
	condition_progressed.emit(s, c)
	if c.is_met():
		_resolve(s, c)

## Résout de force un scénario par une condition donnée (utilisé par le Sceau au franchissement).
func force_resolve(scenario_id: StringName, cond_id: StringName) -> void:
	var s: Scenario = _scenarios.get(scenario_id)
	if s == null or s.state == Scenario.State.RESOLVED:
		return
	var c := s.get_condition(cond_id)
	if c == null:
		return
	c.progress = c.target   # marquer la condition comme atteinte
	_resolve(s, c)

func _resolve(s: Scenario, c: WinCondition) -> void:
	s.state = Scenario.State.RESOLVED
	s.resolved_by = c.id
	c.discovered = true
	WorldFlags.apply(c.sets_flags)
	if c.chaos_delta != 0:
		WorldFlags.add_chaos(c.chaos_delta)
	scenario_resolved.emit(s, c)
	if s.next_scenario != &"":
		start(s.next_scenario)
	else:
		floor_cleared.emit(s.floor_number)

# --- Sauvegarde ---
func to_dict() -> Dictionary:
	var out := {}
	for id in _scenarios:
		var s: Scenario = _scenarios[id]
		var prog := {}
		var disc := {}
		for c in s.win_conditions:
			prog[String(c.id)] = c.progress
			disc[String(c.id)] = c.discovered
		out[String(id)] = {"state": s.state, "resolved_by": String(s.resolved_by),
			"progress": prog, "discovered": disc}
	return out

func from_dict(data: Dictionary) -> void:
	_pending_save = data
	for id in _scenarios:
		if data.has(String(id)):
			_restore(_scenarios[id], data[String(id)])

func _restore(s: Scenario, d: Dictionary) -> void:
	s.state = int(d.get("state", 0)) as Scenario.State
	s.resolved_by = StringName(d.get("resolved_by", ""))
	for c in s.win_conditions:
		c.progress = int(d.get("progress", {}).get(String(c.id), 0))
		c.discovered = bool(d.get("discovered", {}).get(String(c.id), false))
