## Les habitants de la Tour : tempérament, habitudes, désirs, relations, savoir.
## Aucun d'eux ne connaît « les lois de la Tour » comme un règlement : ils savent des choses vues, entendues,
## parfois honteuses. Ce qu'ils savent, ils ne le disent pas à n'importe qui (voir Society.ask).
class_name Cast
extends RefCounted

## Sujets sur lesquels le joueur peut interroger. Certains sont connus d'emblée, d'autres se débloquent.
const SUBJECTS := {
	"epreuves": "Les épreuves", "porte": "La porte", "puits": "Le Puits", "fosse": "La Fosse",
	"recoltes": "Les récoltes", "garde": "Le Garde", "ancien": "L'Ancien", "chasseur": "Le Chasseur",
	"enfant": "L'Enfant", "fermiere": "La Fermière", "infirmiere": "L'Infirmière", "minuit": "Minuit",
	"patients": "Les patients", "gourou": "Le Gourou", "cle": "La clé du Directeur",
}
const INITIAL_TOPICS := ["epreuves", "porte", "puits", "fosse", "recoltes"]

## Faits : texte rapporté, sujet, effet éventuel sur le journal des scénarios.
## La discrétion (secrecy) est propre à chaque personne qui le sait (voir Person.knows).
const FACTS := {
	"trials_general": {"subject": "epreuves", "discovers": ["village_trials", "labyrinth_exit"],
		"text": "Pour monter, il faut faire ses preuves. Le labyrinthe de haies, au nord-ouest, en est une : une bannière marque son centre."},
	"well_relic": {"subject": "puits", "discovers": ["village_trials", "well_relic"], "while_res": "relic_at_well",
		"text": "Il y a quelque chose qui brille au fond du Puits, au nord-est. Une relique, paraît-il."},
	"pit_beasts": {"subject": "fosse", "discovers": ["village_trials", "pit_survive"],
		"text": "La Fosse, à l'est, grouille de bêtes volantes. Cinq têtes suffiraient à convaincre le village."},
	"harvest": {"subject": "recoltes", "discovers": ["village_trials", "farm_help"],
		"text": "Trois caisses de récolte attendent d'être portées jusqu'à la grange, côté sud."},
	"guard_lunch": {"subject": "garde",
		"text": "Vers midi, le Garde quitte son poste pour manger sur la place."},
	"guard_naps": {"subject": "garde",
		"text": "Le Garde s'assoupit à son poste juste avant l'aube. Il ne l'avouera jamais."},
	"pass_lost": {"subject": "ancien", "while_res": "elder_pass_ground",
		"text": "L'Ancien a égaré un parchemin de passage, du côté des bois du sud-ouest. Il en a honte."},
	# Faits créés par le monde lui-même quand un habitant agit (voir WORK_EFFECTS)
	"relic_with_child": {"subject": "puits", "gives": "ancient_relic",
		"text": "C'est le gamin qui a pris la relique du Puits. Il la garde sur lui."},
	"pass_with_elder": {"subject": "ancien", "gives": "elder_pass",
		"text": "L'Ancien a fini par retrouver son parchemin. Il le garde précieusement sur lui."},
	"tower_seals": {"subject": "porte",
		"text": "Les sceaux de la Tour, dit-on, ne retiennent que ce qui est regardé. Une porte sans témoin n'est qu'une porte."},
	"asylum_patients": {"subject": "patients", "discovers": ["asylum_in_distress", "heal_patients"],
		"text": "Les patients ne sont pas méchants, juste terrifiés. Une dizaine de soignés suffirait à rétablir l'ordre."},
	"asylum_guru": {"subject": "gourou", "discovers": ["asylum_in_distress", "kill_guru"],
		"text": "Au nord règne le Gourou. Tant qu'il vit, personne ne dort vraiment."},
	"asylum_key": {"subject": "cle", "discovers": ["asylum_in_distress", "director_key"],
		"text": "La clé du Directeur est restée dans son bureau, dans l'aile est."},
	"gravity_midnight": {"subject": "minuit",
		"text": "À minuit, ici, tout se retourne. Les anciens patients se cramponnent à leur lit avant que le plafond ne les appelle."},
}

