## Étage 1 : le Village des Épreuves (modèles Kenney City Kit, CC0). Un « ciel » de Tour au plafond
## dont la couleur suit l'horloge : l'aube orangée est visible, donc découvrable.
class_name VillageLayout
extends FloorLayout

const HOUSES := [
	["house_a", -14, -16, 8.0], ["house_b", 14, -16, 8.0], ["house_c", -34, -4, 8.0],
	["house_d", 34, -4, 8.0], ["house_a", -34, 14, 8.0], ["house_b", 36, 12, 8.0],
	["house_c", 0, -36, 8.0], ["house_d", -12, 8, 7.0], ["garage", 16, 10, 8.0],
	["house_a", 34, -30, 8.0],
]
const LABYRINTH_C := Vector3(-25, 0, -25)
const WELL_C := Vector3(25, 0, -25)
const EDGE := 120.0                       ## limite jouable ; au-delà : montagnes (N, O, E) et Bout du monde (S)
const HATCH := Vector3(-9.5, 0, -12.5)    ## trappe de la cave, contre la maison de l'Ancien
const CHAMBER_Y := -8.0                   ## la Chambre du Sceau est sous le sol, juste sous la maison, sur l'Axe

var _seal: Interactable
var _seal_mat: StandardMaterial3D
var _pillar_mat: StandardMaterial3D        ## piliers décoratifs (2 et 5)
var _lock_mats: Array[StandardMaterial3D]  ## un matériau par verrou (indices 0-3 → piliers 0,1,2,3)

var _sky_mat: StandardMaterial3D

func _init() -> void:
	floor_height = 14.0
	footprint = Vector2(290, 290)
	title = "Étage 1 - Le Village des Épreuves"
	ground_hole = Rect2(-145.0, EDGE - 1.0, 290.0, 26.0)   # le vide au-delà du Bout du monde

func spawn_point() -> Vector3:
	return Vector3(0, 0.3, 6)

func _ground_color() -> Color:
	return Color(0.32, 0.25, 0.19)   # terre : c'est le plafond de la Chambre du Sceau, vu d'en dessous

func _floor_material() -> Material:
	return WorldUtil.checker(Color(0.34, 0.6, 0.31), Color(0.31, 0.55, 0.29), 4.0)

func _ceiling_material() -> Material:
	_sky_mat = WorldUtil.unshaded(GameClock.sky_color())
	return _sky_mat

func apply_environment(env: Environment, sun: DirectionalLight3D) -> void:
	var d := GameClock.daylight()
	sun.light_energy = lerpf(0.05, 1.0, d)
	sun.rotation_degrees = Vector3(-18.0 - 55.0 * d, 40, 0)
	sun.light_color = Color(1.0, 0.85, 0.7).lerp(Color(1, 1, 0.95), d)
	env.ambient_light_color = Color(0.3, 0.35, 0.55).lerp(Color(0.72, 0.74, 0.72), d)
	env.background_color = GameClock.sky_color()
	env.fog_enabled = false
	if _sky_mat:
		_sky_mat.albedo_color = GameClock.sky_color()

func _society_places() -> Dictionary:
	return {
		"square": Vector3(3, 0, -2), "well": Vector3(22, 0, -19), "pit": Vector3(17, 0, 19),
		"farm": Vector3(11, 0, 28), "post": Vector3(-8, 0, -9.5), "woods_sw": Vector3(-34, 0, 30),
		"home_elder": Vector3(-14, 0, -11.5), "home_child": Vector3(14, 0, -11.5),
		"home_hunter": Vector3(29.5, 0, -4), "home_farmer": Vector3(12.5, 0, 7),
		"barn": Vector3(5, 0, 37.5),
	}

