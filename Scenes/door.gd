extends AnimatableBody3D

@onready var animPlayer: AnimationPlayer = $"../AnimationPlayer"

@export var open: bool = false

@export var hasDialogue: bool = false

func ready():
	animPlayer.play("open")

func Interact()-> void:

	if open:

		if !animPlayer.is_playing() && animPlayer.current_animation != "close":
			animPlayer.play("close")
			open = false
	else:
		if !animPlayer.is_playing() && animPlayer.current_animation != "open":

			animPlayer.play("open")
			open = true
