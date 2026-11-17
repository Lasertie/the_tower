## Étage 2 — L'Asile : folie, hallucinations, gravité inversée à minuit, 4 chemins de victoire.
class_name Floor02Asylum
extends FloorController

signal madness_changed(value: float)
signal message(text: String)

const SCENARIO_ID := &"asylum_in_distress"
const GRAVITY_LAW := &"gravity_inverts_at_midnight"
const EXIT_LAW := &"asylum_gate_sealed"
const HALLUCINATION_THRESHOLD := 40.0
const INVERTED_CONTROLS_THRESHOLD := 70.0
const BASE_MADNESS_RATE := 0.6     ## points/seconde
const SAFE_ZONE_RATE := -2.5       ## dans une pièce éclairée, la folie reflue
const HEAL_RELIEF := 10.0
const HIT_MADNESS := 3.0

const OVERLAY_SHADER := """
shader_type canvas_item;
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 uv = UV - 0.5;
	float v = smoothstep(0.25, 0.85, length(uv) * (0.8 + intensity));
	COLOR = vec4(0.35, 0.0, 0.05, v * intensity);
}
"""

var madness := 0.0:  # 0..100
	set(v):
		madness = clampf(v, 0.0, 100.0)
		madness_changed.emit(madness)

var controls_inverted := false
var patients_healed := 0
var safe_zone_count := 0

var _player: Player
var _phantom_timer := 5.0
var _overlay_mat: ShaderMaterial

func _init() -> void:
	floor_number = 2
	floor_name = "L'Asile"
	scenarios = [_build_scenario()]
	laws = [_build_gravity_law(), _build_exit_law()]

func _ready() -> void:
	super._ready()
	_player = get_tree().get_first_node_in_group("player") as Player
	if _player:
		_player.health.damaged.connect(func(_a, _s): add_madness(HIT_MADNESS))
	_build_overlay()

func _build_scenario() -> Scenario:
	var s := Scenario.new()
	s.id = SCENARIO_ID
	s.floor_number = 2
	s.title = "L'Asile en Détresse"

	var a := WinCondition.new()
	a.id = &"kill_guru"
	a.description = "Tuer le Gourou"
	a.clue = "Le Gourou règne sur l'aile nord. Sans lui, l'Asile retrouverait peut-être le calme."
	a.sets_flags = {&"killed_asylum_guru": true}
	a.chaos_delta = 2

	var b := WinCondition.new()
	b.id = &"heal_patients"
	b.description = "Soigner 10 patients clés"
	b.clue = "Les patients pourraient être apaisés un par un : dix suffiraient à rétablir l'ordre."
	b.target = 10
	b.sets_flags = {&"healed_asylum_patients": true}

	var c := WinCondition.new()
	c.id = &"director_key"
	c.description = "Trouver la Clé du Directeur"
	c.clue = "La clé du Directeur ouvre la sortie. Son bureau est dans l'aile est."

	var d := WinCondition.new()
	d.id = &"forgotten_door"
	d.hidden = true
	d.clue = "Vous avez franchi la Porte des Oubliés, un mur qui n'obéit qu'à ceux qui ont tout perdu."
	d.sets_flags = {&"used_forgotten_door": true}

	s.win_conditions = [a, b, c, d]
	return s

## Loi : à minuit, la gravité s'inverse. Faille : les bottes d'ancrage.
func _build_gravity_law() -> FloorLaw:
	var law := FloorLaw.new()
	law.id = GRAVITY_LAW
	law.effect = FloorLaw.Effect.GRAVITY_INVERT
	law.active_hours = Vector2i(0, 0)
	law.description = "Étage 2 : à minuit, la gravité s'inverse pour tout ce qui vit ici, monstres compris."
	var boots := LawExploit.new()
	boots.id = &"anchor_boots"
	boots.required_items = [&"anchor_boots"]
	boots.discovery_text = "Les bottes d'ancrage vous gardent au sol quand la gravité s'inverse."
	law.exploits = [boots]
	return law

func _build_exit_law() -> FloorLaw:
	var law := FloorLaw.new()
	law.id = EXIT_LAW
	law.effect = FloorLaw.Effect.SEALED_EXIT
	law.description = "Étage 2 : la porte vers l'étage supérieur reste scellée tant que l'Asile n'est pas apaisé."
	return law

func _build_overlay() -> void:
	var sh := Shader.new()
	sh.code = OVERLAY_SHADER
	_overlay_mat = ShaderMaterial.new()
	_overlay_mat.shader = sh
	var layer := CanvasLayer.new()
	layer.layer = 0
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.material = _overlay_mat
	layer.add_child(rect)
	add_child(layer)

func _process(delta: float) -> void:
	# --- folie ---
	var chaos := int(WorldFlags.get_flag(&"current_floor_chaos_level", 0))
	var rate := SAFE_ZONE_RATE if safe_zone_count > 0 else BASE_MADNESS_RATE * (1.0 + 0.25 * chaos)
	madness += rate * delta
	if _player:
		_player.madness = madness

	# --- contrôles inversés par fenêtres temporaires ---
	controls_inverted = madness >= INVERTED_CONTROLS_THRESHOLD \
		and fmod(Time.get_ticks_msec() / 1000.0, 20.0) < 6.0
	if _player:
		_player.controls_inverted = controls_inverted

	# --- hallucinations ---
	var hallu := hallucinations_active()
	if _overlay_mat:
		_overlay_mat.set_shader_parameter("intensity", madness / 100.0 if hallu else 0.0)
	if hallu and _player:
		_phantom_timer -= delta
		if _phantom_timer <= 0.0:
			_phantom_timer = randf_range(3.0, 7.0)
			_spawn_phantom()

func on_leave() -> void:
	if _overlay_mat:
		_overlay_mat.set_shader_parameter("intensity", 0.0)
	if _player:
		_player.controls_inverted = false
		_player.madness = 0.0

func _spawn_phantom() -> void:
	var ph := Phantom.new()
	get_parent().add_child(ph)
	var a := randf() * TAU
	ph.global_position = _player.global_position + Vector3(cos(a), 0, sin(a)) * randf_range(6.0, 9.0)

func add_madness(amount: float) -> void:
	madness += amount

func heal_patient() -> void:
	patients_healed += 1
	madness -= HEAL_RELIEF
	ScenarioManager.report(SCENARIO_ID, &"heal_patients")
	message.emit("Patient soigné (%d/10)" % patients_healed)

func find_director_key() -> void:
	ScenarioManager.report(SCENARIO_ID, &"director_key")

func kill_guru() -> void:
	ScenarioManager.report(SCENARIO_ID, &"kill_guru")

func register_guru(guru: Enemy) -> void:
	guru.died.connect(func(_e): kill_guru())

## Exploit : le mur secret n'est franchissable qu'à 100 % de folie.
func try_forgotten_door() -> bool:
	if madness >= 100.0:
		ScenarioManager.report(SCENARIO_ID, &"forgotten_door")
		return true
	return false

func hallucinations_active() -> bool:
	return madness >= HALLUCINATION_THRESHOLD or WorldFlags.get_flag(&"used_forgotten_door", false)

func to_save_dict() -> Dictionary:
	return {"madness": madness, "patients": patients_healed}

func from_save_dict(d: Dictionary) -> void:
	madness = float(d.get("madness", 0.0))
	patients_healed = int(d.get("patients", 0))
