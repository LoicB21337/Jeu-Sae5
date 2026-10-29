extends Control

const PORT := 7777
const MAX_CLIENTS := 2

@onready var play: Button = $HBoxContainer/VBoxContainer/play
@onready var join: Button = $HBoxContainer/VBoxContainer/join
@onready var code_input: LineEdit = $HBoxContainer/VBoxContainer/code_input
@onready var status: Label = $HBoxContainer/VBoxContainer/status


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	if not play.pressed.is_connected(_on_play_pressed):
		play.pressed.connect(_on_play_pressed)
	if not join.pressed.is_connected(_on_join_pressed):
		join.pressed.connect(_on_join_pressed)
	status.text = "Local test : Créer (host) ou Rejoindre (127.0.0.1:%d)" % PORT


func _on_play_pressed() -> void:
	_set_busy(true, "Création du serveur local...")
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		_fail("Impossible de créer le serveur (erreur %d)" % err)
		return
	multiplayer.multiplayer_peer = peer
	status.text = "Serveur lancé sur le port %d. Chargement du niveau..." % PORT
	get_tree().change_scene_to_file("res://Scenes/world.tscn")


func _on_join_pressed() -> void:
	_set_busy(true, "Connexion au serveur local...")
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client("127.0.0.1", PORT)
	if err != OK:
		_fail("Impossible de se connecter (erreur %d)" % err)
		return
	multiplayer.multiplayer_peer = peer
	status.text = "Connexion en cours..."


func _on_connected() -> void:
	get_tree().change_scene_to_file("res://Scenes/world.tscn")


func _on_failed() -> void:
	_fail("Connexion échouée. Lance d'abord \"Créer une partie\" sur une autre instance.")


func _fail(message: String) -> void:
	push_warning(message)
	_set_busy(false, message)


func _set_busy(busy: bool, message: String) -> void:
	play.disabled = busy
	join.disabled = busy
	status.text = message


func _on_quit_pressed() -> void:
	get_tree().quit()
