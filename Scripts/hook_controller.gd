extends Node
@export var ray: RayCast3D
@export var rope: Node3D
@export var input_strength := 5.0
@export var tether_lerp := 10.0
@export var damping := 0.999  # slow down swing naturally

@onready var player: CharacterBody3D = get_parent()
@onready var moveScript: Node = get_node("../MovementController")
var target_pos: Vector3
var max_dist: float
var hooked: float = false
var selected: int = 1 #1 = grapple #2 = tech hook #3 = harpoon
var old_target_dist
func _process(delta: float) -> void:
	#weapon switching
	if Input.is_action_just_pressed("one"):
		selected = 1
	if Input.is_action_just_pressed("two"):
		selected = 2
	if Input.is_action_just_pressed("three"):
		selected = 3
	if  Input.is_action_just_pressed("Q"):
		selected = selected-1
		if selected <= 0:
			selected = 3
	if  Input.is_action_just_pressed("E"):
		selected = selected+1
		if selected >= 4:
			selected = 1

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		print("hook used")
		hook()
	if Input.is_action_just_released("shoot"):
		print("hook relesed")
		unHook()
	if hooked:
		match selected:
			1:
				handle_grapple(delta)
			2:
				handle_Hook(delta)
			3:
				pass
	update_rope()

func hook():
	if ray.get_collider():
		target_pos = ray.get_collision_point()
		max_dist = player.global_position.distance_to(target_pos)
		player.is_grappled = true
		hooked = true
	
func unHook():
	hooked = false
	moveScript.is_grappled = false
	moveScript.move_dir = player.velocity.normalized()
	
func handle_grapple(delta: float):

	var player_pos = player.global_position
	var offset = player_pos - target_pos
	var dist = offset.length()
	if dist == 0.0:
		return  # avoid divide by zero

	var dir = offset / dist  # direction from target to player

	# --- Step 1: Remove outward radial velocity ---
	var radial_speed = player.velocity.dot(dir)
	if radial_speed > 0.0:
		player.velocity -= dir * radial_speed

	# --- Step 2: Soft tether constraint (prevent snapping) ---
	if dist > max_dist:
		var desired_pos = target_pos + dir * max_dist
		player.global_position = player.global_position.lerp(desired_pos, tether_lerp * delta)

	# --- Step 3: Apply player input along tangent plane ---
	# Calculate swing plane tangent: cross product with velocity to get true 3D tangent
	var tangent: Vector3
	if player.velocity.length() > 0.01:
		tangent = player.velocity.cross(dir).normalized()  # tangential around the rope
	else:
		# If stationary, pick an arbitrary perpendicular vector
		tangent = dir.cross(Vector3.UP).normalized()
	
	# Combine input along tangent and vertical tangents
	var tangent_input = (tangent + tangent.cross(dir)).normalized()
	player.velocity += tangent_input * input_strength * delta

	# --- Step 4: Optional damping to avoid infinite swing ---
	player.velocity *= damping

func handle_Hook(delta: float):
	pass

func update_rope():
	if !hooked:
		rope.visible = false
		return
		
	rope.visible = true
	var dist = player.global_position.distance_to(target_pos)
	rope.look_at(target_pos)
	rope.scale = Vector3(1,1,dist)
