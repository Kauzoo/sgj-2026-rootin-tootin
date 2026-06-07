class_name CombinationQTE extends KeyQTE

@export var key_sequence: Array[Key] = [KEY_A, KEY_D, KEY_A, KEY_D]
@export var first_step_wait_time: float = 7.0
@export var follow_up_step_wait_time: float = 2.0
@export var click_sound: AudioStream
var current_step: int = 0

func _ready():
	add_to_group("qte")
	$FailTimer.timeout.connect(_on_timeout)
		
	if key_sequence.size() > 0:
		key = key_sequence[current_step]
		
	register_key_qte()
	_start_step_timer()
	update_ui()

func _unhandled_input(event):
	if DifficultyDirector.is_input_on_cooldown():
		_mark_input_as_handled()
		return

func check_event(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.key_label == key:
			_mark_input_as_handled()
			advance_sequence()
			return true

	return false

func advance_sequence():
	if is_resolved:
		return

	current_step += 1

	

	
	if current_step >= key_sequence.size():
		$SuccessSound.stream = success_sounds.pick_random()

		$SuccessSound.play()	
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property($KeySprite, "position:y", $KeySprite.position.y + 5, 0.1)
		await get_tree().create_timer(0.5).timeout
		is_resolved = true
		unregister_key_qte()
		$FailTimer.stop()
		DifficultyDirector.start_input_cooldown(0.25)
		QTE_succeded.emit(position)
		queue_free()
		
	else:
		var progress = 1.0 - (float(current_step) / float(maxi(key_sequence.size(), 1)))
		$SuccessSound.pitch_scale = maxf(0.01, lerp(1.0, 2.0, clampf(progress, 0.0, 1.0)))
		$SuccessSound.stream = click_sound
		$SuccessSound.play()
		key = key_sequence[current_step]
		_start_step_timer()
		update_ui()

func _on_timeout():
	if is_resolved:
		return

	is_resolved = true
	unregister_key_qte()
	QTE_failed.emit(position)
	queue_free()

func update_ui():
	if has_node("KeySprite") and $KeySprite.has_method("update_sprite"):
		$KeySprite.update_sprite()

func _start_step_timer():
	var base_window = first_step_wait_time if current_step == 0 else follow_up_step_wait_time
	var adjusted_window = DifficultyDirector.get_qte_time_window(base_window)
	$FailTimer.start(adjusted_window)
