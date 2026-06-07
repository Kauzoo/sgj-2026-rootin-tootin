extends Node

@onready var bgm_asp: AudioStreamPlayer = $BackgroundAudioStreamPlayer

const BGM_VOLUME_DB := -6.0
const BGM_FADE_OUT_DB := -80.0
const BGM_FADE_OUT_SECONDS := 2.5

var _sound_queues_by_name: Dictionary = {}
var _sound_pools_by_name: Dictionary = {}
var _bgm_fade_tween: Tween
var _should_loop_bgm := false

func _ready() -> void:
	if bgm_asp:
		bgm_asp.finished.connect(_on_bgm_finished)
	
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
	if _sound_queues_by_name.has("BirdsSoundQueue"):
		_sound_queues_by_name["BirdsSoundQueue"].play_sound()
		
func play_bgm() -> void:
	if bgm_asp:
		_stop_bgm_fade()
		_should_loop_bgm = true
		bgm_asp.volume_db = BGM_VOLUME_DB
		bgm_asp.play()
		
func stop_bgm() -> void:
	if bgm_asp:
		_should_loop_bgm = false
		_stop_bgm_fade()
		bgm_asp.stop()

func fade_out_bgm(fade_seconds: float = BGM_FADE_OUT_SECONDS) -> void:
	if not bgm_asp or not bgm_asp.playing:
		return

	_should_loop_bgm = false
	_stop_bgm_fade()
	_bgm_fade_tween = create_tween()
	_bgm_fade_tween.tween_property(bgm_asp, "volume_db", BGM_FADE_OUT_DB, fade_seconds)
	_bgm_fade_tween.finished.connect(_on_bgm_fade_finished)

func _on_bgm_fade_finished() -> void:
	if bgm_asp:
		bgm_asp.stop()
		bgm_asp.volume_db = BGM_VOLUME_DB

	_bgm_fade_tween = null

func _stop_bgm_fade() -> void:
	if _bgm_fade_tween:
		_bgm_fade_tween.kill()
		_bgm_fade_tween = null

func _on_bgm_finished() -> void:
	if _should_loop_bgm and bgm_asp:
		bgm_asp.play()
