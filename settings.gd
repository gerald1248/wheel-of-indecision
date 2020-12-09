extends Node2D

onready var tree = get_node("Tree")
var padding = global.gui_control_padding
var height = global.gui_control_height
var root = null
var title = global.title
var edited_item = null
var tab_seen = false

var person_texture = load("res://sprites/person-aaa-48x48.png")
var group_texture = load("res://sprites/group_aaa-48x48.png")
var groups_texture = load("res://sprites/groups-aaa-48x48.png")
var person_add_texture = load("res://sprites/person_add-aaa-48x48.png")
var group_add_texture = load("res://sprites/group_add-aaa-48x48.png")
var remove_texture = load("res://sprites/remove-aaa-48x48.png")
var arrow_right_texture = load("res://sprites/arrow_right-aaa-48x48.png")
var arrow_down_texture = load("res://sprites/arrow_drop_down-aaa-48x48.png")
var north_texture = load("res://sprites/north-aaa-48x48.png")
var edit_texture = load("res://sprites/edit-aaa-48x48.png")

func _ready():
	var _err = get_tree().get_root().connect("size_changed", self, "on_window_resized")
	update_size()

	$Label.text = title
	root = tree.create_item()
	root.set_text(0, "Groups")
	root.set_icon(0, groups_texture)
	root.set_selectable(0, false)
	root.add_button(0, group_add_texture, 100, false, "add group")

	build_tree(root, global.settings)

	tree.set_hide_root(false)
	tree.set_hide_folding(true)
	tree.set_column_titles_visible(false)
	tree.ensure_cursor_is_visible()
	
	tree.show()

	show_current_selection()

	$OkButton.grab_focus()

func _process(delta):
	if Input.is_action_pressed("ui_focus_next"):
		if !tab_seen:
			tab_seen = true
			enable_keyboard_access()
	elif Input.is_action_pressed("ui_focus_prev"):
		if !tab_seen:
			tab_seen = true
			enable_keyboard_access()

# currently unused - shortcuts required for buttons
func enable_keyboard_access():
	if !root:
		return

	root.set_selectable(0, true)

	var my_item = root.get_children()
	while my_item != null:
		my_item.set_selectable(0, true)
		my_item.set_editable(0, true)
		
		var my_subitem = my_item.get_children()
		while my_subitem != null:
			my_subitem.set_selectable(0, true)
			my_subitem.set_editable(0, true)
			my_subitem = my_subitem.get_next()
		my_item = my_item.get_next()

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
	my_item.set_editable(0, false)
	my_item.add_button(0, north_texture, 150, false, "select group")
	my_item.add_button(0, edit_texture, 160, false, "edit group name")
	my_item.add_button(0, person_add_texture, 200, false, "add person to group")
	my_item.add_button(0, remove_texture, 300, false, "remove group")
	my_item.set_icon(0, group_texture)
	my_item.set_editable(0, false)
	my_item.set_selectable(0, false)
	return my_item

func add_subitem(item, label):
	var my_subitem = tree.create_item(item)
	my_subitem.set_text(0, label)
	my_subitem.set_editable(0, false)
	my_subitem.add_button(0, edit_texture, 170, false, "edit name")
	my_subitem.add_button(0, remove_texture, 400, false, "remove person")
	my_subitem.set_icon(0, person_texture)
	my_subitem.set_selectable(0, false)
	
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
	global.save_config()

	tree.clear()
	
	get_tree().change_scene("res://main.tscn")

func _on_CancelButton_pressed():
	tree.clear()
	get_tree().change_scene("res://main.tscn")

func _on_Tree_button_pressed(item, column, id):
	match id:
		# add item
		100:
			var new_item = add_item("New group")
			new_item.move_to_top()
			activate_edit_mode(new_item)
			validate_settings()
		# select group
		150:
			var s = item.get_text(0)
			if group_is_present(s):
				title = s
				$Label.text = title
				validate_settings()
		160:
			activate_edit_mode(item)
		170:
			activate_edit_mode(item)
			var parent = item.get_parent()
			if parent:
				title = parent.get_text(0)
				$Label.text = title
		# add subitem
		200:
			var new_subitem = add_subitem(item, "New group member")
			new_subitem.move_to_top()
			activate_edit_mode(new_subitem)
			title = item.get_text(0)
			$Label.text = title
			validate_settings()
		# remove item
		300:
			var parent = item.get_parent()
			if parent:
				parent.remove_child(item)
				validate_settings()
				if !title_is_present():
					$Label.set_text("")
					title = ""
		# remove subitem
		400:
			var parent = item.get_parent()
			if parent:
				parent.remove_child(item)
				validate_settings()
		_:
			pass

func activate_edit_mode(item):
	item.set_selectable(0, true)
	item.set_editable(0, true)
	item.select(0)
	edited_item = item

	var rect = tree.get_item_area_rect(item, 0)
	call_deferred("simulate_input_event", rect, true)
	call_deferred("simulate_input_event", rect, false)

func simulate_input_event(rect, is_down):
	var a = InputEventMouseButton.new()
	var point = Vector2(rect.position.x + rect.size.x/2, rect.position.y + rect.size.y/2)
	var offset = $Tree.rect_position - $Tree.get_scroll()
	var center = point + offset
	a.set_button_index(1)
	a.set_pressed(is_down)
	a.set_position(center)
	Input.parse_input_event(a)

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

func _on_Tree_item_edited():
	if !edited_item:
		return
	
	var my_current = edited_item.get_text(0)
	var my_validated = validate_name(my_current)
	if my_current != my_validated:
		edited_item.set_text(0, my_validated)
	
	# check if this is a group label
	# if so, assume it's the new selection
	# and set title accordingly
	if edited_item.get_parent() == root:
		title = my_validated
		$Label.set_text(my_validated)

	edited_item.set_selectable(0, false)
	edited_item.set_editable(0, false)
	edited_item.deselect(0)
	edited_item = null

	validate_settings()

func validate_name(name):
	var validated = name.replace(":", "")
	validated = validated.replace(";", "")
	return validated


func validate_settings():
	# ensure selected group name is present and contains at least one item
	var valid = false

	var my_item = root.get_children()
	while my_item != null:
		if my_item.get_text(0) == title && my_item.get_children():
			valid = true
		my_item = my_item.get_next()
	
	$OkButton.set_disabled(!valid)
	var mode = 2 if valid else 0
	$OkButton.set_focus_mode(mode)
	return valid

func group_is_present(name):
	var my_item = root.get_children()
	while my_item != null:
		if my_item.get_text(0) == name:
			return true
		my_item = my_item.get_next()
	return false

func title_is_present():
	return group_is_present(title)

func show_current_selection():
	if !root:
		return
	var my_item = root.get_children()
	while my_item != null:
		if my_item.get_text(0) == title:
			my_item.set_selectable(0, true)
			my_item.select(0)
			tree.ensure_cursor_is_visible()
			my_item.deselect(0)
			my_item.set_selectable(0, false)
			break
		my_item = my_item.get_next()
