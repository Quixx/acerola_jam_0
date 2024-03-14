extends BaseAbility
@onready var teleport_effect = $"../../TeleportEffect"

func _process(delta):
	super._process(delta)

func trigger(character: Player):
	var parent_result = super.can_trigger(character, character.ability_target)
	if parent_result != AbilityTriggerResult.OK:
		return parent_result
	
	if not character.ability_target:
		return AbilityTriggerResult.INVALID_TARGET
	
	super.trigger(character)
	
	teleport_effect.emitting = true
	var swap_position = Vector3(character.ability_target.global_position)
	character.ability_target.global_position = character.global_position
	character.global_position = swap_position
	
	return AbilityTriggerResult.OK
