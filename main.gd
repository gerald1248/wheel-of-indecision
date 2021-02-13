extends Node2D

const CANVAS = preload("res://canvas.tscn")
const HUD = preload("res://hud.tscn")
var rotation_per_second_rad = 0.0
var start_angle = 0.0
var current_rotation_rad = 0.0
var canvas = null
var hud = null
var timer = null
var rng = null
var viewport_size = Vector2(0, 0)
var viewport_center = Vector2(0, 0)
var spinning = false
var is_reveal = false
var desired_transform = Transform2D()
var countdown = 0
var font = null
var default_banner_font_size = 160
var banner_min_scale = 0.2
var banner_max_scale = 1.0
var friction_factor = 0.015

# manage touch control state
var previous_rotation_rad = 0.0
var previous_speed = Vector2(0.0, 0.0)
var previous_drag_time_msec = 0
var delta_rad = 0.0
var delta_msec = 0
var drag_time_threshold = 100
var audio_current_index = 0
var audio_max_index = 8
var is_wheel_drag = false

func _ready():
	rng = RandomNumberGenerator.new()

	var _err = get_tree().get_root().connect("size_changed", self, "on_window_resized")
	viewport_size = get_viewport().get_visible_rect().size
	canvas = CANVAS.instance()
	canvas.z_index = -100
	add_child(canvas)

	hud = HUD.instance()
	hud.z_index = -50
	add_child(hud)
	
	global.debug_string = str(global.debug_string, ":")

	update_size()

	font = DynamicFont.new()
	font.font_data = load("res://fonts/Roboto-Light.ttf")
	font.size = default_banner_font_size

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
	var my_previous_rotation_rad = canvas.rotation
	canvas.rotate(delta * rotation_per_second_rad)
	current_rotation_rad = canvas.rotation
	
	if global.audio_enabled && global.is_bell_interval(my_previous_rotation_rad, current_rotation_rad):
		play_bell()

	var postpone_deceleration = spinning && canvas.rotation < start_angle
	
	if (abs(rotation_per_second_rad) > 0.0 && !postpone_deceleration):		
		rotation_per_second_rad = lerp(rotation_per_second_rad, 0.0, friction_factor)
		if abs(rotation_per_second_rad) < 0.05:
			rotation_per_second_rad = 0.0
			spinning = false
			start_angle = 0.0
			reveal()
	
	if (is_reveal):
		$Label.rect_scale = Vector2(
			lerp($Label.rect_scale.x, banner_max_scale, 0.1),
			lerp($Label.rect_scale.y, banner_max_scale, 0.1))

func on_window_resized():
	call_deferred("update_size")

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

	canvas.rotation = current_rotation_rad

	# HUD update requires current scale
	hud.update_size(viewport_size, viewport_center)

func spin():
	spinning = true
	$Label.hide()

	canvas.rotation = fmod(canvas.rotation, 2 * PI)

	rng.randomize()
	var rand = rng.randf()
	start_angle = canvas.rotation + 2 * PI + rand * PI * 2.0
	rotation_per_second_rad = global.base_top_speed if rotation_per_second_rad <= 0.0 else global.base_top_speed + rotation_per_second_rad

func reveal():
	is_reveal = true

	var current_rotation = fmod(canvas.rotation, 2 * PI)
	var selection = canvas.get_node("Canvas").get_top_label(current_rotation)
	
	var label_size = font.get_string_size(selection)

	banner_max_scale = 1.0
	if label_size.x > viewport_size.x:
		var factor = float(viewport_size.x)/float(label_size.x)
		banner_max_scale = factor if factor > banner_min_scale else banner_min_scale

	var offset = Vector2(label_size.x/2, label_size.y/2)

	$Label.text = selection
	$Label.rect_pivot_offset = offset
	$Label.rect_position = viewport_center - offset
	$Label.rect_scale = Vector2(banner_min_scale, banner_min_scale)
	$Label.show_on_top = true
	$Label.show()

	if global.audio_enabled:
		$gong.play()

func stop():
	is_reveal = false
	spinning = false
	rotation_per_second_rad = 0.0

func point_on_wheel(p1):
	return (p1.distance_to(viewport_center)) <= (global.radius * global.scale)

func _unhandled_input(event):
	# exit condition: no touch press
	match event.get_class():
		"InputEventScreenTouch":
			var position = event.position

			if !point_on_wheel(position) && !is_wheel_drag:
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
				is_wheel_drag = false
		"InputEventScreenDrag":
			var position = event.position

			if !point_on_wheel(position) && !is_wheel_drag:
				return

			stop()

			is_wheel_drag = true # drag originated on wheel

			var rotation_rad = get_rotation_at(position)
			
			var my_delta = rotation_rad - previous_rotation_rad
			canvas.rotate(my_delta)
			
			# sound bell as appropriate
			if global.audio_enabled && global.is_bell_interval(previous_rotation_rad, rotation_rad):
				play_bell()

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
				MainLoop.NOTIFICATION_WM_ABOUT:
					global.show_about()

func play_bell():
	var audio = null
	match (audio_current_index):
		0:
			audio = $audio01
		1:
			audio = $audio02
		2:
			audio = $audio03
		3:
			audio = $audio04
		4:
			audio = $audio05
		5:
			audio = $audio06
		6:
			audio = $audio07
		7:
			audio = $audio08
	# play even if it means interrupting the current sample
	# this only occurs when the wheel is spinning fast
	audio.play()
	audio_current_index += 1
	audio_current_index = audio_current_index % audio_max_index
