extends Node

const debug = false

const config_path = "user://wheel-of-indecision.data"
const base_top_speed = 4 * PI

# radius and font_size have to be mutable
var radius = 900
var font_size = 76

const gui_padding = 30
const gui_control_padding = 20
const gui_control_height = 64

const wheel_delimiter = ";"
const label_delimiter = ":"

const about_text = """
Copyright © 2021 Gerald Schmidt, MIT License
<github.com/gerald1248/wheel-of-indecision>

Godot Engine by Juan Linietsky, Ariel Manzur and Godot Engine Contributors, MIT License
<github.com/godotengine/godot>

Percussion samples taken from sample pack Percussion by Joao_Janz
Attribution Noncommercial: http://creativecommons.org/licenses/by-nc/3.0/
<freesound.org/people/Joao_Janz/packs/27269>

Color palette taken from Colors by mrmrs, MIT License
<github.com/mrmrs/colors>

Icons taken from Material Design set, Apache License, Version 2.0
<material.io/resources/icons/?style=baseline>

Roboto font by Christian Robertson, Apache License, Version 2.0
<fonts.google.com/specimen/Roboto>
"""

var viewport_size
var viewport_ratio
var safe_area
var safe_area_position
var is_ios
var is_ipad
var is_iphone_x
var is_android
var hud_padding
var bell_rad = PI
var bell_adjustment_rad = 0.0

var debug_string = ""

const default_settings = \
	"Team:Alexander:Ali:Do Yoon:Maria:Nozomi:Saanvi:Sofia:Wei;" \
	+ "Coin:Heads:Tails;" \
	+ "Die (4 sides):1:2:3:4;" \
	+ "Die (6 sides):1:2:3:4:5:6;" \
	+ "Die (10 sides):1:2:3:4:5:6:7:8:9:10;" \
	+ "Die (20 sides):1:2:3:4:5:6:7:8:9:10:11:12:13:14:15:16:17:18:19:20;"
const default_title = "Team"
const default_audio_enabled = true

var scale = 1.0

var settings = ""
var title = ""
var labels = []
var audio_enabled = true

func _ready():
	load_config()
	if len(title) == 0 || len(settings) == 0:
		print("using default settings")
		settings = default_settings
		title = default_title

	# prepare for device and screen management
	safe_area = OS.get_window_safe_area()
	safe_area_position = Vector2(safe_area.position.x, safe_area.position.y)
	viewport_size = get_viewport().get_visible_rect().size
	hud_padding = safe_area_position.x

	viewport_size = get_viewport().get_visible_rect().size
	viewport_ratio = max(viewport_size.x, viewport_size.y)/min(viewport_size.x, viewport_size.y)
	is_ios = OS.get_name() == "iOS"
	is_ipad = is_ios && viewport_ratio < 1.34
	is_iphone_x = is_ios && viewport_ratio > 1.8
	is_android = OS.get_name() == "Android"

	# halve radius when it does not add to the resolution
	# applies to mobile only
	if (is_android || is_ios) && min(viewport_size.x, viewport_size.y) <= radius:
		radius = radius/2
		font_size = font_size/2

func get_labels(my_settings, my_title):
	var wheels = my_settings.split(";")
	for wheel in wheels:
		if (wheel.length() == 0):
			break

		var my_labels = wheel.split(":")
		
		if (my_title == my_labels[0]):
			my_labels.remove(0)
			return my_labels
	return []

func is_mobile():
	var my_name = OS.get_name()
	return (my_name == "iOS" || my_name == "Android")

func load_config():
	var file = File.new()
	if not file.file_exists(config_path): return
	file.open(config_path, File.READ)
	settings = file.get_var()
	title = file.get_var()
	audio_enabled = file.get_var()
	if (typeof(audio_enabled) == TYPE_NIL):
		audio_enabled = default_audio_enabled
	file.close()

func save_config():
	var file = File.new()
	file.open(config_path, File.WRITE)
	file.store_var(settings)
	file.store_var(title)
	file.store_var(audio_enabled)
	file.close()

func is_bell_interval(previous_rad, current_rad):
	previous_rad += bell_adjustment_rad
	current_rad += bell_adjustment_rad
	var previous_rad_mod = fmod(previous_rad, PI*2)
	var current_rad_mod = fmod(current_rad, PI*2)
	# clockwise
	if previous_rad < current_rad && current_rad_mod < previous_rad_mod:
		return true
	# anti-clockwise
	elif current_rad < previous_rad && previous_rad_mod < current_rad_mod:
		return true
	return false

func show_about():
	$AcceptDialog.dialog_text = about_text
	$AcceptDialog.get_close_button().hide()
	$AcceptDialog.popup_centered_minsize()
