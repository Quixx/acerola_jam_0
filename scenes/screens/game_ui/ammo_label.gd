extends Label


func _process(delta):
	var player = Global.player
	if not player or player.is_dead:
		self.visible = false
		return
	var gun: Gun = player.equipped_weapon
	if not gun:
		self.visible = false
		return
	
	self.visible = true
	self.text = str(gun.ammo) + "/" + str(gun.ammo_max)
	
func _input(event):
	if event is InputEventMouseMotion:
		self.set_global_position( event.position + Vector2(22.0, -12.0))
