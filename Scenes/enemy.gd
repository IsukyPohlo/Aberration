extends CharacterBody3D

var hp = 100
@export var char: CharacterBody3D
@export var type: int
@onready var navAgent: NavigationAgent3D = $NavigationAgent3D
@onready var char_model: Node3D = $CharModel
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

const SPEED = 2.0
const ATTACK_RANGE = 2.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

#Most of this code is from https://www.youtube.com/watch?v=iV710Vm5qm0

func _ready() -> void:
	char_model.setWalk(Vector2(0,1))
	char_model.setSkin(0)
	char_model.enableAberrantChar(false)
	
	match type:
		2: 
			hp = 120
		3:
			hp = 150
		4:
			hp = 300
		_:
			hp = 100

func _process(delta: float) -> void:
	#print(hp)
	char_model.type = type

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if hp > 0: 
		navAgent.target_position = char.global_transform.origin
		var nextNavPoint = navAgent.get_next_path_position()
		velocity = (nextNavPoint - global_transform.origin).normalized() * SPEED
		
		look_at(Vector3(char.global_position.x, global_position.y, char.global_position.z), Vector3.UP)
		
		if global_position.distance_to(char.global_position) < ATTACK_RANGE:
			char_model.setUpperAnim("Attack")
		else:
			char_model.setUpperAnim("Idle")
			
	else:
		velocity = Vector3.ZERO

	move_and_slide()

func damage (dam: float) -> void:
	hp -= dam
	if hp <= 0:
		char_model.setState("death")
		collision_shape_3d.disabled = true
		await get_tree().create_timer(1).timeout
		char.killCount += 1
		char.aberration += 1
		if char.numbness >= 2:
			char.numbness -= 2
		else:
			char.numbness = 0
		queue_free()
