class_name Endscreen extends Node2D

@export var scoreboard: PackedScene

var score: int

func _ready():
	$NameMenu.set_score(score)
	$NameMenu.name_entered.connect(_on_name_entered)

func _on_name_entered():
	var menu = $NameMenu
	remove_child(menu)
	menu.queue_free()

	var instance: Node = scoreboard.instantiate()
	add_child(instance)
