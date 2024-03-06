extends Node3D



@onready var animTree = $AnimationTree as AnimationTree
@onready var walkDir: Vector2
@onready var moveState: String = "walk"
@onready var walkState = animTree.get("parameters/WalkStateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var upperState = animTree.get("parameters/UpperStateMachine/playback") as AnimationNodeStateMachinePlayback

func _process(delta: float) -> void:
	pass

func setWalk(blend: Vector2) -> void:
	
	if blend.y > 0:
		animTree.set("parameters/TimeScale/scale", -1)
	else:
		animTree.set("parameters/TimeScale/scale", 1)
	
	blend = abs(blend)
	
	match moveState:
		"crouch":
			animTree.set("parameters/WalkStateMachine/CrouchBlend/blend_position", blend.y)
		"walk":
			animTree.set("parameters/WalkStateMachine/WalkBlend/blend_position", blend.y)
		"run":
			animTree.set("parameters/WalkStateMachine/RunBlend/blend_position", blend.y)
		
	#parameters/WalkStateMachine/playback
	#BlendSpace1D

func setState(newState: String) -> void:
	
	moveState = newState
	
	match moveState:
		"crouch":
			walkState.travel("CrouchBlend")
		"walk":
			walkState.travel("WalkBlend")
		"run":
			walkState.travel("RunBlend")

func setUpperAnim(anim: String) -> void:
	print("Setting Animation: ", anim)
	upperState.travel(anim)
