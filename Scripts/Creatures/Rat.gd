extends "res://Scripts/Parents/Creature.gd"

export var constant_roam = false # if this is true we never stop to idle
export var idle_length = 3 # how manc secs do we want to idle
export var move_length = 5 # how long we want to move before turning back to idle

func _physics_process(delta):
	on_ledge = check_if_on_ledge()
	if(constant_roam):
		match_speed_to_direction()
		ani.play("MOVE")
	else:
		do_states(state)
	pass
	
func do_states(var current_state):
	if(current_state == states.IDLE):
		ani.play("IDLE")
		hSpeed = 0
		yield(get_tree().create_timer(idle_length),"timeout")
		state = states.MOVE
		pass
	elif(current_state == states.MOVE):
		match_speed_to_direction()
		ani.play("MOVE")
		yield(get_tree().create_timer(move_length),"timeout")
		state = states.IDLE
