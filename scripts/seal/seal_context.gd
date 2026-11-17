## Contexte snapshot pour évaluer un Sceau : regroupe l'état du joueur, de la société,
## des lois et des flags au moment où le héros touche le Sceau.
class_name SealContext
extends RefCounted

var _player: Player
var _floor_number: int
var _seal_pos: Vector3

func _init(player: Player, floor_number: int, seal_pos: Vector3) -> void:
	_player = player
	_floor_number = floor_number
	_seal_pos = seal_pos

# ---- Joueur ----

func has_item(item: StringName) -> bool:
	return _player != null and _player.has_item(item)

func player_madness() -> float:
	return _player.madness if _player != null else 0.0

# ---- Surveillance ----

## Nombre de sentinelles éveillées dans un rayon autour du Sceau.
func watchers_near(radius: float) -> int:
	return LawSystem.watchers_near(_seal_pos, radius)

## Vrai si une personne précise est dans le rayon du Sceau (elle « se tient là »).
func person_near(pid: StringName, radius: float) -> bool:
	for n in _player.get_tree().get_nodes_in_group("inhabitants"):
		if n.person_id == pid and n.global_position.distance_to(_seal_pos) <= radius:
			return true
	return false

# ---- Flags ----

## Vrai si un flag WorldFlags est posé et vrai (ou correspond à la valeur attendue).
func has_flag(key: StringName, expected: Variant = true) -> bool:
	return WorldFlags.get_flag(key) == expected

# ---- Société ----

func trust_of(pid: StringName) -> float:
	if not Society.persons.has(pid):
		return 0.0
	return Society.person(pid).trust
