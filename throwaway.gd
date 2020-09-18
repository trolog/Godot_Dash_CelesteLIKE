extends ItemList


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	add_item("TEST",ResourceLoader.load("res://Sprites/Player/WALLSLIDE/adventurer-wall-slide-00.png"),true);
	add_item("This is just",ResourceLoader.load("res://Sprites/Player/WALLSLIDE/adventurer-wall-slide-00.png"),true);
	add_item("A",ResourceLoader.load("res://Sprites/Player/WALLSLIDE/adventurer-wall-slide-00.png"),true);
	add_item("TEST",ResourceLoader.load("res://Sprites/Player/WALLSLIDE/adventurer-wall-slide-00.png"),true);
	add_item("Again we are",ResourceLoader.load("res://Sprites/Player/WALLSLIDE/adventurer-wall-slide-00.png"),true);
	add_item("TEST",ResourceLoader.load("res://Sprites/Player/WALLSLIDE/adventurer-wall-slide-00.png"),true);
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
