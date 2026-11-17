## La société de la Tour (autoload « Society ») : simulée EN PERMANENCE, sur tous les étages, que le
## joueur soit présent ou non. Les corps 3D (Inhabitant) ne sont que des marionnettes de ces personnes.
##
## Chaque pas (10 min de jeu) : les besoins évoluent, chacun décide de son activité (habitudes, fatigue,
## peur, désirs, solitude, caprice), agit sur la Tour (ressources), rencontre d'autres personnes (relations,
## querelles, ragots) et le savoir circule. L'imprévu est voulu : tirages aléatoires, siestes décalées.
extends Node

signal social_event(a: StringName, b: StringName, kind: String)
signal world_effect(person_id: StringName, resource: String, carried: String)
signal fact_learned(fact_id: String)
signal item_given(item_id: String, from_person: StringName)
signal event_logged(ev: Dictionary)
signal gossip_told(speaker: StringName, listener: StringName, event_id: int)  ## un ragot est raconté (audible de près)
signal overheard(event_id: int)                                               ## le joueur l'a surpris

const STEP := 10.0  ## minutes de jeu par pas de simulation

var persons: Dictionary = {}       # StringName -> Person
var places: Dictionary = {}        # floor(int) -> {nom: Vector3}
var resources: Dictionary = {}     # String -> int
var chronicle: Array = []          # [{id, t, text, ids, deed}]
var player_facts: Dictionary = {}  # fait appris par le joueur
var player_topics: Dictionary = {} # sujets débloqués
var rumors_heard: Array = []       # ids d'événements racontés au joueur
var rng := RandomNumberGenerator.new()

var _regen_acc: Dictionary = {}
var _pair_cd: Dictionary = {}
var _next_event := 1
var _last_step := 0.0

func _ready() -> void:
	rng.randomize()
	setup_cast()

# ------------------------------------------------------------------ mise en place
func new_game() -> void:
	rng.randomize()
	setup_cast()

func setup_cast() -> void:
	persons.clear()
	chronicle.clear()
	player_facts.clear()
	player_topics.clear()
	rumors_heard.clear()
	_pair_cd.clear()
	_regen_acc.clear()
	_next_event = 1
	resources.clear()
	for r in Cast.RESOURCES:
		resources[r] = int(Cast.RESOURCES[r].start)
		_regen_acc[r] = 0.0
	for t in Cast.INITIAL_TOPICS:
		player_topics[t] = true
	for p in Cast.people():
		persons[p.id] = p
	_last_step = GameClock.absolute_minutes()
	replan()

## Replace tout le monde selon l'heure courante (nouvelle partie, sauts de temps, tests).
func replan() -> void:
	_last_step = GameClock.absolute_minutes()
	for p in persons.values():
		p.busy_until = -1.0
		var slot := _slot(p, GameClock.get_hour_float())
		p.activity = slot.act
		p.location = slot.place

func register_places(floor_number: int, dict: Dictionary) -> void:
	places[floor_number] = dict

func place_pos(floor_number: int, place_name: String, fallback := Vector3.ZERO) -> Vector3:
	return places.get(floor_number, {}).get(place_name, fallback)

func person(pid: StringName) -> Person:
	return persons.get(pid)

func people_on_floor(n: int) -> Array:
	return persons.values().filter(func(p): return p.floor_number == n)

func res(name: String) -> int:
	return int(resources.get(name, 0))

## Prélève une ressource (le joueur ou un habitant). Faux si elle est épuisée.
func take_resource(name: String) -> bool:
	if res(name) <= 0:
		return false
	resources[name] = res(name) - 1
	return true

# ------------------------------------------------------------------ boucle
func _process(_delta: float) -> void:
	var now := GameClock.absolute_minutes()
	if now < _last_step:      # le temps a reculé (chargement, test) : on se recale
		_last_step = now
		return
	var guard := 0
	while now - _last_step >= STEP and guard < 80:
		_last_step += STEP
		_step(_last_step)
		guard += 1
	if guard == 80:
		_last_step = now

