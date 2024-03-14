extends BaseAbility

@export var time_scale = 0.5

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	super._process(delta)
	
	if not is_equal_approx(Engine.time_scale, 1.0) and not is_active():
		Engine.time_scale = 1.0

func trigger(character: Player):
	var parent_result = super.can_trigger(character, null)
	if parent_result != AbilityTriggerResult.OK:
		return parent_result

	super.trigger(character)
	Engine.time_scale = time_scale
	
	return AbilityTriggerResult.OK
