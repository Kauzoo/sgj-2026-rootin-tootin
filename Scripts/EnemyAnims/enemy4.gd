class_name Enemy4 extends Node

var animation_tree: AnimationTree
var state_machine: AnimationNodeStateMachinePlayback 

signal done_animation()
signal spawned()

func die():
	state_machine.travel("Enemy4_Death")

func say_done(string):
	if string == "Enemy4_Death":
		done_animation.emit()

func say_spawned(string):
	if string == "Enemy4_Spawn":
		spawned.emit()

func _ready():
	animation_tree = $AnimationTree
	state_machine = animation_tree.get("parameters/playback")
	animation_tree.animation_finished.connect(say_done)
	animation_tree.animation_finished.connect(say_spawned)
