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
var label_placeholder = "Spin again"

func _ready():
	font = DynamicFont.new()
	font.font_data = load("res://fonts/Roboto-Light.ttf")
	font.size = global.font_size
	font.use_filter = true

func _draw():
	if (labels.size() == 0):
		return

	# enforce even number of labels
	if (labels.size() % 2):
		labels.append(label_placeholder)
	
	label_count = labels.size()
	label_step_rad = 2 * PI/label_count
	var current_rotation_rad = 0.0

	var counter = 0
		
	for label in labels:
		# draw background
		counter += 1
		var color = Color(255, 0, 0) if (counter % 2) else Color(0, 0, 0)		
		draw_circle_arc_poly(Vector2(0, 0), radius, rad2deg(PI/2 - label_step_rad/2), rad2deg(PI/2 + label_step_rad/2), color)

		# draw label
		var font_size = font.get_string_size(label)
		if font_size.x > label_box_width:
			font_size.x = label_box_width
		# allow 1.5 times padding at center
		draw_string(font, Vector2(radius_border * 1.5 + label_box_width - font_size.x, font_size.y/2),label, Color(255, 255, 255), label_box_width)

		# rotate
		current_rotation_rad += label_step_rad
		draw_set_transform(Vector2(0, 0), current_rotation_rad, Vector2(1, 1))
	pass

# https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html
func draw_circle_arc_poly(center, radius, angle_from, angle_to, color):
	var nb_points = 32
	var points_arc = PoolVector2Array()
	points_arc.push_back(center)
	var colors = PoolColorArray([color])

	for i in range(nb_points + 1):
		var angle_point = deg2rad(angle_from + i * (angle_to - angle_from) / nb_points - 90)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	draw_polygon(points_arc, colors)

func normalize_rad(rad):
	if (rad < 0 && rad > -2 * PI):
		rad = rad + 2 * PI

	return fmod(rad, 2 * PI)

func get_top_label(rotation_rad):
	var labels_inverted = global.labels.duplicate()
	labels_inverted.invert()
	
	# flip negative values
	if (rotation_rad < 0.0):
		rotation_rad = fmod(rotation_rad, 2 * PI) + 2 * PI
	
	# >= 0 does not match initial 0, so adjust here
	if (rotation_rad == 0.0):
		rotation_rad = 0.000001
	
	var index = 0
	var adjust = 4.712389 # pick top label
	var selection = ""
	var lower = 0.0
	var upper = 0.0
	for label in labels_inverted:
		lower = normalize_rad(index * label_step_rad + 0.5 * label_step_rad + adjust)
		upper = normalize_rad((index + 1) * label_step_rad + 0.5 * label_step_rad + adjust)
		
		if (rotation_rad >= lower && rotation_rad < upper):
			return label
		elif (lower > upper):
			if (rotation_rad >= upper && rotation_rad >= lower):
				return label
			elif (rotation_rad < upper && rotation_rad < lower):
				return label

		index = index + 1
	return "not found" 
