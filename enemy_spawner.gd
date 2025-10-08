extends Node2D
@export var spawn_interval: float = 3.0
@export var enemy_scene: PackedScene = preload("res://enemy.tscn")
var screen_size: Vector2
var spawning: bool = false
var floor_y: float = 575.0                # Ground level
var current_enemy: Node2D = null
var spawn_height_offset: float = 200.0    # How far above the floor to spawn
var spawn_toggle: bool = false            # Alternates between left and right
var edge_margin: float = 50.0             # Distance from screen edge to spawn

func _ready():
	screen_size = get_viewport().get_visible_rect().size

func start_spawning():
	if spawning:
		return
	spawning = true
	_spawn_enemy()
	_schedule_next_spawn()

func _schedule_next_spawn():
	if spawning:
		get_tree().create_timer(spawn_interval).timeout.connect(_spawn_enemy)

func _spawn_enemy():
	if not spawning:
		return
	if current_enemy != null and is_instance_valid(current_enemy):
		_schedule_next_spawn()
		return
	
	var enemy = enemy_scene.instantiate()
	var player = get_tree().get_first_node_in_group("player")
	
	# Alternate between left and right edges
	var spawn_x: float
	if not spawn_toggle:
		# Spawn on left edge
		spawn_x = edge_margin
	else:
		# Spawn on right edge
		spawn_x = screen_size.x - edge_margin
	
	spawn_toggle = !spawn_toggle
	
	# If player is too close to the selected edge, spawn on the opposite edge instead
	var min_distance = 300.0
	if player:
		if abs(player.global_position.x - spawn_x) < min_distance:
			# Switch to opposite edge
			if spawn_x < screen_size.x / 2:
				spawn_x = screen_size.x - edge_margin
			else:
				spawn_x = edge_margin
	
	var spawn_y = floor_y - spawn_height_offset
	var spawn_pos = Vector2(spawn_x, spawn_y)
	
	enemy.global_position = spawn_pos
	current_enemy = enemy
	enemy.connect("enemy_defeated", _on_enemy_defeated)
	get_parent().add_child(enemy)
	
	_schedule_next_spawn()

func _on_enemy_defeated():
	current_enemy = null
