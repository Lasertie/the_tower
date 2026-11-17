## xvfb-run -a godot --rendering-driver opengl3 --path . res://tests/shot_life.tscn -- <carry|strike> out.png
extends Node

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var mode: String = a[0]
	var out: String = a[1]
	SaveSystem.new_game()
	Society.set_process(false)
	GameClock.minutes = 10.0 * 60.0
	Society.replan()
	var tower: Tower = (load("res://scenes/tower.tscn") as PackedScene).instantiate()
	add_child(tower)
	for i in 8: await get_tree().process_frame
	var p: Player = tower.player
	var v: VillageLayout = tower.layouts[0]
	var who: Inhabitant
	for n in get_tree().get_nodes_in_group("inhabitants"):
		if n.person_id == (&"farmer" if mode == "carry" else &"hunter"):
			who = n
	GameClock.minutes = 10.0 * 60.0 if mode == "carry" else 15.0 * 60.0
	Society.replan()
	who.catch_up(true)
	p.global_position = Vector3(10, 0.3, 36) if mode == "carry" else Vector3(14, 0.3, 28)
	p.rotation.y = deg_to_rad(0.0) if mode == "carry" else deg_to_rad(-60.0)
	p._pitch.rotation.x = -0.15
	if mode == "carry":
		Society.resources["pit_monsters"] = 0
		v._sync_world()
		Society.resources["farm_crates"] = 2
		v._sync_world()
		await get_tree().physics_frame
		Society.resources["farm_crates"] = 1
		Society.world_effect.emit(&"farmer", "farm_crates", "")
		var w := 0
		while who._carried == null and w < 400:
			await get_tree().physics_frame
			w += 1
		for i in 50: await get_tree().physics_frame
	else:
		Society.resources["pit_monsters"] = 3
		v._sync_world()
		await get_tree().physics_frame
		Society.resources["pit_monsters"] = 2
		Society.world_effect.emit(&"hunter", "pit_monsters", "")
		var w := 0
		while who.has_task() and w < 400:
			await get_tree().physics_frame
			w += 1
			if who.has_task() and w > 20 and _flat(who.position, v._pit_enemies[0].position) < 4.0:
				break
		for i in 6: await get_tree().physics_frame
	for i in 4: await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out)
	get_tree().quit()

func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
