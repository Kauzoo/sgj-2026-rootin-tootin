extends Node

enum PacingState { BUILD, PEAK, BREATHER }
enum EnemyType { BASIC, LONG_PRESS, BUTTON_MASH, QUICK_COMBO, FAKE_BUTTONS }

@export var difficulty_curve: Curve
@export var min_spawn_delay: float = 1.2
@export var max_spawn_delay: float = 3.5
@export var critical_health_threshold_percent: float = 0.25

@export var build_duration: float = 40.0
@export var peak_duration: float = 15.0
@export var breather_duration: float = 12.0

var current_state: PacingState = PacingState.BUILD
var state_timer: float = 0.0
var total_time: float = 0.0
var door_health_percent: float = 1.0
var input_cooldown: float = 0.0

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

func get_spawn_delay() -> float:
	# Sample difficulty curve or linear fallback based on 10 min timescale
	var time_factor = clamp(total_time / 600.0, 0.0, 1.0)
	var difficulty = time_factor
	if difficulty_curve:
		difficulty = difficulty_curve.sample(time_factor)
		
	var delay = lerp(max_spawn_delay, min_spawn_delay, difficulty)
	
	# Pacing adjustments
	if current_state == PacingState.PEAK:
		delay *= 0.75
	elif current_state == PacingState.BREATHER:
		delay *= 1.25 # Much softer breather, no big break
		
	# Panic scaling
	if door_health_percent <= critical_health_threshold_percent:
		delay *= 1.5 
		
	return max(0.1, delay)

func get_spawn_count() -> int:
	var time_factor = clamp(total_time / 600.0, 0.0, 1.0)
	var max_concurrent = 2
	if time_factor > 0.2:
		max_concurrent = 3
	if time_factor > 0.5:
		max_concurrent = 4
	
	# Skew towards lower numbers so it's not constantly spawning max amount
	var count = randi_range(1, max_concurrent)
	if count > 1 and randf() < 0.5:
		count -= 1
		
	return count

func get_enemy_type() -> int:
	if active_special_qtes > 0:
		return EnemyType.BASIC

	var time_factor = clamp(total_time / 600.0, 0.0, 1.0)
	var weights = _get_weights(time_factor)
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

func _get_weights(time_factor: float) -> Dictionary:
	# 1. RAPID ONBOARDING (0.0 to 0.2)
	# Quickly bleed in the mechanics so the player sees them all early.
	if time_factor < 0.05:
		return { "basic": 1.0, "long_press": 0.0, "button_mash": 0.0, "quick_combo": 0.0, "fake_buttons": 0.0 }
	elif time_factor < 0.10:
		return { "basic": 0.7, "long_press": 0.3, "button_mash": 0.0, "quick_combo": 0.0, "fake_buttons": 0.0 }
	elif time_factor < 0.15:
		return { "basic": 0.5, "long_press": 0.2, "button_mash": 0.3, "quick_combo": 0.0, "fake_buttons": 0.0 }
	elif time_factor < 0.20:
		# All mechanics are now in the pool by 20% of the timeline
		return { "basic": 0.4, "long_press": 0.15, "button_mash": 0.15, "quick_combo": 0.15, "fake_buttons": 0.15 }
		
	# 2. ESCALATION & MASTERY (0.2 to 1.0)
	# Basic QTEs remain a core pressure element, while un-implemented mechanics now scale up smoothly
	else:
		var escalation_factor = (time_factor - 0.2) / 0.8
		
		return {
			"basic": lerp(0.5, 0.3, escalation_factor),
			"long_press": lerp(0.15, 0.15, escalation_factor),
			"button_mash": lerp(0.15, 0.15, escalation_factor),
			"quick_combo": lerp(0.1, 0.2, escalation_factor),
			"fake_buttons": lerp(0.1, 0.2, escalation_factor)
		}

# Called automatically by special enemies when they initialize in the scene tree
func register_special_spawn(enemy_node: Node) -> void:
	active_special_qtes += 1
	
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

func get_qte_time_window(base_window: float) -> float:
	var time_factor = clamp(total_time / 600.0, 0.0, 1.0)
	var difficulty = difficulty_curve.sample(time_factor) if difficulty_curve else time_factor
	return lerp(base_window, base_window * 0.5, difficulty)

func start_input_cooldown(duration: float = 0.25) -> void:
	if input_cooldown < duration:
		input_cooldown = duration

func is_input_on_cooldown() -> bool:
	return input_cooldown > 0.0
