extends Node

@export var BulletHole : PackedScene
@export var BloodParticles : PackedScene

func _ready():
	GlobalSignals.connect("bullet_hit", on_bullet_hit)

func on_bullet_hit(options):
	if options.hit_type == Bullet.HitType.WALL:
		var bullet_hole = BulletHole.instantiate()
		self.add_child(bullet_hole)
		
		bullet_hole.position = options.hit_point
		bullet_hole.look_at(options.hit_point + options.normal, -Vector3.UP)
	
	if options.hit_type == Bullet.HitType.CHARACTER:
		var blood_particles = BloodParticles.instantiate()
		self.add_child(blood_particles)

		blood_particles.position = options.hit_point
		blood_particles.look_at(options.hit_point + options.direction, Vector3.UP)
		blood_particles.emitting = true
