class_name Player
extends KinematicBody2D


# list of state machine states
enum STATES {IDLE, WALKING, POWERING, ATTACKING}

# movement speeds, this primarily affects the Y axis since X autoscrolls forward
const ACCELERATION = 30
const MAX_SPEED = 400
const FRICTION = .1

# camera offsets for front and back lanes
const FORWARD_LANE = -240
const BACK_LANE = -30

# lower edge of the playfield
const BOTTOM_EDGE = 170


# main state variable
var state : int = STATES.IDLE

# lane toggle
var isFront : bool = false

# forward scrolling speed
var forwardSpeed : float = 1.0
var xAccel: float = .1

# store most recent non-zero movement input for setting attack direction
var velocity : Vector2 = Vector2.ZERO
var lastVelocity : Vector2 = Vector2.ZERO

# variables controlling movement
var targetSpeed : int = forwardSpeed

# reference to HUD components
onready var cameraNode : Node = get_node("/root/GameWorld/RootCamera")
# onready var powerUpGauge = get_node("/root/World/HUD_GUI/PowerUpBar")
# onready var toolDisplay = get_node("/root/World/HUD_GUI/ActiveToolDisplay")


# call changeLane on start to set camera position
func _ready() -> void:
	changeLane()



func _physics_process(delta) -> void:

	# call a state-specific function
	match state:
		STATES.IDLE: idle(delta)
		STATES.WALKING: walking(delta)

	# accel/decel towards target speed
	speedControl(delta)
	if (forwardSpeed < targetSpeed):
		forwardSpeed += xAccel
	elif (forwardSpeed > targetSpeed):
		forwardSpeed -= xAccel
	print(forwardSpeed, "/", targetSpeed)

	# scroll camera + player forward no matter what state
	self.position.x += forwardSpeed
	cameraNode.position.x += forwardSpeed

	# clamp vertical movement
	self.position.y = clamp(self.position.y, 0, BOTTOM_EDGE)



# toggle between front and back lanes
func changeLane() -> void:
	if isFront:
		isFront = false
		cameraNode.offset.x = BACK_LANE
	else:
		isFront = true
		cameraNode.offset.x = FORWARD_LANE


# read action buttons (expand to add shooting, etc.)
func readButtons() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		changeLane()


# return normalized movement input from keyboard or gamepad
func readMovement() -> Vector2:
	var _i = Vector2.ZERO
	_i.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	_i.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	# normalize fast/distorted diagonals
	_i = _i.normalized()
	return _i


# state function for player moving vertically
func walking(delta) -> void:
	var _i = readMovement()
	readButtons()
	if _i != Vector2.ZERO:
		var _nv : Vector2 = Vector2(0, _i.y)
		lastVelocity = _i
		velocity = move_and_slide(_nv * MAX_SPEED)

	else:
		velocity = velocity.move_toward(Vector2(0, 0), FRICTION * delta)
		state = STATES.IDLE

# function for controlling player target speed
func speedControl(delta) -> void:
	var _i = readMovement()
	readButtons()
	targetSpeed += _i.x
	targetSpeed = clamp(targetSpeed, 0, 50) #test numbers


# state function for no input
func idle(delta) -> void:
	var _i = readMovement()
	readButtons()
	if _i != Vector2.ZERO:
		state = STATES.WALKING
	else:
		velocity = velocity.move_toward(Vector2(0, 0), FRICTION * delta)


func _input(event):
	# Bow aiming
	if event is InputEventMouseMotion: 
		# set projectile spawn point between player and mouse
		var angle = get_angle_to(get_global_mouse_position())
		$Shoulder/BowLoc.position =  Vector2(cos(angle), sin(angle)) * 15
		#print("Mouse Motion at: ", event.position)
		print("Bow Angle: ", rad2deg(angle) )
		$Shoulder/BowLoc/BowSprite.rotation_degrees = rad2deg(angle+135)
		
	if event is InputEventMouseButton:
		#print("Mouse Click/Unclick at: ", event.position)
		fire_arrow()
		
func fire_arrow():
	#if reload timer not active
		#create arrow projectile at angle of bow
		#start reload timer
		print ("Arrow Fired")
