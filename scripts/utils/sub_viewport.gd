extends SubViewport

func _ready():
	get_viewport().connect("size_changed", _on_vp_size_changed)

func _on_vp_size_changed() -> void:
	self.size = get_viewport().size
	# self.size_override_stretch = true
	# .set_size_override(true, viewport_orig_size)
