extends Node

enum PacingState { BUILD, PEAK, BREATHER }

@export var difficulty_curve: Curve
@export var min_spawn_delay: float = 1.5
@export var max_spawn_delay: float = 5.0
@export var critical_health_threshold_percent: float = 0.25

@export var build_duration: float = 40.0
@export var peak_duration: float = 15.0
@export var breather_duration: float = 12.0

var current_state: PacingState = PacingState.BUILD
var state_timer: float = 0.0
var total_time: float = 0.0
var door_health_percent: float = 1.0
var input_cooldown: float = 0.0

# AI configurations mapped in Inspector
var basic_qte_ai: PackedScene = preload("res://Scenes/Enemies/EnemyBase.tscn")
var button_mash_ai: PackedScene = preload("res://Scenes/Enemies/MashEnemy.tscn")
var long_press_ai: PackedScene = null
var quick_combo_ai: PackedScene = null
var fake_buttons_ai: PackedScene = null

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
	# Sample difficulty curve or linear fallback based on 4 min timescale
	var time_factor = clamp(total_time / 600.0, 0.0, 1.0)
	var difficulty = time_factor
	if difficulty_curve:
		difficulty = difficulty_curve.sample(time_factor)
		
	var delay = lerp(max_spawn_delay, min_spawn_delay, difficulty)
	
	# Pacing adjustments
	if current_state == PacingState.PEAK:
		delay *= 0.5
	elif current_state == PacingState.BREATHER:
		delay *= 1.25 # Much softer breather, no big break
		
	# Panic scaling
	if door_health_percent <= critical_health_threshold_percent:
		delay *= 1.5 
		
	return max(0.1, delay)

func get_enemy_scene(fallback_array: Array[PackedScene]) -> PackedScene:
	var time_factor = clamp(total_time / 600.0, 0.0, 1.0)
	var weights = _get_weights(time_factor)
	var r = randf()
	var chosen_scene = null
	var cumulative = 0.0
	
	if r < cumulative + weights.get("basic", 0.0):
		chosen_scene = basic_qte_ai
	cumulative += weights.get("basic", 0.0)
	
	if chosen_scene == null and r < cumulative + weights.get("long_press", 0.0):
		chosen_scene = long_press_ai
	cumulative += weights.get("long_press", 0.0)
	
	if chosen_scene == null and r < cumulative + weights.get("button_mash", 0.0):
		chosen_scene = button_mash_ai
	cumulative += weights.get("button_mash", 0.0)
	
	if chosen_scene == null and r < cumulative + weights.get("quick_combo", 0.0):
		chosen_scene = quick_combo_ai
	cumulative += weights.get("quick_combo", 0.0)
	
	if chosen_scene == null and r < cumulative + weights.get("fake_buttons", 0.0):
		chosen_scene = fake_buttons_ai

	if chosen_scene == null and fallback_array.size() > 0:
		chosen_scene = fallback_array[randi_range(0, fallback_array.size() - 1)]
		
	return chosen_scene

func _get_weights(time_factor: float) -> Dictionary:
	# 1. RAPID ONBOARDING (0.0 to 0.2)
	# Quickly bleed in the mechanics so the player sees them all early.
	if time_factor < 0.05:
		return { "basic": 1.0, "long_press": 0.0, "button_mash": 0.0, "quick_combo": 0.0, "fake_buttons": 0.0 }
	elif time_factor < 0.10:
		return { "basic": 0.7, "long_press": 0.3, "button_mash": 0.0, "quick_combo": 0.0, "fake_buttons": 0.0 }
	elif time_factor < 0.15:
		return { "basic": 0.6, "long_press": 0.2, "button_mash": 0.2, "quick_combo": 0.0, "fake_buttons": 0.0 }
	elif time_factor < 0.20:
		# All mechanics are now in the pool by 20% of the timeline
		return { "basic": 0.6, "long_press": 0.15, "button_mash": 0.1, "quick_combo": 0.1, "fake_buttons": 0.05 }
		
	# 2. ESCALATION & MASTERY (0.2 to 1.0)
	# Keep basic QTEs as the main mechanic, and slowly introduce the special ones 
	# as rare, high-pressure threats rather than replacing the basics.
	else:
		# Normalize the remaining time factor to a 0.0 - 1.0 scale
		var escalation_factor = (time_factor - 0.2) / 0.8
		
		return {
			"basic": lerp(0.6, 0.6, escalation_factor),
			"long_press": lerp(0.15, 0.1, escalation_factor),
			"button_mash": lerp(0.1, 0.1, escalation_factor),
			"quick_combo": lerp(0.1, 0.1, escalation_factor),
			"fake_buttons": lerp(0.05, 0.1, escalation_factor)
		}

func reset():
	current_state = PacingState.BUILD
	state_timer = 0.0
	total_time = 0.0
	door_health_percent = 1.0

# Mechanical scaling helpers
func get_qte_complexity() -> int:
	var time_factor = clamp(total_time / 600.0, 0.0, 1.0)
	if time_factor < 0.33:
		return 1
	elif time_factor < 0.66:
		return 3
	else:
		return 5

func get_qte_time_window(base_window: float) -> float:
	var time_factor = clamp(total_time / 600.0, 0.0, 1.0)
	var difficulty = difficulty_curve.sample(time_factor) if difficulty_curve else time_factor
	return lerp(base_window, base_window * 0.5, difficulty)

func start_input_cooldown(duration: float = 0.25) -> void:
	if input_cooldown < duration:
		input_cooldown = duration

func is_input_on_cooldown() -> bool:
	return input_cooldown > 0.0
