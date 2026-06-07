extends Control

signal go_to_lore()

# grabby grab, not to grab here!
#@onready var my_sound_pool := $SoundPool as SoundPool
@onready var start_button: Button = $VBoxContainer/Start
@onready var options_button: Button = $VBoxContainer/Options
@onready var exit_button: Button = $VBoxContainer/Exit

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#pass
	#SoundManager.play_fireball_sound()
	#SoundManager.play_random_pool_sound()
	start_button.focus_neighbor_bottom = start_button.get_path_to(options_button)
	start_button.focus_neighbor_top = start_button.get_path_to(exit_button)
	
	options_button.focus_neighbor_top = options_button.get_path_to(start_button)
	options_button.focus_neighbor_bottom = options_button.get_path_to(exit_button)
	
	exit_button.focus_neighbor_top = exit_button.get_path_to(options_button)
	exit_button.focus_neighbor_bottom = exit_button.get_path_to(start_button)
	
	start_button.grab_focus()
		
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#pass
	var current_focus = get_viewport().gui_get_focus_owner()
	if current_focus:
		print("Currently focusing: ", current_focus.name)


func _on_start_pressed() -> void:
	print("start pressed")
	SoundManager.play_click5_sound()
	go_to_lore.emit()

func _input(event) -> void:
	if event.is_action_pressed("LoreEnterToAdvance (can be replaced later)"):
		print("start pressed")
		SoundManager.play_click5_sound()
		go_to_lore.emit()

func _on_options_pressed() -> void:
	print("options pressed")
	SoundManager.play_click5_sound()
	#get_tree().change_scene_to_file()

func _on_exit_pressed() -> void:
	print("exit pressed")
	SoundManager.play_click5_sound()
	get_tree().quit()
