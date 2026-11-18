extends Control
# Écran de sélection : il ne charge aucun niveau, il choisit juste un index
# et le confie à Session avant d'ouvrir level.tscn.

# Noms des mondes affichés dans le message d'aide du bas.
const WORLD_NAMES := ["Monde 1", "Monde 2"]

# Miniatures provisoires : remplace les chemins par tes vraies captures de niveaux.
# Un chemin par case de la grille (6 cases = 6 niveaux).
const LEVEL_TEXTURES := [
	"res://Assets/bg1/bg1arbres.png",
	"res://Assets/bg1/bg1arbres.png",
	"res://Assets/bg1/bg1arbres.png",
	"res://Assets/bg1/bg1arbres.png",
	"res://Assets/bg1/bg1arbres.png",
	"res://Assets/bg1/bg1arbres.png",
]

# Onglet actuellement actif dans la barre du haut (0 ou 1).
var current_world: int = 0

# Case actuellement sélectionnée dans la grille (0 à 5).
var current_level: int = 0

# Les deux boutons de la barre des mondes.
@onready var world1: Button = $Main/WorldBar/WorldTabs/World1
@onready var world2: Button = $Main/WorldBar/WorldTabs/World2

# Les 6 cartes de la grille, dans l'ordre (ligne 1 puis ligne 2).
@onready var level_buttons: Array[TextureButton] = [
	$Main/GridCenter/Grid/Level1,
	$Main/GridCenter/Grid/Level2,
	$Main/GridCenter/Grid/Level3,
	$Main/GridCenter/Grid/Level4,
	$Main/GridCenter/Grid/Level5,
	$Main/GridCenter/Grid/Level6,
]

# Les textes "Niveau X" affichés à l'intérieur des cartes.
@onready var level_labels: Array[Label] = [
	$Main/GridCenter/Grid/Level1/Label,
	$Main/GridCenter/Grid/Level2/Label,
	$Main/GridCenter/Grid/Level3/Label,
	$Main/GridCenter/Grid/Level4/Label,
	$Main/GridCenter/Grid/Level5/Label,
	$Main/GridCenter/Grid/Level6/Label,
]

# Message d'aide en bas de l'écran (verrous, instruction...).
@onready var hint: Label = $Main/Bottom/Hint

# Bouton qui lance la partie : c'est lui qui ouvre level.tscn.
@onready var launch: Button = $Main/Bottom/Launch


# Branche les clics et applique l'affichage initial quand l'écran démarre.
func _ready() -> void:
	# Cliquer un onglet change de monde et revient au niveau 1.
	world1.pressed.connect(func(): select_world(0))
	world2.pressed.connect(func(): select_world(1))

	for i in level_buttons.size():
		var index: int = i  # Copie de i : sinon les 6 lambdas partageraient la dernière valeur.
		level_buttons[i].pressed.connect(func(): select_level(index))
		level_buttons[i].texture_normal = load(LEVEL_TEXTURES[i])

	launch.pressed.connect(on_launch_pressed)
	$Main/Bottom/Back.pressed.connect(on_back_pressed)

	refresh()


# Change de monde (0 ou 1) et sélectionne le premier niveau par défaut.
func select_world(world: int) -> void:
	current_world = world
	current_level = 0
	refresh()


# Sélectionne une case de la grille (0 à 5) et la fait apparaître en blanc.
# Note : cliquer une carte ne lance pas le jeu, il faut ensuite cliquer Lancer.
func select_level(level: int) -> void:
	current_level = level
	refresh()


# Redessine tout l'écran : verrous, couleurs, textes et bouton Lancer.
func refresh() -> void:
	var world2_open: bool = Session.is_world_unlocked(1)  # Demande la règle à Session.
	world2.disabled = not world2_open
	world2.text = "Monde 2" if world2_open else "Monde 2 (verr.)"

	# L'onglet actif est blanc, l'autre est grisé.
	world1.modulate = Color.WHITE if current_world == 0 else Color(0.6, 0.6, 0.6)
	world2.modulate = Color.WHITE if current_world == 1 else Color(0.6, 0.6, 0.6)

	for i in level_buttons.size():
		var open: bool = Session.is_level_unlocked(current_world, i)  # Cette case est-elle débloquée ?
		var button: TextureButton = level_buttons[i]  # La carte en cours de mise à jour.

		button.disabled = not open
		if i == current_level:
			button.modulate = Color.WHITE  # Carte choisie.
		elif open:
			button.modulate = Color(0.78, 0.78, 0.78)  # Carte disponible.
		else:
			button.modulate = Color(0.38, 0.38, 0.38)  # Carte verrouillée.

		level_labels[i].text = "Niveau %d" % (i + 1) if open else "Niveau %d (verr.)" % (i + 1)

	launch.disabled = not Session.is_level_unlocked(current_world, current_level)

	# Message d'aide adapté à la situation.
	if not Session.is_world_unlocked(current_world):
		hint.text = "Termine tous les niveaux du monde précédent."
	elif current_world == 0 and not Session.is_level_unlocked(0, 1):
		hint.text = "Termine le niveau 1 pour débloquer le niveau 2."
	else:
		hint.text = "Choisis un niveau de %s." % WORLD_NAMES[current_world]


# Étape 1 : écrire le choix dans Session. Étape 2 : ouvrir level.tscn.
# Session n'ouvre rien : c'est get_tree() qui change de scène.
func on_launch_pressed() -> void:
	Session.selected_world = current_world
	Session.selected_level = current_level
	# TODO backend : envoyer le choix au serveur
	# Session.request_level.rpc_id(1, current_world, current_level)
	get_tree().change_scene_to_file("res://Scenes/level.tscn")


# Bouton Retour : à brancher plus tard sur le menu principal / waiting menu.
func on_back_pressed() -> void:
	print("Retour")
