class_name MashQTE extends KeyQTE

var mash_amount: int = 10

func _ready():
	$FailTimer.timeout.connect(_on_timeout)
	$NumberLabel.text = str(mash_amount)


func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.key_label == key:
			# set pressed to false so it cant remove another input query for the same key
			# idk if this has bad consequences but it seems to work :P
			event.pressed = false

			mash_amount -= 1
			$NumberLabel.text = str(mash_amount)

			if mash_amount <= 0:
				QTE_succeded.emit(position)
				queue_free()
