extends Node2D

const MAIN = preload("res://main.tscn")
const SETTINGS = preload("res://settings.tscn")
var main = null
var settings = null
var samples_rad = []
var samples_count = 100

func _ready():
	main = MAIN.instance()
	add_child(main)
	yield(populate_samples_rad(), "completed")

	test_distribution()
	test_consecutive()

func populate_samples_rad():
	var samples_count = 100
	var threshold_factor = 0.8
	var time_interval = 2.5
	main.friction_factor = 1.0 # override for speed

	for n in range(samples_count):
		main.spin()
		yield(get_tree().create_timer(time_interval), "timeout")
		samples_rad.append(abs(fmod(main.canvas.rotation, 2 * PI)))
	pass

func get_bucket(angle_rad):
	if angle_rad < PI * 0.5:
		return 0
	elif angle_rad < PI:
		return 1
	elif angle_rad < PI * 1.5:
		return 2
	elif angle_rad < PI * 2.0:
		return 3
	elif angle_rad < 0.0:
		return -1.0

func test_consecutive():
	print("test_consecutive")
	var error_threshold_lower = (samples_count/4)-5
	var error_threshold_upper = (samples_count/4)+5
	var angle_rad = -1.0
	var previous_angle_rad = -1.0
	var repeat_buckets = 0
	for n in range(samples_rad.size()):
		angle_rad = samples_rad[n]
		if get_bucket(angle_rad) == get_bucket(previous_angle_rad):
			repeat_buckets = repeat_buckets + 1
		previous_angle_rad = angle_rad

	print("Repeat buckets: ", repeat_buckets, "/", samples_count)
	print("Boundaries: [", error_threshold_lower, ",", error_threshold_upper, "]")

	if repeat_buckets > error_threshold_lower && repeat_buckets < error_threshold_upper:
		print("PASS")
		return

	print("FAIL")

func test_distribution():
	print("test_distribution")
	# four buckets, each at PI/2 from one another
	var threshold_factor = 0.8 
	var buckets = [ 0, 0, 0, 0 ]
	var error_threshold = round(samples_count * threshold_factor/buckets.size())
	print("error_threshold=", error_threshold)

	for n in range(samples_rad.size()):
		var angle_rad = samples_rad[n]
		var bucket = get_bucket(angle_rad)
		buckets[bucket] = buckets[bucket] + 1

	var errors = 0
	for i in buckets.size():
		if buckets[i] < error_threshold:
			errors = errors + 1
	
	print("Distribution: ", String(buckets))
	print("Threshold: ", error_threshold)

	if !errors:
		print("PASS")
		return

	print("FAIL with distribution errors: ", errors)
