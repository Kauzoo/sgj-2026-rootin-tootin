extends Node2D

var qte_amount = 2
var cleared_QTE = 0
@export var QTENode: PackedScene

func _ready():
	var instance
	for i in range(qte_amount):
		instance = QTENode.instantiate()
		add_child(instance)

func keyPressed():
	print("KEY GOT PRESSED!!!")

