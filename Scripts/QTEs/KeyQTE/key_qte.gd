class_name KeyQTE extends QTEBase

var key: int = [KEY_W, KEY_A, KEY_S, KEY_D].pick_random()

func _ready():
	$FailTimer.wait_time = DifficultyDirector.get_qte_time_window($FailTimer.wait_time)
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
