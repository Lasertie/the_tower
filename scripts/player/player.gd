## Héros solo, 3ème personne (modèle animé Kenney, CC0).
class_name Player
extends CharacterBody3D

signal died
signal item_added(id: StringName)

@export var speed := 6.0
@export var jump_velocity := 5.5
@export var mouse_sensitivity := 0.003
@export var attack_damage := 25.0
@export var attack_cooldown := 0.5

var health: HealthComponent
var inventory: Array[StringName] = []
var controls_inverted := false  ## piloté par l'étage 2 (folie)
var gravity_scale := 1.0        ## -1 : gravité inversée par une loi de la Tour
var madness := 0.0              ## écrit par l'étage 2, lu par les failles (LawExploit.min_sanity)
var interact_block := 0.0
var frozen := false             ## immobilisé pendant une transition (ascension, descente)

var model: CharacterModel
var _pitch: Node3D
var _hitbox: Area3D
var _interact_area: Area3D
var _slash: MeshInstance3D
var _cam: Camera3D
var _shake_t := 0.0
var _shake_amp := 0.0
var _attack_timer := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	add_to_group("player")
	_ensure_actions()
	_build_body()

func _build_body() -> void:
	health = HealthComponent.new()
	health.max_health = 100.0
	add_child(health)
	health.died.connect(func(_src): died.emit())

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	col.shape = cap
	col.position.y = 0.9
	add_child(col)

	model = CharacterModel.new().setup("character", 1.8)
	add_child(model)
	_apply_orientation()

	_pitch = Node3D.new()
	_pitch.position.y = 1.8
	add_child(_pitch)
	var arm := SpringArm3D.new()
	arm.spring_length = 5.6
	arm.margin = 0.3
	arm.add_excluded_object(get_rid())
	_pitch.add_child(arm)
	var cam := Camera3D.new()
	_cam = cam
	cam.current = true
	cam.fov = 70.0
	arm.add_child(cam)

	_hitbox = Area3D.new()
	var hs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.8, 1.6, 1.8)
	hs.shape = box
	_hitbox.add_child(hs)
	_hitbox.position = Vector3(0, 0.9, -1.3)
	add_child(_hitbox)

	_slash = MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(1.6, 0.08, 1.4)
	_slash.mesh = sm
	var mat := WorldUtil.unshaded(Color(1, 1, 1, 0.55))
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_slash.material_override = mat
	_slash.position = Vector3(0, 1.0, -1.1)
	_slash.visible = false
	add_child(_slash)

	_interact_area = Area3D.new()
	var isc := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 2.3
	isc.shape = sph
	_interact_area.add_child(isc)
	_interact_area.position.y = 1.0
	add_child(_interact_area)

## Secousse de caméra (grondement de l'ascension).
func shake(seconds: float, amp := 0.06) -> void:
	_shake_t = seconds
	_shake_amp = amp

func _process(delta: float) -> void:
	if _cam == null:
		return
	if _shake_t > 0.0:
		_shake_t -= delta
		_cam.h_offset = randf_range(-_shake_amp, _shake_amp)
		_cam.v_offset = randf_range(-_shake_amp, _shake_amp)
	elif _cam.h_offset != 0.0 or _cam.v_offset != 0.0:
		_cam.h_offset = 0.0
		_cam.v_offset = 0.0

func _apply_orientation() -> void:
	# Le modèle regarde vers +Z : on le retourne pour qu'il fasse face à -Z (avant du joueur).
	if gravity_scale < 0.0:
		model.position.y = 1.8
		model.rotation = Vector3(0, PI, PI)
	else:
		model.position.y = 0.0
		model.rotation = Vector3(0, PI, 0)
	if _pitch:
		_pitch.position.y = 1.8 if gravity_scale > 0.0 else 0.2

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch.rotation.x = clampf(_pitch.rotation.x - event.relative.y * mouse_sensitivity, -1.2, 0.6)

func _physics_process(delta: float) -> void:
	if health.dead:
		return
	if frozen:
		velocity = Vector3.ZERO
		return
	interact_block = maxf(interact_block - delta, 0.0)

	# La gravité est une loi de la Tour, identique pour tous les corps de l'étage.
	var g := LawSystem.gravity_scale_for(self)
	if g != gravity_scale:
		set_gravity_scale(g)
	if not is_on_floor():
		velocity.y -= _gravity * gravity_scale * delta
	elif Input.is_action_just_pressed("jump") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		velocity.y = jump_velocity * gravity_scale

	var dir := Vector2.ZERO
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if controls_inverted:
		dir = -dir
	var move := (global_basis * Vector3(dir.x, 0, dir.y)).normalized()
	velocity.x = move.x * speed
	velocity.z = move.z * speed
	move_and_slide()

	if not is_on_floor():
		model.play(&"jump")
	elif Vector2(velocity.x, velocity.z).length() > 0.5:
		model.play(&"walk")
	else:
		model.play(&"idle")

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if Input.is_action_just_pressed("interact") and interact_block <= 0.0:
			var target := nearest_interactable()
			if target:
				target.interact(self)
		_attack_timer = maxf(_attack_timer - delta, 0.0)
		if Input.is_action_just_pressed("attack") and _attack_timer <= 0.0:
			_attack()

func _attack() -> void:
	_attack_timer = attack_cooldown
	_slash.visible = true
	get_tree().create_timer(0.12).timeout.connect(func(): _slash.visible = false)
	for b in _hitbox.get_overlapping_bodies():
		if b != self and b.has_method("take_damage"):
			b.take_damage(attack_damage, self)

func nearest_interactable() -> Interactable:
	var best: Interactable = null
	var best_d := INF
	for a in _interact_area.get_overlapping_areas():
		if a is Interactable and a.is_available():
			var d := global_position.distance_to(a.global_position)
			if d < best_d:
				best_d = d
				best = a
	return best

func set_gravity_scale(s: float) -> void:
	gravity_scale = s
	up_direction = Vector3.UP * s
	velocity.y = 0.0
	_apply_orientation()

func law_context() -> Dictionary:
	return {"items": inventory, "sanity": madness}

func take_damage(amount: float, source: Node = null) -> void:
	health.take_damage(amount, source)

func add_item(id: StringName) -> void:
	if id not in inventory:
		inventory.append(id)
		item_added.emit(id)

func has_item(id: StringName) -> bool:
	return id in inventory

func respawn(at: Vector3) -> void:
	health.dead = false
	health.health = health.max_health
	set_gravity_scale(1.0)
	global_position = at
	velocity = Vector3.ZERO

func to_save_dict() -> Dictionary:
	var inv: Array = []
	for i in inventory:
		inv.append(String(i))
	return {
		"pos": [global_position.x, global_position.y, global_position.z],
		"yaw": rotation.y,
		"health": health.health,
		"inventory": inv,
	}

func from_save_dict(d: Dictionary) -> void:
	var p: Array = d.get("pos", [0, 1, 0])
	global_position = Vector3(p[0], p[1], p[2])
	rotation.y = float(d.get("yaw", 0.0))
	health.dead = false
	health.health = float(d.get("health", health.max_health))
	inventory.clear()
	for i in d.get("inventory", []):
		inventory.append(StringName(i))

static func _ensure_actions() -> void:
	var map := {
		"move_forward": [KEY_W, KEY_UP],
		"move_back": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"jump": [KEY_SPACE],
		"interact": [KEY_E],
		"journal": [KEY_TAB, KEY_J],
	}
	for action in map:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for k in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
	if not InputMap.has_action("attack"):
		InputMap.add_action("attack")
		var m := InputEventMouseButton.new()
		m.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("attack", m)
