extends AnimatableBody3D

@onready var animPlayer: AnimationPlayer = $"../AnimationPlayer"

@export var open: bool = false
@export var locked: bool = false

@export var hasDialogue: bool = false

@onready var door_open: AudioStreamPlayer = $"../../../../Sounds/DoorOpen"
@onready var door_close: AudioStreamPlayer = $"../../../../Sounds/DoorClose"

func ready():
	animPlayer.play("open")

func Interact()-> void:
	
	if locked == true:
		return

	if open:

		if !animPlayer.is_playing() && animPlayer.current_animation != "close":
			animPlayer.play("close")
			open = false
			door_close.play()
	else:
		if !animPlayer.is_playing() && animPlayer.current_animation != "open":
			door_open.play()
			animPlayer.play("open")
			open = true
