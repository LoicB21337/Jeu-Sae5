extends Node

# ---------------------------------------------------------------------------
# Session est un "autoload" : créé au lancement du jeu, il n'est jamais détruit
# quand on change de scène. C'est le carnet commun au menu, à la sélection,
# au niveau et (plus tard) au serveur.
# ---------------------------------------------------------------------------

# Code de la salle reçu du lobby. Déjà présent avant notre travail :
# main_menu.gd l'écrit, pause_menu.gd l'affiche pour le bouton "Copier".
var room_code: String

# Monde choisi dans la barre du haut (0 = Monde 1, 1 = Monde 2).
# Écrit par le bouton Lancer, lu par level.gd au démarrage.
var selected_world: int = 0

# Niveau choisi dans la grille (0 = première case, 5 = sixième case).
# Écrit par le bouton Lancer, lu par level.gd au démarrage.
var selected_level: int = 0

# Progression en mémoire pour l'instant (à sauvegarder côté serveur plus tard).
const WORLD_COUNT := 2

# Nombre de cartes par monde : sert de référence pour la progression.
const LEVELS_PER_WORLD := 6

# Quels niveaux sont terminés : clé = monde, valeur = 6 booléens.
var completed: Dictionary = {
	0: [false, false, false, false, false, false],
	1: [false, false, false, false, false, false],
}


# Le Monde 1 est toujours ouvert ; les suivants s'ouvrent quand tous les
# niveaux du monde précédent sont terminés.
func is_world_unlocked(world: int) -> bool:
	if world == 0:
		return true
	for done in completed[world - 1]:  # done = ce niveau est-il terminé ?
		if not done:
			return false
	return true


# Le niveau 1 est toujours ouvert ; le niveau N s'ouvre quand N-1 est terminé.
func is_level_unlocked(world: int, level: int) -> bool:
	if not is_world_unlocked(world):
		return false
	if level == 0:
		return true
	return completed[world][level - 1]


# Marque un niveau comme terminé (à appeler quand le portail de fin est atteint).
func mark_completed(world: int, level: int) -> void:
	completed[world][level] = true


# Renvoie la liste des niveaux terminés d'un monde, utile à l'affichage.
func get_completed_levels(world: int) -> Array:
	return completed[world]
