extends Sprite2D

const KEY_TEXTURES := {
	KEY_W: preload("res://2DArt/TastenButtons/W_Evil.png"),
	KEY_A: preload("res://2DArt/TastenButtons/A_Evil.png"),
	KEY_S: preload("res://2DArt/TastenButtons/S_Evil.png"),
	KEY_D: preload("res://2DArt/TastenButtons/D_Evil.png"),
}

var sprite : Sprite2D

func _ready():
	texture = KEY_TEXTURES.get(get_parent().key)
	if texture == null:
		push_warning("No fake key texture for key: " + str(get_parent().key))
	#sprite.texture = texture
	modulate = Color("red")
	pass
	
	
	
	#mke texure more red?
