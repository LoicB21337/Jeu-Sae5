extends SceneTree
# Serveur dédié basique (Godot 4.x)
# Lancement : godot --headless -s server.gd
# Ou avec un port personnalisé : godot --headless -s server.gd -- --port=9000

const DEFAULT_PORT := 3000
const MAX_CLIENTS := 2

var players: Array[int] = []


func _initialize() -> void:
	var port := _get_port()

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_error("Impossible de démarrer le serveur sur le port %d (erreur %d)" % [port, err])
		quit(1)
		return

	# Un script qui étend SceneTree n'a pas de propriété "multiplayer"
	# (elle existe seulement sur Node) : on passe par get_multiplayer().
	var mp := get_multiplayer()
	mp.multiplayer_peer = peer
	mp.peer_connected.connect(_on_peer_connected)
	mp.peer_disconnected.connect(_on_peer_disconnected)

	print("Serveur démarré sur le port %d (max %d joueurs)" % [port, MAX_CLIENTS])

	# Charge la map si elle existe (même scène que chez les clients)
	if ResourceLoader.exists("res://Scenes/world.tscn"):
		var game: Node = load("res://Scenes/world.tscn").instantiate()
		root.add_child(game)
		print("Scène Game.tscn chargée")
	else:
		print("Game.tscn introuvable : le serveur gère uniquement les connexions")


func _on_peer_connected(id: int) -> void:
	players.append(id)
	print("Joueur connecté : %d (%d/%d)" % [id, players.size(), MAX_CLIENTS])


func _on_peer_disconnected(id: int) -> void:
	players.erase(id)
	print("Joueur déconnecté : %d (%d/%d)" % [id, players.size(), MAX_CLIENTS])


func _get_port() -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--port="):
			return int(arg.get_slice("=", 1))
	return DEFAULT_PORT
