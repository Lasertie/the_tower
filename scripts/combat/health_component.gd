class_name HealthComponent
extends Node

signal damaged(amount: float, source: Node)
signal died(source: Node)

@export var max_health := 100.0
var health := 100.0
var dead := false

func _ready() -> void:
	health = max_health

func take_damage(amount: float, source: Node = null) -> void:
	if dead:
		return
	health = maxf(health - amount, 0.0)
	damaged.emit(amount, source)
	if health <= 0.0:
		dead = true
		died.emit(source)

func heal(amount: float) -> void:
	if not dead:
		health = minf(health + amount, max_health)
