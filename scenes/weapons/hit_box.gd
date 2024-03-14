extends Area3D

var life_time = 0.2
var spawner_id = 0
var spawner_character: Character = null
var direction = Vector3.AXIS_X
var bodies_hit = {}

func _process(delta):
	if spawner_character.health <= 0:
		queue_free()
		return
	
	for body in get_overlapping_bodies():
		if not body is Character:
			continue
			
		var body_instance_id = body.get_instance_id()
		if body_instance_id == spawner_id:
			continue
		if bodies_hit.has(body_instance_id):
			continue
		bodies_hit[body_instance_id] = true
		body.hit(60, direction)

	life_time -= delta
	if life_time < 0:
		queue_free()
