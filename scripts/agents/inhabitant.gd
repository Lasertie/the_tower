## Corps 3D d'une Person (voir Society). Il n'a PAS de vie propre : la personne décide (activité, lieu),
## le corps l'exécute (marche, dort, se cache, fuit, parle). Quand l'étage n'est pas actif, la personne
## continue de vivre sans corps ; à notre retour, le corps est replacé selon ce qu'elle a fait.
##
## Il ignore les lois de la Tour : il ne les connaît pas, les subit seulement comme un corps
## (gravité inversée...). Les failles (porte sans surveillance) ne sont qu'une conséquence émergente.
class_name Inhabitant
extends CharacterBody3D

enum State { IDLE, GOTO, WORK, EAT, SLEEP, HOME, FLEE, TALK }

signal talk_requested(speaker: String, lines: Array, then: Callable)   ## lignes simples (réveil brutal)
signal conversation_requested(person_id: StringName)                  ## vraie conversation à choix
signal task_finished(kind: String, done: bool)   ## done = la cible a été atteinte et consommée

@export var person_id: StringName = &""
@export var floor_number := 1

var state := State.IDLE
var model: CharacterModel
var talk_area: Interactable
var gravity_scale := 1.0
var display_name := ""
var is_sentinel := false

var _p: Person
var _task: Dictionary = {}           ## action visible sur la Tour : strike / carry / grab / tend
var _task_t := 0.0
var _carried: Node3D
var _chat_partner: Inhabitant
var _chat_t := 0.0
var _slash: MeshInstance3D
var _col: CollisionShape3D
var _goal := Vector3.ZERO
var _has_goal := false
var _tick := randf() * 0.5
var _wander_t := randf_range(1.0, 4.0)
var _talk_t := 0.0
var _flee_t := 0.0
var _frozen_at := -1.0
var _stuck_t := 0.0
var _stuck_count := 0
var _last_pos := Vector3.ZERO
var _bubble: Label3D
var _bubble_t := 0.0
var _bark_t := randf_range(4.0, 10.0)
var _player: Node3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

func _ready() -> void:
	_p = Society.person(person_id)
	display_name = _p.display_name
	is_sentinel = _p.is_sentinel
	add_to_group("inhabitants")
	if is_sentinel:
		add_to_group("sentinels")

	_col = CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = maxf(_p.height, 1.0)
	_col.shape = cap
	_col.position.y = cap.height * 0.5
	add_child(_col)

	model = CharacterModel.new().setup("character", _p.height)
	model.tint(_p.tint)
	add_child(model)
	_stand()

	talk_area = Interactable.new()
	talk_area.one_shot = false
	talk_area.radius = 1.6
	talk_area.title = display_name
	talk_area.title_height = _p.height + 0.5
	talk_area.prompt = "Parler à %s" % display_name
	add_child(talk_area)
	talk_area.interacted.connect(_on_interact)

	_bubble = Label3D.new()
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.font = UiTheme.font()
	_bubble.font_size = 44
	_bubble.pixel_size = 0.0055
	_bubble.outline_size = 14
	_bubble.position = Vector3(0, _p.height + 1.1, 0)
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.width = 380.0
	_bubble.visible = false
	add_child(_bubble)

	Society.social_event.connect(_on_social)
	Society.gossip_told.connect(_on_gossip)

# ------------------------------------------------------------------ lecture publique
func is_watching() -> bool:
	return state in [State.IDLE, State.GOTO, State.WORK, State.EAT, State.TALK]

func is_asleep() -> bool:
	return state == State.SLEEP

func say(text: String, seconds := 2.6) -> void:
	_bubble.text = text
	_bubble.visible = true
	_bubble_t = seconds

# ------------------------------------------------------------------ gel / rattrapage entre étages
func freeze() -> void:
	_frozen_at = GameClock.absolute_minutes()

func thaw() -> void:
	catch_up(false)