## Laisse la société vivre `minutes` de jeu d'un coup (le temps passe vraiment : mort, repos, tests).
func simulate(minutes: float) -> void:
	var n := int(ceil(minutes / STEP))
	for i in n:
		GameClock.advance(STEP)
		_last_step = GameClock.absolute_minutes()
		_step(_last_step)

func _step(t: float) -> void:
	for p in persons.values():
		_update_needs(p)
	for p in persons.values():
		_decide(p, t)
		_apply_effects(p, t)
	_regen()
	_social(t)
	if chronicle.size() > 60:
		chronicle = chronicle.slice(chronicle.size() - 60)

# ------------------------------------------------------------------ besoins
func _update_needs(p: Person) -> void:
	var h := STEP / 60.0
	if p.activity == "sleep" or p.activity == "home":
		p.energy = minf(1.0, p.energy + 0.15 * h)
	else:
		p.energy = maxf(0.0, p.energy - 0.025 * h)
	if p.activity != "chat":
		p.social = maxf(0.0, p.social - 0.03 * h)
	p.mood *= 0.97

# ------------------------------------------------------------------ habitudes
func _jitter(p: Person) -> float:
	var r := RandomNumberGenerator.new()
	r.seed = hash("%s:%d" % [p.id, GameClock.day])
	return r.randf_range(-0.33, 0.33)  # la sieste commence +/- 20 min selon le jour

func _slot(p: Person, hour: float) -> Dictionary:
	for s in p.routine:
		var f: float = s["from"]
		if s["act"] == "sleep":
			f = wrapf(f + _jitter(p), 0.0, 24.0)
		var t: float = s["to"]
		var inside := (hour >= f and hour < t) if f < t else (hour >= f or hour < t)
		if inside:
			var act: String = s["act"]
			if act == "sleep" and GameClock.absolute_minutes() < p.awake_until:
				act = "work"
			return {"act": act, "place": s["place"]}
	return {"act": "idle", "place": p.location}

# ------------------------------------------------------------------ décisions (utilité)
func _decide(p: Person, t: float) -> void:
	if t < p.busy_until:
		return
	var hour := GameClock.get_hour_float()
	var slot := _slot(p, hour)
	var resting: bool = slot.act == "sleep" or slot.act == "home"
	var best := {"act": slot.act, "place": slot.place, "u": 1.15 if resting else 0.75, "busy": 0.0}

	if p.energy < 0.25 and not resting:   # épuisé : dort où il peut
		var u := 1.0 + (0.25 - p.energy) * 8.0
		if u > best.u:
			best = {"act": p.rest_act, "place": p.rest_place, "u": u, "busy": 60.0}
	if t < p.fear_until:                  # peur : se terre chez soi
		best = {"act": "home", "place": p.home, "u": 3.0, "busy": 0.0}
	elif not resting and hour >= 6.0 and hour < 21.0:
		for d in p.desires:               # désirs : on y va quand l'envie est forte (aléa)
			var u := float(d.strength) * 1.6 * rng.randf_range(0.6, 1.4)
			if u > best.u:
				# Même lieu que l'habitude : on garde l'activité habituelle (un chasseur à la Fosse y CHASSE).
				var act: String = slot.act if d.place == slot.place else "idle"
				best = {"act": act, "place": d.place, "u": u, "busy": 30.0}
		if p.social < 0.3:                # solitude : rejoindre un ami
			var friend := _best_friend(p)
			if friend != null:
				var u := (0.5 - p.social) * 3.0 * (0.5 + p.sociability) + 0.5
				if u > best.u:
					best = {"act": "idle", "place": friend.location, "u": u, "busy": 30.0}
		if rng.randf() < 0.04 * p.curiosity:   # caprice : promenade imprévue
			var spots := _floor_places(p.floor_number)
			if not spots.is_empty():
				best = {"act": "idle", "place": spots.pick_random(), "u": 1.0, "busy": 20.0}

	var changed: bool = best.act != p.activity or best.place != p.location
	p.activity = best.act
	p.location = best.place
	p.busy_until = t + float(best.busy) if best.busy > 0.0 else -1.0
	if changed and p.is_sentinel and p.activity == "sleep" and not (slot.act == "sleep"):
		_log_event("%s s'est endormi en plein jour." % p.display_name, [p.id])

