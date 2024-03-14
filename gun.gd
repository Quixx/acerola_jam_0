extends Node3D

class_name Gun

@onready var muzzle_flash = $Gun/EffectHandle/Muzzle_Flash
@onready var animation_player = $Gun/AnimationPlayer
@onready var shell_emitter = $Gun/EffectHandle/shell_emitter
@onready var gun_shot = $GunShot
@onready var gun_empty = $GunEmpty

@export var ammo_max = 6
var ammo = ammo_max

func _read():
	ammo = ammo_max

func fire():
	if ammo <= 0:
		gun_empty.play()
		return false
	
	ammo -= 1
	muzzle_flash.emitting = true
	shell_emitter.trigger()
	animation_player.play("Gun_Light")
	gun_shot.play()
	GlobalSignals.emit_signal("noise_event", global_position, 12.0)
	return true