func _build() -> void:
	_boundaries()
	_world_end()

	var f := Floor01Village.new()
	floor_ctrl = f
	add_child(f)

	_decor()
	_labyrinth()
	_well_basin()
	WorldUtil.box(self, Vector3(14, 0.04, 9), Vector3(26, 0.03, 25), Color(0.28, 0.2, 0.14), false)  # la Fosse
	_hatch_and_chamber()

func _decor() -> void:
	for h in HOUSES:
		var yaw := rad_to_deg(atan2(-float(h[1]), -float(h[2])))
		Assets.prop(self, h[0], h[3], Vector3(h[1], 0, h[2]), yaw, &"width")
	Assets.prop(self, "fountain", 7.0, Vector3(0, 0, -8), 0, &"width")
	Assets.prop(self, "garage", 8.0, Vector3(5, 0, 42.5), rad_to_deg(atan2(-5.0, -42.5)), &"width")  # la grange
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var placed := 0
	var tries := 0
	while placed < 130 and tries < 1500:
		tries += 1
		var p := Vector2(rng.randf_range(-115, 115), rng.randf_range(-115, 115))
		if _tree_spot_blocked(p):
			continue
		placed += 1
		Assets.prop(self, "trees", rng.randf_range(2.8, 4.2), Vector3(p.x, 0, p.y),
			rng.randf_range(0, 360), &"width", false)

func _tree_spot_blocked(p: Vector2) -> bool:
	for h in HOUSES:
		if p.distance_to(Vector2(h[1], h[2])) < 10.0:
			return true
	for c in [LABYRINTH_C, WELL_C]:
		if p.distance_to(Vector2(c.x, c.z)) < 14.0:
			return true
	if p.distance_to(Vector2(0, -8)) < 8.0 or p.distance_to(Vector2(0, 6)) < 6.0:
		return true
	if p.distance_to(Vector2(HATCH.x, HATCH.z)) < 7.0:  # la trappe de la cave
		return true
	if p.x > 16 and p.x < 34 and p.y > 18 and p.y < 32:  # Fosse
		return true
	if p.x > 2 and p.x < 22 and p.y > 26 and p.y < 38:   # ferme
		return true
	return false

func _labyrinth() -> void:
	# Deux anneaux de haies, ouvertures opposées : on tourne pour atteindre la bannière.
	_ring(LABYRINTH_C, 9.0, 22, PI * 0.5, 0.45, 3.0)
	_ring(LABYRINTH_C, 4.0, 14, -PI * 0.5, 0.6, 2.6)
	var t := ScenarioTrigger.new()
	t.scenario_id = Floor01Village.SCENARIO_ID
	t.condition_id = &"labyrinth_exit"
	t.size = Vector3(3.5, 3, 3.5)
	t.position = LABYRINTH_C + Vector3(0, 1.5, 0)
	add_child(t)
	var flag := Assets.place("flag", 2.6)
	flag.position.y = -1.5
	t.add_child(flag)
	if track(t, &"labyrinth_goal"):
		t.triggered.connect(func(_p): WorldFlags.set_flag(Floor01Village.FLAG_LABYRINTH, true))

func _ring(c: Vector3, r: float, count: int, gap_angle: float, gap_half: float, size: float) -> void:
	for i in count:
		var a := TAU * i / count
		if absf(wrapf(a - gap_angle, -PI, PI)) < gap_half:
			continue
		var pos := c + Vector3(cos(a), 0, sin(a)) * r
		Assets.prop(self, "trees_tall", size, pos, rad_to_deg(a), &"width")

func _well_basin() -> void:
	Assets.prop(self, "fountain", 3.6, WELL_C, 0, &"width")

# ---------------------------------------------------------------- reflet des ressources de la Tour
const CRATE_SLOTS := [Vector3(8, 0, 32), Vector3(12, 0, 32), Vector3(16, 0, 32)]

var _pit_enemies: Array = []
var _crates: Array = []
var _relic: ScenarioTrigger
var _pass: ScenarioTrigger

