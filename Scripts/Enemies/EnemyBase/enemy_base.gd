class_name EnemyBase extends Node2D

@export var start_qte: int
@export var QTE_Node: PackedScene
@export var spawn_locations: Array[Vector2]

var full_locations: Array[Vector2]
var qtes_left_to_spawn: int = 0

signal enemy_killed()
signal do_damage()

func _ready():
	var extra_qtes = DifficultyDirector.get_qte_complexity() - 3
	qtes_left_to_spawn = maxi(1, start_qte + extra_qtes)
	$QTETimer.timeout.connect(spawn_qte)
	spawn_qte()

func spawn_qte():
	if spawn_locations.size() == 0 or qtes_left_to_spawn <= 0:
		return

	qtes_left_to_spawn -= 1

	var location_index: int = randi_range(0, spawn_locations.size() - 1)
	var instance = QTE_Node.instantiate()

	var location = spawn_locations[location_index]
	instance.position = location
	spawn_locations.erase(location)
	full_locations.append(location)
	instance.QTE_failed.connect(_on_QTE_failed)
	instance.QTE_succeded.connect(_on_QTE_succeded)
	add_child(instance)

func _check_enemy_death():
	if full_locations.size() == 0 and qtes_left_to_spawn <= 0:
		enemy_killed.emit()
		queue_free()

func _on_QTE_succeded(pos):
	spawn_locations.append(pos)
	full_locations.erase(pos)
	_check_enemy_death()

func _on_QTE_failed(pos):
	spawn_locations.append(pos)
	full_locations.erase(pos)
	do_damage.emit()
	_check_enemy_death()
