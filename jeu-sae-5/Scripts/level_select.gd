extends Control

const WORLD_NAMES := ["Monde 1", "Monde 2"]

# Miniatures provisoires : remplace les chemins par tes vraies captures de niveaux.
const LEVEL_TEXTURES := [
	"res://Assets/bg1/bg1arbres.png",
	"res://Assets/bg1/bg1arbres.png",
	"res://Assets/bg1/bg1arbres.png",
	"res://Assets/bg1/bg1arbres.png",
	"res://Assets/bg1/bg1arbres.png",
	"res://Assets/bg1/bg1arbres.png",
]

var current_world: int = 0
var current_level: int = 0

@onready var world1: Button = $Main/WorldBar/WorldTabs/World1
@onready var world2: Button = $Main/WorldBar/WorldTabs/World2
@onready var level_buttons: Array[TextureButton] = [
	$Main/GridCenter/Grid/Level1,
	$Main/GridCenter/Grid/Level2,
	$Main/GridCenter/Grid/Level3,
	$Main/GridCenter/Grid/Level4,
	$Main/GridCenter/Grid/Level5,
	$Main/GridCenter/Grid/Level6,
]
@onready var level_labels: Array[Label] = [
	$Main/GridCenter/Grid/Level1/Label,
	$Main/GridCenter/Grid/Level2/Label,
	$Main/GridCenter/Grid/Level3/Label,
	$Main/GridCenter/Grid/Level4/Label,
	$Main/GridCenter/Grid/Level5/Label,
	$Main/GridCenter/Grid/Level6/Label,
]
@onready var hint: Label = $Main/Bottom/Hint
@onready var launch: Button = $Main/Bottom/Launch


func _ready() -> void:
	world1.pressed.connect(func(): select_world(0))
	world2.pressed.connect(func(): select_world(1))

	for i in level_buttons.size():
		var index: int = i
		level_buttons[i].pressed.connect(func(): select_level(index))
		level_buttons[i].texture_normal = load(LEVEL_TEXTURES[i])

	launch.pressed.connect(on_launch_pressed)
	$Main/Bottom/Back.pressed.connect(on_back_pressed)

	refresh()


func select_world(world: int) -> void:
	current_world = world
	current_level = 0
	refresh()


func select_level(level: int) -> void:
	current_level = level
	refresh()


func refresh() -> void:
	var world2_open: bool = Session.is_world_unlocked(1)
	world2.disabled = not world2_open
	world2.text = "Monde 2" if world2_open else "Monde 2 (verr.)"

	world1.modulate = Color.WHITE if current_world == 0 else Color(0.6, 0.6, 0.6)
	world2.modulate = Color.WHITE if current_world == 1 else Color(0.6, 0.6, 0.6)

	for i in level_buttons.size():
		var open: bool = Session.is_level_unlocked(current_world, i)
		var button: TextureButton = level_buttons[i]

		button.disabled = not open
		if i == current_level:
			button.modulate = Color.WHITE
		elif open:
			button.modulate = Color(0.78, 0.78, 0.78)
		else:
			button.modulate = Color(0.38, 0.38, 0.38)

		level_labels[i].text = "Niveau %d" % (i + 1) if open else "Niveau %d (verr.)" % (i + 1)

	launch.disabled = not Session.is_level_unlocked(current_world, current_level)

	if not Session.is_world_unlocked(current_world):
		hint.text = "Termine tous les niveaux du monde précédent."
	elif current_world == 0 and not Session.is_level_unlocked(0, 1):
		hint.text = "Termine le niveau 1 pour débloquer le niveau 2."
	else:
		hint.text = "Choisis un niveau de %s." % WORLD_NAMES[current_world]


func on_launch_pressed() -> void:
	Session.selected_world = current_world
	Session.selected_level = current_level
	# TODO backend : envoyer le choix au serveur
	# Session.request_level.rpc_id(1, current_world, current_level)
	get_tree().change_scene_to_file("res://Scenes/level.tscn")


func on_back_pressed() -> void:
	print("Retour")
