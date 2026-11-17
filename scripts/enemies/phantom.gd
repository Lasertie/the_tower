## Hallucination : silhouette qui s'approche du joueur puis s'évanouit. Inoffensive.
class_name Phantom
extends Node3D

@export var lifetime := 3.5
@export var speed := 2.0

var _t := 0.0
var _mat: StandardMaterial3D

func _ready() -> void:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.4
	cm.height = 1.7
	mi.mesh = cm
	mi.position.y = 0.85
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_color = Color(0.8, 0.05, 0.1, 0.6)
	mi.material_override = _mat
	add_child(mi)

func _process(delta: float) -> void:
	_t += delta
	var c := _mat.albedo_color
	c.a = 0.6 * (1.0 - _t / lifetime)
	_mat.albedo_color = c
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p:
		global_position = global_position.move_toward(p.global_position, speed * delta)
		if global_position.distance_to(p.global_position) < 1.2:
			queue_free()
			return
	if _t >= lifetime:
		queue_free()
