extends Character

class_name Player

@onready var charactger_rigged = $Visuals
@onready var camera = $CamerMount/Camera3D
@onready var animation_tree = $Visuals/charactger_rigged2/AnimationTree
@onready var laser_pointer = $Visuals/charactger_rigged2/laser_pointer
@onready var character_animation_events = $Visuals/charactger_rigged2/Armature
@onready var skeleton = $Visuals/charactger_rigged2/Armature/Skeleton3D
@onready var wepon_attachment = $Visuals/charactger_rigged2/Armature/Skeleton3D/WeaponHandAttach/Offset
@onready var aim_area = $AimArea
@onready var interaction_area = $InteractionArea
@onready var gun_pickup_sound = $Audio/GunPickupSound
@onready var rotation_target = $RotationTarget
@onready var collision_shape_3d = $CollisionShape3D
@onready var punch_hit = $Audio/PunchHit
@onready var ability_sound = $Audio/AbilitySound

@export var hit_type = Bullet.HitType.CHARACTER

@export var MAX_SPEED = 4.0
@export var MAX_SPEED_AIM = 2.5
@export var ACCELERATION = 2
@export var FRICTION = 1
const JUMP_VELOCITY = 4.5
const ROTATION_SPEED = 20.0

# Player state
var ability_q = null
var ability_e = null
var ability_target = null
var ability_target_found = 0
var pickup_interaction_object: WeaponPickup = null

func _ready():
	Global.set_cursor(Global.CursorType.DEFAULT)
	GlobalSignals.connect("bullet_hit", on_bullet_hit)
	Global.register_player(self)
	character_animation_events.character_id = get_instance_id()
	character_animation_events.character = self
	GlobalSignals.connect("random_initialized", on_randomize)

func on_randomize():
	var child_count = $Abilities.get_child_count()
	var ability_index_e = Global.rng.randi() % child_count
	var ability_index_q = Global.rng.randi() % child_count
	while ability_index_e == ability_index_q:
		ability_index_q = Global.rng.randi() % child_count
	
	ability_e = $Abilities.get_child(ability_index_e)
	ability_q = $Abilities.get_child(ability_index_q)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if is_dead:
		return

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var mousePosition = get_viewport().get_mouse_position()
	var dropPlane  = Plane( Vector3(0, 1, 0), 1.0 )
	aim_position = dropPlane.intersects_ray(camera.project_ray_origin(mousePosition), camera.project_ray_normal(mousePosition))

	var input_dir = Input.get_vector("left", "right", "down", "up")
	var direction = Vector3(input_dir.x, 0, -input_dir.y).normalized()

	if aim_position:
		rotation_target.look_at( aim_position )
		charactger_rigged.rotation.y = move_toward_angle(charactger_rigged.rotation.y, rotation_target.rotation.y, ROTATION_SPEED * delta)
		
		aim_area.global_position.x = aim_position.x
		aim_area.global_position.z = aim_position.z
		
		# For now use the teleport position as max range
		var teleport_range = $Abilities.get_child(1).max_distance
		if aim_area.global_position.distance_to(global_position) > teleport_range:
			var clamped_aim_position: Vector3 = aim_position - position
			clamped_aim_position.y = 0
			clamped_aim_position = global_position + clamped_aim_position.normalized() * (teleport_range - 0.1)
			aim_area.global_position.x = clamped_aim_position.x
			aim_area.global_position.z = clamped_aim_position.z 

	aim_position_free = not aim_area.has_overlapping_bodies()

	if direction:
		var current_max_speed = MAX_SPEED_AIM if aim_progress > 0.0 else MAX_SPEED
		
		velocity.x = move_toward(velocity.x, direction.x * current_max_speed, ACCELERATION)
		velocity.z = move_toward(velocity.z, direction.z * current_max_speed, ACCELERATION)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION)
		velocity.z = move_toward(velocity.z, 0, FRICTION)

	move_and_slide()

func handle_animation_state():
	if velocity.is_zero_approx():
		animation_tree["parameters/alive/Movement/blend_amount"] = 0.0
	else:
		animation_tree["parameters/alive/Movement/blend_amount"] = velocity.length() / MAX_SPEED
	
	if(aim_position):
		aim_direction = aim_position - position
		aim_direction.y = 0
		aim_direction = aim_direction.normalized()
		var aim_direction_xz = Vector2(aim_direction.x, aim_direction.z).normalized()
		var velocity_xz = Vector2(velocity.x, velocity.z).normalized()
		var dotMovement = velocity_xz.dot( aim_direction_xz )
		animation_tree["parameters/alive/Run/blend_position"] = dotMovement

	animation_tree["parameters/alive/Aim_State/blend_amount"] = aim_progress
	animation_tree["parameters/alive/Aim_Weapon/blend_amount"] = 1.0 if equipped_weapon else 0.0

