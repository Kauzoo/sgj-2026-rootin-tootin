@tool
extends Node2D
class_name SoundPool

var _sounds: Array[SoundQueue] = []
var _random := RandomNumberGenerator.new()
var _last_index: int = -1

func _ready() -> void:
	for child in get_children():
		if child is SoundQueue:
			_sounds.append(child)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	var number_of_sound_queue_children: int = 0
	
	for child in get_children():
		if child is SoundQueue:
			number_of_sound_queue_children += 1
			
	if number_of_sound_queue_children < 2:
		warnings.append("Expected two or more children of type SoundQueue")
		
	return warnings

func play_random_sound() -> void:
	if _sounds.is_empty():
		return
		
	# Safety check: Prevent infinite loop if there's only 1 sound
	if _sounds.size() == 1:
		_sounds[0].play_sound()
		return

	# GDScript does not have a do-while loop, so we emulate it with a while loop
	var index: int = _random.randi_range(0, _sounds.size() - 1)
	while index == _last_index:
		index = _random.randi_range(0, _sounds.size() - 1)
		
	_last_index = index
	print("random sound index:" + str(index))
	_sounds[index].play_sound()
