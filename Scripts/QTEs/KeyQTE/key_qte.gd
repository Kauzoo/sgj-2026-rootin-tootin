class_name KeyQTE extends QTEBase

var key: int = [KEY_W, KEY_A, KEY_S, KEY_D].pick_random()
var is_resolved: bool = false

func _ready():
	add_to_group("qte")
	register_key_qte()
	$FailTimer.wait_time = DifficultyDirector.get_qte_time_window($FailTimer.wait_time)
	$FailTimer.timeout.connect(_on_timeout)

func _on_timeout():
	if is_resolved:
		return

	is_resolved = true
	unregister_key_qte()
	QTE_failed.emit(position)
	queue_free()

func force_fail():
	_on_timeout()

func _process(_delta):
	queue_redraw()


func _draw():
	var ratio: float = $FailTimer.time_left / $FailTimer.wait_time
	draw_arc(Vector2(0, 0),40, 0 - 0.5 * PI, ratio * 2 * PI - 0.5 * PI, 100, Color(1, ratio, ratio), 3)


func _unhandled_input(event):
	if DifficultyDirector.is_input_on_cooldown():
		# Do not handle the input here so it can fall through to GameScene and be handled there,
		# or just handle it and return. Since GameScene also handles it, setting it as handled is safest.
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.key_label == key:
			if is_resolved:
				return

			is_resolved = true
			unregister_key_qte()
			get_viewport().set_input_as_handled()
			QTE_succeded.emit(position)
			queue_free()

func check_event(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.key_label == key:
			if is_resolved:
				return true

			is_resolved = true
			unregister_key_qte()
			get_viewport().set_input_as_handled()
			QTE_succeded.emit(position)
			queue_free()
			return true

	return false
