@tool
extends Node3D

@onready var animTree = $AnimationTree as AnimationTree
@onready var walkDir: Vector2
@onready var moveState: String = "walk"
@onready var walkState = animTree.get("parameters/WalkStateMachine/playback") as AnimationNodeStateMachinePlayback
@onready var upperState = animTree.get("parameters/UpperStateMachine/playback") as AnimationNodeStateMachinePlayback

@onready var numbhole: MeshInstance3D = $RootNode/Root/Skeleton3D/BoneAttachment3D/Numbhole
@onready var character_large_male: MeshInstance3D = $RootNode/Root/Skeleton3D/characterLargeMale
@onready var aberrant_char: MeshInstance3D = $RootNode/Root/Skeleton3D/BoneAttachment3D/AberrantChar
@onready var aberrant_npc: MeshInstance3D = $RootNode/Root/Skeleton3D/BoneAttachment3D/AberrantNPC
@onready var aberrant_char_camera: MeshInstance3D = $RootNode/Root/Skeleton3D/BoneAttachment3D/AberrantCharCamera

@export var skins: Array[BaseMaterial3D]
@export var type: int 
@export_flags_3d_render var layers_3d_render = 1

var min = 3
var skinIdx = min

func _process(delta: float) -> void:
	
	#print(type)
	
	if layers_3d_render != null && layers_3d_render != 0:
		numbhole.layers = layers_3d_render
		character_large_male.layers = layers_3d_render
		aberrant_char.layers = layers_3d_render
		aberrant_npc.layers = layers_3d_render
	typeSelect(type)
	pass

func changeSkin(increment: bool) -> int:
	
	

	if increment:
		if skinIdx < len(skins)-1:
			skinIdx = skinIdx + 1
		else:
			skinIdx = min
		
	else:
		if skinIdx > min:
			skinIdx = skinIdx - 1
		else:
			skinIdx = len(skins) - 1
	
	setSkin(skinIdx)
	return skinIdx
	
func setSkin(idx: int) -> void:
	character_large_male.set_surface_override_material(0,skins[idx])

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
		"death":
			print("die anim")
			animTree.set("parameters/TimeScale/scale", 1)
			animTree.set("parameters/Blend2/blend_amount", 0)
			walkState.travel("Death")

func setUpperAnim(anim: String) -> void:
	upperState.travel(anim)
	
func enableHole(visible: bool) -> void:
	numbhole.visible = visible

func enableAberrantNPC(visible: bool) -> void:
	aberrant_npc.visible = visible
	
func enableAberrantChar(visible: bool) -> void:
	aberrant_char.visible = visible

func enableAberrantCharCamera(visible: bool) -> void:
	aberrant_char_camera.visible = visible

func typeSelect(type: int) -> void:
	match type:
		0:
			enableHole(false)
			enableAberrantNPC(false)
			enableAberrantChar(false)
			enableAberrantCharCamera(false)
		1: 
			enableHole(false)
			enableAberrantNPC(false)
			enableAberrantChar(false)
			enableAberrantCharCamera(false)
			setSkin(1)
		2: 
			enableHole(true)
			enableAberrantNPC(false)
			enableAberrantChar(false)
			enableAberrantCharCamera(false)
			setSkin(1)
		3:
			enableHole(false)
			enableAberrantNPC(true)
			enableAberrantChar(false)
			enableAberrantCharCamera(false)
			setSkin(2)
		4:
			enableHole(false)
			enableAberrantNPC(false)
			enableAberrantChar(true)
			enableAberrantCharCamera(false)
			setSkin(2)
		5:
			enableHole(false)
			enableAberrantNPC(false)
			enableAberrantChar(false)
			enableAberrantCharCamera(true)
			setSkin(2)