## La personne a continué de vivre pendant l'absence du joueur : on replace le corps en conséquence.
func catch_up(force := false) -> void:
	var elapsed := GameClock.absolute_minutes() - _frozen_at if _frozen_at >= 0.0 else 1.0e9
	if not force and elapsed < 20.0:
		return
	var place := _place(_p.location)
	velocity = Vector3.ZERO
	_has_goal = false
	_stand()
	_set_hidden(false)
	match _p.activity:
		"home":
			position = place
			_set_hidden(true)
			state = State.HOME
		"sleep":
			position = place
			_enter_sleep()
		_:
			var a := randf() * TAU
			position = place + Vector3(cos(a), 0, sin(a)) * _p.wander_radius * randf() * 0.8
			state = _state_for(_p.activity)
	_frozen_at = -1.0

func _place(name: String) -> Vector3:
	return Society.place_pos(floor_number, name, position)

func _state_for(act: String) -> State:
	match act:
		"work": return State.WORK
		"eat": return State.EAT
		"sleep": return State.SLEEP
		"home": return State.HOME
	return State.IDLE  # idle, chat, visit...

# ------------------------------------------------------------------ boucle
func _physics_process(delta: float) -> void:
	if _bubble_t > 0.0:
		_bubble_t -= delta
		if _bubble_t <= 0.0 and state != State.SLEEP:
			_bubble.visible = false

	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.5
		_think()

	if state == State.HOME:
		return

	# Gravité : un habitant est un corps comme un autre, soumis aux mêmes lois que le joueur.
	var g := LawSystem.gravity_scale_for(self)
	if g != gravity_scale:
		gravity_scale = g
		up_direction = Vector3.UP * g
		velocity.y = 0.0
		if state != State.SLEEP:
			_stand()
	if not is_on_floor():
		velocity.y -= _gravity * gravity_scale * delta

	if _talk_t > 0.0:
		_talk_t -= delta
		if _talk_t <= 0.0 and state == State.TALK:
			state = State.IDLE
			_stand()

	_task_step(delta)
	_chat_step(delta)

	var desired := Vector3.ZERO
	if _has_goal and state != State.SLEEP and state != State.TALK:
		var to := _goal - position
		to.y = 0.0
		if to.length() < 0.5:
			_has_goal = false
			_stuck_count = 0
			_on_arrive()
		else:
			var d := to.normalized()
			desired = d * _p.speed * (1.9 if state == State.FLEE else 1.0)
			look_at(global_position + d, Vector3.UP)
		_check_stuck(delta)
	velocity.x = desired.x
	velocity.z = desired.z
	move_and_slide()

	if state != State.SLEEP:
		model.play(&"walk" if Vector2(velocity.x, velocity.z).length() > 0.3 else &"idle")
	_ambient_barks(delta)

func _check_stuck(delta: float) -> void:
	_stuck_t += delta
	if _stuck_t < 1.2:
		return
	_stuck_t = 0.0
	if position.distance_to(_last_pos) < 0.15 and _has_goal:
		_stuck_count += 1
		if _stuck_count >= 6:
			position = _goal
			_stuck_count = 0
		else:
			_goal = position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
	_last_pos = position

# ------------------------------------------------------------------ exécution du plan de la personne
func _think() -> void:
	talk_area.prompt = ("Réveiller %s" if state == State.SLEEP else "Parler à %s") % display_name
	talk_area.used = state == State.HOME

	# Perception : un monstre éveillé à proximité. La peur est immédiate, côté corps ET côté société.
	var threat := _nearest_threat()
	if threat != null and _p.courage < 0.8:
		_start_flee()
		return
	if threat != null and _p.courage >= 0.8 and randf() < 0.15:
		say("Du calme, on se calme !")
	if state == State.FLEE:
		_flee_t -= 0.5
		if _flee_t <= 0.0:
			state = State.IDLE
			_has_goal = false
		else:
			return
	if state == State.TALK or not _task.is_empty() or _chat_t > 0.0:
		return

	# Plan de la personne
	var act := _p.activity
	var place := _place(_p.location)
	match act:
		"sleep":
			if state == State.SLEEP:
				return
			if position.distance_to(place) > 1.0:
				_go(place, State.GOTO)
			else:
				_enter_sleep()
		"home":
			if state == State.HOME:
				return
			if position.distance_to(place) > 1.2:
				_go(place, State.GOTO)
			else:
				_set_hidden(true)
				state = State.HOME
		_:
			if state == State.SLEEP:
				_wake_body()
			if state == State.HOME:
				_emerge(_place(_p.home) if _p.location == _p.home else place)
			if position.distance_to(place) > _p.wander_radius + 1.5:
				_go(place, State.GOTO)
			else:
				if state != State.GOTO or not _has_goal:
					state = _state_for(act)
				_wander(place)

