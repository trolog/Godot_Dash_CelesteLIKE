extends KinematicBody2D

export(PackedScene) var foot_step

export var gravity = 1500
export var acceleration  = 2000
export var deacceleration = 2000
export var friction = 2000
export var current_friction = 2000
export var max_horizontal_speed = 400
export var max_fall_speed = 1000
export var max_fall_speed_wall_slide = 100
export var jump_height = -700
export var double_jump_height = -400
export var wall_jump_height = -500
export var wall_jump_push = 400
export var wall_slide_gravity = 100 

##################
export(PackedScene) var dash_object
export var dash_speed = 1000 
export var dash_length = 0.2

export var slide_friction = 200; # we want less friction to allow us to slide properly

export var squash_speed = 0.01

var vSpeed = 0
var hSpeed = 0

var last_step = 0 

##########################
var is_dashing : bool = false # check if we're dashing
var can_dash : bool = true # check if we can dash? 
var dash_direction : Vector2 # get the direction we'll dash in
############################
var is_wall_sliding : bool = false 
var touching_ground : bool = false # check if we're touching the ground
var touching_wall : bool = false # check if we're touching a wall
var is_jumping : bool = false # see if the character is jumping
var is_double_jumping : bool = false #use this for animation logic
var can_slide : bool = false # check if it's possible to slide
var is_sliding : bool = false # check if we're currently sliding
var can_double_jump : bool = false # check if we can double jump
var air_jump_pressed : bool = false # check if we pressed jump JUST as we land (game feel)
var coyote_time : bool = false # if this is true we can save our jump before falling

var motion = Vector2.ZERO
var UP: Vector2 = Vector2(0,-1)

onready var ani = $AnimatedSprite
onready var ground_ray = $raycats/ground_ray
onready var right_ray = $raycats/right_ray
onready var left_ray = $raycats/left_ray

onready var wallslide_right_ray = $raycats/wallslide_right_ray 
onready var wallslide_left_ray = $raycats/wallslide_left_ray 

onready var slide_shape = $slide_shape
onready var stand_shape = $stand_shape

############################
onready var dash_timer = $dash_timer 
onready var dash_particles = $dash_particles

################
func is_controller():
	print(Input.get_action_strength("lt_down"))
	if(Input.get_action_strength("lt_down") > 0.7):
		return true
	if(Input.get_action_strength("lt_up") > 0.7):
		return true
	if(Input.get_action_strength("lt_right") > 0.7):
		return true
	if(Input.get_action_strength("lt_left") > 0.7):
		return true
	# we're not pressing a direction on the controller further enough, must be keyboard
	return false

func get_direction_from_input():
	var move_dir = Vector2()
	var controller = is_controller()
	print(controller)
	if(controller):
		move_dir.x = -Input.get_action_strength("lt_left") + Input.get_action_strength("lt_right")
		move_dir.y = Input.get_action_strength("lt_down") - Input.get_action_strength("lt_up")
	else:
		move_dir.x = -Input.get_action_strength("ui_left") + Input.get_action_strength("ui_right")
		move_dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		
	move_dir = move_dir.clamped(1)
	
	#check if no movement is pressed further enough... then dash towards ur facing position
	if (move_dir == Vector2(0,0)):
		if(ani.flip_h):
			move_dir.x = -1
		else:
			move_dir.x = 1
			
	return move_dir * dash_speed
	
########################
func _ready():
	dash_timer.connect("timeout",self,"dash_timer_timeout")
	pass # Replace with function body.

###############################

func dash_timer_timeout():
	is_dashing = false

func _physics_process(delta):
	###################
	#check if we can dash and if we're pressing our dash
	handle_dash(delta)
	###################
	#Check if we're grounded, left or landed on the ground
	check_ground_wall_logic() 
	#Check if we're moving/jumping/sliding etc
	handle_input(delta)
	#Handle our collision shape logic
	handle_player_collision_shapes()
	#handle our particles
	handle_player_particles()
	#Apply all the physics once the previous steps have happen
	do_physics(delta)
	pass
	

