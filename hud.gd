extends Node2D

var padding = global.gui_padding

func _ready():
	if global.is_iphone_x:
		padding = max(global.safe_area_position.x, global.safe_area_position.y) * 0.75
	set_audio_enabled(global.audio_enabled)


func update_size(viewport_size, viewport_center):
	if (min(viewport_size.y/2, viewport_size.x/2) < global.radius):
		var y = viewport_center.y - global.radius * global.scale
		$Triangle.offset = Vector2(viewport_center.x, y)
	else:
		$Triangle.scale = Vector2(1.0, 1.0)
		$Triangle.offset = Vector2(viewport_center.x, viewport_center.y - global.radius)
	
	$Settings.rect_position = Vector2(viewport_size.x - $Settings.rect_size.x - padding, padding)
	$Spin.rect_position = Vector2(viewport_size.x - $Spin.rect_size.x - padding, viewport_size.y - $Spin.rect_size.y - padding)
	$SoundOn.rect_position = Vector2(padding, viewport_size.y - $Spin.rect_size.y - padding)
	$SoundOff.rect_position = Vector2(padding, viewport_size.y - $Spin.rect_size.y - padding)

	if !global.is_mobile():
		$Spin.grab_focus()

func _on_Settings_pressed():
	var _err = get_tree().change_scene("res://settings.tscn")

func _on_SoundOn_button_down():
	set_audio_enabled(false)

func _on_SoundOff_button_down():
	set_audio_enabled(true)

func _on_Spin_button_down():
	get_tree().get_root().get_node("Node2D").spin()

func set_audio_enabled(b):
	if (b):
		$SoundOn.show()
		$SoundOff.hide()
		$Settings.focus_next = get_node("SoundOn").get_path()
		$Spin.focus_previous = get_node("SoundOn").get_path()
		$SoundOn.grab_focus()
		global.audio_enabled = true
	else:
		$SoundOff.show()
		$SoundOn.hide()
		$Settings.focus_next = get_node("SoundOff").get_path()
		$Spin.focus_previous = get_node("SoundOff").get_path()
		$SoundOff.grab_focus()
		global.audio_enabled = false
	# need to save config here as normally only called from settings screen
	global.save_config()

