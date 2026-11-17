## Étage 1 — Village des Épreuves.
## Sortie par Sceau à 2 verrous, 2 routes (Honneur et Ruse). Aucune route à élément unique.
class_name Floor01Village
extends FloorController

const SCENARIO_ID := &"village_trials"
const GATE_LAW := &"village_gate_sealed"
const PIT_KILLS_REQUIRED := 5
const FARM_HELP_REQUIRED := 3

## Flags WorldFlags posés par ce contrôleur
const FLAG_PIT_DONE      := &"v1_pit_kills_done"   ## ≥ 5 bêtes tuées à la Fosse
const FLAG_LABYRINTH     := &"v1_labyrinth_done"   ## bannière du labyrinthe atteinte
const FLAG_RELIC_TAKEN   := &"v1_relic_taken"      ## relique du Puits ramassée (par le joueur)
const FLAG_HONOUR := &"v1_mark_reconnu"            ## route Honneur franchie
const FLAG_RUSE   := &"v1_mark_intrus"             ## route Ruse franchie

## Le Sceau de cet étage (construit dans _init).
var seal: Seal

func _init() -> void:
	floor_number = 1
	floor_name = "Le Village des Épreuves"
	exit_exploit_condition = &""          ## plus de sortie par exploit de FloorController
	scenarios = [_build_scenario()]
	laws = [_build_gate_law()]
	seal = _build_seal()

# ------------------------------------------------------------------ Sceau
func _build_seal() -> Seal:
	var s := Seal.new()

	# --- Verrous ---
	var consent := Lock.new()
	consent.id = &"lock_consent"
	consent.type = Lock.Type.CONSENT
	consent.glyph = &"glyph_consent"
	# L'Ancien donne son accord (confiance ≥ 20) ; aucun des 4 autres n'est en rancune (< -15).
	consent.params = {
		"person": "elder",
		"min_trust": 20.0,
		"no_grudge": ["child", "farmer", "hunter", "guard"],
	}

	var merit := Lock.new()
	merit.id = &"lock_merit"
	merit.type = Lock.Type.MERIT
	merit.glyph = &"glyph_merit"
	# Preuve d'épreuve : Fosse (≥5 kills) OU Labyrinthe (bannière) OU Relique du Puits.
	# Au moins un de ces flags doit être posé.
	merit.params = {"flags": [String(FLAG_PIT_DONE), String(FLAG_LABYRINTH), String(FLAG_RELIC_TAKEN)]}

	var watch := Lock.new()
	watch.id = &"lock_watch"
	watch.type = Lock.Type.WATCH
	watch.glyph = &"glyph_watch"
	# Aucun observateur dans un rayon de 14 m autour du Sceau.
	watch.params = {"radius": 14.0}

	var item := Lock.new()
	item.id = &"lock_item"
	item.type = Lock.Type.ITEM
	item.glyph = &"glyph_item"
	# Possession du laissez-passer de l'Ancien.
	item.params = {"item": "elder_pass"}

	s.locks = [consent, merit, watch, item]

	# --- Routes (≥ 2 verrous chacune) ---
	# Route 0 — Honneur : CONSENT + MERIT
	# Route 1 — Ruse    : WATCH  + ITEM
	s.routes = [
		[&"lock_consent", &"lock_merit"],
		[&"lock_watch",   &"lock_item"],
	]

	# Marques selon la route
	s.route_marks = {
		0: String(FLAG_HONOUR),
		1: String(FLAG_RUSE),
	}

	return s

# ------------------------------------------------------------------ ScenarioManager (journal)
## Le scénario sert uniquement au journal (progression visible, témoignages, rumeurs).
## Il ne se résout JAMAIS automatiquement : la sortie passe exclusivement par le Sceau.
## Toutes les conditions ont un target impossible (9999) pour rester toujours ACTIVE.
func _build_scenario() -> Scenario:
	var sc := Scenario.new()
	sc.id = SCENARIO_ID
	sc.floor_number = 1
	sc.title = "Les Épreuves du Village"

	var maze := WinCondition.new()
	maze.id = &"labyrinth_exit"
	maze.description = "Traverser le Labyrinthe"
	maze.target = 9999       ## jamais atteint automatiquement
	maze.clue = "Au nord-ouest, un labyrinthe de haies. On dit qu'une bannière marque son centre."

	var pit := WinCondition.new()
	pit.id = &"pit_survive"
	pit.description = "Vaincre les monstres de la Fosse"
	pit.target = 9999        ## le flag FLAG_PIT_DONE est posé par on_pit_kill() à PIT_KILLS_REQUIRED
	pit.clue = "La Fosse, à l'est, grouille de créatures. Cinq têtes suffiraient à convaincre le village."

	var well := WinCondition.new()
	well.id = &"well_relic"
	well.description = "Récupérer la relique du Puits"
	well.target = 9999
	well.clue = "Quelque chose brille au fond du Puits, au nord-est."

	var farm := WinCondition.new()
	farm.id = &"farm_help"
	farm.description = "Aider les fermiers"
	farm.target = 9999
	farm.clue = "Les fermiers du sud ont trois caisses de récolte à porter."

	var slip := WinCondition.new()
	slip.id = &"slip_past_curfew"
	slip.hidden = true
	slip.chaos_delta = 0     ## le chaos est géré par le Sceau (route Ruse)
	slip.target = 9999
	slip.clue = "Vous avez trouvé une faille dans le sceau de la porte et l'avez franchie sans passer les épreuves."

	sc.win_conditions = [maze, pit, well, farm, slip]
	return sc

