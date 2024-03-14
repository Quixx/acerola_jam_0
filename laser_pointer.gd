extends RayCast3D

@onready var laser = $laser
@onready var decal = $Decal


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	force_raycast_update()

	if is_colliding():
		laser.visible = true
		decal.visible = true

		var hit_point = to_local(get_collision_point())
		laser.mesh.height = hit_point.z
		laser.position.z = hit_point.z / 2
		decal.position = hit_point
	else:
		laser.visible = false
		decal.visible = false
