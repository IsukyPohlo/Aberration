extends Marker3D

var enemy = preload("res://Scenes/enemy.tscn")
@onready var char: CharacterBody3D = $"../../../Char"

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
		enem.position = global_position
		get_parent().get_parent().add_child(enem)
		await get_tree().create_timer(1).timeout
