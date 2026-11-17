## Horloge de la Tour (autoload "GameClock"). 1 seconde réelle = 1 minute de jeu par défaut.
## Une seule horloge pour tous les étages : le temps est une loi de la Tour.
extends Node

signal hour_changed(hour: int)

const START_MINUTES := 8.0 * 60.0

@export var time_scale := 1.0
var minutes := START_MINUTES
var day := 0  ## jours écoulés (varie le comportement des habitants d'un jour à l'autre)

func reset() -> void:
	minutes = START_MINUTES
	day = 0

func _process(delta: float) -> void:
	var before := get_hour()
	minutes += delta * time_scale
	_wrap()
	var now := get_hour()
	if now != before:
		hour_changed.emit(now)

func _wrap() -> void:
	while minutes >= 1440.0:
		minutes -= 1440.0
		day += 1

func advance(game_minutes: float) -> void:
	minutes += game_minutes
	_wrap()

func absolute_minutes() -> float:
	return day * 1440.0 + minutes

func get_hour() -> int:
	return int(minutes / 60.0) % 24

func get_hour_float() -> float:
	return minutes / 60.0

func clock_text() -> String:
	return "%02d:%02d" % [get_hour(), int(minutes) % 60]

## Couleur du « ciel » de la Tour : nuit, aube orangée, plein jour, crépuscule.
func sky_color() -> Color:
	var h := get_hour_float()
	var night := Color(0.02, 0.03, 0.10)
	var dawn := Color(0.95, 0.55, 0.30)
	var day := Color(0.55, 0.78, 0.98)
	var dusk := Color(0.85, 0.40, 0.35)
	if h < 4.0 or h >= 21.0: return night
	if h < 5.5: return night.lerp(dawn, (h - 4.0) / 1.5)
	if h < 8.0: return dawn.lerp(day, (h - 5.5) / 2.5)
	if h < 17.0: return day
	if h < 19.0: return day.lerp(dusk, (h - 17.0) / 2.0)
	return dusk.lerp(night, (h - 19.0) / 2.0)

func daylight() -> float:
	return clampf(sin((get_hour_float() - 6.0) / 12.0 * PI), 0.0, 1.0)

func to_dict() -> Dictionary:
	return {"minutes": minutes, "day": day}

func from_dict(d: Dictionary) -> void:
	minutes = float(d.get("minutes", START_MINUTES))
	day = int(d.get("day", 0))