func _sync_world() -> void:
	_sync_seal()
	_sync_pit()
	_sync_crates()
	_sync_relic()
	_sync_pass()

## La Fosse : le chasseur en abat (on le voit frapper), la Tour en repeuple. Ici on ne fait que refléter.
func _sync_pit() -> void:
	_pit_enemies = _pit_enemies.filter(func(e): return is_instance_valid(e) and not e.health.dead)
	var target := Society.res("pit_monsters")
	var free := _free_of(_pit_enemies)
	while free.size() > target:
		var e: Enemy = free.pop_back()
		_pit_enemies.erase(e)
		e.despawn()  # abattu par un habitant hors de notre vue : pas un meurtre du joueur
	while free.size() < target:
		var e := Enemy.new()
		e.position = Vector3(21 + randf() * 10.0, 0.1, 22.0 + randf() * 6.0)
		add_child(e)
		e.died.connect(_on_pit_monster_killed)
		_pit_enemies.append(e)
		free.append(e)

func _on_pit_monster_killed(_e: Enemy) -> void:
	Society.take_resource("pit_monsters")
	Society.player_deed("pit_kill")
	(floor_ctrl as Floor01Village).on_pit_kill()

func _sync_crates() -> void:
	_crates = _crates.filter(func(c): return is_instance_valid(c) and not c.is_queued_for_deletion())
	var target := Society.res("farm_crates")
	var free := _free_of(_crates)
	while free.size() > target:
		var c: Interactable = free.pop_back()
		_crates.erase(c)
		c.queue_free()   # la Fermière l'a déjà rentrée
	while free.size() < target:
		var used: Array = _crates.map(func(c): return c.get_meta("slot"))
		var slot := 0
		while slot in used:
			slot += 1
		var n := Interactable.new()
		n.prompt = "Porter la caisse"
		n.radius = 1.2
		n.position = CRATE_SLOTS[slot]
		n.set_meta("slot", slot)
		add_child(n)
		n.add_child(Assets.place("box_open", 1.1))
		n.interacted.connect(_on_crate_carried.bind(n))
		_crates.append(n)
		free.append(n)

func _on_crate_carried(_p: Player, crate: Interactable) -> void:
	Society.take_resource("farm_crates")
	Society.player_deed("help_farm")
	ScenarioManager.report(Floor01Village.SCENARIO_ID, &"farm_help")
	message.emit("Vous portez la caisse jusqu'à la grange.")
	crate.queue_free()

## La relique du Puits : l'Enfant peut s'en emparer avant vous (alors il la garde sur lui).
func _sync_relic() -> void:
	var exists := Society.res("relic_at_well") > 0
	if exists and not is_instance_valid(_relic):
		_relic = ScenarioTrigger.new()
		_relic.scenario_id = Floor01Village.SCENARIO_ID
		_relic.condition_id = &"well_relic"
		_relic.grants_item = &"ancient_relic"
		_relic.size = Vector3(7, 4, 7)
		_relic.position = WELL_C + Vector3(0, 2, 0)
		add_child(_relic)
		var coin := Assets.place("coin", 0.9)
		coin.position.y = -0.2
		_relic.add_child(coin)
		coin.create_tween().set_loops().tween_property(coin, "rotation:y", TAU, 3.0).as_relative()
		_relic.triggered.connect(func(_p):
			Society.take_resource("relic_at_well")
			Society.player_deed("relic_taken")
			WorldFlags.set_flag(Floor01Village.FLAG_RELIC_TAKEN, true))
	elif not exists and is_instance_valid(_relic) and not _relic.has_meta("reserved"):
		_relic.queue_free()

