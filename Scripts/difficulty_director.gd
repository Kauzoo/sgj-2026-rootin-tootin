extends Node

# Difficulty Director overview:
# - The game starts in an intro phase. During intro, difficulty stays at 0 and the
#   director guarantees each special enemy type gets introduced once.
# - After a special type has been introduced, intro can repeat that special often,
#   but only if the current special cap and cooldown allow it.
# - After intro, difficulty begins ramping from 0 to 1 over difficulty_ramp_duration.
#   This affects spawn delay, QTE timer windows, enemy health, and special caps.
# - Post-intro pacing cycles through BUILD, PEAK, and BREATHER. BUILD is normal,
#   PEAK is more intense, and BREATHER gives the player a short recovery window.
# - Spawn speed and active enemy count are controlled separately. Spawn delay can
#   be quick, but active enemy caps prevent too many enemies from piling up.
# - Special enemies use the same active-cap system plus their own special cap.
#   min_special_enemy_cap is the starting value, max_special_enemy_cap is the
#   late-game limit, and second_special_unlock_difficulty controls when it scales.
# - Enemy scene selection is scene-based. EnemyBase is basic; MashEnemy,
#   LongPressEnemy, ComboEnemy, and FakeEnemy each define one special QTE, while
#   all other attacks on that enemy use basic QTEs.
# - Post-intro enemy selection uses raw exported weights. The director normalizes
#   those weights before rolling, so values are relative to each other.
# - Enemy QTE count rises over time, but is reduced when the screen is crowded.
#   This avoids impossible situations like several enemies all having high health.
# - QTE timer windows shrink with difficulty, but shrink less aggressively when
#   door health is low.
# - Debug prints can be toggled with debug_prints_enabled. They log intro unlocks,
#   phase changes, spawn decisions, active enemy counts, and special cap behavior.

enum PacingState { BUILD, PEAK, BREATHER }

@export var debug_prints_enabled: bool = true

# Main tuning knobs. The intro phase teaches enemy types first; the difficulty
# ramp only starts after that, so early special enemies do not also become tanky.
@export var difficulty_curve: Curve
@export var difficulty_ramp_duration: float = 120.0
@export var intro_duration: float = 30.0
@export var opening_grace_duration: float = 10.0
@export var min_spawn_delay: float = 0.85
@export var max_spawn_delay: float = 2.25
@export var intro_spawn_delay: float = 1.45
@export var clear_screen_spawn_delay: float = 0.65
@export var critical_health_threshold_percent: float = 0.25

# Pacing cycles after the intro. BUILD is normal pressure, PEAK is a short spike,
# and BREATHER gives the player a little recovery time.
@export var build_duration: float = 28.0
@export var peak_duration: float = 16.0
@export var breather_duration: float = 8.0

# Specials should appear often. This starts at 1 and can scale up later.
@export var min_special_enemy_cap: int = 1
@export var max_special_enemy_cap: int = 2
@export var second_special_unlock_difficulty: float = 0.55
@export var special_enemy_cooldown: float = 4.0
@export var intro_special_chance: float = 0.7

# Post-intro enemy selection weights. These are raw weights and get normalized
# before selection. Start values are used at difficulty 0, end values at difficulty 1.
@export var basic_weight_start: float = 0.55
@export var basic_weight_end: float = 0.35
@export var mash_weight_start: float = 0.24
@export var mash_weight_end: float = 0.18
@export var combo_weight_start: float = 0.16
@export var combo_weight_end: float = 0.16
@export var long_press_weight_start: float = 0.14
@export var long_press_weight_end: float = 0.15
@export var fake_weight_start: float = 0.1
@export var fake_weight_end: float = 0.14

# Enemy count is capped separately from spawn speed. This keeps the game busy
# without allowing too many high-health enemies to pile up.
@export var max_active_enemies_intro: int = 2
@export var max_active_enemies_build: int = 2
@export var max_active_enemies_peak: int = 3
@export var max_active_enemies_late_peak: int = 4

