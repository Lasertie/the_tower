## Étage 2 : l'Asile (mobilier Kenney Furniture Kit + KayKit Furniture Bits, CC0).
class_name AsylumLayout
extends FloorLayout

const H := 3.6
const PATIENT_SPOTS := [
	Vector2(-20, -20), Vector2(-8, -18), Vector2(8, -18), Vector2(20, -15),
	Vector2(-22, -3), Vector2(-5, -6), Vector2(16, -4), Vector2(22, 8),
	Vector2(4, 8), Vector2(-16, 6), Vector2(-6, 22), Vector2(18, 22),
]

func _init() -> void:
	floor_height = H
	footprint = Vector2(62, 62)
	title = "Étage 2 - L'Asile"

func spawn_point() -> Vector3:
	return arrival_point()

func _ground_color() -> Color:
	return Color(0.4, 0.4, 0.42)

func _floor_material() -> Material:
	return WorldUtil.checker(Color(0.78, 0.8, 0.8), Color(0.58, 0.62, 0.64), 1.0)

func _ceiling_material() -> Material:
	return WorldUtil.material(Color(0.72, 0.72, 0.74))

func apply_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_energy = 0.0
	env.ambient_light_color = Color(0.34, 0.34, 0.42)
	env.background_color = Color(0.02, 0.02, 0.03)
	env.fog_enabled = true
	env.fog_light_color = Color(0.05, 0.06, 0.08)
	env.fog_density = 0.02

func _society_places() -> Dictionary:
	return {"post": Vector3(-10, 0, -12.5)}

func on_enter() -> void:
	super.on_enter()
	Society.unlock_topics(["patients", "gourou", "cle"])

func _build() -> void:
	# Murs extérieurs et cloisons (éléments modulaires Kenney)
	var c := 30.5
	for seg in [[-c, -c, c, -c], [c, -c, c, c], [c, c, -c, c], [-c, c, -c, -c],
			[-20, -10, 0, -10], [10, -5, 10, 15], [0, 15, 16, 15], [-12, 11, -12, 25]]:
		WorldUtil.wall_line(self, Vector3(seg[0], 0, seg[1]), Vector3(seg[2], 0, seg[3]), H)

	var f := Floor02Asylum.new()
	floor_ctrl = f
	add_child(f)
	f.message.connect(func(t): message.emit(t))

	_arrival_cabin()
	_lights()
	_beds()
	_f = f
	_guru(f)
	_office()
	_bathroom()
	_safe_room(Vector3(-22, 0, -13), f)
	_safe_room(Vector3(20, 0, 14), f)
	_forgotten_door(f)
	_clutter()

func _lights() -> void:
	for x in [-20, 0, 20]:
		for z in [-20, 0, 20]:
			Assets.prop(self, "lamp_ceiling", 0.6, Vector3(x, H - 0.6, z), 0, &"height", false)
			var l := OmniLight3D.new()
			l.position = Vector3(x, H - 0.5, z)
			l.light_color = Color(0.85, 0.92, 1.0)
			l.light_energy = 0.9
			l.omni_range = 13.0
			add_child(l)

var _f: Floor02Asylum
var _patients: Dictionary = {}  # index de lit -> Interactable

func _beds() -> void:
	for i in PATIENT_SPOTS.size():
		var p: Vector2 = PATIENT_SPOTS[i]
		Assets.prop(self, "bed", 2.0, Vector3(p.x + 1.7, 0, p.y), 0, &"width")

## Les patients : l'Infirmière en soigne (on la voit aller à leur chevet), la Tour en envoie d'autres.
func _sync_world() -> void:
	if _f == null:
		return
	for i in _patients.keys():
		if not is_instance_valid(_patients[i]) or _patients[i].is_queued_for_deletion():
			_patients.erase(i)
	var target := Society.res("asylum_patients")
	var free_idx: Array = _patients.keys().filter(func(i): return not _patients[i].has_meta("reserved"))
	while free_idx.size() > target:
		var idx: int = free_idx.max()
		_patients[idx].queue_free()   # soigné hors de notre vue
		_patients.erase(idx)
		free_idx.erase(idx)
	while free_idx.size() < target:
		var idx := 0
		while _patients.has(idx):
			idx += 1
		_spawn_patient(idx)
		free_idx.append(idx)

