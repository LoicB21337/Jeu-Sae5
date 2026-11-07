extends StaticBody2D
class_name Gate

var open:= false

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var flag_id: String = ""

func _ready() -> void:
	animation_player.play("close")

func open_gate(flag: String):
	open = true
	animation_player.play("open")

func close_gate(flag: String):
	open = false
	animation_player.play("close")

func switch_gate(flag: String, enabled: bool):
	if flag != flag_id:
		return
	if enabled:
		open_gate(flag)
	else:
		close_gate(flag)
	
