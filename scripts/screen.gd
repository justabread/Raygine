extends Node2D

var width
var height

var xPos = 1.0
var yPos = 4.0

var xDir = 1.0
var yDir = 0.0

var xPlane = 0.0
var yPlane = 1.0

#controls the resolution of the walls
var xRes = 1
var entityXRes = 1

const MOVSPEED = 0.03

var texWidth = 64
var texHeight = 64

var barrel = load("res://textures/pics/barrel.png")
var wall = load("res://textures/wall.png")
var door1 = load("res://textures/door_1.png")
var door2 = load("res://textures/door_2.png")
var doorwall = load("res://textures/door_wall.png")

var textures = [
	wall,
	door1,
	door2,
	doorwall
]
var map = [
	[1, 1, 2, 1, 2, 2, 1, 1],
	[2, 0, 0, 0, 0, 0, 0, 2],
	[1, 0, 3, 0, 0, 0, 0, 1],
	[2, 0, 0, 0, 0, 0, 0, 2],
	[1, 0, 1, 0, 2, 0, 3, 1],
	[1, 0, 1, 0, 2, 0, 0, 1],
	[1, 0, 1, 0, 1, 0, 0, 1],
	[1, 1, 3, 2, 1, 1, 3, 1]
]

class Entity:
	var x
	var y
	var color
	
	func _init(_x,_y,_color):
		x=_x
		y=_y
		color=_color

var sprites = [
	Entity.new(2.0, 1.0, Color( 1, 0.84, 0, 1 )),
	Entity.new(2.0, 5.0, Color( 0, 0, 1, 1 )),
]

var ZBuffer = []
var spriteOrder = []
var spriteDistance = []

func sortSprites(order, dist):
	order.sort()
	order.invert()
	
	dist.sort()
	dist.invert()

# Called when the node enters the scene tree for the first time.
func _ready():
	width = get_viewport().size.x
	height = get_viewport().size.y
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _input(event):
	if event is InputEventMouseMotion:
		var ROTSPEED = event.relative.x / 500
		
		var prevXDir = xDir
		xDir = xDir * cos(ROTSPEED) - yDir * sin(ROTSPEED)
		yDir = prevXDir * sin(ROTSPEED) + yDir * cos(ROTSPEED)
		var prevXPlane = xPlane
		xPlane = xPlane * cos(ROTSPEED) - yPlane * sin(ROTSPEED)
		yPlane = prevXPlane * sin(ROTSPEED) + yPlane * cos(ROTSPEED)

func _draw():
	game()

func game():	
	#checking input events every frame
#	print(str(xPos) + ", " + str(yPos))
	if Input.is_action_pressed("gam_exit"):
		get_tree().quit()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.is_action_pressed("mov_forward"):
		if !map[int(xPos + xDir * MOVSPEED)][int(yPos)]:
			xPos += xDir * MOVSPEED
		
		if !map[int(xPos)][int(yPos + yDir * MOVSPEED)]:
			yPos += yDir * MOVSPEED
			
	if Input.is_action_pressed("mov_backward"):
		if !map[int(xPos - xDir * MOVSPEED)][int(yPos)]:
			xPos -= xDir * MOVSPEED
		
		if !map[int(xPos)][int(yPos - yDir * MOVSPEED)]:
			yPos -= yDir * MOVSPEED
			
	if Input.is_action_pressed("mov_right"):
		if !map[int(xPos)][int(yPos + xDir * MOVSPEED)]:
			yPos += xDir * MOVSPEED
		
		if !map[int(xPos - yDir * MOVSPEED)][int(yPos)]:
			xPos -= yDir * MOVSPEED
		
	if Input.is_action_pressed("mov_left"):
		if !map[int(xPos)][int(yPos - xDir * MOVSPEED)]:
			yPos -= xDir * MOVSPEED
		
		if !map[int(xPos + yDir * MOVSPEED)][int(yPos)]:
			xPos += yDir * MOVSPEED
	
	#draw floor and ceiling
	var rectCeil = Rect2(0,0,width,height/2)
	var rectFloor = Rect2(0,height/2,width,height/2)
	draw_rect(rectCeil,Color(0.1,0.1,0.1),true)
	draw_rect(rectFloor,Color(1,1,1),true)

	var column = 0
	for x in range(column, width, xRes):
		var cameraX = 2.0 * column / width - 1.0
		var rayXPos = xPos
		var rayYPos = yPos
		var rayXDir = xDir + xPlane * cameraX
		var rayYDir = yDir + yPlane * cameraX + .000000000000001

		var mapX = int(rayXPos)
		var mapY = int(rayYPos)

		#calculating distance
		var deltaXDist = sqrt(1.0 + (rayYDir * rayYDir) / (rayXDir * rayXDir))
		var deltaYDist = sqrt(1.0 + (rayXDir * rayXDir) / (rayYDir * rayYDir))

		#variables for ray distance calculation
		var stepX
		var stepY
		var sideXDist
		var sideYDist

		if rayXDir < 0:
			stepX = -1
			sideXDist = (rayXPos - mapX) * deltaXDist
		else:
			stepX = 1
			sideXDist = (mapX + 1.0 - rayXPos) * deltaXDist

		if rayYDir < 0:
			stepY = -1
			sideYDist = (rayYPos - mapY) * deltaYDist
		else:
			stepY = 1
			sideYDist = (mapY + 1.0 - rayYPos) * deltaYDist

		#calculating distance to hit wall
		var hit = false
		var side
		while !hit:
			if sideXDist < sideYDist:
				sideXDist += deltaXDist
				mapX += stepX
				side = false
			else:
				sideYDist += deltaYDist
				mapY += stepY
				side = true

			if map[mapX][mapY] > 0:
				hit = true

		#perspective correction
		var perpWallDist
		if side == false:
			perpWallDist = abs((mapX - rayXPos + (1.0 - stepX) / 2.0) / rayXDir)
		else:
			perpWallDist = abs((mapY - rayYPos + (1.0 - stepY) / 2.0) / rayYDir)

		#calculating the height of the column
		var colHeight: float = abs(int(height / (perpWallDist + 0.0000001)))
		var colStart = -colHeight / 2.0 + height / 2.0

		#clamp colStart to stay inside the screen
		if colStart < 0:
			colStart = 0

		var colEnd = colHeight / 2.0 + height / 2.0

		if colEnd >= height:
			colEnd = height - 1
			
		var texNum = map[mapX][mapY] - 1
		
		var wallX
		if !side:
			wallX = yPos + perpWallDist * rayYDir
		else:
			wallX = xPos + perpWallDist * rayXDir
			
		wallX -= floor(wallX)
		
		var texX = int(wallX * float(texWidth))
		if !side && rayXDir > 0:
			texX = texWidth - texX - 1
			
		if side && rayYDir < 0:
			texX = texWidth - texX - 1
			
		var step = 1.0 * texHeight / colHeight
		var texPos = (colStart - height / 2 + colHeight / 2) * step
		
