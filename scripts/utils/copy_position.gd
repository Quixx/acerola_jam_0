extends Node3D

@export var target: Node3D

func _physics_process(_delta):
	global_position = target.global_position