func _nearest_threat() -> Node3D:
	var best: Node3D = null
	var best_d := 9.0 if state != State.SLEEP else 5.0
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.process_mode == Node.PROCESS_MODE_DISABLED or e.health.dead:
			continue
		var d := global_position.distance_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best

func _start_flee() -> void:
	var was_calm := state != State.FLEE
	if state == State.SLEEP:
		_wake_body()
	if state == State.HOME:
		return
	state = State.FLEE
	_flee_t = 3.0
	_goal = _place(_p.home)
	_has_goal = true
	if was_calm:
		say("Au secours !", 2.0)
		Society.on_threat(person_id)
		_spread_alarm()

## Panique contagieuse : les voisins peu courageux fuient à leur tour (rare mais spectaculaire).
func _spread_alarm() -> void:
	for o in get_tree().get_nodes_in_group("inhabitants"):
		if o != self and o.process_mode != Node.PROCESS_MODE_DISABLED \
				and global_position.distance_to(o.global_position) < 10.0:
			o.hear_alarm()

func hear_alarm() -> void:
	if _p.courage < 0.7 and state != State.HOME and state != State.FLEE:
		_start_flee()

func _go(target: Vector3, st: State) -> void:
	_goal = target
	_has_goal = true
	state = st

func _wander(center: Vector3) -> void:
	_wander_t -= 0.5
	if _wander_t > 0.0 or _has_goal:
		return
	_wander_t = randf_range(3.0, 8.0)
	if randf() < 0.3:
		return
	var r := _p.wander_radius
	if _p.curiosity > 0.0 and _p.activity == "idle" and randf() < 0.05:
		r *= 3.0
	var a := randf() * TAU
	_goal = center + Vector3(cos(a), 0, sin(a)) * r * randf()
	_has_goal = true

func _on_arrive() -> void:
	if state == State.GOTO:
		state = _state_for(_p.activity) if _p.activity != "sleep" and _p.activity != "home" else State.IDLE
	if state == State.FLEE and position.distance_to(_place(_p.home)) < 1.5:
		_set_hidden(true)
		state = State.HOME
	elif _p.activity == "eat" and state == State.EAT and randf() < 0.5:
		say("Miam.")

# ------------------------------------------------------------------ sommeil / maison
func _enter_sleep() -> void:
	state = State.SLEEP
	_has_goal = false
	model.rotation = Vector3(-PI * 0.5, PI, 0)
	model.position.y = 0.3
	model.play(&"idle")
	_bubble.text = "Zzz..."
	_bubble.visible = true

func _wake_body() -> void:
	if state == State.SLEEP:
		state = State.IDLE
		_bubble.visible = false
		_stand()

func _stand() -> void:
	if gravity_scale < 0.0:
		model.position.y = _p.height
		model.rotation = Vector3(0, PI, PI)
	else:
		model.position.y = 0.0
		model.rotation = Vector3(0, PI, 0)

func _set_hidden(h: bool) -> void:
	visible = not h
	if _col:
		_col.set_deferred("disabled", h)
	if h:
		_bubble.visible = false

func _emerge(place: Vector3) -> void:
	position = place
	_set_hidden(false)
	_stand()
	state = State.IDLE

