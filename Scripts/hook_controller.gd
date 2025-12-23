extends Node
@export var ray: RayCast3D
@export var rope: Node3D
@export var rest_lenght = 2.0
@export var stiffness = 0
@export var damping = 1.0

@onready var player: CharacterBody3D = get_parent()
var hookTarget: Vector3
var hooked = false

var old_target_dist
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		print("hook used")
		hook()
	if Input.is_action_just_released("shoot"):
		print("hook relesed")
		unHook()
	if hooked:
		handle_grapple(delta)
		
	update_rope()

func hook():
	if ray.get_collider():
		hookTarget = ray.get_collision_point()
		hooked = true
	
func unHook():
	hooked = false
	
func handle_grapple(delta: float):
	#var target_dir = player.global_position.direction_to(hookTarget)
	var target_dist = player.global_position.distance_to(hookTarget)
	var distance = (player.global_position - hookTarget).length()
	if distance >= target_dist:
		var dir := (player.global_position - hookTarget).normalized()
		var radial_velocity := player.velocity.dot(dir)
		if radial_velocity > 0.0:
			player.velocity -= dir * radial_velocity
func update_rope():
	if !hooked:
		rope.visible = false
		return
		
	rope.visible = true
	var dist = player.global_position.distance_to(hookTarget)
	rope.look_at(hookTarget)
	rope.scale = Vector3(1,1,dist)
