extends Control

const LOBBY_URL := "http://10.97.0.28:3000"  # IP de la VM "jeu" (affichée par deploy.sh)

@onready var play: Button = $HBoxContainer/VBoxContainer/play
@onready var join: Button = $HBoxContainer/VBoxContainer/join
@onready var code_input: LineEdit = $HBoxContainer/VBoxContainer/code_input
@onready var status: Label = $HBoxContainer/VBoxContainer/status
@onready var http: HTTPRequest = $HTTPRequest


func _ready() -> void:
	# On connecte les signaux une seule fois (et pas à chaque clic)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	http.request_completed.connect(_on_room_response)


func _on_play_pressed() -> void:
	_set_busy(true, "Création de la salle…")
	http.request(LOBBY_URL + "/rooms", ["Content-Type: application/json"], HTTPClient.METHOD_POST, "{}")


func _on_join_pressed() -> void:
	var code := code_input.text.strip_edges().to_upper()
	if code.is_empty():
		status.text = "Saisis un code de salle."
		return
	_set_busy(true, "Connexion à la salle %s…" % code)
	http.request(LOBBY_URL + "/rooms/%s/join" % code, ["Content-Type: application/json"], HTTPClient.METHOD_POST, "{}")


func _on_room_response(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		_fail("Serveur de lobby injoignable.")
		return
	var data = JSON.parse_string(body.get_string_from_utf8())
	if response_code != 200 or typeof(data) != TYPE_DICTIONARY:
		var reason := "erreur %d" % response_code
		if typeof(data) == TYPE_DICTIONARY and data.has("error"):
			reason = str(data["error"])
		_fail("Impossible de rejoindre : %s" % reason)
		return
	Session.room_code = data["code"]
	status.text = "Salle %s : connexion au serveur de jeu…" % data["code"]
	_connect_enet(str(data["host"]), int(data["port"]))


func _connect_enet(host: String, port: int) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(host, port)
	if err != OK:
		_fail("Impossible de créer le client (erreur %d)." % err)
		return
	multiplayer.multiplayer_peer = peer


func _on_connected() -> void:
	# A CHANGER !!!!
	get_tree().change_scene_to_file("res://Scenes/world.tscn")


func _on_failed() -> void:
	_fail("Connexion au serveur de jeu échouée.")


func _fail(message: String) -> void:
	push_warning(message)
	_set_busy(false, message)


func _set_busy(busy: bool, message: String) -> void:
	play.disabled = busy
	join.disabled = busy
	status.text = message


func _on_quit_pressed() -> void:
	get_tree().quit()
