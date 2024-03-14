extends RigidBody3D

class_name  WeaponPickup

enum Type
{
	GUN,
	SWORD
}

@export var weapon_node: Node
@export var type: Type
@export var spawn_probability = 1.0

func _ready():
	if Global.rng.randf_range(0.0, 1.0) > spawn_probability:
		queue_free()
