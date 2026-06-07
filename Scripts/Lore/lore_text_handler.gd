extends Node2D

@export var label : Label

const LORE_FILE_PATH := "res://Scripts/Lore/Lore_texts.txt"
const FALLBACK_LORE_LINES: Array[String] = [
	"The Rooting started roughly a month ago. Its' thick roots and violent Vegetation have torn apart cities and taken many lives. I've been barricaded in my home the entire time.",
	"Not only am I running out of food, but the Rootlings have torn appart my garden fence and are making their way to my home.",
	"I have no choice but to face them, let's hope my old garden shears can protect me from them..."
]

var current_line := 0
var tween_text_scroll: Tween
var lore_lines: Array[String] = []

signal go_to_game()

func set_visible_characters(num : int):
	label.visible_characters = num
	_on_character_revealed(num)

func _ready():
	lore_lines = _load_lore_lines()
	_show_current_line()

func _process(delta):
	pass

func _input(event):
	if _is_advance_event(event):
		_advance_lore()

func _load_lore_lines() -> Array[String]:
	var loaded_lines: Array[String] = []
	var lore_file := FileAccess.open(LORE_FILE_PATH, FileAccess.READ)

	if lore_file == null:
		return FALLBACK_LORE_LINES.duplicate()

	while not lore_file.eof_reached():
		var line := lore_file.get_line()
		if line.strip_edges() != "":
			loaded_lines.append(line)

	if loaded_lines.is_empty():
		return FALLBACK_LORE_LINES.duplicate()

	return loaded_lines

func _is_advance_event(event: InputEvent) -> bool:
	if event.is_action_pressed("LoreEnterToAdvance (can be replaced later)"):
		return true

	if event is InputEventKey and event.pressed and not event.echo:
		return event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]

	if event is InputEventMouseButton and event.pressed:
		return event.button_index == MOUSE_BUTTON_LEFT

	if event is InputEventScreenTouch and event.pressed:
		return true

	return false

func _advance_lore():
	if tween_text_scroll:
		tween_text_scroll.kill()

	current_line += 1

	if current_line >= lore_lines.size():
		go_to_game.emit()
	else:
		_show_current_line()

func _show_current_line():
	label.set_text(lore_lines[current_line])
	nextSaying()

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
	
	
