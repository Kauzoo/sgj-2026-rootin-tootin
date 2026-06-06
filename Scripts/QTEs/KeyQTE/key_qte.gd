class_name KeyQTE extends QTEBase

var key: int = randi_range(0x41, 0x5A)

func _ready():
	$FailTimer.timeout.connect(_on_timeout)

func _on_timeout():
	QTE_failed.emit(position)
	queue_free()

func _process(_delta):
	queue_redraw()


func _draw():
	var ratio: float = $FailTimer.time_left / $FailTimer.wait_time
	draw_arc(Vector2(0, 0), 30, 0 - 0.5 * PI, ratio * 2 * PI - 0.5 * PI, 100, Color(1, ratio, ratio), 3)


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.key_label == key:
			# set pressed to false so it cant remove another input query for the same key
			# idk if this has bad consequences but it seems to work :P
			event.pressed = false

			QTE_succeded.emit(position)
			queue_free()
