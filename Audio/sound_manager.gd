extends Node

var _sound_queues_by_name: Dictionary = {}
var _sound_pools_by_name: Dictionary = {}

func _ready() -> void:
	# Using the '$' shorthand is equivalent to GetNode()
	# We cast it to SoundQueue for better autocompletion, assuming SoundQueue is a registered class_name
	var fireball_queue := $FireballSoundQueue as SoundQueue
	if fireball_queue:
		_sound_queues_by_name["FireballSoundQueue"] = fireball_queue
	else:
		push_error("FireballSoundQueue node not found!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func play_fireball_sound() -> void:
	# It's good practice to ensure the key exists before accessing to prevent crashes
	if _sound_queues_by_name.has("FireballSoundQueue"):
		_sound_queues_by_name["FireballSoundQueue"].play_sound()