func _best_friend(p: Person) -> Person:
	var best: Person = null
	var best_r := 15.0
	for o in persons.values():
		if o == p or o.floor_number != p.floor_number or o.activity in ["sleep", "home"]:
			continue
		var r := p.get_rel(o.id)
		if r > best_r:
			best_r = r
			best = o
	return best

func _floor_places(n: int) -> Array:
	var out: Array = []
	for p in persons.values():
		if p.floor_number != n:
			continue
		for s in p.routine:
			if not String(s["place"]).begins_with("home") and s["place"] not in out:
				out.append(s["place"])
		for d in p.desires:
			if d.place not in out:
				out.append(d.place)
	return out

# ------------------------------------------------------------------ influence sur la Tour
func _apply_effects(p: Person, t: float) -> void:
	for e in Cast.WORK_EFFECTS:
		if String(p.id) != e["person"] or p.activity != e["act"] or p.location != e["place"]:
			continue
		var rname: String = e["resource"]
		if res(rname) <= 0 or rng.randf() >= float(e["chance"]):
			continue
		resources[rname] = res(rname) - 1
		var carried: String = e.get("carry", "")
		if carried != "":
			p.carrying = carried
			var secret := float(e.get("secret", 0.5))
			p.knows[e["fact"]] = secret
			for w in _witnesses(p):                # les témoins savent, un peu moins discrets
				w.knows[e["fact"]] = maxf(0.0, secret - 0.2)
			for d in p.desires:                    # désir assouvi
				d["strength"] = 0.05
			var ev := _log_event(String(e["event"]), [p.id])
			p.heard.append(ev)
			for w in _witnesses(p):
				w.heard.append(ev)
		world_effect.emit(p.id, rname, carried)

func _regen() -> void:
	for r in Cast.RESOURCES:
		var every: int = Cast.RESOURCES[r].regen_minutes
		if every <= 0 or res(r) >= int(Cast.RESOURCES[r].cap):
			continue
		_regen_acc[r] = float(_regen_acc.get(r, 0.0)) + STEP
		if _regen_acc[r] >= every:
			_regen_acc[r] = 0.0
			resources[r] = res(r) + 1

func _witnesses(p: Person) -> Array:
	return persons.values().filter(func(o):
		return o != p and o.floor_number == p.floor_number and o.location == p.location \
			and not (o.activity in ["sleep", "home"]))

# ------------------------------------------------------------------ relations
func _social(t: float) -> void:
	var groups: Dictionary = {}
	for p in persons.values():
		if p.activity in ["sleep", "home"]:
			continue
		var key := "%d:%s" % [p.floor_number, p.location]
		if not groups.has(key):
			groups[key] = []
		groups[key].append(p)
	for key in groups:
		var g: Array = groups[key]
		for i in g.size():
			for j in range(i + 1, g.size()):
				_meet(g[i], g[j], t)

