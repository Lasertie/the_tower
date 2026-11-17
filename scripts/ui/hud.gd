## Interface en jeu : vie, heure, étage, invite d'interaction, notifications, dialogues, journal, pause.
class_name Hud
extends CanvasLayer

signal transition_done

const ITEM_NAMES := {
	&"ancient_relic": "Relique du Puits",
	&"elder_pass": "Laissez-passer de l'Ancien",
	&"director_key": "Clé du Directeur",
	&"anchor_boots": "Bottes d'ancrage",
	&"waterfall_vial": "Fiole de la cascade",
}

## Voile d'ascension : des traînées lumineuses qui montent, du doré au blanc. Un seul shader, sobre.
const ASCEND_SHADER := """
shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec2 uv = UV;
	float col = sin(uv.x * 70.0 + sin(uv.x * 11.0) * 3.0) * 0.5 + 0.5;
	float streak = smoothstep(0.55, 1.0, col);
	float flow = fract(uv.y * 2.2 + TIME * 1.9 + sin(uv.x * 23.0));
	float glow = streak * smoothstep(0.0, 0.7, flow);
	vec3 c = mix(vec3(0.97, 0.78, 0.26), vec3(1.0), glow);
	float a = clamp(progress * 1.5, 0.0, 1.0) * (0.45 + 0.55 * glow * progress);
	COLOR = vec4(c, a);
}
"""

var tower: Tower
var player: Player

var _root: Control
var _hp: ProgressBar
var _clock: Label
var _floor: Label
var _prompt: PanelContainer
var _prompt_label: Label
var _toasts: VBoxContainer
var _dialog: PanelContainer
var _dlg_name: Label
var _dlg_text: Label
var _journal: PanelContainer
var _journal_text: RichTextLabel
var _pause: PanelContainer
var _load_btn: Button
var _fade: ColorRect
var _veil: ColorRect
var _veil_mat: ShaderMaterial
var _hit: ColorRect
var _banner: Label
var _hints: Label

var _modal := ""  # "", "dialogue", "journal", "pause"
var _dlg_choices: VBoxContainer
var _dlg_hint: Label
var _conv_pid: StringName = &""
var _conv_active := false
var _lines: Array = []
var _line_i := 0
var _then := Callable()

func _init() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS

func setup(t: Tower) -> void:
	tower = t
	player = t.player
	_build()
	player.item_added.connect(func(id): toast("Objet obtenu : %s" % ITEM_NAMES.get(id, String(id)), UiTheme.GOLD))
	player.health.damaged.connect(func(_a, _s): _flash_hit())
	ScenarioManager.condition_discovered.connect(func(_s, _c):
		toast("Nouvelle piste ajoutée au journal (Tab)", UiTheme.GOLD))
	ScenarioManager.scenario_resolved.connect(func(s, _by):
		toast("Épreuve résolue : %s" % s.title, Color(0.6, 0.95, 0.6), 6.0))
	Society.overheard.connect(func(_id):
		toast("Vous surprenez une conversation... une rumeur de plus au journal.", Color(0.75, 0.9, 1.0), 5.0))
	Society.fact_learned.connect(func(_f):
		toast("On vous a confié quelque chose... noté dans le journal.", UiTheme.GOLD, 5.0))
	LawSystem.law_observed.connect(func(law):
		toast("Un phénomène étrange... noté dans le journal.", Color(0.6, 0.8, 1.0), 5.0))
	LawSystem.exploit_used.connect(func(_law, ex):
		toast("Faille exploitée : %s" % (ex.discovery_text if ex else ""), UiTheme.GOLD, 6.0))

