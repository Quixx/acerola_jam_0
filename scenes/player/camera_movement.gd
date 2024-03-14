extends Node3D

@onready var target: Player = $".."

@export var aim_offset = 0.3
@export var camera_speed = 7.0
@export var period = 0.2
@export var magnitude = 0.05
@onready var character_depth_viewport = $CharacterDepthViewport
@onready var environment_depth_viewport = $EnvironmentDepthViewport


func _ready():
	GlobalSignals.connect("screen_shake", _screen_shake)
	get_viewport().connect("size_changed", _on_vp_size_changed)
	_on_vp_size_changed()

func _physics_process(delta):
	var target_position = target.global_position
	if target.aim_position:
		target_position += target.aim_direction * aim_offset
	
	global_position = global_position.lerp(target_position, camera_speed * delta) 

func _on_vp_size_changed() -> void:
	character_depth_viewport.size = get_viewport().size
	environment_depth_viewport.size = get_viewport().size
	# sub_viewport.size_override_stretch = true
	# .set_size_override(true, viewport_orig_size)


func _screen_shake():
	var initial_transform = self.transform 
	var elapsed_time = 0.0
	
	while elapsed_time < period:
		var offset = Vector3(
			randf_range(-magnitude, magnitude),
			randf_range(-magnitude, magnitude),
			0.0
		)
		
		self.transform.origin = initial_transform.origin + offset
		elapsed_time += (get_process_delta_time() / Engine.time_scale)
		await get_tree().process_frame
	
	self.transform = initial_transform