var door_sprite: Sprite2D
var current_state: PacingState = PacingState.BUILD
var state_timer: float = 0.0
var total_time: float = 0.0
var door_health_percent: float = 1.0
var input_cooldown: float = 0.0
var last_special_spawn_time: float = -999.0
var introduced_button_mash: bool = false
var introduced_quick_combo: bool = false
var introduced_long_press: bool = false
var introduced_fake_buttons: bool = false
var active_enemies: int = 0
var was_intro_active: bool = true

# Tracks the number of special QTE enemies currently alive on screen.
var active_special_qtes: int = 0

# Enemy scenes. Each enemy scene decides which QTE is its one special attack.
var basic_qte_ai: PackedScene = preload("res://Scenes/Enemies/EnemyBase.tscn")
var button_mash_ai: PackedScene = preload("res://Scenes/Enemies/MashEnemy.tscn")
var long_press_ai: PackedScene = preload("res://Scenes/Enemies/LongPressEnemy.tscn")
var quick_combo_ai: PackedScene = preload("res://Scenes/Enemies/ComboEnemy.tscn")
var fake_buttons_ai: PackedScene = preload("res://Scenes/Enemies/FakeEnemy.tscn")

func _process(delta: float) -> void:
	total_time += delta
	
	if input_cooldown > 0.0:
		input_cooldown -= delta

	# During intro, keep pacing in BUILD and do not advance the BUILD/PEAK/BREATHER loop.
	if _is_intro_active():
		current_state = PacingState.BUILD
		state_timer = 0.0
		return

	if was_intro_active:
		was_intro_active = false
		_debug_print("INTRO complete -> BUILD. difficulty ramp starts now.")

	state_timer += delta
	
	match current_state:
		PacingState.BUILD:
			if state_timer >= build_duration:
				_set_pacing_state(PacingState.PEAK)
		PacingState.PEAK:
			if state_timer >= peak_duration:
				_set_pacing_state(PacingState.BREATHER)
		PacingState.BREATHER:
			if state_timer >= breather_duration:
				_set_pacing_state(PacingState.BUILD)

func update_door_health(current: int, maximum: int) -> void:
	if maximum > 0:
		door_health_percent = float(current) / float(maximum)
		if door_health_percent < 0.75:
			if door_health_percent < 0.5:
				if door_health_percent < 0.25:
					door_sprite.texture.region.position.x = 78 * 3
					return
				door_sprite.texture.region.position.x = 78 * 2
				return
			door_sprite.texture.region.position.x = 78
	else:
		door_health_percent = 1.0
		door_sprite.texture.region.position.x = 78 * 3

func get_difficulty_factor() -> float:
	# The ramp starts after intro_duration. Before that, difficulty is 0.
	var ramp_time = maxf(0.0, total_time - intro_duration)
	var time_factor = clamp(ramp_time / difficulty_ramp_duration, 0.0, 1.0)
	if difficulty_curve:
		return clamp(difficulty_curve.sample(time_factor), 0.0, 1.0)

	# A power above 1 keeps the beginning softer and ramps harder later.
	return pow(time_factor, 1.15)

func get_spawn_delay() -> float:
	var difficulty = get_difficulty_factor()
	var delay = lerp(max_spawn_delay, min_spawn_delay, difficulty)

	# Intro uses a fixed quick rhythm. Later states modify the delay to create waves.
	if _is_intro_active():
		delay = intro_spawn_delay
	elif current_state == PacingState.PEAK:
		delay *= 0.78
	elif current_state == PacingState.BREATHER:
		delay *= 1.3

	if total_time < opening_grace_duration:
		delay = max(delay, 2.6)

	# If the door is already in trouble, slow the game down a bit.
	if door_health_percent <= critical_health_threshold_percent:
		delay *= 1.55
	elif door_health_percent <= 0.45:
		delay *= 1.25

	var final_delay = max(0.1, delay)
	_debug_print("spawn_delay=", snapped(final_delay, 0.01), " state=", _state_name(current_state), " difficulty=", snapped(difficulty, 0.01), " active=", active_enemies, "/", get_max_active_enemies(), " special=", active_special_qtes, "/", get_special_enemy_cap())
	return final_delay

