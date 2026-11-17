## Une personne de la Tour : donnée pure, simulée en permanence (même hors de l'étage actif).
## Le corps 3D (Inhabitant) n'est qu'une marionnette qui exécute ce que la personne a décidé.
class_name Person
extends RefCounted

var id: StringName
var display_name := ""
var subject := ""              ## clé de sujet pour « Demander à propos de... »
var floor_number := 1

# --- apparence / tempérament (fixes) ---
var tint := Color.WHITE
var height := 1.8
var speed := 2.2
var sociability := 0.5         ## goût pour la compagnie
var courage := 0.5
var curiosity := 0.3           ## envie d'errer sans raison
var is_sentinel := false
var wander_radius := 2.5

# --- habitudes ---
var routine: Array = []        ## [{from, to, act, place}] : act = work/idle/eat/sleep/home
var home := ""                 ## où il se réfugie quand il a peur
var rest_act := "home"         ## « home » (caché chez lui) ou « sleep » (dort sur place)
var rest_place := ""

# --- textes (voix du personnage) ---
var greet_new := "Tiens, un visage inconnu."
var greet_friend := "Ah, te voilà !"
var greet_cold := "Qu'est-ce que tu veux, encore ?"
var evasive: Array = ["Hm. Pourquoi tu veux savoir ça ?"]
var unknown_line := "Je ne sais pas grand-chose là-dessus."
var barks: Array = []
var wake_lines: Array = ["Hein ?! Quoi ? Je ne dormais pas !"]
var scared_line := "Pas le temps de discuter !"
var sad_lines: Array = ["Pas le moral aujourd'hui..."]

# --- état dynamique (sauvegardé) ---
var location := ""
var activity := "idle"
var energy := 0.8              ## 1 = reposé
var social := 0.6              ## 1 = comblé de compagnie
var mood := 0.0                ## -1..1
var busy_until := -1.0         ## minutes absolues : ne change pas d'activité avant
var awake_until := -1.0        ## réveillé de force jusque-là
var fear_until := -1.0
var trust := 0.0               ## confiance envers le joueur (-100..100)
var met_player := false
var last_talk_day := -1
var desires: Array = []        ## [{id, place, strength, text}]
var rel: Dictionary = {}       ## autre personne (String) -> affinité -100..100
var knows: Dictionary = {}     ## fait (String) -> niveau de discrétion 0..1 propre à CETTE personne
var heard: Array = []          ## ids d'événements entendus
var carrying := ""             ## objet emporté (pris au monde) ; peut être confié au joueur

func get_rel(other: StringName) -> float:
	return float(rel.get(String(other), 0.0))

func change_rel(other: StringName, delta: float) -> void:
	rel[String(other)] = clampf(get_rel(other) + delta, -100.0, 100.0)

func change_trust(delta: float) -> void:
	trust = clampf(trust + delta, -100.0, 100.0)

func to_dict() -> Dictionary:
	return {"location": location, "activity": activity, "energy": energy, "social": social,
		"mood": mood, "busy_until": busy_until, "awake_until": awake_until, "fear_until": fear_until,
		"trust": trust, "met_player": met_player, "last_talk_day": last_talk_day,
		"desires": desires, "rel": rel, "knows": knows, "heard": heard, "carrying": carrying}

func from_dict(d: Dictionary) -> void:
	location = String(d.get("location", location))
	activity = String(d.get("activity", activity))
	energy = float(d.get("energy", energy))
	social = float(d.get("social", social))
	mood = float(d.get("mood", mood))
	busy_until = float(d.get("busy_until", -1.0))
	awake_until = float(d.get("awake_until", -1.0))
	fear_until = float(d.get("fear_until", -1.0))
	trust = float(d.get("trust", 0.0))
	met_player = bool(d.get("met_player", false))
	last_talk_day = int(d.get("last_talk_day", -1))
	desires = d.get("desires", desires)
	rel = d.get("rel", rel)
	knows = d.get("knows", knows)
	carrying = String(d.get("carrying", ""))
	heard = []
	for h in d.get("heard", []):
		heard.append(int(h))
