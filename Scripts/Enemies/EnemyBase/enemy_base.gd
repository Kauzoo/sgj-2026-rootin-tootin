class_name EnemyBase extends Node2D

@export var QTE_Node: PackedScene
@export var basic_qte_scene: PackedScene
@export var special_qte_scene: PackedScene
@export var special_qte_index: int = 0
@export var QTE_Nodes: Array[PackedScene] = []
@export var QTE_Sequence: Array[PackedScene] = []
@export var repeat_qte_sequence: bool = true
@export var qte_offset: Vector2 = Vector2(0, -70)
@export_node_path("Marker2D") var qte_marker_path: NodePath
@export var qte_marker_paths: Array[NodePath] = []
@export var qte_count_override: int = 0
@export var simultaneous_qte_count_override: int = 0
@export var progress_bar_offset: Vector2 = Vector2(-32, -105)
@export var progress_bar_size: Vector2 = Vector2(64, 8)
@export var qte_position_jitter: Vector2 = Vector2(28, 18)
@export var qte_screen_margin: Vector2 = Vector2(56, 56)

var active_qtes: Array[QTEBase] = []
var qtes_required: int = 1
var qtes_completed: int = 0
var simultaneous_qte_count: int = 1
var progress_bar: ProgressBar
var is_resolved: bool = false

signal enemy_killed()
signal enemy_removed()
signal do_damage()

func _ready():
	add_to_group("enemy")
	_setup_qte_sequence()
	_setup_progress_bar()
	$AnimatedSprite.spawned.connect(_spawn_next_qte_wave)

func _setup_qte_sequence():
	if qte_count_override > 0:
		qtes_required = qte_count_override
	else:
		qtes_required = DifficultyDirector.get_enemy_qte_count(self)

	qtes_required = maxi(1, qtes_required)

	if simultaneous_qte_count_override > 0:
		simultaneous_qte_count = simultaneous_qte_count_override
	else:
		simultaneous_qte_count = DifficultyDirector.get_enemy_simultaneous_qte_count(self)

	simultaneous_qte_count = maxi(1, simultaneous_qte_count)

func _setup_progress_bar():
	progress_bar = ProgressBar.new()
	progress_bar.position = progress_bar_offset
	progress_bar.size = progress_bar_size
	progress_bar.min_value = 0
	progress_bar.max_value = qtes_required
	progress_bar.show_percentage = false
	add_child(progress_bar)
	_update_progress_bar()

func _spawn_next_qte_wave():
	if active_qtes.size() > 0 or is_resolved:
		return

	var qtes_left = qtes_required - qtes_completed
	var wave_size = mini(simultaneous_qte_count, qtes_left)
	for index in range(wave_size):
		_spawn_qte(qtes_completed + index)

func _spawn_qte(qte_index: int):
	var qte_scene = _get_qte_scene(qte_index)
	if qte_scene == null:
		push_error("EnemyBase: No QTE scene configured.")
		return

	var instance = qte_scene.instantiate() as QTEBase
	if instance == null:
		push_error("EnemyBase: QTE scene must instantiate a QTEBase.")
		return

	active_qtes.append(instance)
	instance.position = _get_qte_position(qte_index)
	instance.QTE_failed.connect(_on_QTE_failed.bind(instance))
	instance.QTE_succeded.connect(_on_QTE_succeded.bind(instance))
	add_child(instance)

func _get_qte_scene(qte_index: int) -> PackedScene:
	if has_special_attack():
		var clamped_special_index = clampi(special_qte_index, 0, qtes_required - 1)
		if qte_index == clamped_special_index:
			return special_qte_scene

		if basic_qte_scene:
			return basic_qte_scene

	if basic_qte_scene:
		return basic_qte_scene

	if qte_index < QTE_Sequence.size():
		return QTE_Sequence[qte_index]

	if repeat_qte_sequence and QTE_Sequence.size() > 0:
		return QTE_Sequence[qte_index % QTE_Sequence.size()]

	if QTE_Nodes.size() > 0:
		return QTE_Nodes.pick_random()

	return QTE_Node

func has_special_attack() -> bool:
	return special_qte_scene != null

func get_min_qte_count() -> int:
	return 1

func _update_progress_bar():
	if progress_bar:
		progress_bar.value = _get_remaining_health()

func _get_remaining_health() -> int:
	return maxi(0, qtes_required - qtes_completed)

func _get_qte_position(qte_index: int) -> Vector2:
	var position = _get_base_qte_position(qte_index)
	position += Vector2(
		randf_range(-qte_position_jitter.x, qte_position_jitter.x),
		randf_range(-qte_position_jitter.y, qte_position_jitter.y)
	)

	return _clamp_qte_position_to_screen(position)

func _get_base_qte_position(qte_index: int) -> Vector2:
	if qte_marker_paths.size() > 0:
		var marker_path = qte_marker_paths[qte_index % qte_marker_paths.size()]
		var marker = get_node_or_null(marker_path)
		if marker is Marker2D:
			return marker.position

	if qte_marker_path != NodePath():
		var marker = get_node_or_null(qte_marker_path)
		if marker is Marker2D:
			return marker.position

	return qte_offset

func _clamp_qte_position_to_screen(local_position: Vector2) -> Vector2:
	var viewport = get_viewport()
	if viewport == null:
		return local_position

	var canvas_transform = viewport.get_canvas_transform()
	var screen_position = canvas_transform * to_global(local_position)
	var viewport_size = viewport.get_visible_rect().size
	var min_position = qte_screen_margin
	var max_position = viewport_size - qte_screen_margin

	screen_position.x = clamp(screen_position.x, min_position.x, max_position.x)
	screen_position.y = clamp(screen_position.y, min_position.y, max_position.y)

	return to_local(canvas_transform.affine_inverse() * screen_position)

func _on_QTE_succeded(_pos, qte: QTEBase):
	if is_resolved:
		return

	if qte:
		active_qtes.erase(qte)

	qtes_completed += 1
	_update_progress_bar()

	if qtes_completed >= qtes_required:
		is_resolved = true
		_clear_active_qtes()
		enemy_killed.emit()
		enemy_removed.emit()
		$AnimatedSprite.die()
		$AnimatedSprite.done_animation.connect(queue_free)
	elif active_qtes.size() == 0:
		_spawn_next_qte_wave()

func _on_QTE_failed(_pos, _qte: QTEBase):
	if is_resolved:
		return

	is_resolved = true
	_clear_active_qtes()
	do_damage.emit()
	enemy_removed.emit()
	$AnimatedSprite.die()
	$AnimatedSprite.done_animation.connect(queue_free)

func _clear_active_qtes():
	for qte in active_qtes:
		if is_instance_valid(qte):
			qte.unregister_key_qte()
			qte.queue_free()
	active_qtes.clear()
