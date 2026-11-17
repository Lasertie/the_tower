## xvfb-run -a godot --rendering-driver opengl3 --path . res://tests/shot_ui.tscn -- <menu|dialogue|journal|pause|asylum_night> out.png
extends Node

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var mode: String = a[0]
	var out: String = a[1]
	SaveSystem.new_game()
	if mode == "menu":
		add_child((load("res://scenes/menu.tscn") as PackedScene).instantiate())
		for i in 10: await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png(out)
		get_tree().quit()
		return
	var tower: Tower = (load("res://scenes/tower.tscn") as PackedScene).instantiate()
	add_child(tower)
	for i in 6: await get_tree().process_frame
	var p: Player = tower.player
	var sid := Floor01Village.SCENARIO_ID
	match mode:
		"dialogue":
			p.global_position = Vector3(3, 0.3, 1)
			for i in 20: await get_tree().physics_frame
			tower.hud.show_dialogue("L'Ancien", ["Voyageur... la Tour t'a mené jusqu'à notre village.",
				"Ici, nul ne monte sans avoir fait ses preuves. Mais il y a plus d'un chemin."])
		"journal":
			ScenarioManager.discover(sid, &"labyrinth_exit")
			ScenarioManager.discover(sid, &"farm_help")
			ScenarioManager.report(sid, &"farm_help")
			LawSystem.observe(LawSystem.find_law(Floor01Village.GATE_LAW))
			p.add_item(&"elder_pass")
			tower.hud._set_modal("journal")
		"conv":
			p.global_position = Vector3(3, 0.3, 1)
			for i in 20: await get_tree().physics_frame
			Society.person(&"hunter").trust = 20.0
			tower.hud.show_conversation(&"hunter")
		"topics":
			p.global_position = Vector3(3, 0.3, 1)
			for i in 20: await get_tree().physics_frame
			Society.person(&"hunter").trust = 20.0
			Society.person(&"hunter").mood = 0.0
			tower.hud.show_conversation(&"hunter")
			tower.hud._conv_topics()
		"journal2":
			Society.person(&"hunter").trust = 20.0
			Society.person(&"hunter").mood = 0.0
			Society.person(&"farmer").met_player = true
			Society.person(&"farmer").trust = 12.0
			Society.person(&"hunter").met_player = true
			Society.ask(&"hunter", "garde")
			Society.ask(&"hunter", "fosse")
			Society.player_deed("help_farm")
			var hid: int = Society.chronicle[-1].id
			Society.rumors_heard.append(hid)
			tower.hud._set_modal("journal")
		"ascend":
			p.global_position = Vector3(-14, -7.7, -12)
			for i in 20: await get_tree().physics_frame
			tower.hud.transition("ascend", func(): pass)
			p.shake(3.0, 0.05)
			await get_tree().create_timer(1.9).timeout
		"pause":
			tower.hud._set_modal("pause")
	for i in 12: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()
