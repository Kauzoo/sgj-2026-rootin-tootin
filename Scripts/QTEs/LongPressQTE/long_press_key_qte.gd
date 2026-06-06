class_name LongPressKeyQTE extends KeyQTE

@export var hold_duration: float = 1.0  # how long player needs to hold

var hold_timer: float = 0.0
var is_holding: bool = false

func _process(delta):
	if is_holding:
		hold_timer += delta
		if hold_timer >= hold_duration:
			get_parent().get_parent().remove_key_qte(self)
			get_viewport().set_input_as_handled()
			QTE_succeded.emit(position)
			queue_free()
	queue_redraw()

func _draw():
	super._draw()  # draws the red fail timer arc from KeyQTE
	
	# just add the green hold progress arc on top
	var hold_ratio: float = hold_timer / hold_duration
	draw_arc(Vector2(0, 0), 30, 0 - 0.5 * PI, hold_ratio * 2 * PI - 0.5 * PI, 100, Color(0, 1, 0), 5)

func _unhandled_input(event):
	if DifficultyDirector.is_input_on_cooldown():
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.key_label == key:
		if event.pressed and not event.is_echo():
			is_holding = true  # key just pressed, start tracking
		elif not event.pressed:
			is_holding = false  # key released, reset
			hold_timer = 0.0
		$FailTimer.paused = is_holding

func check_event(event):
	if event is InputEventKey and event.key_label == key:
		if event.pressed and not event.is_echo():
			is_holding = true
		elif not event.pressed:
			is_holding = false
			hold_timer = 0.0
