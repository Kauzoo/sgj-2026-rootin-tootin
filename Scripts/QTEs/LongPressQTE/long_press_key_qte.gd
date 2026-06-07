class_name LongPressKeyQTE extends KeyQTE

@export var hold_duration: float = 1.0  # how long player needs to hold

var hold_timer: float = 0.0
var is_holding: bool = false
var original_sprite_pos: Vector2
var original_sprite_scale: Vector2
var active_tween: Tween

#var playback: AudioStreamGeneratorPlayback
#var phase: float = 0.0
#var sample_hz: float = 44100.0

func _ready():
	super._ready()
	original_sprite_pos = $KeySprite.position
	original_sprite_scale = $KeySprite.scale
	
	# Create the audio generator
	#var stream = AudioStreamGenerator.new()
	#stream.mix_rate = sample_hz
	#stream.buffer_length = 0.1 # Keep buffer short for real-time changes
	#$SuccessSound.stream = stream
	
func _process(delta):
	if is_holding:
		hold_timer += delta
		var hold_ratio: float = hold_timer / hold_duration
		var shake_intensity = lerp(1.0, 5.0, hold_ratio)
		$KeySprite.position = original_sprite_pos + Vector2(
			randf_range(-shake_intensity, shake_intensity), 
			randf_range(-shake_intensity, shake_intensity)
		)
		#var current_hz = lerp(220.0, 880.0, hold_ratio)
		#fill_audio_buffer(current_hz)
		$SuccessSound.pitch_scale = lerp(1.0, 1.7, hold_ratio)
		
		var linear_volume = lerp(0.1, 0.6, hold_ratio)
		$SuccessSound.volume_db = linear_to_db(linear_volume)
		
		if hold_timer >= hold_duration:
			is_holding = false
			
			$SuccessSound.stop()
			$SuccessSound.pitch_scale = 1.0
			$SuccessSound.volume_db = 0.0
			$SuccessSound.stream = success_sounds.pick_random()
			$SuccessSound.play()
			
			# Pop it big instantly
			$KeySprite.scale = original_sprite_scale * 1.5
			
			var tween = create_tween()
			# Spring it back to its original scale
			tween.tween_property($KeySprite, "scale", original_sprite_scale, 0.3).set_trans(Tween.TRANS_SPRING)
			# Move the position down at the exact same time
			tween.parallel().tween_property($KeySprite, "position:y", original_sprite_pos.y + 5, 0.1).set_trans(Tween.TRANS_SINE)
			
			await get_tree().create_timer(0.5).timeout
			get_parent().get_parent().remove_key_qte(self)
			get_viewport().set_input_as_handled()
			QTE_succeded.emit(position)
			queue_free()
			## Stops the _process loop from triggering this again
			#is_holding = false
			#$KeySprite.scale = Vector2(2.0, 2.0)
			#$SuccessSound.stop()
			#$SuccessSound.pitch_scale = 1.0
			#$SuccessSound.volume_db = 0.0
			#$SuccessSound.stream = success_sounds.pick_random()
			#$SuccessSound.play()
			#$KeySprite.scale = original_sprite_scale * 1.5
			#var tween = create_tween()
			#tween.set_trans(Tween.TRANS_SINE)
			#tween.tween_property($KeySprite, "position:y", $KeySprite.position.y + 5, 0.1)
			#
			#await get_tree().create_timer(0.5).timeout
			#get_parent().get_parent().remove_key_qte(self)
			#get_viewport().set_input_as_handled()
			#QTE_succeded.emit(position)
			#queue_free()
	queue_redraw()

func _draw():
	super._draw()  # draws the red fail timer arc from KeyQTE
	
	# just add the green hold progress arc on top
	#var hold_ratio: float = hold_timer / hold_duration
	#draw_arc(Vector2(0, 0), 30, 0 - 0.5 * PI, hold_ratio * 2 * PI - 0.5 * PI, 100, Color(0, 1, 0), 5)

func _unhandled_input(event):
	if DifficultyDirector.is_input_on_cooldown():
		get_viewport().set_input_as_handled()
		return
	
	# Just pass the event to check_event to avoid duplicating logic
	check_event(event)

func check_event(event) -> bool:
	if event is InputEventKey and event.key_label == key:
		
		# START HOLD
		if event.pressed and not event.is_echo() and not is_holding:
			is_holding = true
			$FailTimer.paused = true
			
			$SuccessSound.pitch_scale = 1.0
			$SuccessSound.play()
			#playback = $SuccessSound.get_stream_playback()
			#phase = 0.0
			
			if active_tween and active_tween.is_valid():
				active_tween.kill()
			active_tween = create_tween()
			active_tween.tween_property($KeySprite, "scale", original_sprite_scale * 0.7, hold_duration)
			
			return true
			
		# STOP HOLD
		elif not event.pressed and is_holding:
			is_holding = false
			hold_timer = 0.0
			$FailTimer.paused = false
			
			$SuccessSound.stop()
			$KeySprite.position = original_sprite_pos
			
			# Spring back to normal size
			if active_tween and active_tween.is_valid():
				active_tween.kill()
			active_tween = create_tween()
			active_tween.tween_property($KeySprite, "scale", original_sprite_scale, 0.15).set_trans(Tween.TRANS_SPRING)
			
			return true
			
	return false
	
#func fill_audio_buffer(hz: float):
	#if not playback:
		#return
		#
	#var frames_available = playback.get_frames_available()
	#for i in frames_available:
		## Generate a sine wave. The 0.2 acts as the volume (amplitude)
		##var sample = sin(phase * TAU) * 0.2 
		#
		#var sample = 1.0 if phase < 0.5 else -1.0
		#
		#playback.push_frame(Vector2(sample, sample)) # Left and right channels
		#
		## Advance the phase based on the target frequency
		#phase = fmod(phase + hz / sample_hz, 1.0)
