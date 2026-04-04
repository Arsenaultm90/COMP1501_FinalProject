extends Control

# NODES
@onready var progress_bar = $ProgressBar
@onready var round_label = $RoundLabel
@onready var timer_label = $TimerLabel
@onready var result_label = $ResultLabel
@onready var success_label = $ResultLabel/SuccessLabel
@onready var pluck_label = $PluckLabel

@onready var h_root = $HorizontalBar
@onready var h_marker = $HorizontalBar/Marker
@onready var h_zone = $HorizontalBar/Zone
@onready var h_bar = $HorizontalBar/Bar

@onready var v_root = $VerticalBar
@onready var v_marker = $VerticalBar/Marker
@onready var v_zone = $VerticalBar/Zone
@onready var v_bar = $VerticalBar/Bar

@onready var instructions = $CanvasLayer/Instructions
@onready var music = $AudioStreamPlayer2D

var total_rounds = 3
var round_duration = 30.0
var round_timer = 30.0
var current_round = 1
var successes = 0
var pluck_score = 0
var round_active = true
var can_pluck = false
var pluck_quality = 0
var pluck_quantity = 0
var freeze_timer = 0.0
var freeze_duration = 0.5

var gravity = 1000.0
var lift_force = 1300.0
var max_speed = 800.0
var catch_rate = 25.0
var decay_rate = 35.0
var velocity = 0.0
var progress = 0.0

var zone_speed = 60.0
var zone_size = 80.0
var zone_target = 0.0
var change_timer = 0.0
var time_in_zone = 0.0

var current_bar
var current_marker
var current_zone
var zone_orientation = "vertical"

# Marker and zone positions
var marker_x = 0.0
var marker_y = 0.0
var zone_x = 0.0
var zone_y = 0.0
var bar_top
var bar_bottom
var bar_start
var bar_end
var current_color = Color(1,0,0)

func _ready():
	GlobalUI.hide_ui()
	randomize()
	setup_round(current_round)
	reset_zone()

func _process(delta):
	if instructions.visible == true and Input.is_action_pressed("pluck"):
		instructions.visible = false
		music.play()
		
	if instructions.visible == true:
		return
	
	if freeze_timer > 0:
		freeze_timer -= delta
		return # Freeze game during pluck animation

	if !round_active:
		return
	
	if progress >= 100 and not can_pluck:
		can_pluck = true
	elif progress < 100 and can_pluck:
		can_pluck = false

	round_timer -= delta
	timer_label.text = "Time Remaining: %.1f" % round_timer

	handle_input(delta)
	move_zone(delta)
	update_progress(delta)
	update_visuals()

	if can_pluck and Input.is_action_just_pressed("pluck"):
		evaluate_pluck()

	if round_timer <= 0 and round_active:
		round_active = false
		show_round_result()
		await show_round_result()

func handle_input(delta):
	var lift = lift_force * delta
	var grav = gravity * delta

	if Input.is_action_pressed("accept"):
		if zone_orientation == "vertical":
			velocity -= lift  # up
		else:
			velocity += lift  # right
	else:
		if zone_orientation == "vertical":
			velocity += grav  # down
		else:
			velocity -= grav  # left

	velocity = clamp(velocity, -max_speed, max_speed)

	if zone_orientation == "vertical":
		marker_y += velocity * delta
		if marker_y <= bar_top:
			marker_y = bar_top
			velocity = 0
		elif marker_y >= bar_bottom:
			marker_y = bar_bottom
			velocity = 0
	else:
		marker_x += velocity * delta
		if marker_x <= bar_start:
			marker_x = bar_start
			velocity = 0
		elif marker_x >= bar_end:
			marker_x = bar_end
			velocity = 0

