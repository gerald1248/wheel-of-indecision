extends Node2D

var labels = global.get_labels(global.settings, global.title)
var center = Vector2(0, 0)
var radius = global.radius
var radius_border = radius/10
var label_box_width = global.radius - radius_border * 2
var font = null
var label_count = 0
var label_step_rad = 0.0
var label_placeholder = "Spin again"
var vertical_adjust = 20.0
var colors = {
	"red": Color("#ff4136"),
	"orange": Color("#ff851B"),
	"yellow": Color("#ffdc00"),
	"lime": Color("#01ff70"),
	"green": Color("#2ecc40"),
	"olive": Color("#3d9970"),
	"teal": Color("#39cccc"),
	"aqua": Color("#7fdbff"),
	"blue": Color("#0074d9"),
	"navy": Color("#001f3f"),
	"purple": Color("#b10dc9"),
	"fuchsia": Color("#f012be"),
	"maroon": Color("#85144b"),
	"black": Color("#111111")
}

var colors_2 = [ colors.red, colors.blue ]
var colors_4 = [ colors.red, colors.yellow, colors.green, colors.blue ]
var colors_6 = [ colors.red, colors.orange, colors.yellow, colors.green, colors.teal, colors.blue ]
var colors_8 = [ colors.red, colors.orange, colors.yellow, colors.lime, colors.green, colors.olive, colors.blue, colors.fuchsia ]
var colors_10 = [ colors.red, colors.orange, colors.yellow, colors.lime, colors.green, colors.olive, colors.teal, colors.blue, colors.purple, colors.maroon ]
var colors_12 = [ colors.red, colors.orange, colors.yellow, colors.lime, colors.green, colors.olive, colors.teal, colors.aqua, colors.blue, colors.purple, colors.fuchsia, colors.maroon ]
var colors_alternating = colors_2.duplicate()

func _ready():
	font = DynamicFont.new()
	font.font_data = load("res://fonts/Roboto-Light.ttf")
	font.size = global.font_size
	font.use_filter = true
	font.use_mipmaps = false

func _draw():
	if (labels.size() == 0):
		return

	# enforce even number of labels
	if (labels.size() % 2):
		labels.append(label_placeholder)
	
	var my_colors = []
	match labels.size():
		2:
			my_colors = colors_2
		4:
			my_colors = colors_4
		6:
			my_colors = colors_6
		8:
			my_colors = colors_8
		10:
			my_colors = colors_10
		12:
			my_colors = colors_12
		_:
			my_colors = colors_alternating

	label_count = labels.size()
	label_step_rad = 2 * PI/label_count
	var current_rotation_rad = 0.0

	var counter = 0
		
	for label in labels:
		# draw background
		var color = get_color(my_colors, counter)
		draw_circle_arc_poly(Vector2(0, 0), radius, rad2deg(PI/2 - label_step_rad/2), rad2deg(PI/2 + label_step_rad/2), color)
		counter += 1

		# draw label
		var font_size = font.get_string_size(label)
		if font_size.x > label_box_width:
			font_size.x = label_box_width
		# color threshold for black/white text is 110
		#var color_threshold = 110
		var label_color = get_font_color(color)
		draw_string(font, Vector2(radius_border * 1.5 + label_box_width - font_size.x, font_size.y/2-vertical_adjust),label, label_color, label_box_width)

		# rotate
		current_rotation_rad += label_step_rad
		draw_set_transform(Vector2(0, 0), current_rotation_rad, Vector2(1, 1))
	pass

func get_color(my_colors, index):
	var length = my_colors.size()
	var offset = index % length
	return my_colors[offset]

func get_font_color(my_color):
	var luma = ((0.299 * my_color.r8) + (0.587 * my_color.g8) + (0.114 * my_color.b8)) / 255
	return Color("#111111") if luma > 0.6 else Color("#ffffff")

# https://docs.godotengine.org/en/stable/tutorials/2d/custom_drawing_in_2d.html
func draw_circle_arc_poly(center, radius, angle_from, angle_to, color):
	var nb_points = 32
	var points_arc = PoolVector2Array()
	points_arc.push_back(center)
	var colors = PoolColorArray([color])

	for i in range(nb_points + 1):
		var angle_point = deg2rad(angle_from + i * (angle_to - angle_from) / nb_points - 90)
		points_arc.push_back(center + Vector2(cos(angle_point), sin(angle_point)) * radius)
	draw_polygon(
		points_arc,
		colors,
		PoolVector2Array(),
		null,
		null,
		true #anti-alias
	)

func normalize_rad(rad):
	if (rad < 0 && rad > -2 * PI):
		rad = rad + 2 * PI

	return fmod(rad, 2 * PI)

func get_top_label(rotation_rad):
	var labels_inverted = PoolStringArray(labels)

	labels_inverted.append_array(labels)
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
	return "redacted"