## Le parchemin égaré de l'Ancien : sur le sol tant qu'il ne l'a pas retrouvé.
func _sync_pass() -> void:
	var exists := Society.res("elder_pass_ground") > 0
	if exists and not is_instance_valid(_pass):
		_pass = ScenarioTrigger.new()
		_pass.grants_item = &"elder_pass"
		_pass.size = Vector3(2.5, 3, 2.5)
		_pass.position = Vector3(-38, 1.5, 32)
		add_child(_pass)
		var b := Assets.place("books", 0.6)
		b.position.y = -1.5
		_pass.add_child(b)
		_pass.triggered.connect(func(_p): Society.take_resource("elder_pass_ground"))
	elif not exists and is_instance_valid(_pass) and not _pass.has_meta("reserved"):
		_pass.queue_free()

## Les habitants agissent sous nos yeux : le Chasseur frappe une bête, la Fermière porte une caisse jusqu'à
## la grange, l'Enfant et l'Ancien vont ramasser leurs trouvailles.
func _on_world_effect(pid: StringName, resource: String, _carried: String) -> void:
	if not _active:
		return
	var who := _puppet(pid)
	if who == null:
		return
	match resource:
		"pit_monsters":
			var best: Node3D = null
			for e in _free_of(_pit_enemies):
				if best == null or e.position.distance_to(who.position) < best.position.distance_to(who.position):
					best = e
			_assign(who, "strike", best, Vector3.ZERO, "Et une de moins !")
		"farm_crates":
			var free := _free_of(_crates).filter(func(c): return c.is_available())
			if not free.is_empty():
				_assign(who, "carry", free[0], Society.place_pos(1, "barn"), "Encore une de rentrée.")
		"relic_at_well":
			_assign(who, "grab", _relic, Vector3.ZERO, "Ha ! Je l'ai !")
		"elder_pass_ground":
			_assign(who, "grab", _pass, Vector3.ZERO, "Enfin ! Le voilà.")

# ---------------------------------------------------------------- un monde clos sous un faux ciel
## Pas de muraille : des montagnes sur trois côtés (elles montent jusqu'au ciel), le Bout du monde au sud.
func _boundaries() -> void:
	WorldUtil.invisible_wall(self, Vector3(2, 20, 244), Vector3(-EDGE - 1.0, 10, 0))
	WorldUtil.invisible_wall(self, Vector3(2, 20, 244), Vector3(EDGE + 1.0, 10, 0))
	WorldUtil.invisible_wall(self, Vector3(244, 20, 2), Vector3(0, 10, -EDGE - 1.0))
	WorldUtil.invisible_wall(self, Vector3(244, 20, 2), Vector3(0, 10, EDGE - 0.5))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var cols := [Color(0.42, 0.4, 0.38), Color(0.5, 0.46, 0.42), Color(0.36, 0.38, 0.4), Color(0.46, 0.42, 0.38)]
	var t := -144.0
	while t <= 144.0:   # nord
		WorldUtil.mountain(self, Vector3(t, 0, -EDGE - 22.0 + rng.randf_range(-5, 5)),
			rng.randf_range(22, 30), 14.6, cols[rng.randi() % cols.size()])
		t += 26.0
	var z := -120.0
	while z <= EDGE:    # ouest et est
		for side in [-1.0, 1.0]:
			WorldUtil.mountain(self, Vector3(side * (EDGE + 22.0 + rng.randf_range(-5, 5)), 0, z),
				rng.randf_range(22, 30), 14.6, cols[rng.randi() % cols.size()])
		z += 26.0

