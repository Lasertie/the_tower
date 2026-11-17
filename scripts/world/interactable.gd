## Objet ou PNJ avec lequel le joueur interagit (touche E).
class_name Interactable
extends Area3D

signal interacted(player: Player)

@export var prompt := "Interagir"
@export var one_shot := true
@export var radius := 0.8
@export var title := ""  ## nom flottant (PNJ)
@export var title_height := 2.3

var used := false

func _ready() -> void:
	add_to_group("interactable")
	if get_child_count() == 0:
		var cs := CollisionShape3D.new()
		var sp := SphereShape3D.new()
		sp.radius = radius
		cs.shape = sp
		add_child(cs)
	if title != "":
		var l := Label3D.new()
		l.text = title
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.no_depth_test = false
		l.font = UiTheme.font()
		l.font_size = 48
		l.pixel_size = 0.006
		l.outline_size = 12
		l.modulate = Color(1, 0.95, 0.75)
		l.position = Vector3(0, title_height, 0)
		add_child(l)

func is_available() -> bool:
	return not used

func interact(player: Player) -> void:
	if used:
		return
	if one_shot:
		used = true
	interacted.emit(player)
