## Un verrou d'un Sceau. Chaque type teste une condition différente sur le SealContext.
## Un Sceau a plusieurs verrous de natures différentes : aucun verrou seul ne suffit.
class_name Lock
extends Resource

enum Type {
	CONSENT,   ## Accord de la société (confiance + absence de rancune)
	MERIT,     ## Preuve d'une épreuve accomplie (flag ou compteur)
	WATCH,     ## Absence de surveillance dans la zone du Sceau
	ITEM,      ## Possession d'un objet spécifique
	STATE,     ## État du monde (flag WorldFlags)
	OFFERING,  ## Dépôt d'un objet au Sceau
}

@export var id: StringName
@export var type: Type = Type.CONSENT
@export var glyph: StringName = &""    ## identifiant du glyphe sur le pilier (cosmétique)

## Paramètres selon le type :
## CONSENT  : { "person": StringName, "min_trust": float, "no_grudge": Array[StringName] }
## MERIT    : { "flags": Array[StringName] }   (AU MOINS UN doit être vrai)
## WATCH    : { "radius": float }
## ITEM     : { "item": StringName }
## STATE    : { "flag": StringName, "value": Variant }
## OFFERING : { "item": StringName }
@export var params: Dictionary = {}

## Évalue le verrou sur un SealContext. Retourne true si le verrou est satisfait.
func evaluate(ctx: SealContext) -> bool:
	match type:
		Type.CONSENT:
			return _eval_consent(ctx)
		Type.MERIT:
			return _eval_merit(ctx)
		Type.WATCH:
			return _eval_watch(ctx)
		Type.ITEM:
			return _eval_item(ctx)
		Type.STATE:
			return _eval_state(ctx)
		Type.OFFERING:
			return _eval_offering(ctx)
	return false

func _eval_consent(ctx: SealContext) -> bool:
	var pid: StringName = params.get("person", &"")
	var min_trust: float = float(params.get("min_trust", 0.0))
	if pid == &"" or not Society.persons.has(pid):
		return false
	if Society.person(pid).trust < min_trust:
		return false
	var no_grudge: Array = params.get("no_grudge", [])
	for other in no_grudge:
		if Society.persons.has(StringName(other)) and Society.person(StringName(other)).trust < -15.0:
			return false
	return true

func _eval_merit(ctx: SealContext) -> bool:
	var flags: Array = params.get("flags", [])
	for f in flags:
		if ctx.has_flag(StringName(f)):
			return true
	return false

func _eval_watch(ctx: SealContext) -> bool:
	var radius: float = float(params.get("radius", 14.0))
	return ctx.watchers_near(radius) == 0

func _eval_item(ctx: SealContext) -> bool:
	var item: StringName = StringName(params.get("item", ""))
	return ctx.has_item(item)

func _eval_state(ctx: SealContext) -> bool:
	var flag: StringName = StringName(params.get("flag", ""))
	var expected: Variant = params.get("value", true)
	return WorldFlags.get_flag(flag) == expected

func _eval_offering(ctx: SealContext) -> bool:
	# Pour l'instant : même logique que ITEM (l'objet est « offert » au moment du contact)
	var item: StringName = StringName(params.get("item", ""))
	return ctx.has_item(item)
