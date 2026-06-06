extends Node2D

@export var animatedSprite : AnimatedSprite2D

func _ready():
	await get_tree().create_timer(5.0).timeout
	get_tree().change_scene_to_file("res://Scenes/leaderboard_scene.tscn")
	pass
