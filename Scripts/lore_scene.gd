class_name LoreScene extends Node2D

signal go_to_game()

func _ready():
	go_to_game.emit()
