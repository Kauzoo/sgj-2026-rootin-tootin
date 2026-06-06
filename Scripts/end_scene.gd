class_name EndScene extends Node2D

signal go_to_lb()

func _ready():
	go_to_lb.emit()