func get_clear_screen_spawn_delay() -> float:
	# When the player clears the screen, bring the next enemy in quickly.
	return minf(clear_screen_spawn_delay, get_spawn_delay())

func get_spawn_count() -> int:
	return 1

func get_active_enemy_count() -> int:
	return active_enemies

func get_max_active_enemies() -> int:
	# This is the main anti-pileup rule. Spawn speed can stay high, but active
	# enemy count stays bounded.
	if _is_intro_active():
		return max_active_enemies_intro

	var difficulty = get_difficulty_factor()
	if current_state == PacingState.PEAK and difficulty >= 0.75:
		return max_active_enemies_late_peak
	if current_state == PacingState.PEAK:
		return max_active_enemies_peak

	return max_active_enemies_build

func get_special_enemy_cap() -> int:
	if _is_intro_active():
		return min_special_enemy_cap

	var difficulty = get_difficulty_factor()
	if max_special_enemy_cap <= min_special_enemy_cap or difficulty < second_special_unlock_difficulty:
		return min_special_enemy_cap

	var cap_progress = inverse_lerp(second_special_unlock_difficulty, 1.0, difficulty)
	var cap = min_special_enemy_cap + floori(cap_progress * float(max_special_enemy_cap - min_special_enemy_cap)) + 1
	return clampi(cap, min_special_enemy_cap, max_special_enemy_cap)

func get_enemy_scene() -> PackedScene:
	# Intro uses a scripted unlock order, then random repeats of unlocked specials.
	if _is_intro_active():
		var intro_scene = _get_intro_enemy_scene()
		_debug_print("enemy_scene intro -> ", _scene_debug_name(intro_scene))
		return intro_scene

	# If a special is already alive, or the cooldown is still running, spawn basics.
	if not _can_spawn_special_enemy():
		_debug_print("enemy_scene regular -> EnemyBase (special blocked)")
		return basic_qte_ai

	var weights = _get_weights()
	var r = randf()
	var cumulative = 0.0
	
	cumulative += weights.get("basic", 0.0)
	if r < cumulative: 
		_debug_print("enemy_scene regular -> EnemyBase")
		return basic_qte_ai
	
	cumulative += weights.get("long_press", 0.0)
	if r < cumulative: 
		var long_press_scene = long_press_ai if long_press_ai else basic_qte_ai
		_debug_print("enemy_scene regular -> ", _scene_debug_name(long_press_scene))
		return long_press_scene
	
	cumulative += weights.get("button_mash", 0.0)
	if r < cumulative: 
		var button_mash_scene = button_mash_ai if button_mash_ai else basic_qte_ai
		_debug_print("enemy_scene regular -> ", _scene_debug_name(button_mash_scene))
		return button_mash_scene
	
	cumulative += weights.get("quick_combo", 0.0)
	if r < cumulative: 
		var quick_combo_scene = quick_combo_ai if quick_combo_ai else basic_qte_ai
		_debug_print("enemy_scene regular -> ", _scene_debug_name(quick_combo_scene))
		return quick_combo_scene
	
	cumulative += weights.get("fake_buttons", 0.0)
	if r < cumulative: 
		var fake_buttons_scene = fake_buttons_ai if fake_buttons_ai else basic_qte_ai
		_debug_print("enemy_scene regular -> ", _scene_debug_name(fake_buttons_scene))
		return fake_buttons_scene

	_debug_print("enemy_scene regular -> EnemyBase (fallback)")
	return basic_qte_ai

func get_enemy_qte_count(enemy: EnemyBase) -> int:
	var difficulty = get_difficulty_factor()
	var count = 1

	# Intro enemies use their minimum health so the player can learn their gimmick.
	if _is_intro_active():
		return enemy.get_min_qte_count()

	if total_time >= intro_duration + 25.0:
		count = 2
	if difficulty > 0.55:
		count = 3
	if difficulty > 0.88:
		count = 4
	if current_state == PacingState.PEAK and difficulty > 0.5:
		count += 1

	# If the screen is crowded, lower individual enemy health to avoid unwinnable piles.
	if active_enemies >= 3:
		count = mini(count, 2)
	elif active_enemies >= 2:
		count = mini(count, 3)

	return maxi(enemy.get_min_qte_count(), count)

