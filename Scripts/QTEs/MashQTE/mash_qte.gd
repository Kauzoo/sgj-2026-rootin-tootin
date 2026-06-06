class_name MashQTE extends KeyQTE

var mash_amount: int = 10
var initial_mash_amount: int
var active_tween: Tween
@export var click_sound : AudioStream

func _ready():
	# yes, im lazy :P
	get_parent().get_parent().get_parent().add_key_qte(self)
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
			
			
			#$SuccessSound.stream = success_sounds.pick_random()
#
			#$SuccessSound.play()
			
			if not done:
				mash_amount -= 1
				$NumberLabel.text = str(mash_amount)
			
			if active_tween and active_tween.is_valid():
				active_tween.kill()
				
			active_tween = create_tween()
			$KeySprite.scale = Vector2(2.0, 2.0) 
			active_tween.tween_property($KeySprite, "scale", Vector2(1.7, 1.7), 0.15).set_trans(Tween.TRANS_SPRING)
			
			if mash_amount > 0:
				# Calculate progress from 0.0 to 1.0
				var progress = 1.0 - (float(mash_amount) / float(initial_mash_amount))
				
				# Increase pitch from 1.0 up to 2.0 as they get closer to 0
				
				$SuccessSound.pitch_scale = lerp(1.0, 2.0, progress)
				$SuccessSound.stream = click_sound
				$SuccessSound.play()
			else:
				if done:
					return
				done = true
				# --- FINISHED ---
				$SuccessSound.pitch_scale = 1.0 
				$SuccessSound.stream = success_sounds.pick_random()
				$SuccessSound.play()
				var tween = create_tween()
				tween.set_trans(Tween.TRANS_SINE)
				tween.tween_property($KeySprite, "position:y", $KeySprite.position.y + 5, 0.1)
			
				await get_tree().create_timer(0.5).timeout

				get_parent().get_parent().get_parent().remove_key_qte(self)
				DifficultyDirector.start_input_cooldown(0.25)
				QTE_succeded.emit(position)
				queue_free()
