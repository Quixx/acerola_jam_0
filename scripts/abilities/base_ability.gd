extends Node
class_name BaseAbility

@export var ability_name = ""
@export var cooldown_time = 0.5
@export var active_duration: float = 0.0
@export var max_distance: float = 0.0

var was_used = false
var cooldown_timer = 0.0
var active_timer = 0.0

enum AbilityTriggerResult {
	OK,
	COOLDOWN,
	OUT_OF_RANGE,
	AREA_OCCUPIED,
	INVALID_TARGET,
	NO_USAGE_LEFT,
}

func _ready():
	pass

func _process(delta):
	if cooldown_timer > 0:
		cooldown_timer -= delta
	if active_timer > 0:
		active_timer -= delta
		
func trigger(character: Player):
	cooldown_timer = cooldown_time
	active_timer = active_duration
	was_used = true
	GlobalSignals.emit_signal("ability_start", active_duration)

	return AbilityTriggerResult.OK

func can_trigger(character: Player, target_position: Node3D):
	if cooldown_timer > 0:
		return AbilityTriggerResult.COOLDOWN
	
	if target_position:
		var start_pos = Vector3( character.global_position )
		start_pos.y = 0
		
		var end_pos = Vector3( target_position.global_position )
		end_pos.y = 0
		
		var sqr_dist = max_distance * max_distance
		if start_pos.distance_squared_to(end_pos) > sqr_dist:
			return AbilityTriggerResult.OUT_OF_RANGE

	return AbilityTriggerResult.OK
	
func is_active():
	return active_timer > 0
