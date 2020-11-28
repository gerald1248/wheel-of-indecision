extends Node2D

var padding = global.gui_padding

func _ready():
	pass

func update_size(viewport_size, viewport_center):
	if (viewport_size.y/2 < global.radius):
		$Triangle.offset = Vector2(viewport_center.x, 0)
	else:
		$Triangle.offset = Vector2(viewport_center.x, viewport_center.y - global.radius)
	
	$Settings.rect_position = Vector2(viewport_size.x - $Settings.rect_size.x - padding, padding)
	$Spin.rect_position = Vector2(viewport_size.x - $Spin.rect_size.x - padding, viewport_size.y - $Spin.rect_size.y - padding)

func _on_Settings_pressed():
	get_tree().change_scene("res://settings.tscn")

func _on_Spin_pressed():
	get_tree().get_root().get_node("Node2D").spin()