func get_enemy_simultaneous_qte_count(_enemy: EnemyBase) -> int:
	return 1

func _get_weights() -> Dictionary:
	var difficulty = get_difficulty_factor()
	# These weights are normalized later. Basic gets less likely over time, while
	# special enemies stay common whenever the special cap allows one.
	var weights = {
		"basic": lerp(basic_weight_start, basic_weight_end, difficulty),
		"long_press": 0.0,
		"button_mash": 0.0,
		"quick_combo": 0.0,
		"fake_buttons": 0.0
	}

	if total_time >= intro_duration:
		weights["button_mash"] = lerp(mash_weight_start, mash_weight_end, difficulty)
		weights["quick_combo"] = lerp(combo_weight_start, combo_weight_end, difficulty)
		if long_press_ai:
			weights["long_press"] = lerp(long_press_weight_start, long_press_weight_end, difficulty)
		if fake_buttons_ai:
			weights["fake_buttons"] = lerp(fake_weight_start, fake_weight_end, difficulty)

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

func _is_intro_active() -> bool:
	return total_time < intro_duration

func _can_spawn_special_enemy() -> bool:
	return active_special_qtes < get_special_enemy_cap() and total_time - last_special_spawn_time >= special_enemy_cooldown

func _get_intro_enemy_scene() -> PackedScene:
	if not _can_spawn_special_enemy():
		_debug_print("enemy_scene intro -> EnemyBase (special blocked)")
		return basic_qte_ai

	var forced_missing_scene = _get_due_intro_missing_scene()
	if forced_missing_scene:
		return forced_missing_scene

	if _is_intro_running_out():
		var next_missing_scene = _get_next_missing_intro_scene()
		if next_missing_scene:
			_debug_print("INTRO catch-up introducing ", _scene_debug_name(next_missing_scene))
			return next_missing_scene

	# First appearances are guaranteed in a fixed order, so every special type gets taught.
	return _get_repeat_intro_enemy_scene()

func _get_due_intro_missing_scene() -> PackedScene:
	# First appearances are guaranteed in a fixed order, so every special type gets taught.
	if total_time >= _get_intro_unlock_time(0) and not introduced_button_mash and button_mash_ai:
		introduced_button_mash = true
		_debug_print("INTRO introduced MashEnemy")
		return button_mash_ai
	if total_time >= _get_intro_unlock_time(1) and not introduced_quick_combo and quick_combo_ai:
		introduced_quick_combo = true
		_debug_print("INTRO introduced ComboEnemy")
		return quick_combo_ai
	if total_time >= _get_intro_unlock_time(2) and not introduced_long_press and long_press_ai:
		introduced_long_press = true
		_debug_print("INTRO introduced LongPressEnemy")
		return long_press_ai
	if total_time >= _get_intro_unlock_time(3) and not introduced_fake_buttons and fake_buttons_ai:
		introduced_fake_buttons = true
		_debug_print("INTRO introduced FakeEnemy")
		return fake_buttons_ai

	return null

func _get_repeat_intro_enemy_scene() -> PackedScene:
	# After a type has been introduced, it can appear again during intro.
	if randf() < intro_special_chance:
		var available_specials = _get_intro_available_special_scenes()
		if available_specials.size() > 0:
			return available_specials.pick_random()

	return basic_qte_ai

func _is_intro_running_out() -> bool:
	return total_time >= intro_duration * 0.82

func _get_next_missing_intro_scene() -> PackedScene:
	if not introduced_button_mash and button_mash_ai:
		introduced_button_mash = true
		return button_mash_ai
	if not introduced_quick_combo and quick_combo_ai:
		introduced_quick_combo = true
		return quick_combo_ai
	if not introduced_long_press and long_press_ai:
		introduced_long_press = true
		return long_press_ai
	if not introduced_fake_buttons and fake_buttons_ai:
		introduced_fake_buttons = true
		return fake_buttons_ai

	return null

func _get_intro_unlock_time(index: int) -> float:
	var unlock_points = [0.12, 0.32, 0.54, 0.76]
	return intro_duration * unlock_points[index]