func _on_world_effect(pid: StringName, resource: String, _carried: String) -> void:
	if not _active or resource != "asylum_patients":
		return
	var nurse := _puppet(pid)
	if nurse == null:
		return
	var best: Node3D = null
	for i in _patients:
		var n: Node3D = _patients[i]
		if is_instance_valid(n) and not n.has_meta("reserved") \
				and (best == null or n.position.distance_to(nurse.position) < best.position.distance_to(nurse.position)):
			best = n
	_assign(nurse, "tend", best, Vector3.ZERO, "Voilà, ça ira mieux.")

func _spawn_patient(i: int) -> void:
	var p: Vector2 = PATIENT_SPOTS[i]
	var n := Interactable.new()
	n.prompt = "Soigner le patient"
	n.title = "Patient"
	n.radius = 1.3
	n.position = Vector3(p.x, 0, p.y)
	add_child(n)
	var m := CharacterModel.new().setup("character", 1.7)
	m.tint(Color(0.82, 0.86, 0.95))
	n.add_child(m)
	m.play(&"idle")
	n.interacted.connect(func(_pl):
		_f.heal_patient()
		Society.take_resource("asylum_patients")
		Society.player_deed("heal_patient")
		n.queue_free())
	_patients[i] = n

func _guru(f: Floor02Asylum) -> void:
	Assets.prop(self, "armchair", 2.2, Vector3(0, 0, -26), 0, &"width")
	var g := Enemy.new()
	g.model_key = "character"
	g.model_height = 2.3
	g.hover = 0.0
	g.tint_color = Color(0.62, 0.25, 0.85)
	g.max_health = 250.0
	g.speed = 3.5
	g.damage = 15.0
	g.attack_range = 2.6
	g.position = Vector3(0, 0.1, -22)
	add_child(g)
	if track(g, &"guru"):
		f.register_guru(g)
		var l := OmniLight3D.new()
		l.position = Vector3(0, 3.0, -23)
		l.light_color = Color(0.7, 0.3, 1.0)
		l.light_energy = 1.6
		l.omni_range = 9.0
		add_child(l)

func _office() -> void:
	Assets.prop(self, "desk", 1.9, Vector3(25, 0, -22), 90, &"width")
	Assets.prop(self, "chair_desk", 0.95, Vector3(27, 0, -22), -90, &"height")
	Assets.prop(self, "bookcase", 2.0, Vector3(29.4, 0, -19), -90, &"height")
	Assets.prop(self, "bookcase", 2.0, Vector3(29.4, 0, -25), -90, &"height")
	Assets.prop(self, "plant", 1.0, Vector3(22, 0, -27), 0, &"height")
	var t := ScenarioTrigger.new()
	t.scenario_id = Floor02Asylum.SCENARIO_ID
	t.condition_id = &"director_key"
	t.grants_item = &"director_key"
	t.size = Vector3(4, 3, 5)
	t.position = Vector3(25, 1.5, -22)
	add_child(t)
	var key := Assets.place("coin", 0.45)
	key.position.y = -0.55
	key.rotation.x = PI * 0.5
	t.add_child(key)
	if not track(t, &"director_key"):
		return
	var l := OmniLight3D.new()
	l.position = Vector3(25, 2.6, -22)
	l.light_color = Color(1.0, 0.85, 0.5)
	l.light_energy = 1.2
	l.omni_range = 8.0
	add_child(l)

func _bathroom() -> void:
	Assets.prop(self, "toilet", 1.0, Vector3(-28, 0, -28), 90, &"height")
	Assets.prop(self, "sink", 1.0, Vector3(-28, 0, -24.5), 90, &"height")
	Assets.prop(self, "bathtub", 2.0, Vector3(-24, 0, -29), 0, &"width")
	# Une caisse oubliée : les bottes d'ancrage (faille de la loi de gravité)
	var t := ScenarioTrigger.new()
	t.grants_item = &"anchor_boots"
	t.size = Vector3(2.5, 3, 2.5)
	t.position = Vector3(-27, 1.5, -22)
	add_child(t)
	var box := Assets.place("box", 0.7)
	box.position.y = -1.5
	t.add_child(box)
	track(t, &"boots")

