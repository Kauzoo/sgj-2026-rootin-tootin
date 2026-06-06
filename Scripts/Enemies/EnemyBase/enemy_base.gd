class_name EnemyBase extends Node2D


@export var start_qte: int
@export var QTE_Node: PackedScene
@export var spawn_locations: Array[Vector2]

var full_locations: Array[Vector2]

signal enemy_killed()
signal do_damage()

func _ready():
	$QTETimer.timeout.connect(spawn_qte)
	for i in range(start_qte):
		spawn_qte()

func spawn_qte():
	if spawn_locations.size() == 0:
		return

	var location_index: int = randi_range(0, spawn_locations.size() - 1)
	var instance = QTE_Node.instantiate()

	var location = spawn_locations[location_index]
	instance.position = location
	spawn_locations.erase(location)
	full_locations.append(location)
	instance.QTE_failed.connect(_on_QTE_failed)
	instance.QTE_succeded.connect(_on_QTE_succeded)
	add_child(instance)


func _on_QTE_succeded(pos):
	spawn_locations.append(pos)
	full_locations.erase(pos)
	if full_locations.size() == 0:
		enemy_killed.emit()
		queue_free()

func _on_QTE_failed(pos):
	spawn_locations.append(pos)
	full_locations.erase(pos)
	do_damage.emit()
	if full_locations.size() == 0:
		enemy_killed.emit()
		queue_free()
