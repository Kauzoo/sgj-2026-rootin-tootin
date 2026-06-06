class_name GameScene extends Node2D

@export var health: int

var kills: int = 0

signal game_over(score)

func _ready():
	for child in get_children():
		if child is Crack:
			child.kill.connect(_on_enemy_kill)
			child.damage.connect(_on_do_damage)
	$HelthLabel.text = "DOOR HELTH: " + String.num_uint64(health)

func _on_enemy_kill():
	kills += 1

func _on_do_damage():
	if health <= 1 :
		doGameOver()
		return

	health -= 1
	$HelthLabel.text = "DOOR HELTH: " + String.num_uint64(health)

func doGameOver():
	game_over.emit(kills)
