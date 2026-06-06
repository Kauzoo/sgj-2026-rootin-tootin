extends Node2D

@export var Start_Scene: PackedScene
@export var Game_Scene: PackedScene
@export var Game_Over_Animation_Scene: PackedScene
@export var Game_Over_Scene: PackedScene

var current_scene: Node
var score: int = 0

func _ready():
	var instance: Node = Game_Scene.instantiate()
	instance.game_over.connect(_on_game_over)
	current_scene = instance
	add_child(instance)

func _on_game_over(achieved_score):
	score = achieved_score
	remove_child(current_scene)
	current_scene.queue_free()

	var instance: Node = Game_Over_Scene.instantiate()
	current_scene = instance
	instance.score = score
	add_child(instance)
