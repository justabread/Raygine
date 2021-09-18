extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var width
var height

var xPos = 1.0
var yPos = 1.0

var xDir = 1.0
var yDir = 0.0

var xPlane = 0.0
var yPlane = 0.5

const ROTSPEED = 0.02
const MOVSPEED = 0.03

var g = 0
var map = [
		[1, 1, 1, 1, 1],
		[1, 0, 0, 0, 0],
		[2, 0, 1, 0, 0],
		[1, 0, 2, 0, 0],
		[2, 0, 3, 0, 0]]

# Called when the node enters the scene tree for the first time.
func _ready():
	width = get_viewport().size.x
	height = get_viewport().size.y

func _draw():
	game()

func game():
	#checking input events every frame
	if Input.is_action_pressed("mov_forward"):
		print("forward")
	if Input.is_action_pressed("mov_backward"):
		print("backward")
	if Input.is_action_pressed("mov_left"):
		print("left")
	if Input.is_action_pressed("mov_right"):
		print("right")
	
	#drawing floor and ceiling
	var rectCeil = Rect2(0,0,width,height/2)
	var rectFloor = Rect2(0,height/2,width,height/2)
	draw_rect(rectCeil,Color(0.1,0.1,0.1),true)
	draw_rect(rectFloor,Color(0.7,0.7,0.7),true)
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update()
