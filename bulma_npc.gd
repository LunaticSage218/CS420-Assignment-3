extends CharacterBody2D

var dialog_started: bool = false
var player_in_area: bool = false

# Offset for dialog box above NPC
var dialog_offset := Vector2(0, -50)

func _ready():
	# Connect the Area2D signals for collision detection
	var area = $Area2D
	if area:
		area.body_entered.connect(_on_area_2d_body_entered)
		area.body_exited.connect(_on_area_2d_body_exited)
		# Check if player is already in the area at startup
		var overlapping_bodies = area.get_overlapping_bodies()
		for body in overlapping_bodies:
			if body != self and body.is_in_group("player"):
				_on_area_2d_body_entered(body)
				break

func _on_area_2d_body_entered(body):
	# Ignore self-detection (NPC detecting itself)
	if body == self:
		return
	
	# Check if the colliding body is the player
	if body.is_in_group("player"):
		player_in_area = true
		if not dialog_started:
			dialog_started = true
			start_dialog()

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		player_in_area = false


func start_dialog():
	var dialog_box = get_tree().current_scene.get_node("DialogBox")

	# Position the dialog box above the NPC
	var camera = get_viewport().get_camera_2d()
	var screen_pos = global_position + dialog_offset
	dialog_box.get_node("Panel").position = screen_pos

	dialog_box.show_dialog([
		"Goku, help!", 
		"King Piccolo's minions are coming!", 
		"Stop them, Goku!"
	])

	# Connect dialog_finished signal to start battle, if not already connected
	if not dialog_box.is_connected("dialog_finished", Callable(self, "start_battle")):
		dialog_box.connect("dialog_finished", Callable(self, "start_battle"))

func start_battle():
	var spawner = get_tree().current_scene.get_node("EnemySpawner")
	if spawner:
		spawner.start_spawning()
	queue_free()  # remove NPC after triggering
