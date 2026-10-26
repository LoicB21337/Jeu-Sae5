extends Area2D

@onready var timer: Timer = $Timer
@onready var players: Node2D = $"../Players"
@onready var world: Node2D = $".."

signal respawn_prop(prop: Node2D)

var player

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player = body
		timer.start()
	elif body is RigidBody2D and multiplayer.is_server():
		body.queue_free()
		respawn_prop.emit(body)


func _on_timer_timeout() -> void:
	player.position = players.position
