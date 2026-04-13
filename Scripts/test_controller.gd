extends CharacterBody3D

@export var speed := 8.0
@export var jump_velocity := 6.0
@export var gravity := 18.0
@export var mouse_sensitivity := 0.002
@export var rope: Node3D
# Hook variables
var is_hooked := false
var hook_point : Vector3
var rope_length := 0.0

# Camera
@onready var camera = $Head

var yaw := 0.0
var pitch := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * mouse_sensitivity
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -1.5, 1.5)

		rotation.y = yaw
		camera.rotation.x = pitch

# -----------------------------------
# MOVEMENT
# -----------------------------------
func _physics_process(delta):
	update_rope()
	if Input.is_action_just_pressed("shoot"):
		print("hook used")
		shoot_hook()
	if Input.is_action_just_released("shoot"):
		print("hook relesed")
		release_hook()
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Movement input
	var input_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Move first
	move_and_slide()

	# Apply grappling AFTER movement
	if is_hooked:
		apply_rope_constraint(delta)

# -----------------------------------
# HOOK LOGIC
# -----------------------------------
func shoot_hook():
	var space_state = get_world_3d().direct_space_state
	
	var from = camera.global_position
	var to = from + camera.global_transform.basis.z * -1000
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result:
		hook_point = result.position
		rope_length = global_position.distance_to(hook_point)
		is_hooked = true

func release_hook():
	is_hooked = false

# -----------------------------------
# ROPE PHYSICS (IMPORTANT PART)
# -----------------------------------
func apply_rope_constraint(delta):

	var player_pos = global_position
	var offset = player_pos - hook_point
	var dist = offset.length()

	if dist == 0.0:
		return

	var dir = offset.normalized()

	# Predict next position
	var next_pos = player_pos + velocity * delta
	var next_dist = (next_pos - hook_point).length()

	# If exceeding rope length → clamp
	if next_dist > rope_length:

		# Remove velocity pushing outward
		var outward_speed = velocity.dot(dir)
		if outward_speed > 0:
			velocity -= dir * outward_speed

		# Snap position to rope surface
		global_position = hook_point + dir * rope_length
func update_rope():
	if !is_hooked:
		rope.visible = false
		return
		
	rope.visible = true
	var dist = global_position.distance_to(hook_point)
	rope.look_at(hook_point)
	rope.scale = Vector3(1,1,dist)
