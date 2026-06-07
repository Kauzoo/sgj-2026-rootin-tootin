class_name GameScene extends Node2D

@export var health: int

var key_event: InputEvent
var key_qtes: Array[QTEBase] = []
var kills: int = 0

signal game_over(score)

var health_max: int
var global_spawn_timer: Timer
var game_is_over: bool = false

@export var healthBar: ProgressBar
@export var defaultFill: Color
@export var damage_shake_strength: float = 8.0
@export var damage_shake_duration: float = 0.25

var damage_shake_tween: Tween
var damage_shake_camera: Camera2D
var damage_shake_base_offset: Vector2

func add_key_qte(qte):
	key_qtes.append(qte)

func remove_key_qte(qte):
	key_qtes.erase(qte)

func _mark_input_as_handled():
	var viewport = get_viewport()
	if viewport:
		viewport.set_input_as_handled()

func _unhandled_key_input(event: InputEvent):
	key_event = event
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.key_label in [KEY_W, KEY_A, KEY_S, KEY_D]:
			var handled = false
			
			# sort: real QTEs first, fake QTEs last
			var sorted_qtes = key_qtes.duplicate()
			sorted_qtes.sort_custom(func(a, b):
				return not (a is FakeQTE) and (b is FakeQTE)
			)
			
			for qte in sorted_qtes:
				if is_instance_valid(qte):
					if await qte.check_event(key_event):
						handled = true
						break
				else:
					remove_key_qte(qte)
			if not handled:
				_fail_first_active_qte()

func _fail_first_active_qte():
	var has_active_qte = false

	for qte in key_qtes.duplicate():
		if is_instance_valid(qte):
			has_active_qte = true

			if qte is FakeQTE:
				continue

			_mark_input_as_handled()
			qte.force_fail()
			return
		remove_key_qte(qte)

	if has_active_qte:
		_mark_input_as_handled()

func _ready():
	health_max = health
	healthBar.max_value = health_max
	healthBar.value = health
	
	var fill_style = healthBar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style:
		fill_style.bg_color = defaultFill
	
	DifficultyDirector.reset()
	DifficultyDirector.door_sprite = $DoorSprite
	$DoorSprite.texture.region.position.x = 0
	DifficultyDirector.update_door_health(health, health_max)
	
	# Set up a single global timer for all enemy spawn points.
	global_spawn_timer = Timer.new()
	global_spawn_timer.one_shot = true
	global_spawn_timer.timeout.connect(_on_global_spawn_timeout)
	add_child(global_spawn_timer)
	_start_global_spawn_timer(1.0) # Start generating events after a brief 1-second pause

func _on_global_spawn_timeout():
	if game_is_over:
		return

	if not DifficultyDirector.can_spawn_enemy():
		_start_global_spawn_timer(DifficultyDirector.get_spawn_delay())
		return

	var available_cracks = []
	for child in get_children():
		if child is Crack and not child.has_active_monster:
			available_cracks.append(child)
			
	var open_enemy_slots = DifficultyDirector.get_max_active_enemies() - DifficultyDirector.get_active_enemy_count()
	var count = mini(DifficultyDirector.get_spawn_count(), open_enemy_slots)

	while count > 0 and available_cracks.size() > 0:
		var random_crack = available_cracks.pick_random()
		_spawn_enemy_at_crack(random_crack)
		available_cracks.erase(random_crack)
		count -= 1

	# Ask director how long until the next monster spawns
	_start_global_spawn_timer(DifficultyDirector.get_spawn_delay())

func _spawn_enemy_at_crack(crack: Crack):
	if game_is_over:
		return

	if crack.has_active_monster:
		return

	var enemy_scene = DifficultyDirector.get_enemy_scene()
	if enemy_scene == null:
		return

	var enemy = enemy_scene.instantiate() as EnemyBase
	if enemy == null:
		push_error("GameScene: DifficultyDirector returned a scene that is not an EnemyBase.")
		return

	crack.has_active_monster = true
	enemy.position = crack.position
	enemy.enemy_killed.connect(_on_enemy_kill)
	enemy.enemy_removed.connect(_on_enemy_removed.bind(crack))
	enemy.do_damage.connect(_on_do_damage)
	DifficultyDirector.register_enemy_spawn(enemy)
	add_child(enemy)

	if enemy.has_special_attack():
		DifficultyDirector.register_special_spawn(enemy)

func _on_enemy_kill():
	kills += 1

func _on_enemy_removed(crack: Crack):
	crack.has_active_monster = false

	if game_is_over or not is_inside_tree():
		return

	# Check if the screen is completely empty
	var screen_empty = true
	for child in get_children():
		if child is Crack and child.has_active_monster:
			screen_empty = false
			break

	if screen_empty:
		# Fast-track the next spawn if the player cleared everything
		_start_global_spawn_timer(DifficultyDirector.get_clear_screen_spawn_delay())

func _on_do_damage():
	if health <= 0:
		return

	health -= 1
	healthBar.value = health
	var ratio = float(health) / float(health_max)
	var fill_style = healthBar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style and health <= 2:
		fill_style.bg_color = Color(1, 0, 0)
	DifficultyDirector.update_door_health(health, health_max)
	
	_flash_damage()
	_shake_camera()

	if health <= 0:
		doGameOver()
		return

func _flash_damage():
	var tween = create_tween()
	$DamageFlash.color.a = 0.4          # start visible
	tween.tween_property($DamageFlash, "color:a", 0.0, 0.4)

func _shake_camera():
	var camera = get_viewport().get_camera_2d()
	if camera == null:
		camera = $Camera2D
	if camera == null:
		return

	if damage_shake_tween:
		damage_shake_tween.kill()
		_finish_camera_shake()

	damage_shake_camera = camera
	damage_shake_base_offset = camera.offset
	damage_shake_tween = create_tween()
	damage_shake_tween.tween_method(
		Callable(self, "_apply_camera_shake"),
		damage_shake_strength,
		0.0,
		damage_shake_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	damage_shake_tween.finished.connect(_finish_camera_shake)

func _apply_camera_shake(strength: float):
	if not is_instance_valid(damage_shake_camera):
		return

	damage_shake_camera.offset = damage_shake_base_offset + Vector2(
		randf_range(-strength, strength),
		randf_range(-strength, strength)
	)

func _finish_camera_shake():
	if is_instance_valid(damage_shake_camera):
		damage_shake_camera.offset = damage_shake_base_offset
	damage_shake_camera = null
	damage_shake_tween = null

func doGameOver():
	if game_is_over:
		return

	game_is_over = true
	if global_spawn_timer and global_spawn_timer.is_inside_tree():
		global_spawn_timer.stop()

	game_over.emit(kills * 10)

func _start_global_spawn_timer(delay: float):
	if game_is_over:
		return
	if global_spawn_timer == null or not global_spawn_timer.is_inside_tree():
		return

	global_spawn_timer.start(delay)

func _unhandled_input(event):
	if DifficultyDirector.is_input_on_cooldown():
		_mark_input_as_handled()
		return
