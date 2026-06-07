extends Control

signal go_to_lore()
signal go_to_leaderboard()

@export var StartHoverImage : Sprite2D
@export var OptionsHoverImage : Sprite2D
@export var ExitHoverImage : Sprite2D

@export var startButton : Button
@export var optionsButton : Button
@export var exitButton : Button

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

func _on_start_hovered() -> void:
	StartHoverImage.visible = true
	
func _on_start_not_hovered() -> void:
	StartHoverImage.visible = false
	
func _on_options_hovered() -> void:
	OptionsHoverImage.visible = true
	
func _on_options_not_hovered() -> void:
	OptionsHoverImage.visible = false
	
func _on_exit_hovered() -> void:
	ExitHoverImage.visible = true
	
func _on_exit_not_hovered() -> void:
	ExitHoverImage.visible = false

func _on_start_pressed() -> void:
	print("start pressed")
	go_to_lore.emit()

func _input(event) -> void:
	if event.is_action_pressed("LoreEnterToAdvance (can be replaced later)"):
		print("start pressed")
		go_to_lore.emit()

func _on_options_pressed() -> void:
	print("options pressed")
	go_to_leaderboard.emit()

func _on_exit_pressed() -> void:
	print("exit pressed")
	get_tree().quit()