## Le Bout du monde : le sol s'arrête, l'eau tombe dans le vide. On y recueille la Fiole de la cascade
## (un objet qui servira bien plus haut, à l'étage 5).
func _world_end() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for i in range(-14, 15):   # rebord de rochers bas : on voit qu'on est au bord
		WorldUtil.box(self, Vector3(rng.randf_range(4, 7), rng.randf_range(0.2, 0.5), 1.4),
			Vector3(i * 9.0, 0.1, EDGE - 1.2 + rng.randf_range(-0.4, 0.4)), Color(0.4, 0.38, 0.35), false)
	WorldUtil.waterfall(self, Vector3(0, -99.5, EDGE + 2.0), Vector2(300, 200))
	WorldUtil.mist(self, Vector3(0, 7.0, EDGE + 8.0), Vector2(300, 14))   # horizon blanc, visible de loin
	var vial := Interactable.new()
	vial.prompt = "Recueillir l'eau du Bout du monde"
	vial.radius = 1.5
	vial.position = Vector3(0, 0, EDGE - 5.0)
	add_child(vial)
	var orb := WorldUtil.marker(vial, Vector3(0, 0.6, 0), Color(0.6, 0.85, 1.0), 0.35)
	var om := orb.material_override as StandardMaterial3D
	om.emission_enabled = true
	om.emission = Color(0.5, 0.8, 1.0)
	if track(vial, &"vial"):
		vial.interacted.connect(func(p):
			p.add_item(&"waterfall_vial")
			message.emit("Vous recueillez l'eau qui tombe au Bout du monde."))

# ---------------------------------------------------------------- la Chambre du Sceau (sous la maison de l'Ancien)
func _hatch_and_chamber() -> void:
	# Trappe de la cave, contre la maison de l'Ancien
	WorldUtil.box(self, Vector3(2.0, 0.12, 2.0), HATCH + Vector3(0, 0.06, 0), Color(0.33, 0.23, 0.14), false)
	WorldUtil.marker(self, HATCH + Vector3(0.6, 0.2, 0), Color(0.7, 0.6, 0.3), 0.12)
	var hatch := Interactable.new()
	hatch.prompt = "Descendre dans la cave"
	hatch.one_shot = false
	hatch.radius = 1.4
	hatch.position = HATCH
	add_child(hatch)
	hatch.interacted.connect(func(_p):
		travel_requested.emit(Vector3(Tower.AXIS.x, CHAMBER_Y + 0.3, Tower.AXIS.y + 4.0), 0.0, "fade"))

	# La chambre : une pièce de pierre sous le sol, exactement sous la maison (sur l'Axe)
	var c := Vector3(Tower.AXIS.x, CHAMBER_Y, Tower.AXIS.y)
	var stone := WorldUtil.checker(Color(0.42, 0.4, 0.38), Color(0.34, 0.32, 0.3), 1.0)
	WorldUtil.box(self, Vector3(16, 1, 16), c + Vector3(0, -0.5, 0), Color.WHITE, true, stone)
	var wall := WorldUtil.material(Color(0.3, 0.28, 0.27))
	for d in [Vector3(0, 0, -8.0), Vector3(0, 0, 8.0)]:
		WorldUtil.box(self, Vector3(17, 7, 1), c + d + Vector3(0, 3.5, 0), Color.WHITE, true, wall)
	for d in [Vector3(-8.0, 0, 0), Vector3(8.0, 0, 0)]:
		WorldUtil.box(self, Vector3(1, 7, 15), c + d + Vector3(0, 3.5, 0), Color.WHITE, true, wall)

	_seal_mat = WorldUtil.material(Color(0.2, 0.05, 0.05))
	_seal_mat.emission_enabled = true
	_seal_mat.emission = Color(0.9, 0.15, 0.1)
	_seal_mat.emission_energy_multiplier = 1.3
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 2.4
	cyl.bottom_radius = 2.4
	cyl.height = 0.12
	disc.mesh = cyl
	disc.material_override = _seal_mat
	disc.position = c + Vector3(0, 0.06, 0)
	add_child(disc)

	# Piliers décoratifs par défaut (partagés par les 2 piliers neutres)
	_pillar_mat = WorldUtil.material(Color(0.25, 0.2, 0.16))
	_pillar_mat.emission_enabled = true
	_pillar_mat.emission = Color(0.9, 0.15, 0.1)
	_pillar_mat.emission_energy_multiplier = 0.35

	# 6 piliers : les 4 premiers portent un verrou (glyphe), les 2 derniers sont décoratifs.
	# Niveau d'aide 1 : chaque pilier de verrou s'allume individuellement (vert = satisfait).
	_lock_mats.clear()
	for i in 6:
		var a := TAU * i / 6.0
		var pil := WorldUtil.box(self, Vector3(0.5, 2.2, 0.5),
			c + Vector3(cos(a) * 4.2, 1.1, sin(a) * 4.2), Color(0.5, 0.42, 0.3), false)
		if i < 4:
			# Pilier de verrou : matériau propre
			var mat := WorldUtil.material(Color(0.25, 0.2, 0.16))
			mat.emission_enabled = true
			mat.emission = Color(0.9, 0.15, 0.1)   # rouge = non satisfait
			mat.emission_energy_multiplier = 0.35
			(pil as MeshInstance3D).material_override = mat
			_lock_mats.append(mat)
		else:
			(pil as MeshInstance3D).material_override = _pillar_mat
	for off in [Vector3(-5, 3, -5), Vector3(5, 3, 5), Vector3(5, 3, -5), Vector3(-5, 3, 5)]:
		var l := OmniLight3D.new()
		l.position = c + off
		l.light_color = Color(1.0, 0.8, 0.55)
		l.light_energy = 1.2
		l.omni_range = 11.0
		add_child(l)

	_seal = Interactable.new()
	_seal.prompt = "Examiner le sceau"
	_seal.one_shot = false
	_seal.radius = 3.0
	_seal.position = c + Vector3(0, 0.6, 0)
	add_child(_seal)
	_seal.interacted.connect(_on_seal)

	var out := Interactable.new()
	out.prompt = "Remonter à la surface"
	out.one_shot = false
	out.radius = 1.4
	out.position = c + Vector3(0, 0.6, 6.0)
	add_child(out)
	WorldUtil.box(self, Vector3(1.4, 0.1, 1.4), c + Vector3(0, 0.05, 6.0), Color(0.85, 0.85, 0.75), false)
	out.interacted.connect(func(_p):
		travel_requested.emit(HATCH + Vector3(0, 0.3, 2.4), PI, "fade"))

