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

var bullet = preload("res://Scenes/bullet.tscn")

@onready var head = $Head
@onready var camera = $Head/Camera3D as Camera3D
@onready var interaction = $Head/Camera3D/Interaction
@onready var hand = $Head/Camera3D/Hand
@onready var charModel = $CharModel
@onready var dialogueBox = $"../UI/DialogueBox"
@onready var blasterAnim: AnimationPlayer = $Head/Camera3D/BlasterAnimPlayer
@onready var blasterBarrel: RayCast3D = $Head/Camera3D/RayCast3D
@onready var blaster_b: MeshInstance3D = $Head/Camera3D/blasterB

var MISSING_FURNITURE = preload("res://Assets/MissingFurniture.tres")
@onready var numb_eyes: ColorRect = $"../CanvasLayer/NumbEyes"
@onready var aberrant_char_spawn: Marker3D = $"../NavigationRegion3D/Map/AberrantCharSpawn"
@onready var aberrant_spawn: Marker3D = $"../NavigationRegion3D/Map/AberrantSpawn"

var pickedObject: RigidBody3D
var pullPower: float = 5.0

var numb: bool = false
var aberrantGameMode: bool = false
var shootSpeed: float = 1
var killCount: int = 0
var numbness: float = 0
var aberration: float = 0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	charModel.setUpperAnim("Idle")
	MISSING_FURNITURE.set_shader_parameter("barrier_force", 1)

func _unhandled_input(event):
	if event is InputEventMouseMotion && Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		charModel.rotate_y(-event.relative.x * SENSITIVITY)
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))

func _process(delta: float) -> void:
	changeInteractIcon()
	
	if Input.is_action_just_pressed("ui_cancel"):
		# check if outside of dialogue
		if dialogueBox.dialogue_finished == true:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Input.is_action_just_pressed("crouch"):
		print("crouching")
		charModel.setState("crouch")
		head.position.y = 1.4
		print(camera.position)
	if Input.is_action_just_released("crouch"):
		print("walking")
		charModel.setState("walk")
		head.position.y = 1.6
		print(camera.position)
		
	if Input.is_action_pressed("shoot"):
		if !blasterAnim.is_playing() && aberrantGameMode == true:
			blasterAnim.play("shoot")
			blasterAnim.speed_scale = shootSpeed
			var instance = bullet.instantiate()
			instance.position = blasterBarrel.global_position
			instance.transform.basis = blasterBarrel.global_transform.basis
			get_parent().add_child(instance)
	
	if dialogueBox.state["numbness"] >= 90:
		charModel.type = 2
		numb_eyes.visible = true
		var tw = create_tween()
		tw.tween_property(numb_eyes.get_material(), "shader_parameter/strength", 1000, 240.0)
		
		if numb == false && dialogueBox.state["numbness"] >= 100:
			numb = true
			MISSING_FURNITURE.set_shader_parameter("barrier_force", 0)
	
	else:
		charModel.type = 1
		var tw = create_tween()
		tw.tween_property(numb_eyes.get_material(), "shader_parameter/strength", 0, 2)
		
	#aberrant stuff here
	if aberrantGameMode == true:
		if blaster_b.visible == false:
			blaster_b.visible = true
	else:
		if blaster_b.visible == true:
			blaster_b.visible = false
		
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

	if collider is StaticBody3D:
		if (collider as StaticBody3D).is_in_group("work"):
			dialogueBox.startDialogue("work")
			
		if dialogueBox.state["numbness"] >= 100:
			match (collider.name):
				"Mirror":
					collider.remove_from_group("dialogue")
					dialogueBox.changeText("")
					dialogueBox.changeIcon(0)
					dialogueBox.startDialogue("Mirror")
			return
			
		if (collider as StaticBody3D).is_in_group("dialogue"):
			
			dialogueBox.startDialogue(collider.name)
			match (collider.name):
				"Mirror":
					dialogueBox.changeText("")
				"Window1":
					collider.remove_from_group("dialogue")
					if dialogueBox.state["numbness"] > 60:
						dialogueBox.state["numbness"] -= 60
					else:
						dialogueBox.state["numbness"] = 0
				"Window2":
					collider.remove_from_group("dialogue")
					if dialogueBox.state["numbness"] > 60:
						dialogueBox.state["numbness"] -= 60
					else:
						dialogueBox.state["numbness"] = 0
				"Window3":
					collider.remove_from_group("dialogue")
					if dialogueBox.state["numbness"] > 60:
						dialogueBox.state["numbness"] -= 60
					else:
						dialogueBox.state["numbness"] = 0

		if (collider as StaticBody3D).is_in_group("unlockable"):
			dialogueBox.changeText("")
			match (collider.name):
				"Window1":
					collider.visible = false
					collider.remove_from_group("unlockable")
					collider.add_to_group("dialogue")
				"Window2":
					collider.visible = false
					collider.remove_from_group("unlockable")
					collider.add_to_group("dialogue")
				"Window3":
					collider.visible = false
					collider.remove_from_group("unlockable")
					collider.add_to_group("dialogue")
				"Window4":
					collider.visible = false
					collider.remove_from_group("unlockable")
					collider.add_to_group("dialogue")
				"Window5":
					collider.visible = false
					collider.remove_from_group("unlockable")
					collider.add_to_group("dialogue")
				#"toilet":
					#dialogueBox.changeText("50 Credits to buy a toilet")
				"chair":
					collider.find_child("chairDesk").visible = true
					collider.find_child("chairDesk(Clone)").visible = false
					collider.remove_from_group("unlockable")
				"door":
					collider.remove_from_group("unlockable")
					collider.add_to_group("interact")
		
		if (collider as StaticBody3D).is_in_group("game"):
			dialogueBox.startDialogue("Game")
			dialogueBox.state["mission"] += 1
			dialogueBox.changeIcon(6)
			
			
	if collider is AnimatableBody3D:
		if (collider as AnimatableBody3D).is_in_group("interact"):
			collider.Interact()
			if collider.hasDialogue:
				dialogueBox.startDialogue(collider.name)

