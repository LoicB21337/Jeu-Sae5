extends CanvasLayer

@onready var code: Label = $CenterContainer/VBoxContainer/code
@onready var resume: Button = $CenterContainer/VBoxContainer/resume

func _ready() -> void:
	visible = false
	code.text = Session.room_code


func _on_resume_pressed() -> void:
	visible = false
	get_parent().paused = false


func _on_setting_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_visibility_changed() -> void:
	if visible:
		resume.grab_focus()
