extends ParallaxBackground

func _process(delta):
	scroll_offset = get_viewport().get_camera_2d().get_screen_center_position()