# ------------------------------------------------------------------ interaction
func _on_interact(player: Node) -> void:
	if state == State.HOME:
		return
	if state == State.SLEEP:
		_wake_body()
		Society.wake(person_id, 30.0)   # la société le sait : surveillance rétablie, rancune éventuelle
		say(String(_p.wake_lines[0]), 2.5)
		talk_requested.emit(display_name, _p.wake_lines, Callable())
		return
	if state == State.FLEE:
		say(_p.scared_line, 2.0)
		return
	var to: Vector3 = (player as Node3D).global_position - global_position
	model.rotation.y = atan2(to.x, to.z) - rotation.y
	state = State.TALK
	_has_goal = false
	_talk_t = 2.5
	conversation_requested.emit(person_id)

# ------------------------------------------------------------------ vie ambiante
func _ambient_barks(delta: float) -> void:
	if _p.barks.is_empty() or state in [State.SLEEP, State.HOME, State.FLEE, State.TALK]:
		return
	_bark_t -= delta
	if _bark_t > 0.0:
		return
	_bark_t = randf_range(8.0, 18.0)
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player and global_position.distance_to(_player.global_position) < 7.0 and randf() < 0.5:
		say(String(_p.barks.pick_random()), 3.0)

## Les conversations entre habitants (décidées par la société) se voient : ils se rejoignent, se font
## face, et se répondent tour à tour.
func _on_social(a: StringName, b: StringName, kind: String) -> void:
	if person_id != a and person_id != b:
		return
	if state in [State.SLEEP, State.HOME] or process_mode == Node.PROCESS_MODE_DISABLED:
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player == null or global_position.distance_to(_player.global_position) > 14.0:
		return
	var other_id := b if person_id == a else a
	for o in get_tree().get_nodes_in_group("inhabitants"):
		if o.person_id == other_id and o.visible and o.process_mode != Node.PROCESS_MODE_DISABLED:
			chat_with(o)
	var friendly := ["Alors, quoi de neuf ?", "Content de te voir.", "Tu as vu ce temps ?"]
	var chat := ["Hm.", "Comment ça va ?", "Toujours la même chose..."]
	var quarrel := ["Laisse-moi tranquille !", "Ça suffit maintenant !", "Tu exagères !"]
	var pool: Array = quarrel if kind == "quarrel" else (friendly if kind == "friendly" else chat)
	var line := String(pool.pick_random())
	if person_id == a:
		say(line, 3.0)
	else:  # celui qui répond prend la parole un peu après
		get_tree().create_timer(1.8).timeout.connect(func(): if is_instance_valid(self): say(line, 3.0))

func chat_with(other: Inhabitant, seconds := 12.0) -> void:
	if other == self or not _task.is_empty() or state in [State.SLEEP, State.HOME, State.FLEE]:
		return
	_chat_partner = other
	_chat_t = seconds

func _chat_step(delta: float) -> void:
	if _chat_t <= 0.0:
		return
	_chat_t -= delta
	if _chat_partner == null or not is_instance_valid(_chat_partner) \
			or _chat_partner.state in [State.SLEEP, State.HOME, State.FLEE] or _chat_t <= 0.0:
		_chat_t = 0.0
		_has_goal = false
		_stand()
		return
	var to := _chat_partner.position - position
	to.y = 0.0
	if to.length() > 2.2:
		_goal = _chat_partner.position - to.normalized() * 1.7
		_has_goal = true
		if state != State.FLEE:
			state = State.IDLE
	else:
		_has_goal = false
		model.rotation.y = atan2(to.x, to.z) - rotation.y   # face à face

# ------------------------------------------------------------------ actions visibles sur la Tour
## strike : aller frapper un monstre | carry : porter un objet jusqu'à `dest` | grab : s'emparer d'un objet
## tend : soigner quelqu'un. Les cibles sont des enfants du même décor (coordonnées locales).
func start_task(kind: String, target: Node3D, dest := Vector3.ZERO, line := "") -> bool:
	if not _task.is_empty() or state in [State.SLEEP, State.HOME, State.FLEE] or target == null:
		return false
	_task = {"kind": kind, "target": target, "dest": dest, "phase": 0, "line": line}
	_task_t = 20.0
	_chat_t = 0.0
	state = State.WORK
	return true

func has_task() -> bool:
	return not _task.is_empty()

