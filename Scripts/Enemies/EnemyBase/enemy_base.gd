class_name EnemyBase extends Node2D

@export var QTE_Node: PackedScene
@export var qte_offset: Vector2 = Vector2(0, -70)
@export_node_path("Marker2D") var qte_marker_path: NodePath

var active_qte: QTEBase

signal enemy_killed()
signal do_damage()

func _ready():
	add_to_group("enemy")
	spawn_qte()

func spawn_qte():
	if active_qte != null or QTE_Node == null:
		return

	var instance = QTE_Node.instantiate() as QTEBase
	if instance == null:
		push_error("EnemyBase: QTE_Node must instantiate a QTEBase.")
		return

	active_qte = instance
	instance.position = _get_qte_position()
	instance.QTE_failed.connect(_on_QTE_failed)
	instance.QTE_succeded.connect(_on_QTE_succeded)
	add_child(instance)

func _get_qte_position() -> Vector2:
	if qte_marker_path != NodePath():
		var marker = get_node_or_null(qte_marker_path)
		if marker is Marker2D:
			return marker.position

	return qte_offset

func _on_QTE_succeded(_pos):
	active_qte = null
	enemy_killed.emit()
	queue_free()

func _on_QTE_failed(_pos):
	active_qte = null
	do_damage.emit()
	enemy_killed.emit()
	queue_free()
