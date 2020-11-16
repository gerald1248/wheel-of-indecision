extends Node2D

const CANVAS = preload("res://canvas.tscn")
var rotation_per_second_rad = 0.0
var canvas = null
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

func _ready():
	var _err = get_tree().get_root().connect("size_changed", self, "on_window_resized")
	viewport_size = get_viewport().get_visible_rect().size
	canvas = CANVAS.instance()
	canvas.z_index = -1
	add_child(canvas)
	update_size()
	
	font = DynamicFont.new()
	font.font_data = load("res://fonts/Roboto-Light.ttf")
	font.size = 160

	rng = RandomNumberGenerator.new()	

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

	# apply rotation
	canvas.rotate(delta * rotation_per_second_rad)
	
	if (rotation_per_second_rad > 0.0):
		rotation_per_second_rad = lerp(rotation_per_second_rad, 0.0, 0.015)
		if rotation_per_second_rad < 0.05:
			rotation_per_second_rad = 0.0
			reveal()
	else:
		spinning = false
	
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
	top_speed = global.base_top_speed + (rng.randf() * PI)
	rotation_per_second_rad = top_speed

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
