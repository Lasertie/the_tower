## Loi immuable d'un étage. Les mêmes règles s'appliquent à TOUS les corps de l'étage
## (joueur, PNJ, monstres) : seule une faille personnelle (objet, heure, état) en exempte.
class_name FloorLaw
extends Resource

enum Effect { NONE, GRAVITY_INVERT, SEALED_EXIT }

@export var id: StringName
@export_multiline var description := ""     ## journal, une fois la loi observée
@export var effect: Effect = Effect.NONE
@export var active_hours := Vector2i(-1, -1)  ## (-1,-1) = toujours active
@export var exploits: Array[LawExploit] = []

func is_active(hour: int) -> bool:
	return LawExploit.hour_in(hour, active_hours)

## Retourne l'id de la première faille valide, ou &"" si la loi s'applique normalement.
func find_exploit(context: Dictionary) -> StringName:
	for e in exploits:
		if e.is_satisfied(context):
			return e.id
	return &""

func get_exploit(exploit_id: StringName) -> LawExploit:
	for e in exploits:
		if e.id == exploit_id:
			return e
	return null
