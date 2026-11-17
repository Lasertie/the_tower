## La Tour : tous les étages sont EMPILÉS dans un seul monde (mêmes lois, même horloge), chacun clos sous
## son faux ciel. On monte par des lieux d'ascension cachés, tous alignés sur le même axe vertical (l'Axe).
## Une seule horloge, un seul système de lois (LawSystem), une seule mémoire (WorldFlags).
class_name Tower
extends Node3D

const SLAB := 1.0
## L'Axe : (x, z) commun à tous les lieux d'ascension et d'arrivée. Sous la maison de l'Ancien, à l'étage 1.
const AXIS := Vector2(-14.0, -16.0)
const SAVE_SLOT := 1

var player: Player
var hud: Hud
var layouts: Array[FloorLayout] = []
var active_floor := 0

var _env: Environment
var _sun: DirectionalLight3D
var _traveling := false

func _ready() -> void:
	LawSystem.clear_floors()
	var save := SaveSystem.take_pending()
	_build_environment()

	player = Player.new()
	add_child(player)
	player.died.connect(_on_player_died)

	_setup_floors(save.get("layouts", {}))
	if save.has("player"):
		player.from_save_dict(save["player"])
	else:
		player.global_position = layouts[0].to_global(layouts[0].spawn_point())

	Society.item_given.connect(_on_item_given)
	hud = Hud.new()
	add_child(hud)
	hud.setup(self)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_environment() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)
	_sun = DirectionalLight3D.new()
	add_child(_sun)

# ------------------------------------------------------------------ étages
## Lit les FloorLayout déjà présents dans la scène (définis dans tower.tscn) et les configure.
## Pour ajouter un étage : glisser une nouvelle scène FloorLayout dans tower.tscn dans l'éditeur.
func _setup_floors(saved_layouts: Dictionary) -> void:
	var y := 0.0
	for child in get_children():
		if not child is FloorLayout:
			continue
		var l: FloorLayout = child
		var i := layouts.size()
		l.floor_number = i + 1
		l.base_y = y
		l.position.y = y
		y += l.floor_height + SLAB
		l.player = player
		l.layout_state = saved_layouts.get(str(l.floor_number), {})
		l.message.connect(func(t): if hud: hud.toast(t))
		l.dialogue_requested.connect(func(s, lines, then): if hud: hud.show_dialogue(s, lines, then))
		l.conversation_requested.connect(func(pid): if hud: hud.show_conversation(pid))
		l.travel_requested.connect(func(dest, yaw, style): travel(l.to_global(dest), yaw, style))
		l.ascend_requested.connect(func(): _ascend_from(l.floor_number))
		l.setup()
		l.set_active(false)
		layouts.append(l)

# ------------------------------------------------------------------ voyages
## Déplace le héros avec une animation (le monde ne montre aucun escalier : on ne voit que l'effet).
func travel(dest: Vector3, yaw := NAN, style := "fade") -> void:
	if _traveling:
		return
	_traveling = true
	player.frozen = true
	if style == "ascend":
		player.shake(3.6, 0.05)
	hud.transition(style, func():
		player.global_position = dest
		player.velocity = Vector3.ZERO
		if not is_nan(yaw):
			player.rotation.y = yaw)
	await hud.transition_done
	player.frozen = false
	_traveling = false

func _ascend_from(n: int) -> void:
	if n >= layouts.size():
		hud.toast("Le Sceau s'ouvre sur le vide : la Tour n'a pas encore bâti l'étage suivant.")
		return
	var nxt := layouts[n]
	travel(nxt.to_global(nxt.arrival_point()), PI, "ascend")

# ------------------------------------------------------------------ boucle
func _process(_delta: float) -> void:
	var n := LawSystem.floor_at(player.global_position.y)
	if n != 0 and n != active_floor:
		_set_active(n)
	if active_floor != 0:
		var cur := layouts[active_floor - 1]
		cur.apply_environment(_env, _sun)
		if player.global_position.y < cur.base_y - 1.5:   # sous terre (cave) : ni soleil, ni ciel
			_sun.light_energy = 0.0
			_env.ambient_light_color = Color(0.3, 0.26, 0.22)
			_env.background_color = Color(0.02, 0.02, 0.02)

func _set_active(n: int) -> void:
	if active_floor != 0:
		layouts[active_floor - 1].on_leave()
	active_floor = n
	for l in layouts:
		l.set_active(l.floor_number == n)
	var l := layouts[n - 1]
	l.on_enter()
	if hud:
		hud.show_banner(l.title)

## Un habitant confie un objet au joueur (confiance suffisante) : c'est aussi une manière de résoudre l'épreuve.
func _on_item_given(item: String, _from: StringName) -> void:
	player.add_item(StringName(item))
	if item == "ancient_relic":
		ScenarioManager.report(Floor01Village.SCENARIO_ID, &"well_relic")

# ------------------------------------------------------------------ mort
## Pas de téléportation gratuite : la Tour fait payer (temps écoulé, chaos) et on repart du pied de l'étage.
func _on_player_died() -> void:
	hud.fade(1.0, 0.8)
	await get_tree().create_timer(1.2).timeout
	Society.simulate(120.0)  # la Tour continue de vivre pendant votre absence
	WorldFlags.add_chaos(1)
	var l := layouts[maxi(active_floor, 1) - 1]
	player.respawn(l.to_global(l.spawn_point()))
	hud.toast("Vous revenez à vous... deux heures ont passé et la Tour s'agite.", UiTheme.DANGER, 6.0)
	hud.fade(0.0, 1.0)

# ------------------------------------------------------------------ sauvegarde
func collect_save() -> Dictionary:
	var d := {"player": player.to_save_dict(), "floor": active_floor, "layouts": {}}
	for l in layouts:
		d["layouts"][str(l.floor_number)] = l.to_save_dict()
	return d

func save_game() -> Error:
	return SaveSystem.save_game(SAVE_SLOT, collect_save())

func load_game() -> bool:
	var d := SaveSystem.load_game(SAVE_SLOT)
	if d.is_empty():
		return false
	SaveSystem.pending = d
	get_tree().paused = false
	get_tree().reload_current_scene()
	return true

func exit_to_menu() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
