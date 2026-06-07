class_name GameManager extends Node2D

@export var Main_Menu: PackedScene
@export var Lore_Scene: PackedScene
@export var Game_Scene: PackedScene
@export var End_Scene: PackedScene
@export var Leaderboard_Scene: PackedScene

var current_scene: Node
var score: int = 0

func _ready():
	var instance: Node = Main_Menu.instantiate()
	instance.go_to_lore.connect(_on_lore)
	current_scene = instance
	add_child(instance)

func _on_lore():
	remove_child(current_scene)
	current_scene.queue_free()

	var instance: Node = Lore_Scene.instantiate()
	current_scene = instance
	instance.go_to_game.connect(_on_game)
	add_child(instance)


func _on_game():
	$AudioStreamPlayer2D.play()

	remove_child(current_scene)
	current_scene.queue_free()

	var instance: Node = Game_Scene.instantiate()
	current_scene = instance
	instance.game_over.connect(_on_game_over)
	add_child(instance)


func _on_game_over(achieved_score):
	score = achieved_score
	remove_child(current_scene)
	current_scene.queue_free()

	var instance: Node = End_Scene.instantiate()
	current_scene = instance
	instance.go_to_lb.connect(_on_lb)
	add_child(instance)

func _on_lb():
	remove_child(current_scene)
	current_scene.queue_free()
	
	var instance: Node = Leaderboard_Scene.instantiate()
	current_scene = instance
	instance.score = score
	instance.go_to_menu.connect(_on_menu)
	add_child(instance)
	SoundManager.play_fireball_sound()

func _on_menu():
	remove_child(current_scene)
	current_scene.queue_free()

	var instance: Node = Main_Menu.instantiate()
	instance.go_to_lore.connect(_on_lore)
	current_scene = instance
	add_child(instance)
