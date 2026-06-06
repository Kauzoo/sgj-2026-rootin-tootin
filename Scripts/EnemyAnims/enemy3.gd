class_name Enemy3 extends Node

var animation_tree: AnimationTree
var state_machine: AnimationNodeStateMachinePlayback 

signal done_animation()
signal spawned()

func die():
	state_machine.travel("Enemy3_Die")

func say_done(string):
	if string == "Enemy3_Die":
		done_animation.emit()

func say_spawned(string):
	if string == "Enemy3_Spawn":
		spawned.emit()

func _ready():
	animation_tree = $AnimationTree
	state_machine = animation_tree.get("parameters/playback")
	animation_tree.animation_finished.connect(say_done)
	animation_tree.animation_finished.connect(say_spawned)
