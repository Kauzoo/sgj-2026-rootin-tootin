extends Node

@onready var bgm_asp: AudioStreamPlayer = $BackgroundAudioStreamPlayer

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
		
	var failed_queue := $FailedSoundQueue as SoundQueue
	if failed_queue:
		_sound_queues_by_name["FailedSoundQueue"] = failed_queue
	else:
		push_error("FailedSoundQueue node not found!")
		
	var bird_queue := $BirdsSoundQueue as SoundQueue
	if bird_queue:
		_sound_queues_by_name["BirdsSoundQueue"] = bird_queue
	else:
		push_error("BirdsSoundQueue node not found!")	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func play_fireball_sound() -> void:
	if _sound_queues_by_name.has("FireballSoundQueue"):
		_sound_queues_by_name["FireballSoundQueue"].play_sound()
		
func play_random_pool_sound() -> void:
	if _sound_pools_by_name.has("MySoundPool"):
		_sound_pools_by_name["MySoundPool"].play_random_sound()
		
func play_failed_sound() -> void:
	if _sound_queues_by_name.has("FailedSoundQueue"):
		_sound_queues_by_name["FailedSoundQueue"].play_sound()

func play_bird_sound() -> void:
	if _sound_queues_by_name.has("BirdSoundQueue"):
		_sound_queues_by_name["BirdSoundQueue"].play_sound()
		
func play_bgm() -> void:
	if bgm_asp:
		bgm_asp.play()
		
func stop_bgm() -> void:
	if bgm_asp:
		bgm_asp.stop()
