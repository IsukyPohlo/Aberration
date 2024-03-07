extends CharacterBody3D

var speed
@export var WALK_SPEED = 3.0
@export var SPRINT_SPEED = 5.0
@export var JUMP_VELOCITY = 5.0
@export var SENSITIVITY = 0.004

#bob variables
@export var bob_freq: float = 1
@export var bob_amp: float = 0.03
var t_bob = 0.0

#fov variables
@export var base_fov = 75.0
@export var fov_change = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 9.8

@onready var head = $Head
@onready var camera = $Head/Camera3D as Camera3D
@onready var interaction = $Head/Camera3D/Interaction
@onready var hand = $Head/Camera3D/Hand
@onready var charModel = $CharModel
@onready var dialogueBox = $"../UI/DialogueBox"

var pickedObject: RigidBody3D
var pullPower: float = 5.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	charModel.setUpperAnim("Idle")

func _unhandled_input(event):
	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		charModel.rotate_y(-event.relative.x * SENSITIVITY)
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		# check if outside of dialogue
		if dialogueBox.dialogue_finished == true:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Input.is_action_just_pressed("crouch"):
		print("crouching")
		charModel.setCrouch(true)
		head.position.y = 1.6
		print(camera.position)
	if Input.is_action_just_released("crouch"):
		print("walking")
		charModel.setCrouch(false)
		head.position.y = 1.8
		print(camera.position)

func _physics_process(delta):
	
	# Very based on: https://github.com/LegionGames/FirstPersonController
	
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Object handling based on: https://www.youtube.com/watch?v=jLIe1_xvOXU
	if pickedObject != null:
		var objPos = pickedObject.global_transform.origin
		var handPos = hand.global_transform.origin
		pickedObject.linear_velocity = (handPos-objPos) * pullPower
	

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:

		# Handle Jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		
		# Handle animation
		if Input.is_action_pressed("sprint"):
			speed = SPRINT_SPEED
		else:
			speed = WALK_SPEED

		# Get the input direction and handle the movement/deceleration.
		if is_on_floor():
			if direction:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
			else:
				velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
				velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
		
		# Head bob
		t_bob += delta * velocity.length() * float(is_on_floor())
		camera.transform.origin = _headbob(t_bob)
		
		# FOV
		var velocity_clamped = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
		var target_fov = base_fov + fov_change * velocity_clamped
		camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
		
	else:
		velocity.x = 0
		velocity.z = 0
	
	# animation
	charModel.setWalk(input_dir.normalized())
	
	move_and_slide()
	
func _input(event) -> void:
	if Input.is_action_just_pressed("interact") && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if pickedObject == null:
			pickObject()
		else:
			removeObject()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	pos.x = cos(time * bob_freq / 2) * bob_amp
	return pos

func pickObject()-> void:
	var collider = interaction.get_collider()
	print(collider)
	if collider == null:
		return
	if collider is RigidBody3D:
		if (collider as RigidBody3D).is_in_group("pickable"):
			pickedObject = collider
			charModel.setUpperAnim("Interact")

	if collider is StaticBody3D:
		if (collider as StaticBody3D).is_in_group("mirror"):
			print("Mirror interaction")
			#dialogueBox.startDialogue("mirror")
			
	if collider is AnimatableBody3D:
		if (collider as AnimatableBody3D).is_in_group("interact"):
			collider.get_parent_node_3d().Interact()
			
			if collider.get_parent_node_3d().hasDialogue:
				dialogueBox.startDialogue(collider.get_parent_node_3d().name)

func removeObject():
	if pickedObject != null:
		pickedObject = null
		charModel.setUpperAnim("Idle")
		