func _on_seal(p: Player) -> void:
	if _seal == null:
		return
	var f1 := floor_ctrl as Floor01Village
	# La surveillance est vérifiée à la trappe (entrée en surface), pas dans la chambre souterraine.
	var watch_pos := to_global(HATCH)
	var result := f1.attempt_seal(p, watch_pos)
	if result.open:
		ascend_requested.emit()
	else:
		message.emit("Le sceau reste inerte.")

func _sync_seal() -> void:
	if _seal == null or floor_ctrl == null:
		return
	var f1 := floor_ctrl as Floor01Village
	# La surveillance est vérifiée à la trappe (entrée en surface).
	var seal_world_pos := to_global(HATCH)
	var ctx := SealContext.new(player, f1.floor_number, seal_world_pos)
	var result := f1.seal.evaluate(ctx)
	var satisfied: Dictionary = result.get("satisfied", {})
	# Mettre à jour les 4 piliers de verrous (ordre : consent, merit, watch, item)
	var lock_ids := [&"lock_consent", &"lock_merit", &"lock_watch", &"lock_item"]
	for i in _lock_mats.size():
		var ok: bool = satisfied.get(String(lock_ids[i]), false)
		_lock_mats[i].emission = Color(0.2, 0.9, 0.3) if ok else Color(0.9, 0.15, 0.1)
	# Disque central et prompt selon l'ouverture globale
	var open: bool = result.open or floor_ctrl.is_cleared()
	_seal_mat.emission = Color(0.2, 0.9, 0.3) if open else Color(0.9, 0.15, 0.1)
	_seal.prompt = "Franchir le sceau" if open else "Examiner le sceau"

func _on_floor_cleared() -> void:
	message.emit("Un grondement sourd monte de la cave.")
