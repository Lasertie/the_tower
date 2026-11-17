## godot --headless --path . res://tests/sim_balance.tscn : laisse la société vivre 5 jours, plusieurs tirages.
extends Node

func _ready() -> void:
	await get_tree().process_frame
	Society.set_process(false)
	for seed_i in 8:
		SaveSystem.new_game()
		Society.set_process(false)
		Society.rng.seed = 100 + seed_i
		GameClock.minutes = 8.0 * 60.0
		Society.replan()
		var relic_day := -1.0
		var pass_day := -1.0
		var pit_min := 5
		var pit_sum := 0.0
		var crates_zero := 0
		var steps := 0
		var quarrels := 0
		var friends := 0
		var asleep_guard_off_routine := 0
		for i in 5 * 144:   # 5 jours en pas de 10 min
			Society.simulate(10.0)
			steps += 1
			var d := GameClock.absolute_minutes() / 1440.0
			if relic_day < 0.0 and Society.res("relic_at_well") == 0:
				relic_day = d
			if pass_day < 0.0 and Society.res("elder_pass_ground") == 0:
				pass_day = d
			pit_min = mini(pit_min, Society.res("pit_monsters"))
			pit_sum += Society.res("pit_monsters")
			if Society.res("farm_crates") == 0:
				crates_zero += 1
		for e in Society.chronicle:
			if str(e.text).contains("disputés"): quarrels += 1
			if str(e.text).contains("amis"): friends += 1
		print("graine %d | relique prise jour %s | parchemin trouvé jour %s | Fosse moy %.1f min %d | caisses=0 %d%% du temps | disputes %d amitiés %d | rel chasseur-garde %.0f" % [
			seed_i, ("%.1f" % relic_day) if relic_day >= 0 else "jamais", ("%.1f" % pass_day) if pass_day >= 0 else "jamais",
			pit_sum / steps, pit_min, int(100.0 * crates_zero / steps), quarrels, friends,
			Society.person(&"hunter").get_rel(&"guard")])
	get_tree().quit()
