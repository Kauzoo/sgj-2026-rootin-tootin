extends Node2D

@export var animatedSprite : AnimatedSprite2D

signal go_to_lb()

func _ready():
	await get_tree().create_timer(5.0).timeout
	go_to_lb.emit()
	pass
