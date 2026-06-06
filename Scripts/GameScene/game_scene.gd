class_name GameScene extends Node2D

@export var health: int

var key_event: InputEvent
var key_qtes: Array[QTEBase] = []
var kills: int = 0

signal game_over(score)

var health_max: int
var global_spawn_timer: Timer

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
	for qte in key_qtes.duplicate():
		if is_instance_valid(qte):
			_mark_input_as_handled()
			qte.force_fail()
			return
		remove_key_qte(qte)

func _ready():
	health_max = health
	DifficultyDirector.reset()
	DifficultyDirector.update_door_health(health, health_max)
	
	# Set up a single global timer for all enemy spawn points.
	global_spawn_timer = Timer.new()
	global_spawn_timer.one_shot = true
	global_spawn_timer.timeout.connect(_on_global_spawn_timeout)
	add_child(global_spawn_timer)
	global_spawn_timer.start(1.0) # Start generating events after a brief 1-second pause

	$HealthLabel.text = "DOOR HELTH: " + str(health)

func _on_global_spawn_timeout():
	if not DifficultyDirector.can_spawn_enemy():
		global_spawn_timer.start(DifficultyDirector.get_spawn_delay())
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
	global_spawn_timer.start(DifficultyDirector.get_spawn_delay())

func _spawn_enemy_at_crack(crack: Crack):
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

	# Check if the screen is completely empty
	var screen_empty = true
	for child in get_children():
		if child is Crack and child.has_active_monster:
			screen_empty = false
			break

	if screen_empty:
		# Fast-track the next spawn if the player cleared everything
		global_spawn_timer.start(DifficultyDirector.get_clear_screen_spawn_delay())

func _on_do_damage():
	if health <= 0:
		return

	health -= 1
	DifficultyDirector.update_door_health(health, health_max)
	$HealthLabel.text = "DOOR HELTH: " + str(health)

	if health <= 0:
		doGameOver()
		return

func doGameOver():
	game_over.emit(kills)

func _unhandled_input(event):
	if DifficultyDirector.is_input_on_cooldown():
		_mark_input_as_handled()
		return
