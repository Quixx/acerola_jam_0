extends Character

class_name Enemy

@onready var navigationAgent = $NavigationAgent3D
@onready var collision_shape = $CollisionShape3D
@onready var charactger_rigged = $Visuals/charactger_rigged
@onready var character_animation_events = $Visuals/charactger_rigged/Armature
@onready var animation_tree = $Visuals/charactger_rigged/AnimationTree
@onready var skeleton = $Visuals/charactger_rigged/Armature/Skeleton3D
@onready var weapon_attachment = $Visuals/charactger_rigged/Armature/Skeleton3D/WeaponHandAttach/Offset
@onready var visuals = $Visuals
@onready var rotation_target = $RotationTarget
@onready var view_cone = $Visuals/ViewCone
@onready var punch_hit = $Audio/PunchHit
@onready var bullet_start = $Visuals/charactger_rigged/BulletStart
@onready var debug_label: Label3D = $Visuals/Label3D

enum EnemyState {
	IDLE,
	PATROL,
	COMBAT,
	DEAD,
}

const SPEED = 5.0
const PATROL_SPEED = 2.0
const FRICTION = 0.5
const VIEW_RANGE = 5.0
const ROTATION_SPEED = 8.0
const WEAPON_RANGE = 6.0
const MELEE_RANGE = 1.0
const PATROL_START_MIN = 3.0
const PATROL_START_MAX = 10.0

@export var weapon_scene: PackedScene
@export var patrol_points: Array[Node3D] = []
@export var weapon_probability = 0.5

var state = EnemyState.IDLE
var input_dir = Vector2.ZERO
var hit_type = Bullet.HitType.CHARACTER
var current_patrol_point = 0
var next_patrol_start = 0


func _ready():
	GlobalSignals.connect("bullet_hit", on_bullet_hit)
	GlobalSignals.connect("noise_event", on_noise_event)
	character_animation_events.character_id = get_instance_id()
	character_animation_events.character = self
	if Global.rng.randf_range(0.0, 1.0) < weapon_probability:
		equip_weapon()
	start_idle()

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	if direction:
		var speed = SPEED if state == EnemyState.COMBAT else PATROL_SPEED
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION)
		velocity.z = move_toward(velocity.z, 0, FRICTION)
	
	match state:
		EnemyState.DEAD:
			input_dir = Vector2.ZERO
			return
		EnemyState.IDLE:
			update_idle(delta)
		EnemyState.PATROL:
			update_patrol()
		EnemyState.COMBAT:
			update_combat()

	move_and_slide()

func detect_player():
	if not Global.player:
		return
	if Global.player.is_dead:
		return
	
	var view_direction = -visuals.global_transform.basis.z.normalized() 
	var player_direction = (Global.player.global_position - global_position).normalized()
	var player_distance = global_position.distance_to(Global.player.global_position)
	var dot = player_direction.dot(view_direction)

	if player_distance < VIEW_RANGE or player_distance < VIEW_RANGE * 2.0 and dot >= 0.0:
		view_cone.visible = true
	else:
		view_cone.visible = false
	
	if player_distance > VIEW_RANGE:
		return
	if dot <= 0.75:
		return
	
	if is_player_visible():
		start_combat()

func is_player_visible():
	if not Global.player:
		return false

	var player_position = Vector3(Global.player.global_position)
	player_position.y = 1.3
	var current_positoin = Vector3(global_position)
	current_positoin.y = 1.3
	
	var space_state = get_world_3d().direct_space_state
	var vision_query = PhysicsRayQueryParameters3D.create(current_positoin, player_position)
	vision_query.exclude = [self]
	vision_query.collision_mask = 3
	var vision_query_result = space_state.intersect_ray(vision_query)
	if vision_query_result:
		if vision_query_result.collider is Player:
			return true
	return false

func start_idle():
	state = EnemyState.IDLE
	input_dir = Vector2.ZERO
	is_aiming = false
	request_shoot = false

func start_patrol():
	next_patrol_start = randf_range(PATROL_START_MIN, PATROL_START_MAX)
	
	if not patrol_points.is_empty():
		current_patrol_point += 1
		current_patrol_point = current_patrol_point % patrol_points.size()
		state = EnemyState.PATROL
	else:
		var rotation_direction = 90.0 if randi() % 2 == 0 else -90
		rotation_target.rotate_y(PI * 0.5)

func start_combat():
	view_cone.visible = false
	state = EnemyState.COMBAT
	GlobalSignals.emit_signal("noise_event", global_position, 8.0)

func update_idle(delta):
	detect_player()
	next_patrol_start -= delta
	if next_patrol_start <= 0:
		start_patrol()

