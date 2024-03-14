extends Marker3D

var enemy = preload("res://Scenes/enemy.tscn")
@onready var char: CharacterBody3D = $"../../../Char"

@onready var room_spawn: Marker3D = $"../../Room/RoomSpawn"
@onready var aberrant_spawn: Marker3D = $"."
@onready var aberrant_spawn_3: Marker3D = $"../AberrantSpawn3"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func spawn(number: int, type: int) -> void:
	for i in number:
		print("spawning ", i)
		var enem = enemy.instantiate()
		enem.type = type
		enem.char = char
		match type:
			3:
				enem.position = aberrant_spawn_3.global_position
			4:
				enem.position = room_spawn.global_position
				enem.aggresive = false
			_:
				enem.position = aberrant_spawn.global_position
		
		get_parent().get_parent().add_child(enem)
		await get_tree().create_timer(0.3).timeout
