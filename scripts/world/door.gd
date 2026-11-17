## Porte physique scellée par une loi de la Tour. S'ouvre quand la loi cède (scénario résolu).
class_name Door
extends StaticBody3D

@export var size := Vector3(4.0, 4.0, 0.5)

var is_open := false
var _mat: StandardMaterial3D
var _col: CollisionShape3D

func _ready() -> void:
	_col = CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	_col.shape = bs
	add_child(_col)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	_mat = WorldUtil.material(Color(0.22, 0.2, 0.25))
	_mat.emission_enabled = true
	_mat.emission = Color(0.9, 0.15, 0.1)
	_mat.emission_energy_multiplier = 0.6
	mi.material_override = _mat
	add_child(mi)
	# Sceau : rune lumineuse
	var seal := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.35
	sm.height = 0.7
	seal.mesh = sm
	seal.material_override = _mat
	seal.position = Vector3(0, 0, size.z * 0.5 + 0.1)
	add_child(seal)
	var seal_back := seal.duplicate() as MeshInstance3D
	seal_back.position.z = -size.z * 0.5 - 0.1
	add_child(seal_back)

func set_open(value: bool, animate := true) -> void:
	if value == is_open:
		return
	is_open = value
	_mat.emission = Color(0.2, 0.9, 0.3) if value else Color(0.9, 0.15, 0.1)
	_col.set_deferred("disabled", value)
	var target_y := position.y + (size.y + 0.4 if value else -(size.y + 0.4))
	if animate and is_inside_tree():
		create_tween().tween_property(self, "position:y", target_y, 1.2)
	else:
		position.y = target_y
