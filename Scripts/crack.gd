class_name Crack extends Node2D

@export var available_monsters: Array[PackedScene]

signal kill()
signal damage()

func _ready():
	$SpawnTimer.timeout.connect(_on_spawn_time)

func _on_spawn_time():
	var instance: Node = available_monsters[randi_range(0, available_monsters.size() - 1)].instantiate()
	instance.enemy_killed.connect(_on_monster_killed)
	instance.do_damage.connect(_on_monster_hit)
	add_child(instance)

func _on_monster_hit():
	damage.emit()

func _on_monster_killed():
	kill.emit()
	$SpawnTimer.start()
