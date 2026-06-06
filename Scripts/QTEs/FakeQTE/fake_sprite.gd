extends Sprite2D

var sprite : Sprite2D

func _ready():
	texture = load("res://Sprites/SimpleKeys/Jumbo/Light/Single PNGs/" + String.chr(get_parent().key) + ".png")
	#sprite.texture = texture
	modulate = Color("red")
	pass
	
	
	
	#mke texure more red?
