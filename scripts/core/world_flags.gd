## Mémoire de la Tour : flags persistants entre les étages (autoload "WorldFlags").
extends Node

signal flag_changed(key: StringName, value: Variant)

const DEFAULTS := {
	&"healed_asylum_patients": false,
	&"killed_asylum_guru": false,
	&"used_forgotten_door": false,
	&"killed_elf_queen": false,
	&"stole_pirate_treasure": false,
	&"current_floor_chaos_level": 0,
}

var _flags: Dictionary = DEFAULTS.duplicate()

func get_flag(key: StringName, fallback: Variant = null) -> Variant:
	return _flags.get(key, fallback)

func set_flag(key: StringName, value: Variant) -> void:
	if _flags.get(key) == value:
		return
	_flags[key] = value
	flag_changed.emit(key, value)

func add_chaos(amount: int) -> void:
	set_flag(&"current_floor_chaos_level", int(get_flag(&"current_floor_chaos_level", 0)) + amount)

## Applique un lot de changements {flag: valeur}.
func apply(changes: Dictionary) -> void:
	for k in changes:
		set_flag(StringName(k), changes[k])

## Vrai si tous les flags requis ont la valeur attendue.
func matches(required: Dictionary) -> bool:
	for k in required:
		if _flags.get(StringName(k)) != required[k]:
			return false
	return true

const MEMORY_TEXT := {
	&"killed_asylum_guru": "Vous avez tué le Gourou de l'Asile. Ses cauchemars suivent votre ascension.",
	&"healed_asylum_patients": "Vous avez soigné les patients de l'Asile. Ils se souviennent de vous.",
	&"used_forgotten_door": "Vous avez franchi la Porte des Oubliés. Quelque chose vous a suivi.",
	&"killed_elf_queen": "Vous avez tué la Reine des Elfes.",
	&"stole_pirate_treasure": "Vous avez volé le trésor des pirates.",
}

## Ce dont « la Tour se souvient », en phrases pour le journal.
func memories() -> Array:
	var out: Array = []
	for k in MEMORY_TEXT:
		if _flags.get(k, false):
			out.append(MEMORY_TEXT[k])
	return out

func reset() -> void:
	_flags = DEFAULTS.duplicate()

func to_dict() -> Dictionary:
	var out := {}
	for k in _flags:
		out[String(k)] = _flags[k]
	return out

func from_dict(data: Dictionary) -> void:
	reset()
	for k in data:
		_flags[StringName(k)] = data[k]
