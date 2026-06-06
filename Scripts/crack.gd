class_name Crack extends Node2D

@export var available_monsters: Array[PackedScene]

signal kill()
signal damage()

var has_active_monster: bool = false

func _ready():
	$SpawnTimer.stop() # Explicitly disable the local timer if it tries to run

func spawn_monster():
	if has_active_monster:
		return
	
	var monster_scene = DifficultyDirector.get_enemy_scene(available_monsters)
	if monster_scene != null:
		has_active_monster = true
		var instance: Node = monster_scene.instantiate()
		instance.enemy_killed.connect(_on_monster_killed)
		instance.do_damage.connect(_on_monster_hit)
		add_child(instance)

func _on_monster_hit():
	damage.emit()

func _on_monster_killed():
	has_active_monster = false
	kill.emit()
