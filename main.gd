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
var spin_index = 0
var top_speed = 0.0
var desired_transform = Transform2D()
var countdown = 0
var font = null

# manage touch control state
var previous_rotation_rad = 0.0
var previous_speed = Vector2(0.0, 0.0)
var previous_drag_time_msec = 0
var delta_rad = 0.0
var delta_msec = 0
var drag_time_threshold = 1 #2 #5
var delta_rad_threshold = 0.005

enum TOUCH_STATE {
	Idle,
	Down
}

var touch_state = TOUCH_STATE.Idle

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
		rotation_per_second_rad = rotation_per_second_rad + PI/10
		$Label.hide()
	elif Input.is_action_pressed("ui_down"):
		rotation_per_second_rad = rotation_per_second_rad - PI/10
		$Label.hide()
	elif Input.is_action_pressed("ui_right"):
		spin()
	elif Input.is_action_pressed("ui_left"):
		reveal()
	elif Input.is_action_pressed("ui_focus_next"):
		pass
	elif Input.is_action_pressed("ui_focus_prev"):
		pass

	# apply rotation
	canvas.rotate(delta * rotation_per_second_rad)
	
	var postpone_deceleration = spinning && canvas.rotation < start_angle
	
	if (rotation_per_second_rad > 0.0 && !postpone_deceleration):
		rotation_per_second_rad = lerp(rotation_per_second_rad, 0.0, 0.015)
		if rotation_per_second_rad < 0.05:
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

	# center on viewport
	viewport_size = get_viewport().get_visible_rect().size
	viewport_center = Vector2(viewport_size.x/2, viewport_size.y/2)
	
	hud.update_size(viewport_size, viewport_center)
	
	# scale to smaller dimension
	var min_length = min(viewport_size.x, viewport_size.y)
	var scale = min_length/(global.radius*2) if min_length < (global.radius*2) else 1.0

	canvas.transform = Transform2D(0.0, viewport_center)
	canvas.scale = Vector2(scale, scale)

func spin():
	if (spinning):
		return

	spinning = true
	$Label.hide()

	rng.randomize()
	start_angle = canvas.rotation + 2 * PI + rng.randf() * PI * 2.0
	rotation_per_second_rad = global.base_top_speed

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

func _unhandled_input(event):
	# exit condition: no touch press
	match event.get_class():
		"InputEventScreenTouch":
			var position = event.position
			var rotation_rad = get_rotation_at(position)
			# touch press
			if event.pressed:
				$Label.hide()
				touch_state = TOUCH_STATE.Down
				previous_rotation_rad = rotation_rad
				var time_msec = OS.get_ticks_msec()
				
				previous_drag_time_msec = time_msec if time_msec != previous_drag_time_msec else previous_drag_time_msec
			# touch release
			else:
				# spin if previous recorded angle not same
				touch_state = TOUCH_STATE.Idle
				var elapsed_time = OS.get_ticks_msec() - previous_drag_time_msec

				# if no recent rotation change, stop movement
				if (elapsed_time > drag_time_threshold || delta_rad < delta_rad_threshold):
					print("movement stopped")
					return
				else:
					# use delta_* values
					print("keep spinning")
					delta_msec = 1 if delta_msec < 1 else delta_msec
					rotation_per_second_rad = (delta_rad/delta_msec) * 1000
					#rotation_per_second_rad = (1000 * delta_rad)/elapsed_time
		"InputEventScreenDrag":
			var position = event.position
			var rotation_rad = get_rotation_at(position)
			
			var my_delta = rotation_rad - previous_rotation_rad
			canvas.rotate(my_delta)

			# now update delta_rad, but only if meaningful
			var now = OS.get_ticks_msec()
			if abs(my_delta) > delta_rad_threshold:
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
