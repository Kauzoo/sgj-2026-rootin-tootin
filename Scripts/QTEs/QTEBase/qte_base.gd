class_name QTEBase extends Node2D

signal QTE_failed(pos)
signal QTE_succeded(pos)

func _ready():
	add_to_group("qte")
