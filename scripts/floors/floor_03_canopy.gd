## Étage 3 — La Canopée. Montre la propagation des flags de l'étage 2.
class_name Floor03Canopy
extends FloorController

var enemy_aggro_multiplier := 1.0
var hallucinations := false

func _init() -> void:
	floor_number = 3

func _apply_world_consequences() -> void:
	# Tuer le Gourou → cauchemars : ennemis plus agressifs
	if WorldFlags.get_flag(&"killed_asylum_guru", false):
		enemy_aggro_multiplier = 1.5
	# Porte des Oubliés → malus de folie permanent
	hallucinations = WorldFlags.get_flag(&"used_forgotten_door", false)
