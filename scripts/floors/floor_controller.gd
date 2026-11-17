## Classe de base des contrôleurs d'étage.
class_name FloorController
extends Node

@export var floor_number := 1
@export var floor_name := ""
@export var scenarios: Array[Scenario] = []
@export var laws: Array[FloorLaw] = []

## Condition cachée qui se déclenche quand la loi de sortie est contournée par une faille.
var exit_exploit_condition: StringName = &""

var _begun := false

func _ready() -> void:
	for s in scenarios:
		ScenarioManager.register(s)
	_apply_world_consequences()

## Surcharger : modifier spawns / dialogues selon WorldFlags.
func _apply_world_consequences() -> void:
	pass

## Le joueur découvre l'étage : le premier scénario démarre (une seule fois).
func begin() -> void:
	if _begun:
		return
	_begun = true
	if not scenarios.is_empty():
		ScenarioManager.start(scenarios[0].id)

func on_enter() -> void:
	begin()

func on_leave() -> void:
	pass

## Contexte pour tester les failles du joueur.
func build_law_context() -> Dictionary:
	var ctx := {"items": [], "sanity": 0.0}
	var p := get_tree().get_first_node_in_group("player")
	if p and p.has_method("law_context"):
		ctx = p.law_context()
		ctx["watchers"] = LawSystem.watchers_near(p.global_position, 14.0)
	ctx["hour"] = GameClock.get_hour()
	return ctx

## Vrai si une faille autorise de contourner cette loi dans le contexte courant.
func is_law_bypassed(law_id: StringName) -> bool:
	for law in laws:
		if law.id == law_id:
			return law.find_exploit(build_law_context()) != &""
	return false

## Le joueur touche le sceau de sortie : vrai si la porte est (ou devient) ouverte.
func attempt_exit(_player: Player = null) -> bool:
	if is_cleared():
		return true
	var law := LawSystem.sealed_exit_law(floor_number)
	if law:
		LawSystem.observe(law)
		var ex := law.find_exploit(build_law_context())
		if ex != &"" and exit_exploit_condition != &"" and not scenarios.is_empty():
			LawSystem.note_exploit(law, ex)
			ScenarioManager.report(scenarios[0].id, exit_exploit_condition)
	return is_cleared()

## Vrai si un scénario terminal (sans suivant) a été résolu.
func is_cleared() -> bool:
	for s in scenarios:
		if s.next_scenario == &"" and s.state == Scenario.State.RESOLVED:
			return true
	return false

## État propre à l'étage (surcharger si besoin).
func to_save_dict() -> Dictionary:
	return {}

func from_save_dict(_d: Dictionary) -> void:
	pass