func update_weapon_gun(delta):
	var is_aiming = Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	var request_shoot = Input.is_action_just_pressed("fire")
	laser_pointer.visible = equipped_weapon and aim_progress == 1.0
	handle_weapon_gun(delta, is_aiming, request_shoot, laser_pointer, animation_tree)

func handle_melee_combat():
	if equipped_weapon:
		return
		
	if Input.is_action_just_pressed("fire"):
		do_melee_attack(animation_tree)

func handle_ability(ability: BaseAbility, ability_input: String):
	if not ability:
		return

	if Input.is_action_just_pressed(ability_input):
		var ability_result = ability.trigger(self)
		if ability_result != BaseAbility.AbilityTriggerResult.OK:
			GlobalSignals.emit_signal("ability_fail", ability_result, ability)
			return
		ability_sound.play()
		GlobalSignals.emit_signal("screen_shake")

func handle_interaction_offers():
	var closest_area = null
	for area in interaction_area.get_overlapping_areas():
		if area is PickupArea:
			if closest_area == null:
				closest_area = area
				continue
			if not aim_position:
				break
			if aim_position.distance_squared_to(area.global_position) < aim_position.distance_squared_to(closest_area.global_position):
				closest_area = area
	if closest_area:
		pickup_interaction_object = closest_area.get_parent()
	else:
		pickup_interaction_object = null
	
	if not pickup_interaction_object:
		return

func update_ability_target():
	var cur_time = Time.get_ticks_usec()
	if cur_time > ability_target_found + 200:
		ability_target = null
	
	var mouse_position = get_viewport().get_mouse_position()
	if not mouse_position:
		return
	
	var worldspace = get_world_3d().direct_space_state
	var start = camera.project_ray_origin(mouse_position)
	var end = camera.project_position(mouse_position, 50.0)
	
	var vision_query = PhysicsRayQueryParameters3D.create(start, end)
	vision_query.collision_mask = 128
	
	var result = worldspace.intersect_ray(vision_query)
	if result:
		var result_node = result.collider
		if 'redirect_ability_target' in result_node:
			ability_target = result_node.redirect_ability_target
		else:
			ability_target = result_node
		ability_target_found = cur_time

func pickup_weapon():
	var weapon_pickup: WeaponPickup = pickup_interaction_object
	weapon_pickup.weapon_node.reparent(wepon_attachment, false)
	equipped_weapon = weapon_pickup.weapon_node
	equipped_weapon.transform = Basis()
	weapon_pickup.queue_free()
	Global.set_cursor(Global.CursorType.CROSSHAIR)
	
	if weapon_pickup.type == WeaponPickup.Type.GUN:
		gun_pickup_sound.play()

func handle_pickup_input():
	if not Input.is_action_just_pressed("pickup"):
		return
	if equipped_weapon:
		throw_weapon()
	if pickup_interaction_object:
		pickup_weapon()

func throw_weapon():
	super.throw_weapon()
	Global.set_cursor(Global.CursorType.DEFAULT)

func hit(damage, direction):
	super.hit(damage, direction)
	punch_hit.play()

func kill():
	collision_shape_3d.queue_free()
	skeleton.physical_bones_start_simulation()
	is_dead = true
	GlobalSignals.emit_signal("player_dead")

func on_bullet_hit(options):
	if options.collider_id != get_instance_id():
		return
		
	GlobalSignals.emit_signal("screen_shake")
	kill()
	skeleton.get_node("PhysicalBoneBody").apply_central_impulse(options.direction * 10.0)
	skeleton.get_node("PhysicalBoneLegL").apply_central_impulse(options.direction * 5.0)
	skeleton.get_node("PhysicalBoneLegR").apply_central_impulse(options.direction * 5.0)


func _process(delta):
	if is_dead:
		return
	
	if health <= 0:
		kill()

	update_cooldowns(delta)
	update_ability_target()
	handle_interaction_offers()
	handle_pickup_input()
	update_weapon_gun(delta)
	handle_melee_combat()
	handle_ability(ability_q, 'ability_a')
	handle_ability(ability_e, 'ability_b')
	handle_animation_state()
	view_direction = -charactger_rigged.global_transform.basis.z
