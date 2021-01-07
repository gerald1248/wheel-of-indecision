extends Node2D

var padding = global.gui_padding

func _ready():
	if global.is_iphone_x:
		padding = max(global.safe_area_position.x, global.safe_area_position.y) * 0.75

func update_size(viewport_size, viewport_center):
	if (min(viewport_size.y/2, viewport_size.x/2) < global.radius):
		var y = viewport_center.y - global.radius * global.scale
		$Triangle.offset = Vector2(viewport_center.x, y)
	else:
		$Triangle.scale = Vector2(1.0, 1.0)
		$Triangle.offset = Vector2(viewport_center.x, viewport_center.y - global.radius)
	
	$Settings.rect_position = Vector2(viewport_size.x - $Settings.rect_size.x - padding, padding)
	$Spin.rect_position = Vector2(viewport_size.x - $Spin.rect_size.x - padding, viewport_size.y - $Spin.rect_size.y - padding)

	if !global.is_mobile():
		$Spin.grab_focus()

func _on_Settings_pressed():
	get_tree().change_scene("res://settings.tscn")

func _on_Spin_pressed():
	get_tree().get_root().get_node("Node2D").spin()