func _get_intro_available_special_scenes() -> Array[PackedScene]:
	var available_specials: Array[PackedScene] = []

	if introduced_button_mash and button_mash_ai:
		available_specials.append(button_mash_ai)
	if introduced_quick_combo and quick_combo_ai:
		available_specials.append(quick_combo_ai)
	if introduced_long_press and long_press_ai:
		available_specials.append(long_press_ai)
	if introduced_fake_buttons and fake_buttons_ai:
		available_specials.append(fake_buttons_ai)

	return available_specials

func can_spawn_enemy() -> bool:
	var can_spawn = active_enemies < get_max_active_enemies()
	if not can_spawn:
		_debug_print("spawn blocked by active cap active=", active_enemies, "/", get_max_active_enemies(), " state=", _state_name(current_state))

	return can_spawn

func register_enemy_spawn(enemy_node: Node) -> void:
	# Called by GameScene before add_child(), so the new enemy counts toward its
	# own QTE health calculation in EnemyBase._ready().
	active_enemies += 1
	_debug_print("enemy_spawned active=", active_enemies, "/", get_max_active_enemies())
	enemy_node.tree_exiting.connect(func():
		active_enemies = max(0, active_enemies - 1)
		_debug_print("enemy_removed active=", active_enemies, "/", get_max_active_enemies())
	)

func register_special_spawn(enemy_node: Node) -> void:
	active_special_qtes += 1
	last_special_spawn_time = total_time
	_debug_print("special_spawned active_special=", active_special_qtes, "/", get_special_enemy_cap())

	# Free the special slot when the enemy dies or despawns.
	enemy_node.tree_exiting.connect(func():
		active_special_qtes = max(0, active_special_qtes - 1)
		_debug_print("special_removed active_special=", active_special_qtes, "/", get_special_enemy_cap())
	)

func reset() -> void:
	current_state = PacingState.BUILD
	state_timer = 0.0
	total_time = 0.0
	door_health_percent = 1.0
	active_special_qtes = 0
	active_enemies = 0
	last_special_spawn_time = -999.0
	was_intro_active = true
	introduced_button_mash = false
	introduced_quick_combo = false
	introduced_long_press = false
	introduced_fake_buttons = false
	_debug_print("reset -> INTRO. intro_duration=", intro_duration)

func get_qte_time_window(base_window: float) -> float:
	var difficulty = get_difficulty_factor()
	# QTE timers shrink with difficulty, but not as harshly when the door is low.
	var minimum_window = base_window * 0.55
	if door_health_percent <= critical_health_threshold_percent:
		minimum_window = base_window * 0.7

	return lerp(base_window, minimum_window, difficulty)

func start_input_cooldown(duration: float = 0.25) -> void:
	if input_cooldown < duration:
		input_cooldown = duration

func is_input_on_cooldown() -> bool:
	return input_cooldown > 0.0

func _set_pacing_state(next_state: PacingState) -> void:
	current_state = next_state
	state_timer = 0.0
	_debug_print("phase -> ", _state_name(current_state), " difficulty=", snapped(get_difficulty_factor(), 0.01))

func _state_name(state: PacingState) -> String:
	match state:
		PacingState.BUILD:
			return "BUILD"
		PacingState.PEAK:
			return "PEAK"
		PacingState.BREATHER:
			return "BREATHER"
		_:
			return "UNKNOWN"

func _scene_debug_name(scene: PackedScene) -> String:
	if scene == null:
		return "null"

	return scene.resource_path.get_file().get_basename()

func _debug_print(
	part_a = "",
	part_b = "",
	part_c = "",
	part_d = "",
	part_e = "",
	part_f = "",
	part_g = "",
	part_h = "",
	part_i = "",
	part_j = "",
	part_k = "",
	part_l = "",
	part_m = "",
	part_n = "",
	part_o = "",
	part_p = ""
) -> void:
	if not debug_prints_enabled:
		return

	print("[DifficultyDirector t=", snapped(total_time, 0.01), "] ", part_a, part_b, part_c, part_d, part_e, part_f, part_g, part_h, part_i, part_j, part_k, part_l, part_m, part_n, part_o, part_p)
