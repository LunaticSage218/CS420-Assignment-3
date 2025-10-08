extends CharacterBody2D

signal enemy_defeated

@export var speed: float = 2.5
@export var vertical_amplitude: float = 150.0    # Controls vertical size of figure-8
@export var horizontal_amplitude: float = 1000.0  # Controls horizontal size - make bigger to cross screen
@export var ground_y: float = 789.5

var time: float = 0.0
var spawn_position: Vector2  # Store where we spawned
var center_y: float
var screen_size: Vector2
var target: Node2D = null

func _ready():
	add_to_group("enemies")
	screen_size = get_viewport_rect().size
	target = get_tree().get_first_node_in_group("player")
	
	# Store spawn position to orbit around it
	spawn_position = global_position
	center_y = spawn_position.y

	var attackbox = $AttackBox
	if attackbox:
		attackbox.body_entered.connect(_on_attack_box_body_entered)

func _physics_process(delta):
	time += delta * speed

	# Figure-8 motion centered on screen middle
	var x_center = screen_size.x / 2
	var x_offset = horizontal_amplitude * sin(time) * cos(time)  # Figure-8 on X axis
	var y_offset = vertical_amplitude * sin(time)                 # Simple wave on Y axis

	var new_x = x_center + x_offset
	var new_y = center_y + y_offset

	# Keep above ground
	if new_y > ground_y - 50:
		new_y = ground_y - 50

	# Keep on screen
	new_x = clamp(new_x, 50, screen_size.x - 50)

	global_position = Vector2(new_x, new_y)
	rotation = sin(time) * 0.2

func defeat():
	emit_signal("enemy_defeated")
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager:
		game_manager.on_enemy_defeated()
	queue_free()

func _on_attack_box_body_entered(body):
	if body.is_in_group("player"):
		var game_manager = get_tree().get_first_node_in_group("game_manager")
		if game_manager:
			game_manager.on_player_died()
		else:
			get_tree().change_scene_to_file("res://death_screen.tscn")
	elif body.is_in_group("projectiles"):
		defeat()
