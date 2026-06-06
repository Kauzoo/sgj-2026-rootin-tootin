class_name KeyQTE extends QTEBase

var key: int = [KEY_W, KEY_A, KEY_S, KEY_D].pick_random()

var is_resolved: bool = false
@export var success_sounds: Array[AudioStream]

func _ready():
	add_to_group("qte")
	register_key_qte()
	$FailTimer.wait_time = DifficultyDirector.get_qte_time_window($FailTimer.wait_time)
	$FailTimer.timeout.connect(_on_timeout)

func _mark_input_as_handled():
	var viewport = get_viewport()
	if viewport:
		viewport.set_input_as_handled()

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
		_mark_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.key_label == key:
			if is_resolved:
				return

			is_resolved = true
			unregister_key_qte()
			_mark_input_as_handled()
			QTE_succeded.emit(position)
			queue_free()

func check_event(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.key_label == key:

			if is_resolved:
				return true

			is_resolved = true
			unregister_key_qte()
			_mark_input_as_handled()

			
			# yes, im lazy :P
			get_viewport().set_input_as_handled()
			
			$FailTimer.stop()
			
			$SuccessSound.stream = success_sounds.pick_random()

			#var original_length = $SuccessSound.stream.get_length()
			#$SuccessSound.pitch_scale = 1.0

			$SuccessSound.play()
			
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_SINE)
			tween.tween_property($KeySprite, "position:y", $KeySprite.position.y + 5, 0.1)
			
			await get_tree().create_timer(0.5).timeout
			
			get_parent().get_parent().remove_key_qte(self)

			QTE_succeded.emit(position)
			queue_free()
			return true

	return false
