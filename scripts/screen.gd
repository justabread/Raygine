extends Node2D

var isGameRunning = false

var width
var height
var xPos = 1.0
var yPos = 4.0
var xDir = 1.0
var yDir = 0.0
var xPlane = 0.0
var yPlane = 1.0
#controls the resolution of the walls (LEAVE AT 1)
var xRes = 1
var texSize = 64
var currentTime = 0
var isTimerOn = false

const PICKUPDISTANCE = 0.1
const MOVSPEED = 0.03


var map = [
	[1, 1, 2, 1, 2, 2, 1, 1, 1, 1, 2, 1],
	[2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2],
	[1, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 1],
	[2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2],
	[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
	[1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
	[1, 0, 2, 0, 2, 0, 0, 0, 0, 0, 0, 1],
	[1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1],
	[1, 0, 1, 0, 3, 0, 0, 0, 0, 0, 0, 1],
	[1, 0, 2, 0, 1, 0, 0, 0, 0, 0, 0, 1],
	[1, 0, 3, 0, 1, 0, 0, 0, 0, 0, 0, 1],
	[1, 1, 3, 2, 1, 1, 3, 1, 1, 1, 1, 1]
]

var spriteColor = Color( 0, 0.5, 1, 1 )

class Entity:
	var x
	var y
	var distance
	var color
	
	func _init(_x,_y,_color):
		x=_x
		y=_y
		color=_color

var sprites = [
	Entity.new(2.0, 5.0, spriteColor),
	Entity.new(3.0, 6.0, spriteColor)
]

var currentScore = 0
var goalScore = sprites.size()

var ZBuffer = []
var spriteOrder = []
var spriteDistance = []

func startTimer():
	if(!isTimerOn):
		isTimerOn = true

func stopTimer():
	if(isTimerOn):
		isTimerOn = false

func resetTimer():
	currentTime = 0

func SortSprites(order, dist):
	order.sort()
	order.invert()
	
	dist.sort()
	dist.invert()

# Called when the node enters the scene tree for the first time.
func _ready():
	width = get_viewport().size.x
	height = get_viewport().size.y
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	isGameRunning = true
	startTimer()
	
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
	draw_rect(rectCeil,Color(0,1,1),true)
	draw_rect(rectFloor,Color(0.7,0.7,0.7),true)

	var column = 0
	for x in range(column, width):
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
		
		var texX = int(wallX * float(texSize))
		if !side && rayXDir > 0:
			texX = texSize - texX - 1
			
		if side && rayYDir < 0:
			texX = texSize - texX - 1
			
		var step = 1.0 * texSize / colHeight
		var texPos = (colStart - height / 2 + colHeight / 2) * step
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
		var distance = pow((xPos - sprites[i].x), 2) + pow((yPos - sprites[i].y), 2)
		spriteDistance.push_back(distance)
		sprites[i].distance = distance
		
	SortSprites(spriteOrder, spriteDistance)
	
	for j in sprites.size():
		var xSprite: float = sprites[spriteOrder[j]].x - xPos
		var ySprite: float = sprites[spriteOrder[j]].y - yPos
		var invDet: float = 1.0 / (xPlane * yDir - xDir * yPlane)
		var xTransform: float = invDet * (yDir * xSprite - xDir * ySprite)
		var yTransform: float = invDet * (-yPlane * xSprite + xPlane * ySprite)
		var spriteScreenX: int = int((width / 2) * (1 + xTransform / yTransform));

		var spriteSize: int = abs(int(height / (yTransform))) / 4
		var drawStartY: int = -spriteSize / 2 + height / 2

		if(drawStartY < 0):
			drawStartY = 0
		var drawEndY: int = spriteSize / 2 + height / 2

		if(drawEndY >= height):
			drawEndY = height - 1
		var drawStartX: int = -spriteSize / 2 + spriteScreenX
		if(drawStartX < 0):
			drawStartX = 0

		var drawEndX: int = spriteSize / 2 + spriteScreenX
		if(drawEndX >= width):
			drawEndX = width - 1

		for stripe in range(drawStartX, drawEndX):
			if(yTransform > 0 && stripe > 0 && stripe < width && yTransform < ZBuffer[stripe]):
				draw_line(Vector2(stripe, drawStartY), Vector2(stripe, drawEndY), sprites[j].color, xRes)

	for k in sprites.size():
		if(sprites[spriteOrder[k]].distance <= PICKUPDISTANCE):
			sprites.remove(spriteOrder[k])
			currentScore += 1

	$GUI/scoreLabel.text = var2str(currentScore)
	ZBuffer.clear()
	spriteOrder.clear()
	spriteDistance.clear()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(isGameRunning):
		update()
		if(isTimerOn):
			currentTime += delta
			var milseconds = fmod(currentTime, 1)*10
			var seconds = fmod(currentTime, 60)
			var minutes = fmod(currentTime, 60*60) / 60
			var hours = fmod(currentTime, 60*60*60) / 60
			
			$GUI/timerLabel.text = "%01d:%02d:%02d:%01d" % [hours,minutes,seconds,milseconds]
