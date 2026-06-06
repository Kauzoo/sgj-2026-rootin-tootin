extends Control

signal go_to_lore()

# grabby grab, not to grab here!
#@onready var my_sound_pool := $SoundPool as SoundPool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#SoundManager.play_fireball_sound()
	#SoundManager.play_random_pool_sound()
		
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_pressed() -> void:
	print("start pressed")
	go_to_lore.emit()


func _on_options_pressed() -> void:
	print("options pressed")
	#get_tree().change_scene_to_file()

func _on_exit_pressed() -> void:
	print("exit pressed")
	get_tree().quit()
