extends Node2D

var text: String

func _ready():
	$Label.add_theme_color_override("font_color", Color.hex(0xFF00EEFF))
	$Label.text = text
