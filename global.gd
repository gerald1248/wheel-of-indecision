extends Node

const config_path = "user://wheel-of-indecision.data"
const radius = 900
const base_top_speed = 6 * PI
const font_size = 76

const gui_padding = 30
const gui_control_padding = 20
const gui_control_height = 64

const wheel_delimiter = ";"
const label_delimiter = ":"

const default_settings = \
	"Team:Alexander:Ali:Do Yoon:Maria:Nozomi:Saanvi:Sofia:Wei;" \
	+ "Coin:Heads:Tails;" \
	+ "Die (4 sides):1:2:3:4;" \
	+ "Die (6 sides):1:2:3:4:5:6;" \
	+ "Die (10 sides):1:2:3:4:5:6:7:8:9:10;" \
	+ "Die (20 sides):1:2:3:4:5:6:7:8:9:10:11:12:13:14:15:16:17:18:19:20;"
const default_title = "Team"

var scale = 1.0

var settings = ""
var title = ""
var labels = []

func _ready():
	load_config()
	if len(title) == 0 || len(settings) == 0:
		print("using default settings")
		settings = default_settings
		title = default_title

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
		file.close()

func save_config():
		var file = File.new()
		file.open(config_path, File.WRITE)
		file.store_var(settings)
		file.store_var(title)
		file.close()
