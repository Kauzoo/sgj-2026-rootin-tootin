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

func _unhandled_key_input(event: InputEvent):
	key_event = event
	if event is InputEventKey and event.pressed and not event.is_echo():
			if event.key_label in [KEY_W, KEY_A, KEY_S, KEY_D]:
				var _a = key_qtes.all(check)
				get_viewport().set_input_as_handled()
				_on_do_damage()

func check(qte):
	qte.check_event(key_event)
	return qte.key != key_event.key_label

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
	$HealthLabel.text = "DOOR HELTH: " + String.num_uint64(health)

func _on_global_spawn_timeout():
	var available_cracks = []
	for child in get_children():
		if child is Crack and not child.has_active_monster:
			available_cracks.append(child)
			
	if available_cracks.size() > 0:
		var random_crack = available_cracks.pick_random()
		random_crack.spawn_monster()
		
	# Ask director how long until the next monster spawns
	global_spawn_timer.start(DifficultyDirector.get_spawn_delay())

func _on_enemy_kill():
	kills += 1

func _on_do_damage():
	if health <= 1 :
		doGameOver()
		return

	health -= 1
	DifficultyDirector.update_door_health(health, health_max)
	$HealthLabel.text = "DOOR HELTH: " + String.num_uint64(health)

func doGameOver():
	game_over.emit(kills)
