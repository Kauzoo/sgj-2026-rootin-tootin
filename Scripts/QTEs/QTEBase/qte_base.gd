class_name QTEBase extends Node2D

signal QTE_failed(pos)
signal QTE_succeded(pos)

func _ready():
	add_to_group("qte")

func _get_qte_manager():
	var current = get_parent()
	while current != null:
		if current.has_method("add_key_qte") and current.has_method("remove_key_qte"):
			return current
		current = current.get_parent()
	return null

func register_key_qte():
	var manager = _get_qte_manager()
	if manager:
		manager.add_key_qte(self)
	else:
		push_error("QTEBase: Could not find a key QTE manager.")

func unregister_key_qte():
	var manager = _get_qte_manager()
	if manager:
		manager.remove_key_qte(self)

func check_event(event):
	pass
