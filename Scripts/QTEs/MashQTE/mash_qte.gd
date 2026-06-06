class_name MashQTE extends KeyQTE

var mash_amount: int = 10

func _ready():
	add_to_group("qte")
	register_key_qte()
	$FailTimer.wait_time = DifficultyDirector.get_qte_time_window($FailTimer.wait_time)
	$FailTimer.timeout.connect(_on_timeout)
	$NumberLabel.text = str(mash_amount)


func _unhandled_input(event):
	if DifficultyDirector.is_input_on_cooldown():
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey:
		if event.pressed and event.key_label == key:
			# set pressed to false so it cant remove another input query for the same key
			# idk if this has bad consequences but it seems to work :P
			event.pressed = false
func check_event(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.key_label == key:
			get_viewport().set_input_as_handled()

			mash_amount -= 1
			$NumberLabel.text = str(mash_amount)

			if mash_amount <= 0:
				if is_resolved:
					return

				is_resolved = true
				unregister_key_qte()
				$FailTimer.stop()
				DifficultyDirector.start_input_cooldown(0.25)
				QTE_succeded.emit(position)
				queue_free()
