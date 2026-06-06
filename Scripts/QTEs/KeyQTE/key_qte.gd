class_name KeyQTE extends QTEBase

var key: int = randi_range(0x41, 0x5A)

func _ready():
	$FailTimer.timeout.connect(_on_timeout)

func _on_timeout():
	QTE_failed.emit(position)
	queue_free()


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.key_label == key:
			# set pressed to false so it cant remove another input query for the same key
			# idk if this has bad consequences but it seems to work :P
			event.pressed = false

			QTE_succeded.emit(position)
			queue_free()