func update_patrol():
	detect_player()
	
	if patrol_points.is_empty():
		start_idle()
		return
	
	var patrol_target = patrol_points[current_patrol_point]
	if global_position.distance_to(patrol_target.global_position) < 1.0:
		input_dir = Vector2.ZERO
		var next_target = patrol_points[(current_patrol_point + 1) % patrol_points.size()]
		rotation_target.look_at(next_target.global_position)
		start_idle()
		return
	
	navigationAgent.target_position = patrol_target.global_position
	var next_node = navigationAgent.get_next_path_position()
	var direction = (next_node - global_position).normalized()
	input_dir = Vector2(direction.x, direction.z)
	# if not rotation_target.global_position.is_equal_approx(next_node):
	if (rotation_target.global_position - next_node).dot(Vector3.UP) > 0.001:
		rotation_target.look_at(next_node)

func update_combat():
	var player = Global.player
	if not player:
		return
		
	if player.is_dead:
		start_idle()
		return
		
	var player_visible =  is_player_visible()
	var player_distance = global_position.distance_to(Global.player.global_position)

	is_aiming = false
	request_shoot = false
	if player_visible:
		# melee
		if not equipped_weapon:
			if player_distance < MELEE_RANGE and melee_cooldown <= 0.0:
				do_melee_attack(animation_tree)
		# ranged
		else:
			if equipped_weapon.ammo <= 0:
				throw_weapon()
				return
			
			if player_distance < WEAPON_RANGE:
				input_dir = Vector2.ZERO
				is_aiming = true
				rotation_target.look_at(player.global_position)

			#debug_label.text = str(rotation_target.global_rotation.y - visuals.global_rotation.y)
			# is enemy aiming in player direction
			if absf(rotation_target.global_rotation.y - visuals.global_rotation.y) < 0.01:
				request_shoot = true
			
			return

	navigationAgent.target_position = player.global_position
	var next_node = navigationAgent.get_next_path_position()
	var direction = (next_node - global_position).normalized()
	
	if player_visible and player_distance <= 0.8 or player_distance <= 0.5:
		input_dir = Vector2.ZERO
	else:
		input_dir = Vector2(direction.x, direction.z)
	
	if is_player_visible():
		rotation_target.look_at(player.global_position)
	else:
		rotation_target.look_at(next_node)
	rotation_target.rotation.x = 0
	rotation_target.rotation.z = 0

func update_animation_state():
	if velocity.is_zero_approx():
		animation_tree["parameters/alive/Movement/blend_amount"] = 0.0
	else:
		animation_tree["parameters/alive/Movement/blend_amount"] = velocity.length() / SPEED
	
	animation_tree["parameters/alive/Aim_State/blend_amount"] = aim_progress
	animation_tree["parameters/alive/Aim_Weapon/blend_amount"] = 1.0 if equipped_weapon else 0.0

func _process(delta):
	if state == EnemyState.DEAD:
		return
	
	if health <= 0:
		kill()


	update_cooldowns(delta)
	update_weapon_gun(delta)
	update_animation_state()
	visuals.rotation.y = move_toward_angle(visuals.rotation.y, rotation_target.rotation.y, ROTATION_SPEED * delta)
	view_direction = -visuals.global_transform.basis.z

func update_weapon_gun(delta):
	handle_weapon_gun(delta, is_aiming, request_shoot, bullet_start, animation_tree)

func kill():
	if equipped_weapon:
		throw_weapon()
	if is_dead:
		return

	view_cone.visible = false
	collision_shape.queue_free()
	skeleton.physical_bones_start_simulation()
	state = EnemyState.DEAD
	is_dead = true

func on_bullet_hit(options):
	if options.collider_id != get_instance_id():
		return
	
	GlobalSignals.emit_signal("screen_shake")
	kill()
	skeleton.get_node("PhysicalBoneBody").apply_central_impulse(options.direction * 10.0)
	skeleton.get_node("PhysicalBoneLegL").apply_central_impulse(options.direction * 5.0)
	skeleton.get_node("PhysicalBoneLegR").apply_central_impulse(options.direction * 5.0)

func on_noise_event(position, distance):
	if state == EnemyState.IDLE or state == EnemyState.PATROL:
		if global_position.distance_to(position) <= distance:
			start_combat()

func hit(damage, direction):
	super.hit(damage, direction)
	view_cone.visible = false
	state = EnemyState.COMBAT
	punch_hit.play()
	reset_cooldowns()

func equip_weapon():
	var gun: Gun = weapon_scene.instantiate()
	weapon_attachment.add_child(gun)
	equipped_weapon = gun;
	equipped_weapon.transform = Basis()