func _safe_room(pos: Vector3, f: Floor02Asylum) -> void:
	Assets.prop(self, "sofa", 2.2, pos + Vector3(0, 0, -3), 0, &"width")
	Assets.prop(self, "lamp_standing", 1.6, pos + Vector3(-3, 0, -3), 0, &"height")
	Assets.prop(self, "plant", 1.0, pos + Vector3(3, 0, -3), 0, &"height")
	Assets.prop(self, "side_table", 0.8, pos + Vector3(3, 0, 0), 0, &"height")
	var l := OmniLight3D.new()
	l.position = pos + Vector3(0, 2.6, 0)
	l.light_color = Color(1.0, 0.82, 0.55)
	l.light_energy = 2.2
	l.omni_range = 11.0
	add_child(l)
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(9, 3, 9)
	cs.shape = bs
	area.add_child(cs)
	area.position = pos + Vector3(0, 1.5, 0)
	add_child(area)
	area.body_entered.connect(func(b): if b is Player: f.safe_zone_count += 1)
	area.body_exited.connect(func(b): if b is Player: f.safe_zone_count = maxi(f.safe_zone_count - 1, 0))

## Condition D : un mur nu qui ne cède qu'à 100 % de folie. Aucun indice explicite.
func _forgotten_door(f: Floor02Asylum) -> void:
	# Les Oubliés, derrière le mur
	for i in 3:
		var m := CharacterModel.new().setup("character", 1.7)
		m.tint(Color(0.45, 0.12, 0.15))
		m.position = Vector3(24 + i * 2.2, 0, 29.0)
		m.rotation.y = 0.0
		add_child(m)
		m.play(&"idle")
	if consumed.has("forgotten_door"):
		return
	var wall := WorldUtil.wall_line(self, Vector3(23, 0, 27), Vector3(29, 0, 27), H)
	var door := Interactable.new()
	door.prompt = "Examiner le mur"
	door.one_shot = false
	door.radius = 1.4
	door.position = Vector3(26, 1.0, 25.6)
	add_child(door)
	door.interacted.connect(func(_p):
		if f.try_forgotten_door():
			consumed["forgotten_door"] = true
			wall.queue_free()
			door.queue_free()
			message.emit("Le mur s'efface. Derrière, les Oubliés vous attendent...")
		else:
			message.emit("Un mur nu. Rien ne se passe."))

func _clutter() -> void:
	var items := [["trashcan", 0.9, -5, 4], ["box", 0.7, 6, -3], ["radio", 0.5, 12, 20], ["trashcan", 0.9, 14, -9],
		["box_open", 0.7, -14, 22], ["stool", 0.9, -3, 12], ["cabinet", 1.0, 26, 4], ["cabinet_small", 1.0, -26, 6],
		["shelf", 0.9, 0, 29.6], ["table_round", 0.8, 3, 20], ["bench", 1.0, -14, -4]]
	for it in items:
		Assets.prop(self, it[0], it[1], Vector3(it[2], 0, it[3]), randf() * 360.0, &"height")

## Cabine d'arrivée : on émerge ici, sur l'Axe, juste au-dessus de la Chambre du Sceau de l'étage 1.
func _arrival_cabin() -> void:
	var cx := Tower.AXIS.x
	var cz := Tower.AXIS.y
	WorldUtil.wall_line(self, Vector3(cx - 3, 0, cz - 3), Vector3(cx + 3, 0, cz - 3), H)
	WorldUtil.wall_line(self, Vector3(cx - 3, 0, cz - 3), Vector3(cx - 3, 0, cz + 3), H)
	WorldUtil.wall_line(self, Vector3(cx + 3, 0, cz - 3), Vector3(cx + 3, 0, cz + 3), H)
	var glow := WorldUtil.material(Color(0.1, 0.3, 0.3))
	glow.emission_enabled = true
	glow.emission = Color(0.3, 0.9, 0.85)
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.6
	cyl.bottom_radius = 1.6
	cyl.height = 0.06
	disc.mesh = cyl
	disc.material_override = glow
	disc.position = Vector3(cx, 0.04, cz)
	add_child(disc)
	var l := OmniLight3D.new()
	l.position = Vector3(cx, H - 0.6, cz)
	l.light_color = Color(0.6, 1.0, 0.95)
	l.light_energy = 1.4
	l.omni_range = 9.0
	add_child(l)