func _task_step(delta: float) -> void:
	if _task.is_empty():
		return
	if state in [State.SLEEP, State.HOME, State.FLEE]:
		_end_task(false)
		return
	_task_t -= delta
	var kind: String = _task.kind
	var target: Node3D = _task.target
	var carrying: bool = kind == "carry" and int(_task.phase) == 1
	if not carrying and (target == null or not is_instance_valid(target) or target.is_queued_for_deletion()):
		_end_task(false)
		return
	if _task_t <= 0.0:
		_finish_target(kind, target)
		_end_task(true)
		return
	state = State.WORK
	_has_goal = true
	match kind:
		"strike", "grab", "tend":
			_goal = target.position
			var reach := 2.0 if kind == "strike" else 1.4
			if _flat_dist(position, target.position) <= reach:
				_perform(kind, target)
				_end_task(true)
		"carry":
			if int(_task.phase) == 0:
				_goal = target.position
				if _flat_dist(position, target.position) <= 1.3:
					target.get_parent().remove_child(target)   # la caisse passe sur son épaule
					add_child(target)
					target.position = Vector3(0, _p.height + 0.5, 0)
					if target is Interactable:
						(target as Interactable).used = true
					_carried = target
					_task.phase = 1
			else:
				_goal = _task.dest
				if _flat_dist(position, _task.dest) <= 1.4:
					if is_instance_valid(_carried):
						_carried.queue_free()
					_say_task_line()
					_end_task(true)

func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

func _perform(kind: String, target: Node3D) -> void:
	var to := target.position - position
	model.rotation.y = atan2(to.x, to.z) - rotation.y
	match kind:
		"strike":
			_flash_slash()
			if target is Enemy:
				(target as Enemy).despawn()
		"grab":
			target.queue_free()
		"tend":
			Assets.tint(target, Color(0.7, 1.0, 0.7))
			get_tree().create_timer(1.4).timeout.connect(func(): if is_instance_valid(target): target.queue_free())
	_say_task_line()

## Délai dépassé : on termine de force pour que le monde reste cohérent avec la société.
func _finish_target(kind: String, target: Node3D) -> void:
	if target == null or not is_instance_valid(target):
		return
	if kind == "strike" and target is Enemy:
		(target as Enemy).despawn()
	else:
		target.queue_free()

func _say_task_line() -> void:
	if String(_task.get("line", "")) != "":
		say(String(_task.line), 2.8)

func _end_task(done: bool) -> void:
	var kind: String = _task.get("kind", "")
	if not done and is_instance_valid(_carried):
		_carried.queue_free()
	_carried = null
	_task = {}
	_has_goal = false
	_stand()
	task_finished.emit(kind, done)

func _flash_slash() -> void:
	if _slash == null:
		_slash = MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.4, 0.08, 1.2)
		_slash.mesh = bm
		var m := WorldUtil.unshaded(Color(1, 1, 1, 0.6))
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_slash.material_override = m
		_slash.position = Vector3(0, _p.height * 0.55, -1.0)
		add_child(_slash)
	_slash.visible = true
	get_tree().create_timer(0.15).timeout.connect(func(): if is_instance_valid(_slash): _slash.visible = false)

## Un ragot raconté entre deux habitants : on l'entend si l'on est assez près (il rejoint alors le journal).
func _on_gossip(speaker: StringName, _listener: StringName, event_id: int) -> void:
	if person_id != speaker or process_mode == Node.PROCESS_MODE_DISABLED or state in [State.SLEEP, State.HOME]:
		return
	var txt := Society.event_raw(event_id)
	if txt == "":
		return
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player == null or global_position.distance_to(_player.global_position) > 10.0:
		return
	get_tree().create_timer(2.5).timeout.connect(func():
		if not is_instance_valid(self) or state in [State.SLEEP, State.HOME, State.FLEE]:
			return
		say("Tu as su ? " + txt, 5.0)
		if is_instance_valid(_player) and global_position.distance_to(_player.global_position) < 8.0:
			Society.overhear(event_id))
