## Base d'un décor d'étage : coque (sol/plafond troués pour l'escalier), porte physique de sortie,
## PNJ, objets « consommés » sauvegardés. Les étages sont EMPILÉS dans un même monde (voir Tower).
class_name FloorLayout
extends Node3D

signal message(text: String)
signal dialogue_requested(speaker: String, lines: Array, then: Callable)
signal conversation_requested(person_id: StringName)
## Voyage animé du héros (descente à la cave, ascension...) : destination en coordonnées du décor.
signal travel_requested(local_dest: Vector3, yaw: float, style: String)
## Le héros franchit le Sceau de sortie de cet étage : la Tour l'emmène à l'étage suivant, sur l'Axe.
signal ascend_requested

var floor_number := 1
var base_y := 0.0
var floor_height := 14.0
var footprint := Vector2(100, 100)
var title := ""
var ceiling_hole := Rect2()
var ground_hole := Rect2()       ## trou dans le sol (ex : le vide au-delà du Bout du monde)

var player: Player
var floor_ctrl: FloorController
var layout_state: Dictionary = {}  ## à renseigner AVANT add_child (chargement de partie)
var consumed: Dictionary = {}      ## uid -> true (objets déjà pris / ennemis déjà tués)

var _active := false
var _sync_t := 0.0

func _ready() -> void:
	# Les enfants en scène (.tscn) sont initialisés par Tower via setup() après _ready().
	# Les enfants créés en code (ancien usage) appelaient setup() implicitement via add_child.
	# Dans les deux cas, Tower appelle setup() explicitement : on ne fait rien ici.
	pass

## Appelé par Tower après avoir assigné floor_number, base_y, position.y, player et layout_state.
## C'est ici que se fait la construction réelle du décor.
func setup() -> void:
	for uid in layout_state.get("consumed", []):
		consumed[String(uid)] = true
	Society.register_places(floor_number, _society_places())
	_build_shell()
	_build()
	if floor_ctrl:
		LawSystem.register_floor(floor_number, base_y, floor_height, floor_ctrl.laws)
		floor_ctrl.from_save_dict(layout_state.get("ctrl", {}))
		ScenarioManager.floor_cleared.connect(_on_cleared)
	spawn_people()
	_sync_world()
	Society.world_effect.connect(_on_world_effect)

## Le décor n'est que le reflet de l'état de la Tour (ressources gérées par Society) : il se resynchronise
## chaque seconde quand l'étage est actif, et d'un coup à l'arrivée du joueur.
func _process(delta: float) -> void:
	if not _active:
		return
	_sync_t -= delta
	if _sync_t <= 0.0:
		_sync_t = 1.0
		_sync_world()

# ---------- à surcharger ----------
func _build() -> void:
	pass

## Lieux nommés de l'étage (coordonnées du décor) : c'est là que les personnes se rendent.
func _society_places() -> Dictionary:
	return {}

func _sync_world() -> void:
	pass

## Un habitant vient d'agir sur la Tour (la ressource est déjà décomptée) : on le MONTRE si possible.
func _on_world_effect(_pid: StringName, _resource: String, _carried: String) -> void:
	pass

func _puppet(pid: StringName) -> Inhabitant:
	for n in get_tree().get_nodes_in_group("inhabitants"):
		if n.person_id == pid and is_ancestor_of(n):
			return n
	return null

## Réserve la cible (le décor ne la retire pas d'un coup) et envoie l'habitant l'atteindre pour de vrai.
## Si le corps est occupé ou en fuite, rien n'est réservé : la resynchronisation s'applique sans animation.
func _assign(who: Inhabitant, kind: String, target: Node3D, dest := Vector3.ZERO, line := "") -> void:
	if who == null or target == null or not is_instance_valid(target) or target.has_meta("reserved"):
		return
	target.set_meta("reserved", true)
	if not who.start_task(kind, target, dest, line):
		target.remove_meta("reserved")
		return
	# Réussie : la cible est consommée et disparaît d'elle-même, elle reste donc réservée (sinon la
	# resynchronisation la retirerait une seconde fois). Échouée (fuite...) : on libère la réservation.
	who.task_finished.connect(func(_k, done):
		if not done and is_instance_valid(target) and target.get_parent() == self:
			target.remove_meta("reserved"), CONNECT_ONE_SHOT)

