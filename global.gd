extends Node

const radius = 900
const base_top_speed = 6 * PI
const font_size = 60

const gui_padding = 30
const gui_control_padding = 20
const gui_control_height = 64

const wheel_delimiter = ";"
const label_delimiter = ":"

const default_settings = \
	"Team:Alexander:Ali:Do Yoon:Maria:Nozomi:Saanvi:Sofia:Wei;" \
	+ "Doom Lords:Cat:Pooja:Seema:Daniela:Dave:Dan:Florent:Thomas:Gerald;" \
	+ "Coin:Heads:Tails;" \
	+ "Die (4 sides):1:2:3:4;" \
	+ "Die (6 sides):1:2:3:4:5:6;" \
	+ "Die (10 sides):1:2:3:4:5:6:7:8:9:10;" \
	+ "Die (20 sides):1:2:3:4:5:6:7:8:9:10:11:12:13:14:15:16:17:18:19:20;"
const default_title = "Team"

var settings = default_settings
var title = default_title
var labels = []

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