# ------------------------------------------------------------------ construction
func _label(text := "", size := 20, color := UiTheme.INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _anchored(c: Control, preset: Control.LayoutPreset, l: float, t: float, r: float, b: float) -> void:
	c.set_anchors_preset(preset)
	c.offset_left = l
	c.offset_top = t
	c.offset_right = r
	c.offset_bottom = b

func _build() -> void:
	_root = Control.new()
	_root.theme = UiTheme.theme()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	# Flash de dégâts
	_hit = ColorRect.new()
	_hit.color = Color(0.8, 0.05, 0.05, 0.0)
	_hit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hit.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_hit)

	# Vie (haut gauche)
	var hp_panel := PanelContainer.new()
	_anchored(hp_panel, Control.PRESET_TOP_LEFT, 16, 16, 300, 60)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	hb.add_child(_label("PV", 22, UiTheme.DANGER))
	_hp = ProgressBar.new()
	_hp.custom_minimum_size = Vector2(210, 22)
	_hp.max_value = 100
	_hp.show_percentage = false
	_hp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(_hp)
	hp_panel.add_child(hb)
	_root.add_child(hp_panel)

	# Étage + heure (haut droite)
	var info := PanelContainer.new()
	_anchored(info, Control.PRESET_TOP_RIGHT, -330, 16, -16, 76)
	var vb := VBoxContainer.new()
	_floor = _label("", 20, UiTheme.GOLD)
	_floor.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_clock = _label("", 26)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(_floor)
	vb.add_child(_clock)
	info.add_child(vb)
	_root.add_child(info)

	# Notifications (haut centre)
	_toasts = VBoxContainer.new()
	_anchored(_toasts, Control.PRESET_CENTER_TOP, -330, 70, 330, 300)
	_toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_toasts)

	# Bannière d'étage (centre)
	_banner = _label("", 54, UiTheme.GOLD)
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_anchored(_banner, Control.PRESET_CENTER_TOP, -450, 140, 450, 230)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_constant_override("outline_size", 10)
	_banner.modulate.a = 0.0
	_root.add_child(_banner)

	# Invite d'interaction (bas centre)
	_prompt = PanelContainer.new()
	_anchored(_prompt, Control.PRESET_CENTER_BOTTOM, -230, -150, 230, -96)
	var ph := HBoxContainer.new()
	ph.alignment = BoxContainer.ALIGNMENT_CENTER
	ph.add_theme_constant_override("separation", 12)
	var key := PanelContainer.new()
	key.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(0.97, 0.78, 0.26), Color(1, 1, 1, 0.6), 6, 10))
	var kl := _label("E", 24, Color(0.1, 0.08, 0.02))
	kl.add_theme_constant_override("outline_size", 0)
	key.add_child(kl)
	ph.add_child(key)
	_prompt_label = _label("", 24)
	ph.add_child(_prompt_label)
	_prompt.add_child(ph)
	_prompt.visible = false
	_root.add_child(_prompt)

	# Dialogue (bas)
	_dialog = PanelContainer.new()
	_anchored(_dialog, Control.PRESET_BOTTOM_WIDE, 140, -210, -140, -40)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 6)
	_dlg_name = _label("", 28, UiTheme.GOLD)
	_dlg_text = _label("", 24)
	_dlg_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dlg_text.custom_minimum_size = Vector2(0, 90)
	_dlg_choices = VBoxContainer.new()
	_dlg_choices.add_theme_constant_override("separation", 6)
	_dlg_hint = _label("E : continuer", 18, Color(1, 1, 1, 0.55))
	_dlg_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dv.add_child(_dlg_name)
	dv.add_child(_dlg_text)
	dv.add_child(_dlg_choices)
	dv.add_child(_dlg_hint)
	_dialog.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(0.05, 0.06, 0.1, 0.97)))
	_dialog.add_child(dv)
	_dialog.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_dialog.visible = false
	_root.add_child(_dialog)

	# Journal
	_journal = PanelContainer.new()
	_anchored(_journal, Control.PRESET_CENTER, -400, -270, 400, 270)
	var jv := VBoxContainer.new()
	jv.add_child(_label("Journal", 36, UiTheme.GOLD))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_journal_text = RichTextLabel.new()
	_journal_text.bbcode_enabled = true
	_journal_text.fit_content = true
	_journal_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_journal_text.add_theme_font_size_override("normal_font_size", 21)
	_journal_text.add_theme_font_size_override("italics_font_size", 21)
	sc.add_child(_journal_text)
	jv.add_child(sc)
	var jh := _label("Tab / J : fermer", 18, Color(1, 1, 1, 0.55))
	jh.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	jv.add_child(jh)
	_journal.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(0.05, 0.06, 0.1, 0.97)))
	_journal.add_child(jv)
	_journal.visible = false
	_root.add_child(_journal)

	# Pause
	_pause = PanelContainer.new()
	_anchored(_pause, Control.PRESET_CENTER, -190, -190, 190, 190)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 12)
	var pt := _label("Pause", 40, UiTheme.GOLD)
	pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pv.add_child(pt)
	pv.add_child(_button("Reprendre", func(): _set_modal("")))
	pv.add_child(_button("Sauvegarder", _on_save))
	_load_btn = _button("Charger", func(): tower.load_game())
	pv.add_child(_load_btn)
	pv.add_child(_button("Menu principal", func(): tower.exit_to_menu()))
	_pause.add_theme_stylebox_override("panel", UiTheme.panel_style(Color(0.05, 0.06, 0.1, 0.97), Color(1, 1, 1, 0.15), 10, 20))
	_pause.add_child(pv)
	_pause.visible = false
	_root.add_child(_pause)

	# Fondu noir (mort)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_fade)

	# Voile d'ascension (au-dessus de tout)
	var sh := Shader.new()
	sh.code = ASCEND_SHADER
	_veil_mat = ShaderMaterial.new()
	_veil_mat.shader = sh
	_veil = ColorRect.new()
	_veil.material = _veil_mat
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.visible = false
	_root.add_child(_veil)

	# Rappel des touches
	_hints = _label("ZQSD / WASD : bouger   Espace : sauter   Clic : attaquer   E : interagir   Tab : journal   Echap : pause", 18, Color(1, 1, 1, 0.7))
	_anchored(_hints, Control.PRESET_BOTTOM_LEFT, 16, -40, 1100, -12)
	_root.add_child(_hints)
	var tw := create_tween()
	tw.tween_interval(25.0)
	tw.tween_property(_hints, "modulate:a", 0.0, 2.0)

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	return b