func _meet(a: Person, b: Person, t: float) -> void:
	var ck := "%s|%s" % [a.id, b.id]
	if t < float(_pair_cd.get(ck, -1.0)):
		return
	var chance := 0.35 * (a.sociability + b.sociability) * 0.5
	if a.activity == "eat" and b.activity == "eat":
		chance *= 1.6
	if rng.randf() >= chance:
		return
	_pair_cd[ck] = t + 60.0
	var avg := (a.get_rel(b.id) + b.get_rel(a.id)) * 0.5
	var stressed := a.mood < -0.2 or b.mood < -0.2
	if avg <= -15.0 and (stressed or rng.randf() < 0.3):
		a.change_rel(b.id, -5.0)
		b.change_rel(a.id, -5.0)
		a.mood -= 0.25
		b.mood -= 0.25
		a.busy_until = t + 10.0
		b.busy_until = t + 10.0
		var ev := _log_event("%s et %s se sont disputés." % [a.display_name, b.display_name], [a.id, b.id])
		a.heard.append(ev)
		b.heard.append(ev)
		social_event.emit(a.id, b.id, "quarrel")
		return
	var before := avg
	a.change_rel(b.id, 1.5)
	b.change_rel(a.id, 1.5)
	a.social = minf(1.0, a.social + 0.3)
	b.social = minf(1.0, b.social + 0.3)
	a.mood = minf(1.0, a.mood + 0.1)
	b.mood = minf(1.0, b.mood + 0.1)
	a.activity = "chat"
	b.activity = "chat"
	a.busy_until = t + 20.0
	b.busy_until = t + 20.0
	if before < 40.0 and avg + 1.5 >= 40.0:
		var ev := _log_event("%s et %s sont devenus amis." % [a.display_name, b.display_name], [a.id, b.id])
		a.heard.append(ev)
		b.heard.append(ev)
	_gossip(a, b)
	_gossip(b, a)
	social_event.emit(a.id, b.id, "friendly" if avg >= 25.0 else "chat")

## `speaker` confie une nouvelle ou un secret à `listener` (le savoir et la réputation circulent).
func _gossip(speaker: Person, listener: Person) -> void:
	if rng.randf() < 0.6:
		var fresh: Array = speaker.heard.filter(func(e): return e not in listener.heard)
		if not fresh.is_empty():
			var id: int = fresh.pick_random()
			listener.heard.append(id)
			gossip_told.emit(speaker.id, listener.id, id)
			var ev := _event(id)
			if ev.has("deed"):          # la réputation du joueur circule, pondérée par les affinités
				var d: Dictionary = ev.deed
				listener.change_trust(float(d.delta) * listener.get_rel(StringName(d.who)) / 100.0 * 0.5)
			return
	var rel_ab := speaker.get_rel(listener.id)
	for f in speaker.knows:
		if f in listener.knows or not _fact_valid(f):
			continue
		if float(speaker.knows[f]) * 60.0 <= maxf(0.0, rel_ab) + 10.0:
			listener.knows[f] = minf(1.0, float(speaker.knows[f]) + 0.1)
			return

func _fact_valid(fid: String) -> bool:
	var f: Dictionary = Cast.FACTS.get(fid, {})
	if f.is_empty():
		return false
	return not (f.has("while_res") and res(f["while_res"]) <= 0)

# ------------------------------------------------------------------ chronique
func _log_event(text: String, ids: Array, deed := {}) -> int:
	var ev := {"id": _next_event, "t": GameClock.absolute_minutes(), "text": text, "ids": ids}
	if not deed.is_empty():
		ev["deed"] = deed
	_next_event += 1
	chronicle.append(ev)
	event_logged.emit(ev)
	return int(ev.id)

## Texte neutre d'un événement (pour un ragot entre habitants, pas adressé au joueur).
func event_raw(id: int) -> String:
	var ev := _event(id)
	return "" if ev.is_empty() else String(ev.text)

## Le joueur surprend un ragot : il rejoint ses rumeurs.
func overhear(id: int) -> void:
	if id not in rumors_heard and not _event(id).is_empty():
		rumors_heard.append(id)
		overheard.emit(id)

func event_text(id: int) -> String:
	var ev := _event(id)
	if ev.is_empty():
		return ""
	return String(ev.deed.told) if ev.has("deed") else String(ev.text)

