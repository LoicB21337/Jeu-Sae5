extends CanvasLayer


func _on_resume_pressed() -> void:
	get_tree().paused = false
	visible = false


func _on_setting_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause") and get_tree().paused == true:
		get_tree().paused = false
		hide()
	elif Input.is_action_just_pressed("pause") and get_tree().paused == false:
		get_tree().paused = true
		show()
