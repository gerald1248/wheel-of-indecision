extends Node2D

var labels = global.labels
var center = Vector2(0, 0)
var radius = global.radius
var radius_border = radius/10
var label_box_width = global.radius - radius_border * 2
var color = Color(1.0, 1.0, 1.0)
var font = null
var label_count = 0
var label_step_rad = 0.0

func _ready():
	font = DynamicFont.new()
	font.font_data = load("res://fonts/Roboto-Light.ttf")
	font.size = global.font_size
	font.use_filter = true

func _draw():
	if (labels.size() == 0):
		return

	if (labels.size() % 2):
		labels.append("Spin again")
	
	label_count = labels.size()
	label_step_rad = 2 * PI/label_count
	var current_rotation_rad = 0.0

	var counter = 0

	# prepare background
	var last_boundary_rad = PI - 2 * label_step_rad
	var first_boundary_rad = 2 * label_step_rad
	
	var a = Vector2(0, 0)
	var b = Vector2(radius * sin(last_boundary_rad), radius * cos(last_boundary_rad))
	var c = Vector2(b.x, -b.y)
	
	var points = [ a, b, c ]
	
	for label in labels:
		# draw background
		counter += 1
		var color = Color(255, 0, 0) if (counter % 2) else Color(0, 0, 0)		
		var colors = [ color, color, color ]
		draw_polygon(points, colors)

		# draw label
		var font_size = font.get_string_size(label)
		if font_size.x > label_box_width:
			font_size.x = label_box_width
		draw_string(font, Vector2(radius_border + label_box_width - font_size.x, font_size.y/2),label, Color(255, 255, 255), label_box_width)

		# rotate
		current_rotation_rad += label_step_rad
		draw_set_transform(Vector2(0, 0), current_rotation_rad, Vector2(1, 1))
	pass

func normalize_rad(rad):
	if (rad < 0 && rad > -2 * PI):
		rad = rad + 2 * PI

	return fmod(rad, 2 * PI)

func get_top_label(rotation_rad):
	var labels_inverted = global.labels.duplicate()
	labels_inverted.invert()
	
	print(labels_inverted)
	
	var index = 0
	var adjust = 4.712389
	var selection = ""
	for label in labels_inverted:
		var lower = normalize_rad(index * label_step_rad + 0.5 * label_step_rad + adjust)
		var upper = normalize_rad((index + 1) * label_step_rad + 0.5 * label_step_rad + adjust)
		
		if (rotation_rad >= lower && rotation_rad < upper):
			return label
		elif (lower > upper && rotation_rad > upper && rotation_rad > lower):
			return label

		index = index + 1

	return "not found"
