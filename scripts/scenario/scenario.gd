class_name Scenario
extends Resource

enum State { LOCKED, ACTIVE, RESOLVED }

@export var id: StringName
@export var floor_number := 1
@export var title := ""
@export var win_conditions: Array[WinCondition] = []
@export var next_scenario: StringName = &""  ## vide = dernier scénario → ouvre le portail
@export var requires_flags: Dictionary = {}  ## le scénario n'est dispo que si ces flags matchent

var state: State = State.LOCKED
var resolved_by: StringName = &""

func get_condition(cond_id: StringName) -> WinCondition:
	for c in win_conditions:
		if c.id == cond_id:
			return c
	return null
