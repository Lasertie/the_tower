## Sauvegarde JSON (autoload "SaveSystem") : monde (Tour) + flags + scénarios + horloge + lois.
extends Node

const VERSION := 3

var pending: Dictionary = {}  ## état à appliquer au prochain chargement de la Tour

func _path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot

func has_save(slot: int = 1) -> bool:
	return FileAccess.file_exists(_path(slot))

func new_game() -> void:
	WorldFlags.reset()
	GameClock.reset()
	LawSystem.reset()
	ScenarioManager.reset()
	Society.new_game()
	pending = {}

func save_game(slot: int, world_data: Dictionary) -> Error:
	var payload := {
		"version": VERSION,
		"world": world_data,
		"flags": WorldFlags.to_dict(),
		"scenarios": ScenarioManager.to_dict(),
		"clock": GameClock.to_dict(),
		"laws": LawSystem.to_dict(),
		"society": Society.to_dict(),
	}
	var f := FileAccess.open(_path(slot), FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(JSON.stringify(payload, "\t"))
	return OK

## Restaure flags, scénarios, horloge et lois ; retourne l'état du monde ({} si échec).
func load_game(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_path(slot)))
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) != VERSION:
		return {}
	ScenarioManager.reset()
	WorldFlags.from_dict(parsed.get("flags", {}))
	ScenarioManager.from_dict(parsed.get("scenarios", {}))
	GameClock.from_dict(parsed.get("clock", {}))
	LawSystem.from_dict(parsed.get("laws", {}))
	Society.from_dict(parsed.get("society", {}))
	return parsed.get("world", {})

func take_pending() -> Dictionary:
	var p := pending
	pending = {}
	return p
