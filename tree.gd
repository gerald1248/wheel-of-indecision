extends Tree

func _ready():
	if !global.is_mobile():
		return

	# for mobile devices, increase scrollbar width
	var children = get_children()
	for child in children:
		if "VScrollBar" in str(child):
			var current_size = child.get_size()
			print("current_size=", current_size)
			child.rect_min_size = Vector2(24, current_size.y)

func _unhandled_input(event):
	pass
