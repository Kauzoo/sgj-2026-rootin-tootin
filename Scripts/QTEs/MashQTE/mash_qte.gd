class_name MashQTE extends KeyQTE

var mash_amount: int = 10
var initial_mash_amount: int
var active_tween: Tween
var original_sprite_scale: Vector2
@export var click_sound : AudioStream

func _ready():
	add_to_group("qte")
	register_key_qte()
	original_sprite_scale = $KeySprite.scale
	$FailTimer.wait_time = DifficultyDirector.get_qte_time_window($FailTimer.wait_time)
	$FailTimer.timeout.connect(_on_timeout)
	$FailTimer.start($FailTimer.wait_time)
	var rng = RandomNumberGenerator.new()
	mash_amount = rng.randi_range(5, 10)
	initial_mash_amount = mash_amount
	_update_number_label()


func _unhandled_input(event):
	if DifficultyDirector.is_input_on_cooldown():
		_mark_input_as_handled()
		return

func check_event(event):
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.key_label == key:

			_mark_input_as_handled()



			get_viewport().set_input_as_handled()
			
			
			#$SuccessSound.stream = success_sounds.pick_random()

			#$SuccessSound.play()
			
			if not is_resolved:
				mash_amount -= 1
				_update_number_label()
				
			if active_tween and active_tween.is_valid():
				active_tween.kill()
				
			active_tween = create_tween()
			$KeySprite.scale = original_sprite_scale
			active_tween.tween_property($KeySprite, "scale", original_sprite_scale * 0.85, 0.15).set_trans(Tween.TRANS_SPRING)
			
			if mash_amount > 0:
				# Calculate progress from 0.0 to 1.0
				var progress = 1.0 - (float(mash_amount) / float(maxi(initial_mash_amount, 1)))
					
				# Increase pitch from 1.0 up to 2.0 as they get closer to 0
					
				$SuccessSound.pitch_scale = maxf(0.01, lerp(1.0, 2.0, clampf(progress, 0.0, 1.0)))
				$SuccessSound.stream = click_sound
				$SuccessSound.play()
			else:
				if is_resolved:
					return true

				is_resolved = true
				unregister_key_qte()
				$FailTimer.stop()
				# --- FINISHED ---
				$SuccessSound.pitch_scale = 1.0
				$SuccessSound.stream = success_sounds.pick_random()
				$SuccessSound.play()
				var tween = create_tween()
				tween.set_trans(Tween.TRANS_SINE)
				tween.tween_property($KeySprite, "position:y", $KeySprite.position.y + 5, 0.1)
			
				await get_tree().create_timer(0.5).timeout

				get_parent().get_parent().remove_key_qte(self)
				DifficultyDirector.start_input_cooldown(0.25)
				QTE_succeded.emit(position)
				queue_free()
			return true

	return false


func _update_number_label() -> void:
	$NumberLabel.text = _space_digits(str(mash_amount))


func _space_digits(text: String) -> String:
	var result := ""
	for i in range(text.length()):
		if i > 0:
			result += " "
		result += text[i]
	return result
