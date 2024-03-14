extends CharacterBody3D

class_name Character

@export var bullet_scene : PackedScene
@export var gun_pickup: PackedScene = null
@export var melee_cooldown_time = 0.35
@export var ranged_cooldown_time = 0.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var aim_position = Vector3(0, 0, 0)
var aim_direction = Vector3(0, 0, -1)
var view_direction = Vector3(0, 0, -1)
var aim_position_free = true
var target_object: Node = null
var equipped_weapon: Gun = null
var aim_progress = 0.0
var health = 100
var melee_cooldown = 0
var ranged_cooldown = 0
var last_attack_version = false
var is_aiming = false
var request_shoot = false
var is_dead = false


func hit(damage, direction):
	GlobalSignals.emit_signal("noise_event", global_position, 3.0)
	GlobalSignals.emit_signal("screen_shake")
	velocity += direction * 5.0
	health -= damage
	
func move_toward_angle(from : float, to: float, delta : float):
	var ans = fposmod(to - from, TAU)
	if ans > PI:
		ans -= TAU
	return from + ans * delta
	
func update_cooldowns(delta):
	if melee_cooldown > 0:
		melee_cooldown -= delta
	if ranged_cooldown > 0:
		ranged_cooldown -= delta

func reset_cooldowns():
	melee_cooldown = melee_cooldown_time
	ranged_cooldown = ranged_cooldown_time

func do_melee_attack(animation_tree):
	if melee_cooldown > 0:
		return
		
	melee_cooldown = melee_cooldown_time
	if last_attack_version:
		animation_tree["parameters/alive/Melee_Hit_2/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE;
	else:
		animation_tree["parameters/alive/Melee_Hit_1/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE;
	last_attack_version = not last_attack_version

func handle_weapon_gun(delta, is_aiming: bool, request_shoot: bool, bullet_start_transform: Node3D, animation_tree: AnimationTree):
	if not equipped_weapon is Gun:
		aim_progress = 0.0
		return
	
	var aim_progress_target = 1.0 if is_aiming else 0.0
	aim_progress = move_toward(aim_progress, aim_progress_target, 10 * delta)
	
	if !is_equal_approx(aim_progress, 1.0):
		return
	
	if ranged_cooldown > 0.0:
		return
	
	if request_shoot:
		ranged_cooldown = ranged_cooldown_time
		if equipped_weapon.fire():
			var bullet = bullet_scene.instantiate()
			get_tree().get_root().add_child(bullet)
			bullet.transform = bullet_start_transform.global_transform
			bullet.velocity = bullet.transform.basis.z * bullet.muzzle_velocity
			animation_tree["parameters/alive/Fire_gun/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE;

func throw_weapon():
	if not equipped_weapon:
		return
	var weapon_pickup: RigidBody3D = gun_pickup.instantiate()
	get_parent().add_child(weapon_pickup)
	weapon_pickup.global_position = equipped_weapon.global_position
	weapon_pickup.rotation = equipped_weapon.rotation
	equipped_weapon.transform = Basis()
	
	equipped_weapon.reparent(weapon_pickup)
	weapon_pickup.weapon_node = equipped_weapon
	var throw_direction = (aim_direction + Vector3(0, 0.5, 0)).normalized();
	weapon_pickup.apply_central_impulse(velocity + throw_direction * 4.0)
	equipped_weapon = null
