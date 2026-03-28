extends Node

@onready var player: CharacterBody3D = get_parent()
@onready var Hook_Controll: Node = get_node("../HookController")
## Normal speed.
@export var run_speed : float = 5
## Normal speed.
@export var run_cap : float = 15
## How fast do we stop
@export var deceleration : float = 5.0
## How fast do we get to full speed
@export var acceleration : float = 5.0
## crouch speed.
@export var crouch_speed : float = 4.5
## slide speed.
@export var slide_speed : float = 10.0
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
		
		if player.is_on_wall():
			var wall_normal = player.get_wall_normal()
			
			if move_dir.dot(wall_normal) < 0:
				move_dir = move_dir.slide(wall_normal).normalized()
		print("movespeed:"+str(move_speed))
		player.velocity.x = move_dir.x * move_speed
		player.velocity.z = move_dir.z * move_speed
		
		if is_grappled and player.is_on_floor():
			#provent the plater from leaving the fround 
			pass
		elif is_grappled and !player.is_on_floor():
			#move player in direction of vector 
			#if player is fearther than max grapple lenght from grapple tharget
				#snap playere to max lenght 
				#change velocity,move_dir and move_speed to new angle
			pass
				
func get_speed(delta):
	var stateMod
	if player.state == "standing":
		stateMod = 1
	elif player.state == "slide":
		stateMod = 2
	elif player.state == "crouch":
		stateMod = 0.5
	else:
		print("unknown state of movement")
		stateMod = 1
		
	if move_speed < run_speed * stateMod:
		move_speed = run_speed * stateMod
	move_speed += acceleration * delta
	#is move_speed higher than the cap
	if move_speed > run_cap*stateMod:
		move_speed -= acceleration*2 * delta
	
	#did the player change deractions
	if player.is_on_floor():
		var move_dot = move_dir.dot(old_move_dir)
		if move_dot < 0.95:
			move_speed *= (move_dot/1.1)
	return move_speed
