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

func switch_gate(flag: String):
	if open:
		close_gate(flag)
	else:
		open_gate(flag)
	