#		for y in range(colStart, colEnd, xRes):
#			var texY = int(texPos) & (texHeight - 1)
#			texPos += step
#			textures[texNum].lock()
#			var texColor = textures[texNum].get_pixel(texX, texY)
#			textures[texNum].unlock()
#			draw_primitive(PoolVector2Array([Vector2(x,y)]), PoolColorArray( [texColor] ), PoolVector2Array())

		var colors = [Color( 0, 0, 0, 0 ) , Color( 0, 0, 1, 1 ), Color( 1, 0.84, 0, 1 ) , Color( 0.98, 0.5, 0.45, 1 )]
		var colColor = colors[map[mapX][mapY]]

		if side:
			colColor.r = colColor.r / 1.5
			colColor.g = colColor.g / 1.5
			colColor.b = colColor.b / 1.5

		draw_line(Vector2(column, colStart), Vector2(column, colEnd), colColor, xRes)
		ZBuffer.push_back(perpWallDist)
		column += xRes
		
	for i in sprites.size():
		spriteOrder.push_back(i)
		spriteDistance.push_back((pow((xPos - sprites[i].x), 2) + pow((yPos - sprites[i].y), 2)))
		
	sortSprites(spriteOrder, spriteDistance)
	
	for j in sprites.size():
		var xSprite = sprites[spriteOrder[j]].x - xPos
		var ySprite = sprites[spriteOrder[j]].y - yPos
		
		var invDet = 1.0 / (xPlane * yDir - xDir * yPlane)
		
		var xTransform = invDet * (yDir * xSprite - xDir * ySprite)
		var yTransform = invDet * (-yPlane * xSprite + xPlane * ySprite)
		
		var spriteScreenX = int((width / 2) * (1 + xTransform / yTransform))
		var spriteHeight = abs(int(height / (yTransform)))
		var spriteWidth = abs(int(height / (yTransform)))
		
		var drawStartY = -spriteHeight / 2 + height / 2
		if(drawStartY < 0):
			drawStartY = 0
		var drawEndY = spriteHeight / 2 + height / 2
		if(drawEndY >= height):
			drawEndY = height - 1
			
		var drawStartX = -spriteWidth / 2 + spriteScreenX
		if(drawStartX < 0):
			drawStartX = 0
		var drawEndX = spriteWidth / 2 + spriteScreenX
		if(drawEndX >= width):
			drawEndX = width - 1
		
		for stripe in range(drawStartX, drawEndX):
			if(yTransform > 0 && stripe > 0 && stripe < width && yTransform < ZBuffer[stripe]):
				draw_line(Vector2(stripe, drawStartY), Vector2(stripe, drawEndY), sprites[j].color, entityXRes)
		
		
		
#		remove_child(sprites[j].entitySprite)
#		sprites[j].entitySprite.position.x = drawStartX
#		sprites[j].entitySprite.position.y = drawStartY
#		sprites[j].entitySprite.scale.x = spriteHeight
#		sprites[j].entitySprite.scale.y = spriteWidth
#		add_child(sprites[j].entitySprite)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update()
