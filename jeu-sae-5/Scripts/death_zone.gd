extends Area2D

@onready var timer: Timer = $Timer
@onready var players: Node2D = $"../Players"

var player

func _on_body_entered(body: Node2D) -> void:
	player = body
	Engine.time_scale=0.5
	timer.start()


func _on_timer_timeout() -> void:
	Engine.time_scale=1.0
	player.position = players.position