func handle_player_particles():
	if(motion.x == 0):
		last_step = -1
	if(ani.animation == "RUN"):
		if(ani.frame == 0 or ani.frame == 3):
			if(last_step != ani.frame):
				last_step = ani.frame
				var footstep = foot_step.instance()
				footstep.emitting = true
				footstep.global_position = Vector2(global_position.x,global_position.y + 23)
				get_parent().add_child(footstep)

#Reset stuff such as our Dash and Double jump
func check_ground_wall_logic():
	#Check for Coyote time(We just this moment left a platform)
	if(touching_ground and !ground_ray.is_colliding()):
		touching_ground = false
		coyote_time = true
		yield(get_tree().create_timer(0.2),"timeout")
		coyote_time = false
		
	#Check the moment we touch the ground for the first time
	if(!touching_ground and ground_ray.is_colliding()):
		ani.scale = Vector2(1.2,0.8)
		can_dash = true
		
	if(right_ray.is_colliding() or left_ray.is_colliding()):
		touching_wall = true
	else:
		touching_wall = false
	#set if we're touching the ground based on the raycast
	touching_ground = ground_ray.is_colliding()
	if(touching_ground):
		is_jumping = false # on ground so can't be jumping
		can_double_jump = true # reset double jump
		motion.y = 0
		vSpeed = 0
	#Logic of wall sliding here
	var check_slide = (wallslide_left_ray.is_colliding() or wallslide_right_ray.is_colliding())
	#if(is_on_wall() and !touching_ground and vSpeed > 0):
	if(check_slide and !touching_ground and vSpeed > 0):
		if((Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")) or 
		abs(Input.get_joy_axis(0,0)) > 0.3):
			is_wall_sliding = true
		else:
			is_wall_sliding = false
	else:
		is_wall_sliding = false

func handle_input(var delta):
	check_sliding_logic()
	handle_movement(delta)
	handle_jumping(delta)

func check_sliding_logic():
	#Check if it's possible to slide
	if(abs(hSpeed) > (max_horizontal_speed -1) && touching_ground):
		if(!is_sliding): can_slide = true
	else:
		can_slide = false
	#Check if we're holding down the slide key/button
	if(can_slide and Input.is_action_pressed("slide")):
		can_slide = false;
		is_sliding = true;
	#Check if we're sliding but just released the slide key
	if(is_sliding and !Input.is_action_pressed("slide")):
		is_sliding = false;
	#Do animation and friction logic
	if(is_sliding and touching_ground):
		current_friction = slide_friction ## reduce our friction for a nice slide
		ani.play("SLIDE")
	else:
		current_friction = friction # return to our standing friction
		is_sliding = false
		
################################
func handle_dash(var delta):
	if(Input.is_action_just_pressed("dash") and can_dash and !touching_ground):
		is_dashing = true
		can_dash = false
		dash_direction = get_direction_from_input()
		dash_timer.start(dash_length)
	
	if(is_dashing):
		var dash_node = dash_object.instance()
		dash_node.texture = ani.frames.get_frame(ani.animation,ani.frame)
		dash_node.global_position = global_position
		dash_node.flip_h = ani.flip_h
		get_parent().add_child(dash_node)
		
		dash_particles.emitting = true
		if(touching_ground):
			is_dashing = false
		if(is_on_wall()):
			is_dashing = false
		pass
	else:
		dash_particles.emitting = false
	
func handle_movement(var delta):
	if(is_on_wall()):
		motion.x = 0
		hSpeed = 0
	# Controller RIGHT
	if((Input.get_joy_axis(0,0) > 0.3 or Input.is_action_pressed("ui_right")) and !is_sliding): 
		if(hSpeed < -100):
			hSpeed += (deacceleration * delta)
			if(touching_ground):
				ani.play("TURN")
		elif(hSpeed < max_horizontal_speed):
			hSpeed += (acceleration * delta)
			ani.flip_h = false
			if(touching_ground):
				ani.play("RUN")
		else:
			if(touching_ground):
				ani.play("RUN")
			
	# Controller LEFT
	elif((Input.get_joy_axis(0,0) < -0.3 or Input.is_action_pressed("ui_left"))and !is_sliding): 
		if(hSpeed > 100):
			hSpeed -= (deacceleration * delta)
			if(touching_ground):
				ani.play("TURN")
		elif(hSpeed > -max_horizontal_speed):
			hSpeed -= (acceleration * delta)
			ani.flip_h = true
			if(touching_ground):
				ani.play("RUN")
		else:
			if(touching_ground):
				ani.play("RUN")
	# Controller Let go
	else: 
		if(touching_ground):
			if(!is_sliding):
				ani.play("IDLE")
			else:
				if(abs(hSpeed) < 0.2):
					ani.stop()
					ani.frame = 1
		hSpeed -= min(abs(hSpeed),current_friction * delta) * sign(hSpeed)
		
func handle_jumping(var delta):
	if(coyote_time and Input.is_action_just_pressed("jump")):
		vSpeed = jump_height
		is_jumping = true
		can_double_jump = true
	
	if(touching_ground):
		if((Input.is_action_just_pressed("jump") or air_jump_pressed) and !is_jumping):
			vSpeed = jump_height
			is_jumping = true
			touching_ground = false
			ani.scale = Vector2(0.5,1.2)
	else: # we're in the air
		if(vSpeed < 0 and !Input.is_action_pressed("jump") and !is_double_jumping):
			vSpeed = max(vSpeed,jump_height / 2)
		if(can_double_jump and Input.is_action_just_pressed("jump") 
		   and !coyote_time and !touching_wall):
			vSpeed = double_jump_height
			ani.play("DOUBLEJUMP")
			is_double_jumping = true
			can_double_jump = false
		#do some animation logic on the jump
		if(!is_double_jumping and vSpeed < 0):
			ani.play("JUMPUP")
		elif(!is_double_jumping and vSpeed > 0):
			ani.play(("JUMPDOWN"))
		elif(is_double_jumping and ani.frame == 3):
			is_double_jumping = false

		if(right_ray.is_colliding() and 
		   Input.is_action_just_pressed("jump")):
				vSpeed = wall_jump_height
				hSpeed = -wall_jump_push
				ani.flip_h = true
				can_double_jump = true
		elif(left_ray.is_colliding() and 
			 Input.is_action_just_pressed("jump")):
			vSpeed = wall_jump_height
			hSpeed = wall_jump_push
			ani.flip_h = false
			can_double_jump = true

		if(is_wall_sliding):
			ani.play("WALLSLIDE")
			is_double_jumping = false # it's possible our double jump doesnt finish

			#Check if we're press jump JUST before we land on a platform
		if(Input.is_action_just_pressed("jump")):
			air_jump_pressed = true
			yield(get_tree().create_timer(0.2),"timeout")
			air_jump_pressed = false

func do_physics(var delta):
	if(is_on_ceiling()):
		motion.y = 10
		vSpeed = 10

	if(!is_wall_sliding):
		vSpeed += (gravity * delta) # apply gravity downwards
		vSpeed = min(vSpeed,max_fall_speed) # Make sure there is a max fall speed
	else:
		vSpeed += (wall_slide_gravity * delta) # apply gravity downwards
		vSpeed = min(vSpeed,max_fall_speed_wall_slide) # Make sure there is a max fall speed
	
	#update our motion vector
	motion.y = vSpeed
	motion.x = hSpeed
	
	#Apply our motion vector using move_and_slide	
	################################################
	if(is_dashing):
		print(dash_direction)
		motion = move_and_slide(dash_direction,UP)
		vSpeed = 0
		hSpeed = 0
	else:
		motion = move_and_slide(motion,UP)
	#################################################
	#Lerp our squash/squeeze scale back to normal over time
	apply_squash_squeeze()
	pass
	
func apply_squash_squeeze():
	ani.scale.x = lerp(ani.scale.x,1,squash_speed)
	ani.scale.y = lerp(ani.scale.y,1,squash_speed)
	
func handle_player_collision_shapes():
	if(is_sliding and slide_shape.disabled):
		stand_shape.disabled = true
		slide_shape.disabled = false
	elif(!is_sliding and stand_shape.disabled):
		stand_shape.disabled = false
		slide_shape.disabled = true
