extends Node

static var instance: SoundManager

var _sound_queues_by_name: Dictionary = {}
var _sound_pools_by_name: Dictionary = {}

func _ready() -> void:
	instance = self
	_sound_queues_by_name["FireballSoundQueue"] = get_node("FireballSoundQueue") as SoundQueue

func _process(delta: float) -> void:
	pass
	
func play_fireball_sound() -> void:
	_sound_queues_by_name["FireballSoundQueue"].play_sound()
