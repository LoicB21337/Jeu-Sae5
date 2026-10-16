extends Control

const SERVER_IP := "127.0.0.1"  # IP du serveur dédié plus tard
const SERVER_PORT := 7777
@onready var play: Button = $HBoxContainer/VBoxContainer/play


func _on_connected() -> void:
	get_tree().change_scene_to_file("res://Scenes/world.tscn")

func _on_failed() -> void:
	print("Connexion échouée")
	play.disabled = false


func _on_play_pressed() -> void:
	# Évite de se connecter deux fois si on clique plusieurs fois
	play.disabled = true  # adapte le chemin vers ton bouton

	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(SERVER_IP, SERVER_PORT)
	if err != OK:
		push_error("Impossible de créer le client (erreur %d)" % err)
		$BoutonJouer.disabled = false
		return
	multiplayer.multiplayer_peer = peer


func _on_quit_pressed() -> void:
	get_tree().quit()
