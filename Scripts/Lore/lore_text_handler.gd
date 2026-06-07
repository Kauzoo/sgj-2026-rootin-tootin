extends Node2D

@export var label : Label

var current_line
var tween_text_scroll
var lore_file_path
var lore_file

signal go_to_game()

func set_visible_characters(num : int):
	label.visible_characters = num
	_on_character_revealed(num)

func _ready():
	
	lore_file_path = "res://Scripts/Lore/Lore_texts.txt"
	lore_file = FileAccess.open(lore_file_path, FileAccess.READ)
	
	var text = lore_file.get_line()
	label.set_text(text)
	
	current_line = 0
	nextSaying()
	
	pass

func _process(delta):
	pass

func _input(event):
	if event.is_action_pressed("LoreEnterToAdvance (can be replaced later)"):
		
		current_line += 1
		tween_text_scroll.kill()
		
		var text = lore_file.get_line()
		if (text == ""):
			go_to_game.emit()
		else:
			label.set_text(text)
			nextSaying()
	pass

#func nextSaying():
#	label.visible_characters = 0
#	
#	var visibleCharactersDuration = label.get_total_character_count() * 0.02
#	
#	tween_text_scroll = create_tween()
#	tween_text_scroll.tween_property(label, "visible_characters", 
#	label.get_total_character_count(), visibleCharactersDuration)
#	
#	pass
	
	
func nextSaying():
	label.visible_characters = 0

	var total = label.get_total_character_count()
	var visibleCharactersDuration = total * 0.02

	tween_text_scroll = create_tween()
#	tween_text_scroll.tween_property(label, "visible_characters",
#		total, visibleCharactersDuration)
	
	tween_text_scroll.tween_method(set_visible_characters, 0, total, visibleCharactersDuration)

func _on_character_revealed(char_index: int):
	#if char_index % 2 == 0:
	SoundManager.play_random_pool_sound()
	
	
