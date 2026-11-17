## Le Sceau d'un étage : plusieurs verrous de natures différentes, groupés en routes.
## Une route = liste d'ids de verrous qui TOUS doivent être satisfaits pour ouvrir le Sceau.
## Il n'existe pas de route à un seul élément (invariant n°3 du projet).
##
## Usage :
##   var result := seal.evaluate(ctx)
##   result.open        -> bool
##   result.route       -> StringName  (id de la route utilisée, &"" si fermé)
##   result.satisfied   -> Dictionary  (lock_id -> bool)
class_name Seal
extends Resource

## Verrous disponibles (instances de Lock).
@export var locks: Array[Lock] = []

## Routes : chaque route est un Array de StringName (ids de verrous).
## Le Sceau s'ouvre si TOUS les verrous d'AU MOINS UNE route sont satisfaits.
## Contrainte : chaque route doit comporter ≥ 2 verrous.
@export var routes: Array = []   # Array[Array[StringName]]

## Marques posées par route : { route_index -> StringName (flag WorldFlags) }.
@export var route_marks: Dictionary = {}

## Évalue le Sceau dans le contexte donné.
## commit=false (défaut) : lecture pure, aucun effet de bord (safe pour les tests et _sync_seal).
## commit=true : pose les marques WorldFlags si une route est ouverte (réservé au franchissement réel).
## Retourne { open: bool, route: StringName, satisfied: {lock_id -> bool} }
func evaluate(ctx: SealContext, commit := false) -> Dictionary:
	# Évalue chaque verrou une seule fois
	var satisfied: Dictionary = {}
	for lock in locks:
		satisfied[String(lock.id)] = lock.evaluate(ctx)

	# Cherche une route entièrement satisfaite
	for i in routes.size():
		var route: Array = routes[i]
		var all_ok := true
		for lid in route:
			if not satisfied.get(String(lid), false):
				all_ok = false
				break
		if all_ok:
			if commit and route_marks.has(i):
				WorldFlags.set_flag(StringName(route_marks[i]), true)
			return {"open": true, "route": _route_name(i), "satisfied": satisfied}

	return {"open": false, "route": &"", "satisfied": satisfied}

## Id lisible de la route (pour les marques WorldFlags et le journal).
func _route_name(i: int) -> StringName:
	return StringName("route_%d" % i)

## Retourne le Lock correspondant à cet id, ou null.
func get_lock(id: StringName) -> Lock:
	for l in locks:
		if l.id == id:
			return l
	return null
