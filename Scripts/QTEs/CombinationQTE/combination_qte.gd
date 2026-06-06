class_name CombinationQTE extends KeyQTE

@export var key_sequence: Array[Key] = [KEY_A, KEY_D, KEY_A, KEY_D]
var current_step: int = 0
var is_resolved: bool = false

func _ready():
	$FailTimer.timeout.connect(_on_timeout)
	
	if key_sequence.size() > 0:
		key = key_sequence[current_step]
	
	_register_with_manager()
	update_ui()

func _get_qte_manager():
	var current = get_parent()
	while current != null:
		if current.has_method("add_key_qte") and current.has_method("remove_key_qte"):
			return current
		current = current.get_parent()
	return null

func _register_with_manager():
	var manager = _get_qte_manager()
	if manager and manager.has_method("add_key_qte"):
		manager.add_key_qte(self)
	else:
		push_error("ComboQTE: Could not find the QTE Manager using the parent chain!")

func _unhandled_input(event):
	if DifficultyDirector.is_input_on_cooldown():
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey:
		if event.pressed and event.key_label == key:
			event.pressed = false

func check_event(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.key_label == key:
			get_viewport().set_input_as_handled()
			advance_sequence()
		else:
			_on_timeout()

func advance_sequence():
	if is_resolved:
		return

	current_step += 1
	
	if current_step >= key_sequence.size():
		is_resolved = true
		var manager = _get_qte_manager()
		if manager:
			manager.remove_key_qte(self)
		$FailTimer.stop()
		DifficultyDirector.start_input_cooldown(0.25)
		QTE_succeded.emit(position)
		queue_free()
	else:
		key = key_sequence[current_step]
		$FailTimer.start() 
		update_ui()

func _on_timeout():
	if is_resolved:
		return

	is_resolved = true
	var manager = _get_qte_manager()
	if manager:
		manager.remove_key_qte(self)
	QTE_failed.emit(position)
	queue_free()

func update_ui():
	if has_node("NumberLabel"):
		$NumberLabel.text = str(key_sequence.size() - current_step)
	
	if has_node("KeySprite") and $KeySprite.has_method("update_sprite"):
		$KeySprite.update_sprite()
