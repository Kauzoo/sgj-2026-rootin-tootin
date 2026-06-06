class_name Enemy1_2 extends Node

@export var is_one: bool

var animation_tree: AnimationTree
var state_machine: AnimationNodeStateMachinePlayback 

signal done_animation()
signal spawned()

func die():
	if is_one:
		state_machine.travel("Enemy1 Dead")
		return
	state_machine.travel("Enemy2_Death")

func say_done(string):
	if string == "Enemy1 Dead" || string == "Enemy2_Death":
		print("ded")
		done_animation.emit()

func say_spawned(string):
	if string == "Spawn" || string == "Enemy2_Spawn":
		spawned.emit()

func _ready():
	animation_tree = $AnimationTree
	state_machine = animation_tree.get("parameters/playback")

	if is_one:
		state_machine.travel("Spawn")
	else:
		state_machine.travel("Enemy2_Spawn")

	animation_tree.animation_finished.connect(say_done)
	animation_tree.animation_finished.connect(say_spawned)
