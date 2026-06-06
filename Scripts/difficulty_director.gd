extends Node

enum PacingState { BUILD, PEAK, BREATHER }
enum EnemyType { BASIC, LONG_PRESS, BUTTON_MASH, QUICK_COMBO, FAKE_BUTTONS }

@export var difficulty_curve: Curve
@export var difficulty_ramp_duration: float = 180.0
@export var opening_grace_duration: float = 8.0
@export var min_spawn_delay: float = 0.95
@export var max_spawn_delay: float = 3.2
@export var critical_health_threshold_percent: float = 0.25

@export var build_duration: float = 28.0
@export var peak_duration: float = 14.0
@export var breather_duration: float = 10.0
@export var special_enemy_cap: int = 1
@export var special_enemy_cooldown: float = 18.0

var current_state: PacingState = PacingState.BUILD
var state_timer: float = 0.0
var total_time: float = 0.0
var door_health_percent: float = 1.0
var input_cooldown: float = 0.0
var last_special_spawn_time: float = -999.0

# Tracks the number of special QTE enemies currently alive on screen
var active_special_qtes: int = 0

# AI configurations mapped in Inspector
var basic_qte_ai: PackedScene = preload("res://Scenes/Enemies/EnemyBase.tscn")
var button_mash_ai: PackedScene = preload("res://Scenes/Enemies/MashEnemy.tscn")
@export var long_press_ai: PackedScene = null
@export var quick_combo_ai: PackedScene = preload("res://Scenes/Enemies/ComboEnemy.tscn")
@export var fake_buttons_ai: PackedScene = null

func _process(delta: float) -> void:
	total_time += delta
	state_timer += delta
	
	if input_cooldown > 0.0:
		input_cooldown -= delta
	
	match current_state:
		PacingState.BUILD:
			if state_timer >= build_duration:
				current_state = PacingState.PEAK
				state_timer = 0.0
		PacingState.PEAK:
			if state_timer >= peak_duration:
				current_state = PacingState.BREATHER
				state_timer = 0.0
		PacingState.BREATHER:
			if state_timer >= breather_duration:
				current_state = PacingState.BUILD
				state_timer = 0.0

func update_door_health(current: int, maximum: int) -> void:
	if maximum > 0:
		door_health_percent = float(current) / float(maximum)
	else:
		door_health_percent = 1.0

func get_difficulty_factor() -> float:
	var time_factor = clamp(total_time / difficulty_ramp_duration, 0.0, 1.0)
	if difficulty_curve:
		return clamp(difficulty_curve.sample(time_factor), 0.0, 1.0)

	return pow(time_factor, 0.85)

func get_spawn_delay() -> float:
	var difficulty = get_difficulty_factor()
	var delay = lerp(max_spawn_delay, min_spawn_delay, difficulty)
	
	if current_state == PacingState.PEAK:
		delay *= 0.78
	elif current_state == PacingState.BREATHER:
		delay *= 1.3

	if total_time < opening_grace_duration:
		delay = max(delay, 2.6)

	if door_health_percent <= critical_health_threshold_percent:
		delay *= 1.55
	elif door_health_percent <= 0.45:
		delay *= 1.25
		
	return max(0.1, delay)

func get_spawn_count() -> int:
	return 1

func get_enemy_type() -> int:
	if active_special_qtes >= special_enemy_cap or total_time - last_special_spawn_time < special_enemy_cooldown:
		return EnemyType.BASIC

	var weights = _get_weights()
	var r = randf()
	var cumulative = 0.0
	
	# Clean, rolling cumulative probability check. 
	# If a scene field is null, it gracefully falls back to the basic QTE enemy.
	cumulative += weights.get("basic", 0.0)
	if r < cumulative: 
		return EnemyType.BASIC
	
	cumulative += weights.get("long_press", 0.0)
	if r < cumulative: 
		return EnemyType.LONG_PRESS
	
	cumulative += weights.get("button_mash", 0.0)
	if r < cumulative: 
		return EnemyType.BUTTON_MASH
	
	cumulative += weights.get("quick_combo", 0.0)
	if r < cumulative: 
		return EnemyType.QUICK_COMBO
	
	cumulative += weights.get("fake_buttons", 0.0)
	if r < cumulative: 
		return EnemyType.FAKE_BUTTONS

	return EnemyType.BASIC

