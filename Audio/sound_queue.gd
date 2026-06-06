@tool
extends Node2D
class_name SoundQueue # Added class_name so you can search it in the node tree

@export var count: int = 1

var _next: int = 0
var _audio_stream_players: Array[AudioStreamPlayer2D] = []

func _ready() -> void:
	if get_child_count() == 0:
		print("No ASP child found.")
		return
		
	var child := get_child(0)
	if child is AudioStreamPlayer2D:
		_audio_stream_players.append(child)
		
		# 'for i in count' is the GDScript equivalent of 'for (int i = 0; i < count; i++)'
		for i in count:
			var duplicate := child.duplicate() as AudioStreamPlayer2D
			add_child(duplicate)
			_audio_stream_players.append(duplicate)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	
	if get_child_count() == 0:
		warnings.append("No children found. Expected ASP child")
	elif not get_child(0) is AudioStreamPlayer2D:
		warnings.append("Expected first child to be an ASP")
		
	return warnings

func play_sound() -> void:
	# Safety check to prevent crashing if the node was not set up correctly
	if _audio_stream_players.is_empty():
		return
		
	if not _audio_stream_players[_next].playing:
		_audio_stream_players[_next].play()
		_next = (_next + 1) % _audio_stream_players.size()