func removeObject():
	if pickedObject != null:
		pickedObject = null
		charModel.setUpperAnim("Idle")
		
func rotateCharSkin(increment: bool) -> int:
	return charModel.changeSkin(increment)
	
func setCharSkin(idx: int) -> void:
	charModel.setSkin(idx)	

func changeInteractIcon() -> void:
	var collider = interaction.get_collider()

	if collider is StaticBody3D:
		
		if (collider as StaticBody3D).is_in_group("work"):
			dialogueBox.changeIcon(2)
			dialogueBox.changeText("WORK")
			
		elif (collider as StaticBody3D).is_in_group("dialogue"):
			dialogueBox.changeIcon(4)
			match (collider.name):
				"Mirror":
					dialogueBox.changeText("Check your status")
				_: 
					dialogueBox.changeText("")
					
		elif dialogueBox.state["numbness"] >= 100:
			return
		
		elif (collider as StaticBody3D).is_in_group("unlockable"):
			dialogueBox.changeIcon(3)
			match (collider.name):
				"Window1":
					dialogueBox.changeText("100 Credits to open window")
				"Window2":
					dialogueBox.changeText("100 Credits to open window")
				"Window3":
					dialogueBox.changeText("100 Credits to open window")
				"Window4":
					dialogueBox.changeText("100 Credits to open window (x2 credits while working)")
				"Window5":
					dialogueBox.changeText("100 Credits to open window")
				"toilet":
					dialogueBox.changeText("50 Credits to buy a toilet")
				"chair":
					dialogueBox.changeText("200 Credits ( halve numbness while working)")
				"door":
					dialogueBox.changeText("2000 Credits")
		
		elif (collider as StaticBody3D).is_in_group("interact"):
			dialogueBox.changeIcon(1)
			dialogueBox.changeText("")

		elif (collider as StaticBody3D).is_in_group("game"):
			dialogueBox.changeIcon(5)
			match dialogueBox.state["mission"]:
				1:
					dialogueBox.changeText("50 Credits to play 'Aberrant'")
				2:
					dialogueBox.changeText("100 Credits to play 'Aberrant'")
				3:
					dialogueBox.changeText("100 Credits to play 'Aberrant'")
				_:
					dialogueBox.changeText("Play 'Aberrant'")
				
		else:
			dialogueBox.changeIcon(0)
	else:
		dialogueBox.changeIcon(0)
		dialogueBox.changeText("")