func move_zone(delta):
	change_timer -= delta
	if change_timer <= 0:
		if zone_orientation == "vertical":
			zone_target = bar_top + randf() * (current_bar.size.y - zone_size)
		else:
			zone_target = bar_start + randf() * (current_bar.size.x - zone_size)
		change_timer = randf_range(0.2,0.8)

	var current_pos = (zone_y if zone_orientation=="vertical" else zone_x)
	var dir = sign(zone_target - current_pos)
	var move_delta = dir * zone_speed * delta

	if zone_orientation == "vertical":
		zone_y += move_delta
		zone_y = clamp(zone_y, bar_top, bar_top + current_bar.size.y - zone_size)
		if abs(zone_target - zone_y) < 5:
			zone_y = zone_target
	else:
		zone_x += move_delta
		zone_x = clamp(zone_x, bar_start, bar_start + current_bar.size.x - zone_size)
		if abs(zone_target - zone_x) < 5:
			zone_x = zone_target

func update_progress(delta):
	var in_zone = false
	var distance = 0.0
	var is_perfect = false

	if zone_orientation == "vertical" :
		progress_bar.global_position = Vector2(v_marker.global_position.x - 50, v_marker.global_position.y)
	else :
		progress_bar.global_position = Vector2(h_marker.global_position.x, h_marker.global_position.y + 50)
	
	if zone_orientation == "vertical":
		var marker_bottom = marker_y + current_marker.size.y
		var zone_bottom = zone_y + current_zone.size.y
		in_zone = marker_bottom >= zone_y and marker_y <= zone_bottom

		var center = zone_y + current_zone.size.y/2
		distance = abs(marker_y - center)
		is_perfect = distance < current_zone.size.y*0.15
	else:
		var marker_end = marker_x + current_marker.size.x
		var zone_end = zone_x + current_zone.size.x
		in_zone = marker_end >= zone_x and marker_x <= zone_end

		var center = zone_x + current_zone.size.x/2
		distance = abs(marker_x - center)
		is_perfect = distance < current_zone.size.x*0.15

	if in_zone:
		time_in_zone += delta
		if time_in_zone > 0.15:
			progress += catch_rate * (1.5 if is_perfect else 1.0) * delta
	else:
		time_in_zone = 0
		progress -= decay_rate * delta

	progress = clamp(progress, 0, 100)
	progress_bar.value = progress

	update_zone_color(in_zone, is_perfect, delta)

func update_visuals():
	if zone_orientation=="vertical":
		current_marker.global_position.y = marker_y
		current_zone.global_position.y = zone_y
		current_zone.size.y = zone_size
	else:
		current_marker.global_position.x = marker_x
		current_zone.global_position.x = zone_x
		current_zone.size.x = zone_size

func update_zone_color(in_zone, is_perfect, delta):
	var target_color = Color(1,0,0)
	if in_zone:
		target_color = Color(0,1,0) if is_perfect else Color(0.836, 0.836, 0.0, 1.0)
	current_color = current_color.lerp(target_color, 10*delta)
	current_zone.color = current_color

func evaluate_pluck():
	var zone_center = (zone_y if zone_orientation=="vertical" else zone_x) + (current_zone.size.y if zone_orientation=="vertical" else current_zone.size.x)/2
	var marker_pos = marker_y if zone_orientation=="vertical" else marker_x
	var distance = abs(marker_pos - zone_center)
	var max_distance = (current_zone.size.y if zone_orientation=="vertical" else current_zone.size.x)/2
	var score_percent = clamp(100 - (distance / max_distance * 100), 0, 100)
	pluck_score += score_percent

	freeze_timer = 0.3

	var tween = create_tween()
	tween.tween_property(current_zone, "modulate:a", 0.0, 0.5)
	tween.tween_callback(Callable(self, "_on_zone_fade_complete"))
	tween.play()

	spawn_rating_label(score_percent)

func _on_zone_fade_complete():
	current_zone.modulate.a = 1.0
	current_zone.visible = true

	if current_round == 3:
		spawn_new_zone()
	else:
		if zone_orientation == "vertical":
			zone_y = bar_top + randf() * (current_bar.size.y - zone_size)
		else:
			zone_x = bar_start + randf() * (current_bar.size.x - zone_size)

	progress = 0
	can_pluck = false
	time_in_zone = 0

