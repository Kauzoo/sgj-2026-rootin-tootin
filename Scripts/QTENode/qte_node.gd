extends Node2D

var key = randi_range(0x41, 0x5A)

func _input(event):
	if event is InputEventKey:
		if event.pressed and event.key_label == key:
			var parent = get_parent()
			if parent.has_method("keyPressed"):
				parent.keyPressed()
				queue_free()
				return
			print("QTE didnt find keyPressed Method")
			queue_free()
