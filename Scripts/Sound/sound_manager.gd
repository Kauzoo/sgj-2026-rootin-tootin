extends Node

var _sound_queues_by_name: Dictionary = {}
var _sound_pools_by_name: Dictionary = {}

func _ready() -> void:
	
	# I love soundQueues. It's fast and quantity. 
	var fireball_queue := $FireballSoundQueue as SoundQueue
	if fireball_queue:
		_sound_queues_by_name["FireballSoundQueue"] = fireball_queue
	else:
		push_error("FireballSoundQueue node not found!")
		
	# I love soundPools. You will never know.
	var my_pool := $MySoundPool as SoundPool
	if my_pool:
		_sound_pools_by_name["MySoundPool"] = my_pool
	else:
		push_error("MySoundPool node not found!")
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func play_fireball_sound() -> void:
	if _sound_queues_by_name.has("FireballSoundQueue"):
		_sound_queues_by_name["FireballSoundQueue"].play_sound()
		
func play_random_pool_sound() -> void:
	if _sound_pools_by_name.has("MySoundPool"):
		_sound_pools_by_name["MySoundPool"].play_random_sound()
