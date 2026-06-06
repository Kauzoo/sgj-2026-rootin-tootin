class_name FakeQTE extends KeyQTE

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
			# yes, im lazy :P
			get_parent().get_parent().remove_key_qte(self)
			get_viewport().set_input_as_handled()
			QTE_failed.emit(position)
			queue_free()

func _on_timeout():
	# yes, im lazy :P
	get_parent().get_parent().remove_key_qte(self)
	QTE_succeded.emit(position)  # player correctly ignored it!
	queue_free()

func check_event(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.key_label == key:
			# yes, im lazy :P
			get_parent().get_parent().remove_key_qte(self)
			get_viewport().set_input_as_handled()
			QTE_failed.emit(position)
			queue_free()
