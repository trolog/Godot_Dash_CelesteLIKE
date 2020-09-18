extends KinematicBody2D
#define enums
enum states{
	IDLE,
	MOVE,
}
enum facing_direction{
	RIGHT,
	LEFT
}

export(facing_direction) var current_direction = facing_direction.RIGHT
export var move_speed = 100 # how fast does our creature move?

onready var right_ray : RayCast2D = $right_ray
onready var left_ray : RayCast2D = $left_ray
onready var ani : AnimatedSprite = $AnimatedSprite

var hSpeed = 0 # how fast is our creature currently moving?
var on_ledge : bool = false # determine if we're on a ledge

var state = states.IDLE

var motion = Vector2.ZERO
var UP: Vector2 = Vector2(0,-1)

func _ready():
	update_facing_direction()
	pass # Replace with function body.
	
func _physics_process(delta):
	do_physics(delta)
	pass
	

func check_if_on_ledge():
	if(!left_ray.is_colliding() or !right_ray.is_colliding()):
		return true
	else:
		return false

func do_physics(var delta):
	motion.y = 0
	motion.x = hSpeed
	#Apply our motion vector using move_and_slide
	motion = move_and_slide(motion,UP)

func match_speed_to_direction():
	if(current_direction == facing_direction.RIGHT):
		hSpeed = move_speed
	else:
		hSpeed = -move_speed
	
	#Chech if we bump into a wall, invert facing direction
	if(is_on_wall() or on_ledge):
		if(current_direction == facing_direction.RIGHT):
			position.x -=10
			current_direction = facing_direction.LEFT
		else:
			position.x +=10
			current_direction = facing_direction.RIGHT
		update_facing_direction()

func update_facing_direction():	
	if(current_direction == facing_direction.RIGHT):
		ani.flip_h = false
	else:
		ani.flip_h = true
