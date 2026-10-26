extends Node
# À attacher au nœud racine de Main.tscn (scène de démarrage du client)

const SERVER_IP := "127.0.0.1"  # remplace par l'IP de ton serveur dédié
const SERVER_PORT := 7777


func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(SERVER_IP, SERVER_PORT)
	if err != OK:
		push_error("Impossible de créer le client (erreur %d)" % err)
		return
	multiplayer.multiplayer_peer = peer


func _on_connected() -> void:
	print("Connecté au serveur ! Mon id : ", multiplayer.get_unique_id())
	get_tree().change_scene_to_file("res://Scenes/world.tscn")


func _on_failed() -> void:
	print("Connexion échouée")


func _on_server_disconnected() -> void:
	print("Serveur déconnecté")
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