func _free_of(list: Array) -> Array:
	return list.filter(func(n): return is_instance_valid(n) and not n.is_queued_for_deletion() \
		and not n.has_meta("reserved"))

func spawn_point() -> Vector3:
	return Vector3(0, 0.3, 0)

## Où l'on arrive en montant : toujours sur l'Axe, juste au-dessus du lieu d'ascension de l'étage précédent.
func arrival_point() -> Vector3:
	return Vector3(Tower.AXIS.x, 0.3, Tower.AXIS.y)

func _floor_material() -> Material:
	return WorldUtil.checker(Color(0.6, 0.6, 0.6), Color(0.5, 0.5, 0.5), 2.0)

func _ceiling_material() -> Material:
	return WorldUtil.material(Color(0.6, 0.6, 0.62))

func _ground_color() -> Color:
	return Color(0.35, 0.35, 0.38)

func apply_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_energy = 0.0
	env.ambient_light_color = Color(0.5, 0.5, 0.5)
	env.fog_enabled = false

# ---------- coque ----------
func _build_shell() -> void:
	if floor_number == 1:
		WorldUtil.slab(self, -0.5, footprint, 1.0, _ground_color(), ground_hole)
	WorldUtil.slab(self, 0.01, footprint, 0.02, Color.WHITE, ground_hole, false, _floor_material())
	WorldUtil.slab(self, floor_height + 0.5, footprint, 1.0, Color(0.4, 0.4, 0.43), ceiling_hole)
	WorldUtil.slab(self, floor_height - 0.01, footprint, 0.02, Color.WHITE, ceiling_hole, false, _ceiling_material())

func _on_cleared(n: int) -> void:
	if floor_ctrl and n == floor_number:
		_on_floor_cleared()

## À surcharger : réaction du décor quand le scénario de l'étage est résolu.
func _on_floor_cleared() -> void:
	message.emit("Quelque chose a cédé, plus bas dans la Tour.")

# ---------- activation ----------
## Gèle les éléments DYNAMIQUES d'un étage où le joueur n'est pas (ennemis, contrôleur).
## Les collisions statiques restent actives : la dalle d'un étage est le sol du suivant.
func set_active(active: bool) -> void:
	_active = active
	if active:
		_sync_world()
	var mode := Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if floor_ctrl:
		floor_ctrl.process_mode = mode
	for e in get_tree().get_nodes_in_group("enemies"):
		if is_ancestor_of(e):
			e.process_mode = mode
	for a in get_tree().get_nodes_in_group("inhabitants"):
		if is_ancestor_of(a):
			if active:
				a.process_mode = Node.PROCESS_MODE_INHERIT
				a.thaw()  # ils ont continué de vivre pendant votre absence
			else:
				a.freeze()
				a.process_mode = Node.PROCESS_MODE_DISABLED

# ---------- entrée / sortie d'étage ----------
func on_enter() -> void:
	if floor_ctrl:
		floor_ctrl.on_enter()

func on_leave() -> void:
	if floor_ctrl:
		floor_ctrl.on_leave()

# ---------- objets consommés ----------
## Appeler APRÈS add_child. Retourne false (et libère le noeud) s'il a déjà été consommé.
func track(node: Node, uid: StringName) -> bool:
	if consumed.has(String(uid)):
		node.queue_free()
		return false
	for sig in [&"triggered", &"interacted", &"died"]:
		if node.has_signal(sig):
			node.connect(sig, func(_a = null): consumed[String(uid)] = true)
	return true

# ---------- PNJ & dialogues ----------
func talk(speaker: String, lines: Array, then := Callable()) -> void:
	dialogue_requested.emit(speaker, lines, then)

## Donne un corps à chaque personne de l'étage. Elles existaient déjà dans la société.
func spawn_people() -> void:
	for p in Society.people_on_floor(floor_number):
		var a := Inhabitant.new()
		a.person_id = p.id
		a.floor_number = floor_number
		a.position = Society.place_pos(floor_number, p.location, Vector3.ZERO)
		add_child(a)
		a.talk_requested.connect(func(sp, ls, th): talk(sp, ls, th))
		a.conversation_requested.connect(func(pid): conversation_requested.emit(pid))
		a.catch_up(true)

func to_save_dict() -> Dictionary:
	return {
		"consumed": consumed.keys(),
		"ctrl": floor_ctrl.to_save_dict() if floor_ctrl else {},
	}