func _event(id: int) -> Dictionary:
	for e in chronicle:
		if int(e.id) == id:
			return e
	return {}

# ------------------------------------------------------------------ actes du joueur
func player_deed(kind: String) -> void:
	var d: Dictionary = Cast.DEEDS.get(kind, {})
	if d.is_empty():
		return
	for pid in d.deltas:
		var p: Person = persons.get(StringName(pid))
		if p:
			p.change_trust(float(d.deltas[pid]))
			p.mood = clampf(p.mood + (0.15 if float(d.deltas[pid]) > 0.0 else -0.4), -1.0, 1.0)
	var who := StringName(d.who)
	var ev := _log_event(String(d.text), [who], {"kind": kind, "who": String(who),
		"delta": float(d.deltas.get(d.who, 0.0)), "told": String(d.told)})
	var ben: Person = persons.get(who)
	if ben:
		ben.heard.append(ev)
		for w in _witnesses(ben):  # ceux qui étaient là ont vu
			w.heard.append(ev)
			w.change_trust(float(d.deltas.get(d.who, 0.0)) * w.get_rel(who) / 100.0 * 0.5)

func wake(pid: StringName, minutes: float) -> void:
	var p: Person = persons.get(pid)
	if p == null:
		return
	var was_asleep := p.activity == "sleep"
	p.awake_until = GameClock.absolute_minutes() + minutes
	if was_asleep:
		p.activity = "work"
		p.busy_until = -1.0
		if p.is_sentinel:
			player_deed("woke_guard")

func on_threat(pid: StringName) -> void:
	var p: Person = persons.get(pid)
	if p == null:
		return
	p.fear_until = GameClock.absolute_minutes() + 30.0
	p.mood = clampf(p.mood - 0.3, -1.0, 1.0)
	p.activity = "home"
	p.location = p.home
	p.busy_until = -1.0

# ------------------------------------------------------------------ conversation
## Début de conversation : retourne l'accueil, enregistre la rencontre et la confiance quotidienne.
func begin_conversation(pid: StringName) -> String:
	var p: Person = persons[pid]
	var first := not p.met_player
	var line := "Oui ? Je t'écoute."
	if first:
		line = p.greet_new
	elif p.trust >= 15.0:
		line = p.greet_friend
	elif p.trust <= -10.0:
		line = p.greet_cold
	p.met_player = true
	player_topics[p.subject] = true
	if p.last_talk_day != GameClock.day:
		p.last_talk_day = GameClock.day
		p.change_trust(2.0)
		p.mood = minf(1.0, p.mood + 0.1)
	return line

func unlock_topics(keys: Array) -> void:
	for k in keys:
		player_topics[k] = true

func topics() -> Array:
	var out: Array = []
	for k in Cast.SUBJECTS:
		if player_topics.has(k):
			out.append({"key": k, "label": Cast.SUBJECTS[k]})
	return out

## « Bavarder » : humeur, nouvelles entendues (ragots), désir, ou simple remarque. Ne livre JAMAIS de secret.
func small_talk(pid: StringName) -> Array:
	var p: Person = persons[pid]
	if p.mood < -0.35 and not p.sad_lines.is_empty():
		return [String(p.sad_lines.pick_random())]
	var lines: Array = []
	if rng.randf() < 0.55 and not p.heard.is_empty():
		var recent: Array = p.heard.slice(maxi(0, p.heard.size() - 6))
		var id: int = recent.pick_random()
		var ev := _event(id)
		if not ev.is_empty():
			if ev.has("deed"):
				lines.append(String(ev.deed.told))
			else:
				lines.append("Tu as su ? " + String(ev.text))
			if id not in rumors_heard:
				rumors_heard.append(id)
	if lines.is_empty():
		var wants: Array = p.desires.filter(func(d): return float(d.strength) > 0.2)
		if not wants.is_empty() and rng.randf() < 0.6:
			lines.append(String(wants.pick_random().text))
	if lines.is_empty() and p.carrying != "" and rng.randf() < 0.4:
		lines.append("Hm... j'ai un petit secret. Mais je ne dirai rien.")
	if lines.is_empty():
		lines.append(String(p.barks.pick_random()) if not p.barks.is_empty() else "Hm.")
	return lines

