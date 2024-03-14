extends Area3D

@onready var debug_sphere = $DebugSphere

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	"""
	if get_overlapping_bodies().size() > 0:
		debug_sphere.visible = true
	else:
		debug_sphere.visible = false
	"""