func spawn_new_zone():
	if current_round == 3:
		if zone_orientation == "vertical":
			zone_orientation = "horizontal"
			current_marker = h_marker
			current_zone = h_zone
			current_bar = h_bar
			h_root.visible = true
			v_root.visible = false
		else:
			zone_orientation = "vertical"
			current_marker = v_marker
			current_zone = v_zone
			current_bar = v_bar
			h_root.visible = false
			v_root.visible = true

	current_zone.visible = true
	current_marker.visible = true
	current_zone.modulate.a = 1
	current_marker.modulate.a = 1

	if zone_orientation == "vertical":
		zone_y = bar_top + randf()*(current_bar.size.y - zone_size)
	else:
		zone_x = bar_start + randf()*(current_bar.size.x - zone_size)

	# Reset progress for next pluck
	progress = 0
	can_pluck = false

func setup_round(round_num):
	round_label.text = "Round " + str(round_num)
	progress_bar.visible = true
	
	if round_num==1:
		zone_orientation = "vertical"
		current_marker = v_marker
		current_zone = v_zone
		current_bar = v_bar
	elif round_num==2:
		zone_orientation = "horizontal"
		current_marker = h_marker
		current_zone = h_zone
		current_bar = h_bar
		h_root.visible = true
		v_root.visible = false
	else:
		spawn_new_zone()
		
	zone_speed += 20
	zone_size -= 10

func reset_zone():
	velocity = 0
	time_in_zone = 0
	round_timer = round_duration
	progress = 30
	can_pluck = false
	round_active = true

	if zone_orientation=="vertical":
		bar_top = current_bar.global_position.y
		bar_bottom = bar_top + current_bar.size.y - current_marker.size.y
		marker_y = bar_top + current_bar.size.y/2
		zone_y = bar_top + randf()*(current_bar.size.y - zone_size)
	else:
		bar_start = current_bar.global_position.x
		bar_end = bar_start + current_bar.size.x - current_marker.size.x
		marker_x = bar_start + current_bar.size.x/2
		zone_x = bar_start + randf()*(current_bar.size.x - zone_size)

func spawn_rating_label(score_percent):
	var color
	var rating_text = ""
	
	if score_percent > 70:   # Green zone
		rating_text = "PERFECT"
		color = Color(0.514, 1.0, 0.482, 1.0)
	elif score_percent > 25: # Yellow zone
		rating_text = "OKAY"
		color = Color(1.0, 0.991, 0.422, 1.0)
	else:                    # Red zone
		rating_text = "POOR"
		color = Color(1.0, 0.318, 0.254, 1.0)

	pluck_quality += score_percent
	pluck_quantity += 1
	pluck_label.text = rating_text
	pluck_label.modulate = color

	if zone_orientation == "vertical":
		pluck_label.global_position = Vector2(current_bar.global_position.x + current_bar.size.x + 20, marker_y)
	else:
		pluck_label.global_position = Vector2(marker_x, current_bar.global_position.y - 50)

	pluck_label.visible = true
	var tween = create_tween()
	tween.tween_property(pluck_label, "modulate:a", 0.0, 1.0)
	tween.play()

func show_round_result():
	print("Quality: %d, Quantity: %d" % [pluck_quality, pluck_quantity])
	var result =  0 if pluck_quantity == 0 else pluck_quality / pluck_quantity
	v_root.visible = false
	h_root.visible = false
	progress_bar.visible = false
	timer_label.text = "Time Remaining " + str(0.0)
	result_label.text = "Round %d Complete! Score: %d" % [current_round, result]
	success_label.text = "Success" if result > 50 else "Fail"
	
	var tween = result_label.create_tween()
	tween.tween_property(result_label, "modulate:a", 0, 3.0)
	tween.play()

	await get_tree().create_timer(3).timeout
	
	current_round += 1
	if current_round > total_rounds:
		end_game()
		return

	# Setup next round
	setup_round(current_round)
	reset_zone()

func end_game():
	print("Successes:", successes)
	if successes >= 3:
		result_label.text = "GOOD END"
		print("GOOD END")
	elif successes == 2:
		result_label.text = "OKAY END"
		print("NEUTRAL END")
	else:
		result_label.text = "BAD END"
		print("BAD END")

	await get_tree().create_timer(3).timeout
	
	# fade out music
	#switch scenes