## « Demander à propos de... » : le savoir se mérite. Retourne {lines, learned}.
func ask(pid: StringName, subject: String) -> Dictionary:
	var p: Person = persons[pid]
	var cands: Array = []
	for fid in p.knows:
		var f: Dictionary = Cast.FACTS.get(fid, {})
		if f.is_empty() or f.subject != subject or not _fact_valid(fid):
			continue
		if f.has("gives") and p.carrying != f["gives"]:
			continue
		cands.append(fid)
	if cands.is_empty():
		return {"lines": [p.unknown_line], "learned": []}
	cands.sort_custom(func(a, b): return float(p.knows[a]) < float(p.knows[b]))
	var lines: Array = []
	var learned: Array = []
	var withheld := false
	for fid in cands:
		var secret := float(p.knows[fid])
		var required := secret * 60.0 - p.mood * 8.0
		if p.trust >= required:
			var prefix := "Entre nous... " if secret >= 0.4 else ""
			lines.append(prefix + String(Cast.FACTS[fid].text))
			learned.append(fid)
			_learn(fid, p, lines)
		else:
			withheld = true
	if learned.is_empty() or withheld:
		lines.append(String(p.evasive.pick_random()) if not p.evasive.is_empty() else "Hm.")
	return {"lines": lines, "learned": learned}

func _learn(fid: String, from: Person, lines: Array) -> void:
	var f: Dictionary = Cast.FACTS[fid]
	if not player_facts.has(fid):
		player_facts[fid] = true
		fact_learned.emit(fid)
		if f.has("discovers"):
			ScenarioManager.discover(StringName(f["discovers"][0]), StringName(f["discovers"][1]))
	if f.has("gives") and from.carrying == f["gives"]:
		var item: String = from.carrying
		from.carrying = ""
		lines.append("Tiens, prends-le. Je n'en ai plus besoin.")
		item_given.emit(item, from.id)

func trust_label(pid: StringName) -> String:
	var p: Person = persons[pid]
	if p.trust >= 40.0: return "vous tient pour un ami"
	if p.trust >= 15.0: return "vous fait confiance"
	if p.trust > -10.0: return "reste réservé"
	if p.trust > -40.0: return "se méfie de vous"
	return "vous est hostile"

# ------------------------------------------------------------------ sauvegarde
func to_dict() -> Dictionary:
	var pd := {}
	for id in persons:
		pd[String(id)] = persons[id].to_dict()
	return {"persons": pd, "resources": resources, "regen": _regen_acc, "chronicle": chronicle,
		"facts": player_facts.keys(), "topics": player_topics.keys(), "rumors": rumors_heard,
		"next_event": _next_event}

func from_dict(d: Dictionary) -> void:
	setup_cast()
	for id in d.get("persons", {}):
		var p: Person = persons.get(StringName(id))
		if p:
			p.from_dict(d["persons"][id])
	for r in d.get("resources", {}):
		resources[String(r)] = int(d["resources"][r])
	for r in d.get("regen", {}):
		_regen_acc[String(r)] = float(d["regen"][r])
	chronicle = d.get("chronicle", [])
	for e in chronicle:
		e["id"] = int(e["id"])
	player_facts.clear()
	for f in d.get("facts", []):
		player_facts[String(f)] = true
	player_topics.clear()
	for t in d.get("topics", []):
		player_topics[String(t)] = true
	rumors_heard = []
	for r in d.get("rumors", []):
		rumors_heard.append(int(r))
	_next_event = int(d.get("next_event", 1))
	_last_step = GameClock.absolute_minutes()
