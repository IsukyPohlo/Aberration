extends Node3D

const SPEED = 50.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var ray: RayCast3D = $RayCast3D
@onready var particles: GPUParticles3D = $GPUParticles3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += transform.basis * Vector3(0,0,-SPEED) * delta
	if ray.is_colliding():
		mesh.visible = false
		particles.emitting = true
		ray.enabled = false
		
		if ray.get_collider() == null:
			return
		
		if ray.get_collider().is_in_group("enemy"):
			ray.get_collider().damage(100.0)
		
		await get_tree().create_timer(0.8).timeout
		queue_free()


func _on_timer_timeout() -> void:
	queue_free()
