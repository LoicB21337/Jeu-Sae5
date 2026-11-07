extends StaticBody2D
class_name Gate

var open:= false

@onready var animation_player: AnimationPlayer = $AnimationPlayer

@export var flag_id: String = ""

func _ready() -> void:
	animation_player.play("close")

func open_gate():
	open = true
	animation_player.play("open")

func close_gate():
	open = false
	animation_player.play("close")

func switch_gate(flag: String):
	if flag != flag_id:
		return
	if not open:
		open_gate()
	else:
		close_gate()
	
