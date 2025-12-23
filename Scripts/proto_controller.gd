# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D
@export_group("Abilities")
## Can we move around?
@export var can_move : bool = true
var move_speed : float = 0.0 #m/s
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we press to air jump?
@export var can_air_jump : bool = true
## How many air jumps?
@export var max_air_jumps : int = 1
var air_jump_counter = max_air_jumps
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false
var freeflying : bool = false

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var run_speed : float = 9.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we freefly?
@export var freefly_speed : float = 25.0
## How fast do we stop
@export_range(0.0, 1.0) var deceleration : float = 0.5
## How fast do we get to full speed
@export_range(0.0, 1.0) var acceleration : float = 0.5

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"

@export_group("miscellaneous")
## Time before decelaration
@export var deceleration_buffer : float = 0.1
@export var jump_buffer : float = 0.1
@export var jump_buffer_distance : float = 0.1
var slope_angle
var base_speed : float = run_speed
var delayed_jump := false 
var timers := {
	"move": 0.0,
	"jump":0.0,
	"air":0.0,
	"debug_timer":0.0
	# Add more actions here in the future
}

var mouse_captured : bool = false
var look_rotation : Vector2
## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $StandingCollider
@onready var rays = $RaycastGroup.get_children()

func _ready() -> void:
	check_input_mappings()
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x

func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _physics_process(delta: float) -> void:
	#Debug message every second
	if timers["debug_timer"] >= 1.0:
		print("speed: " , move_speed)
		timers["debug_timer"] = 0.0

	# time sinc used for grace periods and cooldowns
	for action_name in timers.keys():
		timers[action_name] += delta

	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return

	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta
		#Update ray length
		if velocity.y <= 0.0:
			var fall_speed_factor = 0.05
			var ray_length = jump_buffer_distance + abs(velocity.y) * fall_speed_factor
			#turne of rays for grace jumps
			for ray in rays:
				ray.enabled = true
				ray.target_position = Vector3(0, -ray_length, 0)

	# reset air jumps when on floor
	if is_on_floor():
		timers["air"] = 0.0
		#reset air jumps
		air_jump_counter = max_air_jumps
		#execute delayed jumps
		if delayed_jump:
			velocity.y = jump_velocity
			timers["jump"] = 0.0
			delayed_jump = false
		# Disable landing detection rays (no need when grounded)
		for ray in rays:
			ray.enabled = false

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump):
			#am i on the ground
			if  is_on_floor() or timers["air"] <= jump_buffer:
				#handl normal jumps
				velocity.y = jump_velocity
				print("jump")
				timers["jump"] = 0.0
				
			elif timers["jump"] >= jump_buffer:
				#am i abbout to land
				for ray in rays:
					if ray.is_colliding():
						delayed_jump = true
						break
					#use an air jump
				if can_air_jump and air_jump_counter > 0 and delayed_jump == false:
					velocity.y = jump_velocity
					timers["jump"] = 0.0
					air_jump_counter = air_jump_counter-1
			
	#speed calculation
	base_speed = run_speed

	#Move player
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if move_dir:
			# Accelerate
			move_speed = lerp(move_speed, base_speed, 1.0 - pow(1.0 - acceleration, delta * 60.0))
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
			timers["move"] = 0.0
		elif timers["move"] > deceleration_buffer:
			# Decelerate 
			move_speed = lerp(move_speed, 0.0, 1.0 - pow(1.0 - deceleration, delta * 60.0))
			velocity.x = move_toward(velocity.x, 0, 1.0 - pow(1.0 - deceleration, delta * 60.0)) 
			velocity.z = move_toward(velocity.z, 0, 1.0 - pow(1.0 - deceleration, delta * 60.0))
	else:
		velocity.x = 0
		velocity.y = 0
	# Use velocity to actually move
	move_and_slide()

## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)


func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false
