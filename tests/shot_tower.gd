## xvfb-run -a godot --rendering-driver opengl3 --path . res://tests/shot_tower.tscn -- x y z yaw_deg hour out.png [pitch_deg]
extends Node

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var pos := Vector3(float(a[0]), float(a[1]), float(a[2]))
	var yaw := deg_to_rad(float(a[3]))
	var hour := float(a[4])
	var out: String = a[5]
	var pitch := deg_to_rad(float(a[6])) if a.size() > 6 else -0.15
	SaveSystem.new_game()
	GameClock.minutes = hour * 60.0
	var tower := (load("res://scenes/tower.tscn") as PackedScene).instantiate()
	add_child(tower)
	for i in 5:
		await get_tree().process_frame
	var p: Player = tower.player
	p.global_position = pos
	p.rotation.y = yaw
	p._pitch.rotation.x = pitch
	GameClock.minutes = hour * 60.0
	for i in 40:
		await get_tree().physics_frame
	await get_tree().process_frame
	await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(out)
	print("saved ", out, " floor=", tower.active_floor, " pos=", p.global_position)
	get_tree().quit()