# ------------------------------------------------------------------ API
func toast(text: String, color := UiTheme.INK, seconds := 4.0) -> void:
	if _toasts == null:
		return
	var p := PanelContainer.new()
	var l := _label(text, 20, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(600, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.modulate.a = 0.0
	_toasts.add_child(p)
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	tw.tween_interval(seconds)
	tw.tween_property(p, "modulate:a", 0.0, 0.6)
	tw.tween_callback(p.queue_free)

func show_banner(text: String) -> void:
	_banner.text = text
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.5)
	tw.tween_interval(2.5)
	tw.tween_property(_banner, "modulate:a", 0.0, 1.0)

## Transition animée : « ascend » (traînées lumineuses, ~5 s, masque le chargement) ou « fade » (fondu noir).
## on_mid est appelé au moment le plus opaque (c'est là qu'on déplace le héros).
func transition(style: String, on_mid: Callable) -> void:
	var tw := create_tween()
	if style == "ascend":
		_veil.visible = true
		_veil_mat.set_shader_parameter("progress", 0.0)
		tw.tween_method(func(v): _veil_mat.set_shader_parameter("progress", v), 0.0, 1.0, 1.6)
		tw.tween_interval(1.0)
		tw.tween_callback(on_mid)
		tw.tween_interval(0.7)
		tw.tween_method(func(v): _veil_mat.set_shader_parameter("progress", v), 1.0, 0.0, 1.4)
		tw.tween_callback(func():
			_veil.visible = false
			transition_done.emit())
	else:
		tw.tween_property(_fade, "color:a", 1.0, 0.4)
		tw.tween_callback(on_mid)
		tw.tween_interval(0.15)
		tw.tween_property(_fade, "color:a", 0.0, 0.5)
		tw.tween_callback(func(): transition_done.emit())

func fade(alpha: float, seconds: float) -> void:
	create_tween().tween_property(_fade, "color:a", alpha, seconds)

func _flash_hit() -> void:
	_hit.color.a = 0.35
	create_tween().tween_property(_hit, "color:a", 0.0, 0.35)

func show_dialogue(speaker: String, lines: Array, then := Callable()) -> void:
	if _modal != "" or lines.is_empty():
		return
	_conv_active = false
	_lines = lines
	_line_i = 0
	_then = then
	_dlg_name.text = speaker
	_dlg_text.text = String(lines[0])
	_clear_choices()
	_dlg_hint.visible = true
	_set_modal("dialogue")

# ------------------------------------------------------------------ conversation à choix
func show_conversation(pid: StringName) -> void:
	if _modal != "":
		return
	_conv_pid = pid
	_conv_active = true
	_dlg_name.text = Society.person(pid).display_name
	_conv_menu(Society.begin_conversation(pid))
	_set_modal("dialogue")

func _clear_choices() -> void:
	for c in _dlg_choices.get_children():
		_dlg_choices.remove_child(c)
		c.queue_free()

func _add_choice(label: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 21)
	b.pressed.connect(cb)
	_dlg_choices.add_child(b)

func _focus_choices() -> void:
	if _dlg_choices.get_child_count() > 0:
		(_dlg_choices.get_child(0) as Button).grab_focus.call_deferred()

func _conv_menu(text: String) -> void:
	_clear_choices()
	_dlg_text.text = text
	_dlg_hint.visible = false
	_add_choice("Bavarder", func(): _conv_lines(Society.small_talk(_conv_pid)))
	_add_choice("Demander à propos de...", _conv_topics)
	_add_choice("Au revoir", func(): _set_modal(""))
	_focus_choices()

func _conv_topics() -> void:
	_clear_choices()
	_dlg_text.text = "À propos de quoi ?"
	for t in Society.topics():
		_add_choice(t.label, _conv_ask.bind(t.key))
	_add_choice("Retour", func(): _conv_menu("Autre chose ?"))
	_focus_choices()

func _conv_ask(key: String) -> void:
	_conv_lines(Society.ask(_conv_pid, key).lines)

func _conv_lines(lines: Array) -> void:
	_clear_choices()
	_lines = lines
	_line_i = 0
	_dlg_text.text = String(lines[0])
	_dlg_hint.visible = true

# ------------------------------------------------------------------ état modal
func _set_modal(m: String) -> void:
	_modal = m
	if m != "dialogue":
		_conv_active = false
	_dialog.visible = m == "dialogue"
	_journal.visible = m == "journal"
	_pause.visible = m == "pause"
	if m == "journal":
		_refresh_journal()
	if m == "pause":
		_load_btn.disabled = not SaveSystem.has_save(Tower.SAVE_SLOT)
	var open := m != ""
	get_tree().paused = open
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if open else Input.MOUSE_MODE_CAPTURED
	if not open:
		player.interact_block = 0.3

func _advance_dialogue() -> void:
	_line_i += 1
	if _line_i >= _lines.size() and _conv_active:
		_conv_menu("Autre chose ?")
		return
	if _line_i >= _lines.size():
		var cb := _then
		_then = Callable()
		_set_modal("")
		if cb.is_valid():
			cb.call()
	else:
		_dlg_text.text = String(_lines[_line_i])

func _on_save() -> void:
	var err := tower.save_game()
	toast("Partie sauvegardée." if err == OK else "Échec de la sauvegarde.", Color(0.6, 0.95, 0.6) if err == OK else UiTheme.DANGER)
	_load_btn.disabled = false

func _input(event: InputEvent) -> void:
	if _modal == "dialogue":
		if event.is_action_pressed("ui_cancel"):
			_set_modal("")
			get_viewport().set_input_as_handled()
		elif _dlg_choices.get_child_count() == 0 \
				and (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
			_advance_dialogue()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("journal") and _modal in ["", "journal"]:
		_set_modal("" if _modal == "journal" else "journal")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_set_modal("" if _modal != "" else "pause")
		get_viewport().set_input_as_handled()

# ------------------------------------------------------------------ boucle
func _process(_delta: float) -> void:
	if player == null:
		return
	_hp.value = player.health.health
	_clock.text = GameClock.clock_text()
	var n := tower.active_floor
	_floor.text = "Étage %d" % n if n > 0 else ""
	var near := player.nearest_interactable() if _modal == "" else null
	_prompt.visible = near != null
	if near:
		_prompt_label.text = near.prompt

# ------------------------------------------------------------------ journal
func _refresh_journal() -> void:
	var t := ""
	var any_scenario := false
	for s in ScenarioManager.all_scenarios():
		if s.state == Scenario.State.LOCKED:
			continue
		any_scenario = true
		t += "[color=#f7c742][font_size=28]Étage %d - %s[/font_size][/color]\n" % [s.floor_number, s.title]
		if s.state == Scenario.State.RESOLVED:
			t += "[color=#9be59b]Épreuve résolue.[/color]\n"
		var shown := 0
		for c in s.win_conditions:
			if not c.in_journal():
				continue
			shown += 1
			# target >= 9999 = condition "journal only" : pas de compteur, pas de "(fait)"
			var journal_only: bool = c.target >= 9999
			var mark := "- "
			if not journal_only:
				mark = "[color=#9be59b](fait)[/color] " if c.is_met() else "- "
			var prog := ""
			if not journal_only and c.target > 1 and not c.is_met():
				prog = " [color=#aaaaaa](%d/%d)[/color]" % [c.progress, c.target]
			t += "%s%s%s\n" % [mark, c.clue, prog]
		if shown == 0:
			t += "[i]Vous ne savez pas encore comment venir à bout de cette épreuve. Parlez aux gens, explorez.[/i]\n"
		t += "\n"
	if not any_scenario:
		t += "[i]Rien à signaler pour l'instant.[/i]\n\n"
	if LawSystem.observed.size() > 0:
		t += "[color=#f7c742][font_size=28]Phénomènes de la Tour[/font_size][/color]\n"
		for id in LawSystem.observed:
			var law := LawSystem.find_law(StringName(id))
			if law:
				t += "- %s\n" % law.description
		t += "\n"
	if LawSystem.used_exploits.size() > 0:
		t += "[color=#f7c742][font_size=28]Failles découvertes[/font_size][/color]\n"
		for id in LawSystem.used_exploits:
			var ex := LawSystem.find_exploit_by_id(StringName(id))
			if ex:
				t += "- %s\n" % ex.discovery_text
		t += "\n"
	var mem := WorldFlags.memories()
	if mem.size() > 0:
		t += "[color=#f7c742][font_size=28]La Tour se souvient[/font_size][/color]\n"
		for m in mem:
			t += "- %s\n" % m
	if Society.player_facts.size() > 0:
		t += "\n[color=#f7c742][font_size=28]Ce qu'on vous a confié[/font_size][/color]\n"
		for fid in Society.player_facts:
			t += "- %s\n" % Cast.FACTS[fid].text
	if Society.rumors_heard.size() > 0:
		t += "\n[color=#f7c742][font_size=28]Rumeurs[/font_size][/color]\n"
		for id in Society.rumors_heard:
			t += "- %s\n" % Society.event_text(id)
	var met: Array = Society.persons.values().filter(func(p): return p.met_player)
	if not met.is_empty():
		t += "\n[color=#f7c742][font_size=28]Habitants rencontrés[/font_size][/color]\n"
		for p in met:
			t += "- %s %s.\n" % [p.display_name, Society.trust_label(p.id)]
	_journal_text.text = t
