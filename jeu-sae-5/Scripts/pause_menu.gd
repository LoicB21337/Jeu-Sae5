extends CanvasLayer


func _on_resume_pressed() -> void:
	Engine.time_scale = 1
	visible = false


func _on_setting_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
