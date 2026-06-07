extends Sprite2D

const KEY_TEXTURES := {
	KEY_W: preload("res://2DArt/TastenButtons/W.png"),
	KEY_A: preload("res://2DArt/TastenButtons/A.png"),
	KEY_S: preload("res://2DArt/TastenButtons/S.png"),
	KEY_D: preload("res://2DArt/TastenButtons/D.png"),
}

func _ready():
	update_sprite()

func update_sprite():
	texture = KEY_TEXTURES.get(get_parent().key)
	if texture == null:
		push_warning("No key texture for key: " + str(get_parent().key))
