class_name GameScene extends Node2D

@export var health: int

var kills: int = 0

signal game_over(score)

var health_max: int
var global_spawn_timer: Timer

func _ready():
	health_max = health
	DifficultyDirector.reset()
	DifficultyDirector.update_door_health(health, health_max)
	
	# Set up a single global timer for all cracks
	global_spawn_timer = Timer.new()
	global_spawn_timer.one_shot = true
	global_spawn_timer.timeout.connect(_on_global_spawn_timeout)
	add_child(global_spawn_timer)
	global_spawn_timer.start(1.0) # Start generating events after a brief 1-second pause
	
	for child in get_children():
		if child is Crack:
			child.kill.connect(_on_enemy_kill)
			child.damage.connect(_on_do_damage)
	$HealthLabel.text = "DOOR HELTH: " + str(health)

func _on_global_spawn_timeout():
	var available_cracks = []
	for child in get_children():
		if child is Crack and not child.has_active_monster:
			available_cracks.append(child)
			
	var count = DifficultyDirector.get_spawn_count()
	
	while count > 0 and available_cracks.size() > 0:
		var random_crack = available_cracks.pick_random()
		random_crack.spawn_monster()
		available_cracks.erase(random_crack)
		count -= 1
		
	# Ask director how long until the next monster spawns
	global_spawn_timer.start(DifficultyDirector.get_spawn_delay())

func _on_enemy_kill():
	kills += 1
	
	# Check if the screen is completely empty
	var screen_empty = true
	for child in get_children():
		if child is Crack and child.has_active_monster:
			screen_empty = false
			break
			
	if screen_empty:
		# Fast-track the next spawn if the player cleared everything
		global_spawn_timer.start(1.0)

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
		get_viewport().set_input_as_handled()
		return

	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.key_label in [KEY_W, KEY_A, KEY_S, KEY_D]:
			get_viewport().set_input_as_handled()
			_on_do_damage()
