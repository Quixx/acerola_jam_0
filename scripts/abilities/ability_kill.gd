extends BaseAbility

func _process(delta):
	super._process(delta)

func trigger(character: Player):
	var parent_result = super.can_trigger(character, character.ability_target)
	if parent_result != AbilityTriggerResult.OK:
		return parent_result
	
	if not character.ability_target:
		return AbilityTriggerResult.INVALID_TARGET
	
	if not character.ability_target is Character:
		return AbilityTriggerResult.INVALID_TARGET
	
	var target_character: Character = character.ability_target
	
	super.trigger(character)
	
	target_character.kill()
	
	return AbilityTriggerResult.OK
