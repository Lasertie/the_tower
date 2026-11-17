## Modèle animé (idle / walk / jump) pour le joueur, les PNJ et les ennemis.
class_name CharacterModel
extends Node3D

var anim: AnimationPlayer
var _current := &""

func setup(key := "character", height := 1.8) -> CharacterModel:
	var w := Assets.place(key, height)
	add_child(w)
	for ap in w.find_children("*", "AnimationPlayer", true, false):
		anim = ap
		break
	if anim:
		for n in anim.get_animation_list():
			var a := anim.get_animation(n)
			if a and n in ["idle", "walk"]:
				a.loop_mode = Animation.LOOP_LINEAR
	return self

func tint(color: Color) -> void:
	Assets.tint(self, color)

func play(name: StringName) -> void:
	if anim and name != _current and anim.has_animation(name):
		_current = name
		anim.play(name, 0.15)
