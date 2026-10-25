extends CanvasLayer

@onready var code: Label = $CenterContainer/VBoxContainer/code

func _ready() -> void:
	code.text = Session.room_code

func _on_resume_pressed() -> void:
	visible = false


func _on_setting_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
