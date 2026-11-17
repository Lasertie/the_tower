## Une manière de résoudre un scénario (combat, soin, infiltration, exploit...).
class_name WinCondition
extends Resource

@export var id: StringName
@export_multiline var description := ""
@export_multiline var clue := ""        ## entrée du journal une fois la piste découverte
@export var target := 1                 ## ex: 10 patients à soigner
@export var hidden := false             ## faille : jamais annoncée, découverte en la trouvant
@export var sets_flags: Dictionary = {}
@export var chaos_delta := 0

var progress := 0
var discovered := false

func is_met() -> bool:
	return progress >= target

func in_journal() -> bool:
	return discovered or is_met()
