## Zone réutilisable : le joueur entre → fait avancer une condition de scénario / ramasse un objet.
class_name ScenarioTrigger
extends Area3D

signal triggered(player: Player)

@export var scenario_id: StringName = &""
@export var condition_id: StringName = &""  ## vide = émet seulement le signal
@export var amount := 1
@export var one_shot := true
@export var required_item: StringName = &""
@export var grants_item: StringName = &""
@export var size := Vector3(3, 3, 3)
@export var cooldown := 0.0  ## secondes entre deux déclenchements (zones non one_shot)

var _used := false
var _next_ok := 0.0

func _ready() -> void:
	if get_child_count() == 0:
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		cs.shape = box
		add_child(cs)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if _used or not body is Player:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now < _next_ok:
		return
	var p := body as Player
	if required_item != &"" and not p.has_item(required_item):
		return
	if one_shot:
		_used = true
	_next_ok = now + cooldown
	if grants_item != &"":
		p.add_item(grants_item)
	if condition_id != &"":
		ScenarioManager.report(scenario_id, condition_id, amount)
	triggered.emit(p)
