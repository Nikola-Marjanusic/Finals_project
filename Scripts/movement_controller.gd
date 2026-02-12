extends Node

@onready var player: CharacterBody3D = get_parent()

## Normal speed.
@export var run_speed : float = 5
## Normal speed.
@export var run_cap : float = 15
## How fast do we stop
@export var deceleration : float = 5.0
## How fast do we get to full speed
@export var acceleration : float = 5.0

## Time before decelaration
@export var deceleration_buffer : float = 0.05

var is_grappled := false

var move_dir : Vector3
var old_move_dir : Vector3

var move_speed := 0.0
var base_speed : float = run_speed

func Move_func(delta,input_dir):
	
	old_move_dir = move_dir
	if input_dir != Vector2.ZERO:
		move_dir = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Ground movement
	if move_dir != Vector3.ZERO:
		if input_dir != Vector2.ZERO:
			# ACCELERATE
			move_speed = get_speed(delta)
			player.timers["move"] = 0.0
		
		elif player.timers["move"] >= deceleration_buffer:
			if player.is_on_floor():
				# DECELERATE
				move_speed /= pow(deceleration, delta)
				if move_speed < 10.0:
					move_speed = 0.0
			else:
				#no deceleration in the air
				move_speed = move_speed
		player.velocity.x = move_dir.x * move_speed
		player.velocity.z = move_dir.z * move_speed
		print("move speed: " , move_speed)
		if is_grappled and player.is_on_floor():
			pass
		elif is_grappled and !player.is_on_floor():
			pass
		elif !is_grappled and player.is_on_floor():
			pass
		elif !is_grappled and !player.is_on_floor():
			pass

func get_speed(delta):
	if move_speed < run_speed:
		move_speed = run_speed
	#did the player change deractions
	if player.is_on_floor():
		var move_dot = move_dir.dot(old_move_dir)
		if move_dot < 0.95:
			move_speed *= (move_dot/1.1)
	move_speed += acceleration * delta
	move_speed = min(move_speed, run_cap)
	return move_speed