## Actes du joueur : qui en est le bénéficiaire, variation de confiance, et comment ça se raconte.
const DEEDS := {
	"help_farm": {"who": "farmer", "deltas": {"farmer": 4.0},
		"text": "Un voyageur a aidé la Fermière à porter ses récoltes.",
		"told": "Il paraît que tu as aidé la Fermière à porter ses récoltes."},
	"pit_kill": {"who": "hunter", "deltas": {"hunter": 3.0, "child": 1.0},
		"text": "Un voyageur a abattu une des bêtes de la Fosse.",
		"told": "On raconte que tu as abattu une des bêtes de la Fosse."},
	"relic_taken": {"who": "child", "deltas": {"child": -15.0},
		"text": "Un voyageur a pris la relique du Puits.",
		"told": "On dit que tu as pris la relique du Puits. L'Enfant n'est pas content."},
	"woke_guard": {"who": "guard", "deltas": {"guard": -8.0},
		"text": "Un voyageur a tiré le Garde de son sommeil.",
		"told": "Il paraît que tu as réveillé le Garde en sursaut."},
	"heal_patient": {"who": "nurse", "deltas": {"nurse": 3.0},
		"text": "Un voyageur a soigné un patient de l'Asile.",
		"told": "Il paraît que tu soignes les patients de l'Asile."},
}

## Correspondance condition de scénario -> acte (aider les fermiers, etc.)
const DEED_BY_CONDITION := {"farm_help": "help_farm"}

## Ressources de la Tour que les habitants consomment ET que la Tour renouvelle. Elles évoluent
## même quand le joueur est ailleurs ; le décor n'en est que le reflet quand l'étage est actif.
const RESOURCES := {
	"pit_monsters": {"start": 5, "cap": 5, "regen_minutes": 120},
	"farm_crates": {"start": 3, "cap": 3, "regen_minutes": 120},
	"relic_at_well": {"start": 1, "cap": 1, "regen_minutes": 0},
	"elder_pass_ground": {"start": 1, "cap": 1, "regen_minutes": 0},
	"asylum_patients": {"start": 12, "cap": 12, "regen_minutes": 150},
}

## Quand une personne exerce une activité à un endroit, elle agit sur la Tour (joueur présent ou non).
## carry : objet qu'elle emporte ; fact/secret : savoir créé (pour elle et les témoins) ; event : chronique.
const WORK_EFFECTS := [
	{"person": "hunter", "act": "work", "place": "pit", "resource": "pit_monsters", "chance": 0.2},
	{"person": "farmer", "act": "work", "place": "farm", "resource": "farm_crates", "chance": 0.08},
	{"person": "child", "act": "idle", "place": "well", "resource": "relic_at_well", "chance": 0.012,
		"carry": "ancient_relic", "fact": "relic_with_child", "secret": 0.5,
		"event": "L'Enfant a pris la relique du Puits."},
	{"person": "elder", "act": "idle", "place": "woods_sw", "resource": "elder_pass_ground", "chance": 0.05,
		"carry": "elder_pass", "fact": "pass_with_elder", "secret": 0.5,
		"event": "L'Ancien a retrouvé son vieux parchemin."},
	{"person": "nurse", "act": "work", "place": "post", "resource": "asylum_patients", "chance": 0.07},
]

static func _p(d: Dictionary) -> Person:
	var p := Person.new()
	for k in d:
		p.set(k, d[k])
	return p

