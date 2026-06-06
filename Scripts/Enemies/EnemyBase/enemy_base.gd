class_name EnemyBase extends Node2D

@export var QTE_Node: PackedScene
@export var qte_offset: Vector2 = Vector2(0, -70)
@export_node_path("Marker2D") var qte_marker_path: NodePath
@export var qte_count_override: int = 0
@export var progress_bar_offset: Vector2 = Vector2(-32, -105)
@export var progress_bar_size: Vector2 = Vector2(64, 8)

var active_qte: QTEBase
var enemy_type: int = 0
var qtes_required: int = 1
var qtes_completed: int = 0
var progress_bar: ProgressBar

signal enemy_killed()
signal enemy_removed()
signal do_damage()

func _ready():
	add_to_group("enemy")
	_setup_qte_sequence()
	_setup_progress_bar()
	_spawn_next_qte()

func _setup_qte_sequence():
	if qte_count_override > 0:
		qtes_required = qte_count_override
	else:
		qtes_required = DifficultyDirector.get_enemy_qte_count(enemy_type)

	qtes_required = maxi(1, qtes_required)

func _setup_progress_bar():
	progress_bar = ProgressBar.new()
	progress_bar.position = progress_bar_offset
	progress_bar.size = progress_bar_size
	progress_bar.min_value = 0
	progress_bar.max_value = qtes_required
	progress_bar.value = qtes_completed
	progress_bar.show_percentage = false
	add_child(progress_bar)

func _spawn_next_qte():
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

func _update_progress_bar():
	if progress_bar:
		progress_bar.value = qtes_completed

func _get_qte_position() -> Vector2:
	if qte_marker_path != NodePath():
		var marker = get_node_or_null(qte_marker_path)
		if marker is Marker2D:
			return marker.position

	return qte_offset

func _on_QTE_succeded(_pos):
	active_qte = null
	qtes_completed += 1
	_update_progress_bar()

	if qtes_completed >= qtes_required:
		enemy_killed.emit()
		enemy_removed.emit()
		queue_free()
	else:
		_spawn_next_qte()

func _on_QTE_failed(_pos):
	active_qte = null
	do_damage.emit()
	enemy_removed.emit()
	queue_free()
