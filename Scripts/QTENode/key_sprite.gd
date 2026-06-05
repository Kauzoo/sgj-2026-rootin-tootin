extends Sprite2D

func _ready():
	texture = load("res://Sprites/SimpleKeys/Jumbo/Light/Single PNGs/" + String.chr(get_parent().key) + ".png")
