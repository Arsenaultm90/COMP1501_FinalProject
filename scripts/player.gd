class_name Player extends CharacterBody2D

@onready var animation_player = $AnimationPlayer
@onready var sprite = $Sprite2D
@onready var interact_label = $Area2D/InteractLabel
@onready var interact_area = $Area2D

var cardinal_direction : Vector2 = Vector2.DOWN
var direction : Vector2 = Vector2.ZERO
var move_speed : float = 100.0
var state : String = "idle"
var interact_target = null
var controls_enabled : bool = false

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	if not controls_enabled:
		return
	
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	velocity = direction.normalized() * move_speed
	move_and_slide()
	
	if SetState() == true || SetDirection() == true:
		UpdateAnimation()
	
	### NEED CHECK FOR ITEMS VS NPCS
	if interact_target and Input.is_action_just_pressed("interact"):
		controls_enabled = false
		direction = Vector2.ZERO
		SetState()
		UpdateAnimation()
		hide_prompt()
		interact_target.interact()


func SetDirection() -> bool:
	var new_dir : Vector2 = cardinal_direction
	if direction == Vector2.ZERO:
		return false
	
	if abs(direction.x) >= abs(direction.y):
		new_dir = Vector2.LEFT if direction.x < 0 else Vector2.RIGHT
	else:
		new_dir = Vector2.UP if direction.y < 0 else Vector2.DOWN
	
	if new_dir == cardinal_direction:
		return false
	
	cardinal_direction = new_dir
	sprite.scale.x = -1 if cardinal_direction == Vector2.LEFT else 1
	return true

func SetState() -> bool:
	var new_state : String = "idle" if direction == Vector2.ZERO else "walk"
	if new_state == state:
		return false
	state = new_state
	return true

func UpdateAnimation() -> void:
	animation_player.play(state + "_" + AnimDirection())

func AnimDirection() -> String:
	if cardinal_direction == Vector2.DOWN:
		return "down"
	elif cardinal_direction == Vector2.UP:
		return "up"
	else:
		return "right"


### UTILITY METHODS
func disable_controls() -> void:
	controls_enabled = false
	velocity = Vector2.ZERO

func enable_controls() -> void:
	controls_enabled = true


### INTERACT METHODS
func show_prompt():
	interact_label.visible = true

func hide_prompt():
	interact_label.visible = false

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("Interactable"):
		interact_target = area
		show_prompt()

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area == interact_target:
		interact_target = null
		hide_prompt()
