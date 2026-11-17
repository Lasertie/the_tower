## Créature de la Tour : poursuit et frappe le joueur. Soumise aux mêmes lois que lui (gravité...).
class_name Enemy
extends CharacterBody3D

signal died(enemy: Enemy)

@export var max_health := 40.0
@export var speed := 3.0
@export var aggro_range := 12.0
@export var attack_range := 2.0
@export var damage := 8.0
@export var attack_cooldown := 1.2
@export var model_key := "monster"
@export var model_height := 1.3
@export var hover := 0.4            ## altitude de vol du modèle (monstre volant)
@export var tint_color := Color.WHITE

## Modifié par les contrôleurs d'étage selon WorldFlags (ex: x1.5 après le Gourou).
var aggro_multiplier := 1.0

var health: HealthComponent
var gravity_scale := 1.0
var model: CharacterModel
var _target: Node3D
var _cd := 0.0
var _knock := Vector3.ZERO
var _t := randf() * 10.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	add_to_group("enemies")
	health = HealthComponent.new()
	health.max_health = max_health
	add_child(health)
	health.died.connect(_on_died)

	var total_h := model_height + hover
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = maxf(total_h, 1.0)
	col.shape = cap
	col.position.y = cap.height * 0.5
	add_child(col)

	model = CharacterModel.new().setup(model_key, model_height)
	if tint_color != Color.WHITE:
		model.tint(tint_color)
	add_child(model)
	model.rotation.y = PI  # le modèle regarde vers +Z ; look_at() oriente -Z vers la cible
	model.position.y = hover
	model.play(&"walk")

func law_context() -> Dictionary:
	return {"items": [], "sanity": 0.0}

func _physics_process(delta: float) -> void:
	if health.dead:
		return
	_t += delta
	var g := LawSystem.gravity_scale_for(self)
	if g != gravity_scale:
		gravity_scale = g
		up_direction = Vector3.UP * g
		velocity.y = 0.0
		var total := model_height + hover
		model.position.y = (total - hover) if g < 0.0 else hover
		model.rotation = Vector3(0, PI, PI) if g < 0.0 else Vector3(0, PI, 0)
	if not is_on_floor():
		velocity.y -= _gravity * gravity_scale * delta
	if _target == null or not is_instance_valid(_target):
		_target = get_tree().get_first_node_in_group("player")
	_cd = maxf(_cd - delta, 0.0)

	var vx := 0.0
	var vz := 0.0
	if _target:
		var to := _target.global_position - global_position
		to.y = 0
		var dist := to.length()
		if dist <= aggro_range * aggro_multiplier and dist > attack_range:
			var d := to.normalized()
			vx = d.x * speed * aggro_multiplier
			vz = d.z * speed * aggro_multiplier
			look_at(global_position + d, Vector3.UP)
		elif dist <= attack_range and _cd <= 0.0 and _target.has_method("take_damage"):
			_cd = attack_cooldown
			_target.take_damage(damage, self)
	_knock = _knock.move_toward(Vector3.ZERO, 20.0 * delta)
	velocity.x = vx + _knock.x
	velocity.z = vz + _knock.z
	move_and_slide()
	if model_key == "monster":
		model.position.y = hover + sin(_t * 3.0) * 0.08 if gravity_scale > 0.0 else model.position.y

func take_damage(amount: float, source: Node = null) -> void:
	if source is Node3D:
		var away := global_position - (source as Node3D).global_position
		away.y = 0
		_knock = away.normalized() * 6.0
	health.take_damage(amount, source)

## Retiré du monde par un habitant (ou par la Tour), sans compter comme un meurtre du joueur.
func despawn() -> void:
	if health.dead:
		return
	health.dead = true
	var tw := create_tween()
	tw.tween_property(model, "scale", Vector3.ZERO, 0.4)
	tw.tween_callback(queue_free)

func _on_died(_src: Node) -> void:
	died.emit(self)
	var tw := create_tween()
	tw.tween_property(model, "scale", Vector3.ZERO, 0.25)
	tw.tween_callback(queue_free)
