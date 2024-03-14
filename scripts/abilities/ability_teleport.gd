extends BaseAbility
@onready var teleport_effect = $"../../TeleportEffect"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super._process(delta)

func trigger(character: Player):
	var parent_result = super.can_trigger(character, character.aim_area)
	if parent_result != AbilityTriggerResult.OK:
		return parent_result
	
	if not character.aim_position_free:
		return AbilityTriggerResult.AREA_OCCUPIED
	
	super.trigger(character)
	teleport_effect.emitting = true
	character.global_position.x = character.aim_area.global_position.x
	character.global_position.z = character.aim_area.global_position.z

	return AbilityTriggerResult.OK