static func people() -> Array:
	var out: Array = []

	out.append(_p({"id": &"elder", "display_name": "L'Ancien", "subject": "ancien", "floor_number": 1,
		"tint": Color(0.75, 0.65, 0.95), "speed": 1.6, "sociability": 0.6, "courage": 0.4, "curiosity": 0.4,
		"wander_radius": 4.0, "home": "home_elder", "rest_act": "home", "rest_place": "home_elder",
		"routine": [{"from": 7.0, "to": 19.0, "act": "idle", "place": "square"},
			{"from": 19.0, "to": 7.0, "act": "home", "place": "home_elder"}],
		"greet_new": "Voyageur... la Tour t'a mené jusqu'à notre village.",
		"greet_friend": "Ah, mon ami ! Assieds-toi un instant.",
		"greet_cold": "Hm. Qu'est-ce qui t'amène ?",
		"evasive": ["Il y a des choses qu'on ne confie pas à un étranger...", "Chaque chose en son temps, voyageur."],
		"unknown_line": "Mes vieilles oreilles n'ont rien entendu là-dessus.",
		"barks": ["Le temps passe, ici, comme partout.", "Hm, hm..."],
		"sad_lines": ["Les jours sont longs quand on cherche quelque chose de perdu..."],
		"desires": [{"id": "company", "place": "square", "strength": 0.5, "text": "Il fait bon avoir de la compagnie sur la place."},
			{"id": "lost_pass", "place": "woods_sw", "strength": 0.4, "text": "Il me faudrait retrouver une chose que j'ai égarée..."}],
		"rel": {"child": 40.0, "guard": 10.0, "farmer": 30.0, "hunter": 10.0},
		"knows": {"trials_general": 0.0, "pass_lost": 0.7, "tower_seals": 0.95, "guard_naps": 0.4, "guard_lunch": 0.1}}))

	out.append(_p({"id": &"child", "display_name": "Enfant", "subject": "enfant", "floor_number": 1,
		"tint": Color(1.0, 0.8, 0.5), "height": 1.3, "speed": 2.8, "sociability": 0.9, "courage": 0.2, "curiosity": 0.7,
		"wander_radius": 6.0, "home": "home_child", "rest_act": "home", "rest_place": "home_child",
		"routine": [{"from": 8.0, "to": 19.0, "act": "idle", "place": "well"},
			{"from": 19.0, "to": 8.0, "act": "home", "place": "home_child"}],
		"greet_new": "Hé ! T'es nouveau ? T'as l'air perdu !",
		"greet_friend": "C'est toi ! Tu veux jouer ?",
		"greet_cold": "Tu m'as pris mon trésor... Va-t'en.",
		"evasive": ["Je dirai rien ! C'est un secret !"],
		"unknown_line": "Euh... aucune idée !",
		"barks": ["Tu veux jouer ?", "Chut, je cherche quelque chose."],
		"sad_lines": ["Le Puits est vide maintenant..."],
		"desires": [{"id": "relic", "place": "well", "strength": 0.7, "text": "Un jour, je trouverai ce qui brille au fond du Puits."}],
		"rel": {"elder": 40.0, "hunter": 50.0, "guard": -15.0, "farmer": 10.0},
		"knows": {"well_relic": 0.0, "guard_lunch": 0.0}}))

	out.append(_p({"id": &"hunter", "display_name": "Chasseur", "subject": "chasseur", "floor_number": 1,
		"tint": Color(0.6, 0.85, 0.6), "sociability": 0.5, "courage": 0.85, "curiosity": 0.3,
		"wander_radius": 3.0, "home": "home_hunter", "rest_act": "home", "rest_place": "home_hunter",
		"routine": [{"from": 5.5, "to": 11.0, "act": "work", "place": "pit"},
			{"from": 11.0, "to": 13.0, "act": "eat", "place": "square"},
			{"from": 13.0, "to": 18.0, "act": "work", "place": "pit"},
			{"from": 18.0, "to": 5.5, "act": "home", "place": "home_hunter"}],
		"greet_new": "Un nouveau ? Garde tes distances de la Fosse.",
		"greet_friend": "Content de te voir, camarade.",
		"greet_cold": "Tu as de l'audace de m'adresser la parole.",
		"evasive": ["Ça ne te regarde pas, étranger.", "Je ne parle pas de ces choses-là à n'importe qui."],
		"unknown_line": "Aucune idée. Je chasse, je ne cause pas.",
		"barks": ["Elles ne descendent jamais jusqu'ici. D'habitude.", "Garde un oeil sur le ciel."],
		"sad_lines": ["La chasse est mauvaise en ce moment."],
		"desires": [{"id": "glory", "place": "pit", "strength": 0.5, "text": "Venir à bout de la Fosse, voilà ce que je voudrais."}],
		"rel": {"guard": 30.0, "child": 50.0, "farmer": 20.0, "elder": 10.0},
		"knows": {"pit_beasts": 0.0, "guard_naps": 0.3, "guard_lunch": 0.1, "well_relic": 0.1}}))

	out.append(_p({"id": &"farmer", "display_name": "Fermière", "subject": "fermiere", "floor_number": 1,
		"tint": Color(0.95, 0.75, 0.65), "sociability": 0.4, "courage": 0.3, "curiosity": 0.2,
		"wander_radius": 3.0, "home": "home_farmer", "rest_act": "home", "rest_place": "home_farmer",
		"routine": [{"from": 6.0, "to": 19.0, "act": "work", "place": "farm"},
			{"from": 19.0, "to": 6.0, "act": "home", "place": "home_farmer"}],
		"greet_new": "Oh... bonjour. Excusez-moi, j'ai beaucoup à faire.",
		"greet_friend": "Toujours là pour donner un coup de main, toi.",
		"greet_cold": "Je n'ai pas de temps à perdre avec toi.",
		"evasive": ["Je ne voudrais pas faire de tort à quelqu'un...", "Ce ne sont pas mes affaires."],
		"unknown_line": "Je ne sais rien de tout ça, moi.",
		"barks": ["Encore une journée de labeur.", "Il faut bien que quelqu'un nourrisse tout ce monde."],
		"sad_lines": ["Les récoltes sont maigres cette saison."],
		"desires": [{"id": "sell", "place": "square", "strength": 0.3, "text": "J'aimerais écouler mes récoltes sur la place."}],
		"rel": {"elder": 30.0, "hunter": 20.0, "guard": -10.0, "child": 10.0},
		"knows": {"harvest": 0.0, "pass_lost": 0.45, "guard_lunch": 0.1}}))

	out.append(_p({"id": &"guard", "display_name": "Garde", "subject": "garde", "floor_number": 1,
		"tint": Color(0.65, 0.7, 0.85), "sociability": 0.3, "courage": 0.9, "curiosity": 0.0,
		"is_sentinel": true, "wander_radius": 1.5, "home": "post", "rest_act": "sleep", "rest_place": "post",
		"routine": [{"from": 4.25, "to": 6.0, "act": "sleep", "place": "post"},
			{"from": 12.0, "to": 12.75, "act": "eat", "place": "square"},
			{"from": 6.0, "to": 12.0, "act": "work", "place": "post"},
			{"from": 12.75, "to": 22.0, "act": "work", "place": "post"},
			{"from": 22.0, "to": 6.0, "act": "work", "place": "post"}],
		"greet_new": "Circulez. Ce n'est pas un lieu de promenade.",
		"greet_friend": "Hm. Toi, au moins, tu ne m'embêtes pas.",
		"greet_cold": "Ne me parle pas.",
		"evasive": ["Je n'ai rien à dire là-dessus. Circulez.", "Mes affaires ne regardent que moi."],
		"unknown_line": "Je monte la garde. Je ne sais que ça.",
		"barks": ["Rien à signaler.", "Circulez."],
		"wake_lines": ["Hein ?! Je ne dormais pas ! J'avais les yeux fermés, c'est tout...", "Bon. Circulez, il n'y a rien à voir."],
		"sad_lines": ["Les gardes de nuit ne dorment jamais assez..."],
		"desires": [{"id": "company", "place": "square", "strength": 0.25, "text": "Un peu de compagnie ne me ferait pas de mal."}],
		"rel": {"hunter": 30.0, "elder": 10.0, "farmer": -10.0, "child": -15.0},
		"knows": {"guard_naps": 0.85, "guard_lunch": 0.2}}))

	# Étage à thème : une habitante qui sait des choses sur la Tour, et ne les offre pas.
	out.append(_p({"id": &"nurse", "display_name": "Infirmière", "subject": "infirmiere", "floor_number": 2,
		"tint": Color(0.9, 0.55, 0.65), "sociability": 0.4, "courage": 0.3, "curiosity": 0.0, "wander_radius": 3.0,
		"home": "post", "rest_act": "sleep", "rest_place": "post",
		"routine": [{"from": 0.0, "to": 24.0, "act": "work", "place": "post"}],
		"greet_new": "Vous êtes monté jusqu'ici ? Courageux... ou perdu.",
		"greet_friend": "Vous êtes l'un des rares à me parler gentiment.",
		"greet_cold": "Laissez-moi, je vous prie.",
		"evasive": ["Je ne peux pas parler de ça. Pas ici.", "Les murs ont des oreilles, ici."],
		"unknown_line": "Je ne sais pas.",
		"barks": ["Il faut tenir bon.", "Respirez, tout va bien..."],
		"sad_lines": ["Je ne tiendrai pas longtemps, ici."],
		"rel": {}, "knows": {"gravity_midnight": 0.6, "asylum_patients": 0.0, "asylum_guru": 0.0, "asylum_key": 0.0}}))
	return out