## Loi de surveillance (toujours nécessaire pour LawSystem / gravité etc.)
func _build_gate_law() -> FloorLaw:
	var law := FloorLaw.new()
	law.id = GATE_LAW
	law.effect = FloorLaw.Effect.SEALED_EXIT
	law.description = "Étage 1 : la porte vers l'étage supérieur reste scellée tant que l'épreuve n'est pas résolue."

	var unwatched := LawExploit.new()
	unwatched.id = &"unwatched_gate"
	unwatched.max_watchers = 0
	unwatched.discovery_text = "Personne ne gardait la porte : le sceau n'a rien retenu."

	var pass_ := LawExploit.new()
	pass_.id = &"elder_pass"
	pass_.required_items = [&"elder_pass"]
	pass_.discovery_text = "Le laissez-passer de l'Ancien fait plier le sceau."

	law.exploits = [unwatched, pass_]
	return law

# ------------------------------------------------------------------ kills Fosse
## Appelé par VillageLayout quand un monstre de la Fosse est tué par le joueur.
## Pose le flag MERIT quand le seuil est atteint.
func on_pit_kill() -> void:
	var s: Scenario = ScenarioManager.get_scenario(SCENARIO_ID)
	if s == null:
		return
	ScenarioManager.report(SCENARIO_ID, &"pit_survive")
	var c: WinCondition = s.get_condition(&"pit_survive")
	if c and c.progress >= PIT_KILLS_REQUIRED:
		WorldFlags.set_flag(FLAG_PIT_DONE, true)

# ------------------------------------------------------------------ sortie par Sceau
## Évalue le Sceau dans le contexte courant.
## Retourne le dictionnaire { open, route, satisfied } de Seal.evaluate.
func attempt_seal(player: Player, seal_pos: Vector3) -> Dictionary:
	var ctx := SealContext.new(player, floor_number, seal_pos)
	var result := seal.evaluate(ctx, true)  ## commit=true : pose les marques au franchissement réel
	# Observer la loi (pour le journal) quelle que soit l'issue
	var law := LawSystem.sealed_exit_law(floor_number)
	if law:
		LawSystem.observe(law)
	if result.open:
		var route: StringName = result.route
		if route == &"route_1":
			# Ruse : faille slip_past_curfew
			LawSystem.note_exploit(law, &"unwatched_gate" if _is_route_watch(result) else &"elder_pass")
			ScenarioManager.force_resolve(SCENARIO_ID, &"slip_past_curfew")
		else:
			# Honneur
			_resolve_via_pit_or_relic()
	return result

func _is_route_watch(result: Dictionary) -> bool:
	return result.get("satisfied", {}).get("lock_watch", false)

func _resolve_via_pit_or_relic() -> void:
	# Résolution forcée du scénario pour le journal au franchissement du Sceau (route Honneur).
	if WorldFlags.get_flag(FLAG_PIT_DONE):
		ScenarioManager.force_resolve(SCENARIO_ID, &"pit_survive")
	else:
		ScenarioManager.force_resolve(SCENARIO_ID, &"well_relic")

# ------------------------------------------------------------------ is_cleared (pour les tests)
## Vrai si le Sceau peut s'ouvrir (au moins une route satisfaite) ou a déjà été franchi.
func is_cleared() -> bool:
	if WorldFlags.get_flag(FLAG_HONOUR) or WorldFlags.get_flag(FLAG_RUSE):
		return true
	# Compatibilité : ancien scénario résolu (chargement d'une vieille sauvegarde)
	for sc in scenarios:
		if sc.next_scenario == &"" and sc.state == Scenario.State.RESOLVED:
			return true
	return false
