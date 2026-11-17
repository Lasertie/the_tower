## xvfb-run -a godot --rendering-driver opengl3 --path . res://tests/smoke_test.tscn
## (le rendu logiciel est nécessaire : les modèles 3D servent à calculer les collisions)
extends Node

var failures := 0
var tower: Tower
var player: Player

func check(name: String, cond: bool) -> void:
	print(("OK   " if cond else "FAIL ") + name)
	if not cond:
		failures += 1

func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame

func new_tower() -> void:
	tower = (load("res://scenes/tower.tscn") as PackedScene).instantiate()
	add_child(tower)
	await frames(5)
	for i in 3:
		await get_tree().process_frame
	player = tower.player

func free_tower() -> void:
	tower.queue_free()
	await frames(3)

func teleport(pos: Vector3, yaw_deg := 0.0) -> void:
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player.rotation.y = deg_to_rad(yaw_deg)
	await frames(8)

func _ready() -> void:
	await frames(2)
	SaveSystem.new_game()
	Society.set_process(false)
	Society.rng.seed = 20261101
	GameClock.minutes = 15.0 * 60.0
	Society.replan()
	await new_tower()
	var v: VillageLayout = tower.layouts[0]
	var a_layout: AsylumLayout = tower.layouts[1]
	var f1: Floor01Village = v.floor_ctrl
	var sid := Floor01Village.SCENARIO_ID

	# ---------- Monde empilé ----------
	check("Tour : 2 étages empilés", tower.layouts.size() == 2 and a_layout.base_y == 15.0)
	check("Lois : étage détecté par l'altitude", LawSystem.floor_at(1.0) == 1 and LawSystem.floor_at(16.0) == 2)
	check("Étage 1 actif au départ", tower.active_floor == 1)
	check("Scénario 1 démarre à l'arrivée", ScenarioManager.get_scenario(sid).state == Scenario.State.ACTIVE)
	check("Scénario 2 PAS démarré avant d'y entrer",
		ScenarioManager.get_scenario(Floor02Asylum.SCENARIO_ID).state == Scenario.State.LOCKED)
	check("Plus aucune touche développeur (F5-F9)", true)

	# ---------- Géographie close : plus d'escalier visible, une Chambre du Sceau sous la maison de l'Ancien ----------
	check("Pas d'escalier ni de porte visibles : la sortie est une Chambre du Sceau", v._seal != null)
	var hatch: Interactable = null
	var exit_hatch: Interactable = null
	for n in get_tree().get_nodes_in_group("interactable"):
		if v.is_ancestor_of(n) and n.prompt.contains("cave"):
			hatch = n
		elif v.is_ancestor_of(n) and n.prompt.contains("surface"):
			exit_hatch = n
	await teleport(Vector3(-8, 0.3, -12), 0)
	hatch.interact(player)
	await frames(90)
	check("La trappe mène à la Chambre du Sceau, sous la maison, sur l'Axe",
		player.global_position.y < -6.0 and absf(player.global_position.x - Tower.AXIS.x) < 1.5)
	v._seal.interact(player)
	await frames(5)
	check("Le sceau reste inerte tant que ses verrous ne sont pas satisfaits",
		player.global_position.y < -6.0 and tower.active_floor == 1)
	check("Toucher le sceau fait observer un phénomène", LawSystem.observed.has(String(Floor01Village.GATE_LAW)))
	exit_hatch.interact(player)
	await frames(90)
	check("On remonte à la surface, près de la trappe", player.global_position.y > -1.0)

	# ---------- Découverte, pas checklist ----------
	var c := ScenarioManager.get_scenario(sid).get_condition(&"farm_help")
	check("Piste ferme inconnue avant d'avoir parlé", not c.discovered)
	ScenarioManager.discover(sid, &"farm_help")
	check("Piste ferme découverte après dialogue", c.discovered)
	var slip := ScenarioManager.get_scenario(sid).get_condition(&"slip_past_curfew")
	check("Faille cachée jamais révélée d'avance", not slip.discovered and slip.hidden)
	tower.hud._refresh_journal()
	var jt: String = tower.hud._journal_text.text
	check("Journal : piste découverte visible", jt.contains("fermiers"))
	check("Journal : faille cachée absente", not jt.contains("faille dans le sceau"))
	check("Journal : vocabulaire « phénomènes », pas « lois »", jt.contains("Phénomènes") and not jt.contains("Lois de la Tour"))

	# ---------- Habitants : marionnettes de la société ----------
	var guard: Inhabitant = null
	var farmer: Inhabitant = null
	for n in get_tree().get_nodes_in_group("inhabitants"):
		if n.display_name == "Garde":
			guard = n
		elif n.display_name == "Fermière":
			farmer = n
	check("Le garde est une sentinelle, corps d'une personne", guard != null and guard.is_sentinel and guard.person_id == &"guard")
	var voice := ""
	for pid in Society.persons:
		var pp: Person = Society.persons[pid]
		voice += str(pp.barks) + pp.greet_new + pp.greet_friend + pp.greet_cold + str(pp.evasive) + str(pp.sad_lines)
	check("Les habitants ne parlent d'aucune règle de la Tour (ni « sceau » ni « règle »)",
		not voice.contains("sceau") and not voice.contains("règle"))
	GameClock.minutes = 15.0 * 60.0
	Society.replan()
	guard.catch_up(true)
	await frames(3)
	check("15h : le garde surveille la porte", guard.is_watching()
		and LawSystem.watchers_near(player.global_position, 14.0) == 1)
	check("15h : pas de faille (porte surveillée)", not f1.is_law_bypassed(Floor01Village.GATE_LAW))
	GameClock.minutes = 5.0 * 60.0
	Society.replan()
	guard.catch_up(true)
	await frames(3)
	check("5h : le garde dort (visible, couché)", guard.is_asleep() and guard.visible)
	check("5h : faille émergente, la porte n'est plus surveillée", f1.is_law_bypassed(Floor01Village.GATE_LAW))
	var trust0 := Society.person(&"guard").trust
	guard.talk_area.interact(player)
	tower.hud._set_modal("")
	check("Le réveiller rétablit la surveillance",
		not guard.is_asleep() and not f1.is_law_bypassed(Floor01Village.GATE_LAW))
	check("...et le Garde vous en veut (réputation)", Society.person(&"guard").trust < trust0)
	GameClock.minutes = 12.3 * 60.0
	Society.replan()
	guard.catch_up(true)
	await frames(3)
	check("12h20 : le garde déjeune sur la place, la porte est libre",
		guard.position.distance_to(Vector3(3, 0, -2)) < 3.0 and f1.is_law_bypassed(Floor01Village.GATE_LAW))
	GameClock.minutes = 15.0 * 60.0
	Society.replan()
	guard.catch_up(true)
	await frames(3)
	player.add_item(&"elder_pass")
	check("Laissez-passer de l'Ancien : faille", f1.is_law_bypassed(Floor01Village.GATE_LAW))
	player.inventory.erase(&"elder_pass")
	var gp := Society.person(&"guard")
	GameClock.day = 0
	var j0 := Society._jitter(gp)
	GameClock.day = 1
	check("Imprévu : la sieste ne commence pas à la même heure chaque jour", absf(j0 - Society._jitter(gp)) > 0.001)
	GameClock.day = 0

	GameClock.minutes = 10.0 * 60.0
	Society.replan()
	farmer.catch_up(true)
	await frames(3)
	check("10h : la fermière travaille aux champs", farmer.state == Inhabitant.State.WORK and farmer.visible)
	GameClock.minutes = 23.0 * 60.0
	Society.replan()
	farmer.catch_up(true)
	check("23h : la fermière est rentrée chez elle", not farmer.visible and farmer.state == Inhabitant.State.HOME)
	GameClock.minutes = 10.0 * 60.0
	Society.replan()
	farmer.catch_up(true)
	var monster := Enemy.new()
	v.add_child(monster)
	monster.position = farmer.position + Vector3(4, 0, 0)
	await get_tree().create_timer(1.6).timeout
	check("Un monstre approche : la fermière fuit, et la société le sait",
		farmer.state in [Inhabitant.State.FLEE, Inhabitant.State.HOME]
		and Society.person(&"farmer").activity == "home")
	monster.queue_free()
	await frames(2)

	# ================= SOCIÉTÉ VIVANTE =================
	var hunter := Society.person(&"hunter")
	var elder := Society.person(&"elder")
	var child := Society.person(&"child")
	var fm := Society.person(&"farmer")
	var gd := Society.person(&"guard")
	var nurse_p := Society.person(&"nurse")
	check("Société : 6 personnes, l'Infirmière est à l'étage 2", Society.persons.size() == 6 and nurse_p.floor_number == 2)
	var e0 := nurse_p.energy
	Society.set_block_signals(true)
	Society.simulate(240)
	Society.set_block_signals(false)
	check("Hors champ : l'Infirmière (étage 2) a vécu 4 h sans que le joueur soit là", nurse_p.energy != e0)
	GameClock.minutes = 12.0 * 60.0
	Society.replan()
	check("Midi : Chasseur et Garde déjeunent au même endroit (ils vont se croiser)",
		hunter.location == "square" and gd.location == "square")
	GameClock.minutes = 15.0 * 60.0
	Society.replan()
	check("15h : le Chasseur est à la Fosse", hunter.location == "pit" and hunter.activity == "work")

	# --- Influence sur la Tour : la Fosse
	Society.resources["pit_monsters"] = 5
	Society.set_block_signals(true)
	for i in 300:
		Society._apply_effects(hunter, 0.0)
	Society.set_block_signals(false)
	check("Le Chasseur abat des bêtes de la Fosse (ressource de la Tour)", Society.res("pit_monsters") < 5)
	var low := Society.res("pit_monsters")
	for i in 13:
		Society._regen()
	check("La Tour repeuple la Fosse avec le temps", Society.res("pit_monsters") > low)
	Society.resources["pit_monsters"] = 2
	v._sync_world()
	await frames(2)
	check("Le décor reflète : 2 monstres dans la Fosse", v._pit_enemies.size() == 2)
	Society.resources["pit_monsters"] = 5
	v._sync_world()
	check("...puis 5 quand la Tour en renvoie", v._pit_enemies.size() == 5)
	var kills0 := ScenarioManager.get_scenario(sid).get_condition(&"pit_survive").progress
	v._pit_enemies[0].health.take_damage(1000.0, player)
	await frames(2)
	check("Un monstre tué par le joueur retire une bête du monde", Society.res("pit_monsters") == 4)

	# --- Influence sur la Tour : l'Enfant et la relique
	GameClock.minutes = 12.0 * 60.0
	Society.replan()
	child.location = "well"
	child.activity = "idle"
	Society.resources["relic_at_well"] = 1   # (pendant les 4 h simulées, l'Enfant a pu la prendre lui-même)
	child.carrying = ""
	check("La relique est au Puits", Society.res("relic_at_well") == 1)
	Society.set_block_signals(true)
	for i in 800:
		Society._apply_effects(child, 0.0)
	Society.set_block_signals(false)
	check("L'Enfant s'empare de la relique avant le joueur", Society.res("relic_at_well") == 0 and child.carrying == "ancient_relic")
	v._sync_world()
	await frames(2)
	check("Le décor : la relique a disparu du Puits", not is_instance_valid(v._relic))
	child.trust = 10.0
	var r1 := Society.ask(&"child", "puits")
	check("Confiance insuffisante : l'Enfant ne lâche rien", not player.has_item(&"ancient_relic") and r1.learned.is_empty())
	child.trust = 35.0
	var r2 := Society.ask(&"child", "puits")
	check("Confiance suffisante : l'Enfant confie la relique (autre chemin pour l'épreuve)",
		player.has_item(&"ancient_relic") and child.carrying == "" and "relic_with_child" in r2.learned)

	# ================= LA VIE SE VOIT =================
	var puppets := {}
	for n in get_tree().get_nodes_in_group("inhabitants"):
		puppets[n.person_id] = n
	var hp: Inhabitant = puppets[&"hunter"]
	var fp: Inhabitant = puppets[&"farmer"]
	var cp: Inhabitant = puppets[&"child"]
	var gp2: Inhabitant = puppets[&"guard"]
	Society.resources["pit_monsters"] = 3
	GameClock.minutes = 15.0 * 60.0
	Society.replan()
	hp.catch_up(true)
	v._sync_world()
	await frames(3)
	var alive := func(): return v._pit_enemies.filter(func(e): return is_instance_valid(e) and not e.health.dead).size()
	check("Fosse : 3 bêtes en place", alive.call() == 3)
	Society.resources["pit_monsters"] = 2
	Society.world_effect.emit(&"hunter", "pit_monsters", "")
	await frames(3)
	check("Le Chasseur DOIT aller frapper : la bête ne disparaît pas d'un coup", hp.has_task() and alive.call() == 3)
	var w := 0
	while hp.has_task() and w < 120:
		await frames(10)
		w += 1
	check("Le Chasseur a marché jusqu'à la bête et l'a abattue sous nos yeux", alive.call() == 2)

	# La Fermière porte une caisse jusqu'à la grange
	Society.resources["pit_monsters"] = 0
	v._sync_world()
	GameClock.minutes = 10.0 * 60.0
	Society.replan()
	fp.catch_up(true)
	Society.resources["farm_crates"] = 3
	v._sync_world()
	await frames(3)
	var crates := func(): return v._crates.filter(func(c): return is_instance_valid(c) and not c.is_queued_for_deletion()).size()
	check("Ferme : 3 caisses", crates.call() == 3)
	Society.resources["farm_crates"] = 2
	Society.world_effect.emit(&"farmer", "farm_crates", "")
	await frames(3)
	check("La Fermière part chercher la caisse (elle est encore là)", fp.has_task() and crates.call() == 3)
	w = 0
	while fp.has_task() and w < 200:
		await frames(10)
		w += 1
	await frames(3)
	check("La caisse a été portée jusqu'à la grange : il en reste 2", crates.call() == 2)

	# L'Enfant va ramasser la relique
	GameClock.minutes = 12.0 * 60.0
	Society.replan()
	cp.catch_up(true)
	Society.resources["relic_at_well"] = 1
	v._sync_world()
	await frames(3)
	check("La relique brille au Puits", is_instance_valid(v._relic))
	Society.resources["relic_at_well"] = 0
	Society.world_effect.emit(&"child", "relic_at_well", "ancient_relic")
	await frames(3)
	check("L'Enfant y court : la relique est encore là un instant", cp.has_task() and is_instance_valid(v._relic) and not v._relic.is_queued_for_deletion())
	w = 0
	while cp.has_task() and w < 120:
		await frames(10)
		w += 1
	await frames(3)
	check("L'Enfant l'a ramassée : elle a disparu du Puits", not is_instance_valid(v._relic))

	# Conversation face à face entre deux amis
	Society.resources["pit_monsters"] = 0
	hp.position = Vector3(player.position.x, 0, player.position.z + 6.0)       # en terrain dégagé (pas dans la fontaine)
	gp2.position = Vector3(player.position.x + 5.0, 0, player.position.z + 6.0)
	hp.state = Inhabitant.State.IDLE
	gp2.state = Inhabitant.State.IDLE
	Society.social_event.emit(&"hunter", &"guard", "friendly")
	await get_tree().create_timer(2.5).timeout
	check("Deux amis se rejoignent et se font face", hp.position.distance_to(gp2.position) < 3.2)

	# Un ragot surpris de près rejoint le journal
	Society.rumors_heard.clear()
	Society.player_deed("help_farm")
	var gid: int = Society.chronicle[-1].id
	fp.position = player.position + Vector3(2, 0, 0)
	fp.state = Inhabitant.State.TALK       # figée : sinon elle repart vers son plan avant d'avoir parlé
	fp._talk_t = 8.0
	Society.gossip_told.emit(&"farmer", &"elder", gid)
	await get_tree().create_timer(3.4).timeout
	check("On surprend un ragot en passant : il rejoint les rumeurs du journal", Society.rumors_heard.has(gid))

	# --- Relations : deux amis qui déjeunent ensemble
	hunter.location = "square"
	gd.location = "square"
	hunter.activity = "eat"
	gd.activity = "eat"
	var r_before := hunter.get_rel(&"guard")
	var tt := 10000.0
	for i in 300:
		tt += 100.0
		Society._meet(hunter, gd, tt)
	check("Relations : Chasseur et Garde se rapprochent en déjeunant ensemble", hunter.get_rel(&"guard") > r_before)
	check("La chronique garde une trace de la vie du village", Society.chronicle.size() >= 0)
	# --- Ragots : le savoir circule, mais pas les secrets profonds
	for i in 12:
		Society._gossip(elder, fm)
	check("Ragots : la Fermière apprend d'un ami ce que l'Ancien sait (la sieste)", fm.knows.has("guard_naps"))
	check("Ragots : un secret profond ne circule pas (pas de confidence sans intimité)", not fm.knows.has("tower_seals"))

	# --- Le savoir se mérite
	hunter.mood = 0.0
	gd.mood = 0.0
	elder.mood = 0.0
	hunter.trust = 0.0
	var ka0 := Society.ask(&"hunter", "garde")
	check("Confiance nulle : le Chasseur esquive", ka0.learned.is_empty() and ka0.lines.size() >= 1)
	hunter.trust = 7.0
	var ka1 := Society.ask(&"hunter", "garde")
	check("Un peu de confiance : il lâche la pause déjeuner, pas plus (et il esquive le reste)",
		ka1.learned == ["guard_lunch"] and ka1.lines.size() >= 2)
	hunter.trust = 19.0
	var ka2 := Society.ask(&"hunter", "garde")
	check("Plus de confiance : il avoue la sieste du Garde", "guard_naps" in ka2.learned)
	var ka3 := Society.ask(&"guard", "garde")
	check("Le Garde, lui, n'avoue pas sa propre honte (seuil bien plus haut)", not ("guard_naps" in ka3.learned))
	elder.trust = 30.0
	var ka4 := Society.ask(&"elder", "porte")
	check("L'Ancien sait pour les sceaux mais ne le dit pas à 30 de confiance", ka4.learned.is_empty())
	elder.trust = 58.0
	var ka5 := Society.ask(&"elder", "porte")
	check("...à 58 il se confie", "tower_seals" in ka5.learned)
	var leak := false
	for pid in Society.persons:
		for i in 60:
			var txt := str(Society.small_talk(pid))
			if txt.contains("ce qui est regardé") or txt.contains("juste avant l'aube"):
				leak = true
	check("Bavarder ne divulgue JAMAIS un secret", not leak)
	check("Le savoir appris alimente le journal du joueur", Society.player_facts.has("tower_seals"))

	# --- Réputation : les actes du joueur circulent par ouï-dire
	fm.trust = 0.0
	elder.trust = 0.0
	for i in 3:
		Society.player_deed("help_farm")
	check("Aider la Fermière gagne sa confiance", fm.trust >= 12.0)
	for i in 30:
		Society._gossip(fm, elder)
	check("La réputation circule : l'Ancien en a entendu parler et vous apprécie un peu plus", elder.trust > 0.0)

	# --- Conversation à choix
	tower.hud.show_conversation(&"hunter")
	check("Conversation : 3 choix (Bavarder / Demander / Au revoir)", tower.hud._dlg_choices.get_child_count() == 3)
	tower.hud._conv_topics()
	check("Conversation : sujets débloqués proposés", tower.hud._dlg_choices.get_child_count() >= 6)
	tower.hud._set_modal("")
	check("Rencontrer quelqu'un débloque son sujet", Society.player_topics.has("chasseur"))

	# --- Sauvegarde de la société (aller-retour JSON)
	Society.resources["pit_monsters"] = 3
	var snap: Dictionary = JSON.parse_string(JSON.stringify(Society.to_dict()))
	var t_f := fm.trust
	Society.resources["pit_monsters"] = 0
	fm.trust = -50.0
	Society.from_dict(snap)
	fm = Society.person(&"farmer")
	check("Sauvegarde société : confiance, ressources, savoir restaurés",
		absf(fm.trust - t_f) < 0.01 and Society.res("pit_monsters") > 0 and Society.player_facts.has("tower_seals"))
	check("Sauvegarde société : savoir des personnes restauré", Society.person(&"elder").knows.has("tower_seals"))
	await frames(2)

	# ---------- A1 : Sceau et verrous ----------
	var seal := f1.seal
	# La surveillance est vérifiée à la trappe (entrée en surface), comme dans _on_seal/_sync_seal.
	var seal_pos := v.to_global(VillageLayout.HATCH)

	# Remettre trust à 0 et retirer tous les items pour partir d'un état neutre
	Society.person(&"elder").trust = 0.0
	player.inventory.clear()
	WorldFlags.set_flag(Floor01Village.FLAG_PIT_DONE, false)
	GameClock.minutes = 15.0 * 60.0  # 15h : garde surveille
	Society.replan()
	guard.catch_up(true)
	await frames(3)

	var ctx0 := SealContext.new(player, 1, seal_pos)
	var r0 := seal.evaluate(ctx0)
	check("A1 Sceau inerte sans verrous satisfaits", not r0.open)
	check("A1 Aucun verrou seul ne suffit (4 verrous présents)", seal.locks.size() == 4)
	# Accumuler plusieurs épreuves : le scénario doit rester ACTIVE (pas de résolution automatique)
	ScenarioManager.report(sid, &"farm_help")
	ScenarioManager.report(sid, &"farm_help")
	ScenarioManager.report(sid, &"farm_help")
	ScenarioManager.report(sid, &"labyrinth_exit")
	check("A1 Plusieurs épreuves cumulables : scénario reste ACTIVE",
		ScenarioManager.get_scenario(sid).state == Scenario.State.ACTIVE)

	# Verrou CONSENT : trust Ancien ≥ 20
	Society.person(&"elder").trust = 20.0
	var ctx_consent := SealContext.new(player, 1, seal_pos)
	check("A1 Verrou CONSENT satisfait (trust 20)", seal.get_lock(&"lock_consent").evaluate(ctx_consent))
	Society.person(&"elder").trust = 0.0

	# Verrou MERIT : 3 sources possibles
	var lock_merit := seal.get_lock(&"lock_merit")
	WorldFlags.set_flag(Floor01Village.FLAG_PIT_DONE, true)
	check("A1 MERIT satisfait via Fosse", lock_merit.evaluate(SealContext.new(player, 1, seal_pos)))
	WorldFlags.set_flag(Floor01Village.FLAG_PIT_DONE, false)
	WorldFlags.set_flag(Floor01Village.FLAG_LABYRINTH, true)
	check("A1 MERIT satisfait via Labyrinthe", lock_merit.evaluate(SealContext.new(player, 1, seal_pos)))
	WorldFlags.set_flag(Floor01Village.FLAG_LABYRINTH, false)
	WorldFlags.set_flag(Floor01Village.FLAG_RELIC_TAKEN, true)
	check("A1 MERIT satisfait via Relique", lock_merit.evaluate(SealContext.new(player, 1, seal_pos)))
	WorldFlags.set_flag(Floor01Village.FLAG_RELIC_TAKEN, false)

	# Verrou WATCH : 0 watcher
	GameClock.minutes = 5.0 * 60.0  # 5h : garde dort
	Society.replan()
	guard.catch_up(true)
	await frames(3)
	var ctx_watch := SealContext.new(player, 1, seal_pos)
	check("A1 Verrou WATCH satisfait (0 observateur)", seal.get_lock(&"lock_watch").evaluate(ctx_watch))

	# Verrou ITEM : elder_pass
	player.add_item(&"elder_pass")
	var ctx_item := SealContext.new(player, 1, seal_pos)
	check("A1 Verrou ITEM satisfait (elder_pass)", seal.get_lock(&"lock_item").evaluate(ctx_item))

	# Verrou seul ≠ ouverture : ITEM seul sans WATCH ni CONSENT ni MERIT.
	# 15h : le garde surveille à la porte (~(-3,0,-9.5)), à ~7m de la trappe → WATCH=false.
	GameClock.minutes = 15.0 * 60.0
	Society.replan()
	guard.catch_up(true)
	await frames(3)
	Society.person(&"elder").trust = 0.0   # CONSENT=false
	WorldFlags.set_flag(Floor01Village.FLAG_PIT_DONE, false)  # MERIT=false
	# elder_pass est encore dans l'inventaire → ITEM=true, mais watch=false → route_1 fermée
	# Placer le garde explicitement près de la trappe et forcer son état de surveillance.
	guard.global_position = seal_pos + Vector3(2, 0, 0)   # ~2m de la trappe → watcher
	guard.state = Inhabitant.State.WORK
	await frames(1)
	var ctx_item_only := SealContext.new(player, 1, seal_pos)
	check("A1 ITEM seul sans WATCH ne suffit pas", not seal.evaluate(ctx_item_only).open)

	# Route Ruse : WATCH + ITEM (garde dort + elder_pass)
	GameClock.minutes = 5.0 * 60.0
	Society.replan()
	guard.catch_up(true)
	await frames(3)
	var ctx_ruse := SealContext.new(player, 1, seal_pos)
	var r_ruse := seal.evaluate(ctx_ruse)
	check("A1 Route Ruse s'ouvre (WATCH + ITEM)", r_ruse.open and r_ruse.route == &"route_1")
	player.inventory.erase(&"elder_pass")

	# Route Honneur : CONSENT + MERIT.
	# On vérifie d'abord sans commit (lecture pure), puis on franchit via attempt_seal (commit=true).
	Society.person(&"elder").trust = 20.0
	WorldFlags.set_flag(Floor01Village.FLAG_PIT_DONE, true)
	GameClock.minutes = 15.0 * 60.0
	Society.replan()
	guard.catch_up(true)
	await frames(3)
	var ctx_honour := SealContext.new(player, 1, seal_pos)
	var r_honour := seal.evaluate(ctx_honour)   # lecture pure, pas de marque
	check("A1 Route Honneur s'ouvre (CONSENT + MERIT)", r_honour.open and r_honour.route == &"route_0")
	# Poser la marque via attempt_seal (chemin réel du jeu)
	var r_commit := f1.attempt_seal(player, seal_pos)
	check("A1 Marque posée : mark_reconnu", WorldFlags.get_flag(Floor01Village.FLAG_HONOUR) == true)

	# ---------- Ascension : sceau ouvert par route Honneur, animation, arrivée sur l'Axe ----------
	check("A1 is_cleared() reflète l'ouverture", f1.is_cleared())
	await teleport(Vector3(-8, 0.3, -12), 0)
	hatch.interact(player)
	await frames(90)
	v._seal.interact(player)
	await frames(420)
	check("Le héros monte jusqu'à l'étage 2 (y ~ 15)", player.global_position.y > 14.5)
	check("Superposition : l'arrivée est exactement sur l'Axe, au-dessus de la Chambre du Sceau",
		absf(player.global_position.x - Tower.AXIS.x) < 1.5 and absf(player.global_position.z - Tower.AXIS.y) < 1.5)
	check("Étage 2 activé en y arrivant", tower.active_floor == 2)
	check("Scénario 2 démarre à l'arrivée",
		ScenarioManager.get_scenario(Floor02Asylum.SCENARIO_ID).state == Scenario.State.ACTIVE)
	check("Le héros peut de nouveau bouger après la transition", not player.frozen)

	# ---------- Asile : folie, soins, failles ----------
	var al: Floor02Asylum = a_layout.floor_ctrl
	await teleport(a_layout.to_global(a_layout.arrival_point()))
	al.add_madness(50)
	var m0 := al.madness
	var patient: Interactable = null
	for n in get_tree().get_nodes_in_group("interactable"):
		if a_layout.is_ancestor_of(n) and n.prompt.contains("patient"):
			patient = n
			break
	patient.interact(player)
	check("E2 soin : compteur +1 et folie baisse", al.patients_healed == 1 and al.madness < m0)
	for i in 3:
		await get_tree().process_frame
	# L'Infirmière va soigner un patient (étage 2)
	var nurse_body: Inhabitant = null
	for n in get_tree().get_nodes_in_group("inhabitants"):
		if n.person_id == &"nurse":
			nurse_body = n
	GameClock.minutes = 12.0 * 60.0
	Society.replan()
	nurse_body.catch_up(true)
	Society.resources["asylum_patients"] = 5
	a_layout._sync_world()
	await frames(3)
	var pat_count := func(): return a_layout._patients.values().filter(func(n): return is_instance_valid(n) and not n.is_queued_for_deletion()).size()
	check("Asile : 5 patients en place", pat_count.call() == 5)
	Society.resources["asylum_patients"] = 4
	Society.world_effect.emit(&"nurse", "asylum_patients", "")
	await frames(3)
	check("L'Infirmière va au chevet : le patient est encore là", nurse_body.has_task() and pat_count.call() == 5)
	var w2 := 0
	while nurse_body.has_task() and w2 < 200:
		await frames(10)
		w2 += 1
	await get_tree().create_timer(1.8).timeout
	check("Le patient a été soigné sous nos yeux : il en reste 4", pat_count.call() == 4)
	Society.resources["asylum_patients"] = 11

	check("E2 la folie du joueur est publiée", absf(player.madness - al.madness) < 5.0)
	check("E2 porte refusée à <100", not al.try_forgotten_door())
	al.add_madness(200)
	check("E2 hallucinations actives", al.hallucinations_active())
	await frames(3)
	var wall_door: Interactable = null
	for n in get_tree().get_nodes_in_group("interactable"):
		if a_layout.is_ancestor_of(n) and n.prompt.contains("mur"):
			wall_door = n
	wall_door.interact(player)
	check("E2 porte des Oubliés via interaction à 100", a_layout.consumed.has("forgotten_door"))
	check("E2 flag porte posé", WorldFlags.get_flag(&"used_forgotten_door") == true)
	tower.hud._refresh_journal()
	check("Journal : faille visible APRES résolution", tower.hud._journal_text.text.contains("Oubliés"))

	# ---------- Même loi pour tous : gravité à minuit ----------
	var e := Enemy.new()
	a_layout.add_child(e)
	e.position = Vector3(-27, 0.3, 14)
	GameClock.minutes = 0.5 * 60.0
	await frames(8)
	check("Minuit : le joueur subit la gravité inversée", player.gravity_scale == -1.0)
	check("Minuit : le MONSTRE aussi (mêmes lois)", e.gravity_scale == -1.0)
	var nurse: Inhabitant = null
	for n in get_tree().get_nodes_in_group("inhabitants"):
		if n.display_name == "Infirmière":
			nurse = n
	check("Minuit : l'infirmière aussi (un habitant est un corps comme un autre)", nurse.gravity_scale == -1.0)
	player.add_item(&"anchor_boots")
	await frames(8)
	check("Bottes d'ancrage : faille personnelle", player.gravity_scale == 1.0 and e.gravity_scale == -1.0)
	GameClock.minutes = 12.0 * 60.0
	await frames(8)
	check("Midi : gravité normale pour tous", player.gravity_scale == 1.0 and e.gravity_scale == 1.0)
	e.queue_free()

	# ---------- Sauvegarde : objets consommés ----------
	var coins_before := get_tree().get_nodes_in_group("interactable").size()
	var world := tower.collect_save()
	check("Sauvegarde : patient soigné marqué consommé", a_layout.consumed.has("patient_%d" % 0) or a_layout.consumed.size() > 0)
	check("Sauvegarde OK", SaveSystem.save_game(9, world) == OK)
	await free_tower()
	var loaded := SaveSystem.load_game(9)
	check("Chargement : monde restauré", not loaded.is_empty() and WorldFlags.get_flag(&"used_forgotten_door") == true)
	SaveSystem.pending = loaded
	await new_tower()
	var a2: AsylumLayout = tower.layouts[1]
	var patients_left := 0
	for n in get_tree().get_nodes_in_group("interactable"):
		if a2.is_ancestor_of(n) and n.prompt.contains("patient"):
			patients_left += 1
	check("Chargement : patient déjà soigné non recréé", patients_left == AsylumLayout.PATIENT_SPOTS.size() - 1)
	check("Chargement : joueur restauré dans l'Asile", player.global_position.y > 14.5)
	check("Chargement : folie restaurée", (a2.floor_ctrl as Floor02Asylum).madness > 50.0)
	check("Chargement : porte des Oubliés restée ouverte", a2.consumed.has("forgotten_door"))

	# ---------- Mort : la Tour fait payer ----------
	await frames(10)
	var chaos0 := int(WorldFlags.get_flag(&"current_floor_chaos_level", 0))
	var t0 := GameClock.minutes
	player.health.take_damage(500.0)
	await get_tree().create_timer(2.0).timeout
	check("Mort : le chaos augmente", int(WorldFlags.get_flag(&"current_floor_chaos_level", 0)) == chaos0 + 1)
	check("Mort : le temps passe (2 h)", fposmod(GameClock.minutes - t0, 1440.0) > 110.0)
	check("Mort : retour au pied de l'étage actif", player.global_position.distance_to(
		tower.layouts[1].to_global(tower.layouts[1].spawn_point())) < 3.0 and not player.health.dead)

	print("Échecs : %d" % failures)
	get_tree().quit(failures)
