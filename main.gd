extends Node2D

const CANVAS = preload("res://canvas.tscn")
const HUD = preload("res://hud.tscn")
var rotation_per_second_rad = 0.0
var start_angle = 0.0
var canvas = null
var hud = null
var timer = null
var rng = null
var viewport_size = Vector2(0, 0)
var viewport_center = Vector2(0, 0)
var spinning = false
var reveal = false
var desired_transform = Transform2D()
var countdown = 0
var font = null

# manage touch control state
var previous_rotation_rad = 0.0
var previous_speed = Vector2(0.0, 0.0)
var previous_drag_time_msec = 0
var delta_rad = 0.0
var delta_msec = 0
var drag_time_threshold = 100

func _ready():
	rng = RandomNumberGenerator.new()

	var _err = get_tree().get_root().connect("size_changed", self, "on_window_resized")
	viewport_size = get_viewport().get_visible_rect().size
	canvas = CANVAS.instance()
	canvas.z_index = -1
	add_child(canvas)

	hud = HUD.instance()
	hud.z_index = 100
	add_child(hud)

	update_size()

	font = DynamicFont.new()
	font.font_data = load("res://fonts/Roboto-Light.ttf")
	font.size = 160

func _process(delta):
	if Input.is_action_pressed("ui_up"):
		pass
	elif Input.is_action_pressed("ui_down"):
		spin()
	elif Input.is_action_pressed("ui_right"):
		spin()
	elif Input.is_action_pressed("ui_left"):
		pass

	# apply rotation
	canvas.rotate(delta * rotation_per_second_rad)
	
	var postpone_deceleration = spinning && canvas.rotation < start_angle
	
	if (abs(rotation_per_second_rad) > 0.0 && !postpone_deceleration):
		rotation_per_second_rad = lerp(rotation_per_second_rad, 0.0, 0.015)
		if abs(rotation_per_second_rad) < 0.05:
			rotation_per_second_rad = 0.0
			spinning = false
			start_angle = 0.0
			reveal()
	
	if (reveal):
		$Label.rect_scale = Vector2(
			lerp($Label.rect_scale.x, 1.0, 0.1),
			lerp($Label.rect_scale.y, 1.0, 0.1))

func on_window_resized():
	update_size()

func update_size():
	$Label.hide()
	stop()

	# center on viewport
	viewport_size = get_viewport().get_visible_rect().size
	viewport_center = Vector2(viewport_size.x/2, viewport_size.y/2)

	# scale to smaller dimension
	var min_length = min(viewport_size.x, viewport_size.y)
	var scale = min_length/(global.radius*2) if min_length < (global.radius*2) else 1.0

	canvas.transform = Transform2D(0.0, viewport_center)
	canvas.scale = Vector2(scale, scale)
	global.scale = scale

	# HUD update requires current scale
	hud.update_size(viewport_size, viewport_center)

func spin():
	spinning = true
	$Label.hide()

	rng.randomize()
	start_angle = canvas.rotation + 2 * PI + rng.randf() * PI * 2.0
	rotation_per_second_rad = global.base_top_speed if rotation_per_second_rad <= 0.0 else global.base_top_speed + rotation_per_second_rad

func reveal():
	reveal = true

	var current_rotation = fmod(canvas.rotation, 2 * PI)
	var selection = canvas.get_node("Canvas").get_top_label(current_rotation)
	var label_size = font.get_string_size(selection)
	var offset = Vector2(label_size.x/2, label_size.y/2)

	$Label.text = selection
	$Label.rect_pivot_offset = offset
	$Label.rect_position = viewport_center - offset
	$Label.rect_scale = Vector2(0.25, 0.25)
	$Label.show_on_top = true
	$Label.show()

func stop():
	reveal = false
	spinning = false # experimental
	rotation_per_second_rad = 0.0

func point_on_wheel(p1):
	return (p1.distance_to(viewport_center)) <= (global.radius * global.scale)

func _unhandled_input(event):
	# exit condition: no touch press
	match event.get_class():
		"InputEventScreenTouch":
			var position = event.position

			if !point_on_wheel(position):
				return

			var rotation_rad = get_rotation_at(position)

			if event.pressed: # touch press
				stop()
				$Label.hide()
				previous_rotation_rad = rotation_rad
				var time_msec = OS.get_ticks_msec()
				previous_drag_time_msec = time_msec if time_msec != previous_drag_time_msec else previous_drag_time_msec
				delta_rad = 0.0
			
			else: # touch release
				stop() # but override rotation_per_second_rad if condition met

				# spin if previous recorded angle not same
				var elapsed_time = OS.get_ticks_msec() - previous_drag_time_msec

				# if no recent rotation change, stop movement
				if (elapsed_time > drag_time_threshold):
					return
				else:
					delta_msec = 1 if delta_msec < 1 else delta_msec
					rotation_per_second_rad = (delta_rad/delta_msec) * 1000
		"InputEventScreenDrag":
			var position = event.position

			if !point_on_wheel(position):
				return

			stop()

			var rotation_rad = get_rotation_at(position)
			
			var my_delta = rotation_rad - previous_rotation_rad
			canvas.rotate(my_delta)

			# now update delta_rad
			var now = OS.get_ticks_msec()
			delta_rad = my_delta
			delta_msec = now - previous_drag_time_msec
			previous_drag_time_msec = now

			# now update state
			previous_rotation_rad = rotation_rad
			previous_drag_time_msec = OS.get_ticks_msec()

		_:
			pass

func get_rotation_at(my_position):
	return atan2(my_position.y - viewport_center.y, my_position.x - viewport_center.x)

func _notification(what):
		match (what):
				MainLoop.NOTIFICATION_WM_FOCUS_OUT:
						global.save_config()
				MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
						global.save_config()
				MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
						get_tree().quit()
