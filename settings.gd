extends Node2D

onready var tree = get_node("Tree")
var padding = global.gui_control_padding
var height = global.gui_control_height
var root = null
var title = global.default_title
var person_texture = load("res://sprites/person-aaa-48x48.png")
var group_texture = load("res://sprites/group_aaa-48x48.png")
var groups_texture = load("res://sprites/groups-aaa-48x48.png")
var person_add_texture = load("res://sprites/person_add-aaa-48x48.png")
var group_add_texture = load("res://sprites/group_add-aaa-48x48.png")
var remove_texture = load("res://sprites/remove-aaa-48x48.png")

func _ready():
	var _err = get_tree().get_root().connect("size_changed", self, "on_window_resized")
	update_size()

	$Label.text = title
	root = tree.create_item()
	root.set_text(0, "Groups")
	root.set_icon(0, groups_texture)
	root.add_button(0, group_add_texture, 100, false, "add group")

	build_tree(root, global.default_settings)

	tree.set_hide_root(false)
	tree.set_hide_folding(true) # only for mobile?
	tree.set_column_titles_visible(false)
	tree.ensure_cursor_is_visible()
	
	tree.show()

func build_tree(root, settings):
	var wheels = settings.split(";")
	for wheel in wheels:
		if (wheel.length() == 0):
			break

		var labels = wheel.split(":")
		
		var title = labels[0]
		labels.remove(0)
		var item = add_item(title)
		for label in labels:
			var subitem = add_subitem(item, label)

func add_item(title):
	var my_item = tree.create_item(root)
	my_item.set_text(0, title)
	my_item.set_editable(0, true)
	my_item.add_button(0, person_add_texture, 200, false, "add person to group")
	my_item.add_button(0, remove_texture, 300, false, "remove group")
	my_item.set_icon(0, group_texture)
	my_item.set_editable(0, true)
	return my_item

func add_subitem(item, label):
	var my_subitem = tree.create_item(item)
	my_subitem.set_text(0, label)
	my_subitem.set_editable(0, true)
	my_subitem.add_button(0, remove_texture, 400, false, "remove person")
	my_subitem.set_icon(0, person_texture)
	return my_subitem

func on_window_resized():
	update_size()

func update_size():
	var viewport_size = get_viewport().get_visible_rect().size
	tree.set_size(Vector2(viewport_size.x - 2 * padding, viewport_size.y - $OkButton.rect_size.y - 2 * padding))
	tree.set_position(Vector2(padding, padding + $OkButton.rect_size.y))
	
	var label_gap = (height - $Label.rect_size.y)/2
	$Label.set_position(Vector2(padding, padding + label_gap))
	$CancelButton.set_position(Vector2(viewport_size.x - $CancelButton.rect_size.x * 2 - padding, padding))
	$OkButton.set_position(Vector2(viewport_size.x - $OkButton.rect_size.x - padding, padding))

func _on_OkButton_pressed():
	global.title = title
	global.settings = get_settings()

	tree.clear()
	
	get_tree().change_scene("res://main.tscn")

func _on_CancelButton_pressed():
	tree.clear()
	get_tree().change_scene("res://main.tscn")

func _on_Tree_cell_selected():
	var item = tree.get_next_selected(root)
	
	if (item == root ) or (!item):
		return
	
	var label = item.get_text(0)
	var parent = item.get_parent()
	
	# is item
	if (parent == root):
		title = label
		$Label.text = title
	# is subitem
	else:
		title = parent.get_text(0)
		$Label.text = title

func _on_Tree_item_edited():
	pass

func _on_Tree_button_pressed(item, column, id):
	match id:
		# add item
		100:
			var new_item = add_item(title)
			new_item.move_to_top()
		# add subitem
		200:
			var new_subitem = add_subitem(item, "New group member")
			new_subitem.move_to_top()
		# remove item
		300:
			var parent = item.get_parent()
			if parent:
				parent.remove_child(item)
		# remove subitem
		400:
			var parent = item.get_parent()
			if parent:
				parent.remove_child(item)
		_:
			pass

func get_settings():
	var s = ""
	var my_item = root.get_children()
	while my_item != null:
		s = s + my_item.get_text(0)
		s = s + ":"
		var my_subitem = my_item.get_children()
		var first = true
		while my_subitem != null:
			if first:
				first = false
			else:
				s = s + ":"
			s = s + my_subitem.get_text(0)
			my_subitem = my_subitem.get_next()
		s = s + ";"
		my_item = my_item.get_next()
	return s
