extends Node

var room_code: String

# Choix fait dans l'interface de sélection
var selected_world: int = 0
var selected_level: int = 0

# Progression (en mémoire pour l'instant)
const WORLD_COUNT := 2
const LEVELS_PER_WORLD := 6

var completed: Dictionary = {
	0: [false, false, false, false, false, false],
	1: [false, false, false, false, false, false],
}


func is_world_unlocked(world: int) -> bool:
	if world == 0:
		return true
	for done in completed[world - 1]:
		if not done:
			return false
	return true


func is_level_unlocked(world: int, level: int) -> bool:
	if not is_world_unlocked(world):
		return false
	if level == 0:
		return true
	return completed[world][level - 1]


func mark_completed(world: int, level: int) -> void:
	completed[world][level] = true


func get_completed_levels(world: int) -> Array:
	return completed[world]
