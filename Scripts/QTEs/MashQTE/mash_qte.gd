class_name MashQTE extends KeyQTE

var mash_amount: int = 10

func _ready():
	# yes, im lazy :P
	get_parent().get_parent().get_parent().add_key_qte(self)
	$FailTimer.timeout.connect(_on_timeout)
	$NumberLabel.text = str(mash_amount)

func check_event(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.key_label == key:
			get_viewport().set_input_as_handled()

			mash_amount -= 1
			$NumberLabel.text = str(mash_amount)

			if mash_amount <= 0:
				# yes, im lazy :P
				get_parent().get_parent().get_parent().remove_key_qte(self)
				QTE_succeded.emit(position)
				queue_free()
