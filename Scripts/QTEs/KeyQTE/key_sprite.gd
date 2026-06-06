extends Sprite2D

func _ready():
	update_sprite()

func update_sprite():
	texture = load("res://Sprites/SimpleKeys/Jumbo/Light/Single PNGs/" + String.chr(get_parent().key) + ".png")
