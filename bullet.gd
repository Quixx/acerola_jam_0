extends Node3D

class_name Bullet

@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var cpu_particles_3d = $CPUParticles3D

@export var muzzle_velocity = 30
var velocity = Vector3.ZERO
var wait_for_free = false
var free_timer = 3000

enum HitType {
	WALL,
	PROP,
	CHARACTER,
}

func handle_bullet_impact(hit_point):
	transform.origin = hit_point
	$model.visible = false
	cpu_particles_3d.emitting = false
	free_timer = cpu_particles_3d.lifetime
	wait_for_free = true

func get_hit_type(hit_collider):
	if "hit_type" in hit_collider:
		return hit_collider.hit_type
	
	return HitType.PROP

func _physics_process(delta):
	if wait_for_free:
		free_timer -= delta
		if free_timer <= 0:
			queue_free()
		return
	
	ray_cast_3d.force_raycast_update()
	if ray_cast_3d.is_colliding():
		var hit_collider = ray_cast_3d.get_collider()
		var hit_id = hit_collider.get_instance_id()
		var hit_point = ray_cast_3d.get_collision_point()
		var normal = ray_cast_3d.get_collision_normal()
		
		handle_bullet_impact(hit_point)

		GlobalSignals.emit_signal("bullet_hit", {
			hit_point = hit_point,
			direction = get_global_transform().basis.z,
			normal = normal,
			collider_id = hit_id,
			hit_type = get_hit_type(hit_collider)
		})

		return

	transform.origin += velocity * delta
