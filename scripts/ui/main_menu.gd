## Menu principal.
extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = UiTheme.theme()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.09)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	# Dégradé « lumière en haut de la Tour »
	var grad := Gradient.new()
	grad.set_color(0, Color(0.97, 0.78, 0.26, 0.35))
	grad.set_color(1, Color(0, 0, 0, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 0.7)
	var glow := TextureRect.new()
	glow.texture = gt
	glow.stretch_mode = TextureRect.STRETCH_SCALE
	glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(glow)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.offset_left = -260
	box.offset_right = 260
	box.offset_top = -230
	box.offset_bottom = 230
	box.add_theme_constant_override("separation", 14)
	add_child(box)

	var title := Label.new()
	title.text = "THE TOWER"
	title.add_theme_font_size_override("font_size", 104)
	title.add_theme_color_override("font_color", UiTheme.GOLD)
	title.add_theme_constant_override("outline_size", 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := Label.new()
	sub.text = "Un seul héros. Cinq étages. Des lois à comprendre."
	sub.add_theme_font_size_override("font_size", 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	box.add_child(Control.new())

	var new_btn := Button.new()
	new_btn.text = "Nouvelle partie"
	new_btn.pressed.connect(_new_game)
	box.add_child(new_btn)
	var cont := Button.new()
	cont.text = "Continuer"
	cont.disabled = not SaveSystem.has_save(Tower.SAVE_SLOT)
	cont.pressed.connect(_continue)
	box.add_child(cont)
	var quit := Button.new()
	quit.text = "Quitter"
	quit.pressed.connect(func(): get_tree().quit())
	box.add_child(quit)
	new_btn.grab_focus()

	var credits := Label.new()
	credits.text = "Modèles 3D : Kenney et KayKit (CC0)   Police : Lilita One (OFL)   Moteur : Godot (MIT)"
	credits.add_theme_font_size_override("font_size", 16)
	credits.modulate = Color(1, 1, 1, 0.55)
	credits.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	credits.offset_left = -400
	credits.offset_right = 400
	credits.offset_top = -40
	credits.offset_bottom = -12
	credits.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(credits)

func _new_game() -> void:
	SaveSystem.new_game()
	get_tree().change_scene_to_file("res://scenes/tower.tscn")

func _continue() -> void:
	var d := SaveSystem.load_game(Tower.SAVE_SLOT)
	if d.is_empty():
		return
	SaveSystem.pending = d
	get_tree().change_scene_to_file("res://scenes/tower.tscn")