func get_enemy_scene(enemy_type: int) -> PackedScene:
	match enemy_type:
		EnemyType.LONG_PRESS:
			return long_press_ai if long_press_ai else basic_qte_ai
		EnemyType.BUTTON_MASH:
			return button_mash_ai if button_mash_ai else basic_qte_ai
		EnemyType.QUICK_COMBO:
			return quick_combo_ai if quick_combo_ai else basic_qte_ai
		EnemyType.FAKE_BUTTONS:
			return fake_buttons_ai if fake_buttons_ai else basic_qte_ai
		_:
			return basic_qte_ai

func is_special_enemy_type(enemy_type: int) -> bool:
	return enemy_type != EnemyType.BASIC and get_enemy_scene(enemy_type) != basic_qte_ai

func get_enemy_qte_count(enemy_type: int) -> int:
	var difficulty = get_difficulty_factor()
	var count = 1

	if total_time >= 14.0:
		count = 2
	if difficulty > 0.45:
		count = 3
	if difficulty > 0.72:
		count = 4
	if current_state == PacingState.PEAK and difficulty > 0.28:
		count += 1

	if enemy_type == EnemyType.BUTTON_MASH:
		count = maxi(2, count)
	if enemy_type == EnemyType.QUICK_COMBO:
		count = maxi(3, count)

	return maxi(1, count)

func get_enemy_simultaneous_qte_count(enemy_type: int) -> int:
	return 1

func _get_weights() -> Dictionary:
	var difficulty = get_difficulty_factor()
	var weights = {
		"basic": lerp(1.0, 0.42, difficulty),
		"long_press": 0.0,
		"button_mash": 0.0,
		"quick_combo": 0.0,
		"fake_buttons": 0.0
	}

	if total_time >= 10.0:
		weights["button_mash"] = lerp(0.08, 0.14, difficulty)
	if total_time >= 35.0:
		weights["quick_combo"] = lerp(0.04, 0.1, difficulty)
	if total_time >= 45.0 and long_press_ai:
		weights["long_press"] = lerp(0.04, 0.1, difficulty)
	if total_time >= 60.0 and fake_buttons_ai:
		weights["fake_buttons"] = lerp(0.03, 0.08, difficulty)

	if current_state == PacingState.BREATHER:
		weights["basic"] += 0.25
		weights["quick_combo"] *= 0.55
	elif current_state == PacingState.PEAK:
		weights["button_mash"] *= 1.2
		weights["quick_combo"] *= 1.25

	return _normalize_weights(weights)

func _normalize_weights(weights: Dictionary) -> Dictionary:
	var total = 0.0
	for value in weights.values():
		total += value

	if total <= 0.0:
		return { "basic": 1.0, "long_press": 0.0, "button_mash": 0.0, "quick_combo": 0.0, "fake_buttons": 0.0 }

	for key in weights.keys():
		weights[key] = weights[key] / total

	return weights

# Called automatically by special enemies when they initialize in the scene tree
func register_special_spawn(enemy_node: Node) -> void:
	active_special_qtes += 1
	last_special_spawn_time = total_time
	
	# Automatically listens for the enemy's deletion/death to clear up the slot
	enemy_node.tree_exiting.connect(func():
		active_special_qtes = max(0, active_special_qtes - 1)
	)

func reset() -> void:
	current_state = PacingState.BUILD
	state_timer = 0.0
	total_time = 0.0
	door_health_percent = 1.0
	active_special_qtes = 0
	last_special_spawn_time = -999.0

func get_qte_time_window(base_window: float) -> float:
	var difficulty = get_difficulty_factor()
	var minimum_window = base_window * 0.55
	if door_health_percent <= critical_health_threshold_percent:
		minimum_window = base_window * 0.7

	return lerp(base_window, minimum_window, difficulty)

func start_input_cooldown(duration: float = 0.25) -> void:
	if input_cooldown < duration:
		input_cooldown = duration

func is_input_on_cooldown() -> bool:
	return input_cooldown > 0.0
