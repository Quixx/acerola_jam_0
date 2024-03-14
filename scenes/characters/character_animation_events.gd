extends Node3D

@onready var step_sound = $Audio/StepSound
@onready var shwoosh_sound = $Audio/ShwooshSound
@onready var weapon_hand_attach = $Skeleton3D/WeaponHandAttach
@onready var offhand_attach = $Skeleton3D/OffhandAttach

@export var melee_hitbox: PackedScene

var character_id = 0
var character: Character = null
var last_step_sound = 0
var MIN_STEP_TIME_MS = 200

func on_step():
	var cur_time = Time.get_ticks_msec()
	if last_step_sound + MIN_STEP_TIME_MS > cur_time:
		return
	last_step_sound = cur_time
	step_sound.play()
	
func on_melee_attack():
	if character.is_dead:
		return

	shwoosh_sound.play()
	
func spawn_melee_hitbox(side):
	if character.is_dead:
		return
		
	var hitbox = melee_hitbox.instantiate()
	hitbox.spawner_id = character_id
	hitbox.spawner_character = character
	hitbox.direction = character.view_direction

	if side:
		offhand_attach.add_child(hitbox)
	else:
		weapon_hand_attach.add_child(hitbox)
