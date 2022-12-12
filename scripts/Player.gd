class_name Player
extends KinematicBody2D


# list of state machine states
enum STATES {IDLE, WALKING, SHOOTING,}

# scene for arrow instances
const Arrow = preload("res://scenes/Arrow.tscn")

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


var lastState : int = STATES.IDLE

# lane toggle
var isFront : bool = false

# forward scrolling speed
var forwardSpeed : float = 1.0

# current bow angle
var bowAngle : float = 0.0

# store most recent non-zero movement input for setting attack direction
var velocity : Vector2 = Vector2.ZERO
var lastVelocity : Vector2 = Vector2.ZERO

# reference to HUD components
onready var cameraNode : Node = get_node("/root/GameWorld/RootCamera")
# onready var powerUpGauge = get_node("/root/World/HUD_GUI/PowerUpBar")
# onready var toolDisplay = get_node("/root/World/HUD_GUI/ActiveToolDisplay")


# call changeLane on start to set camera position
func _ready() -> void:
	changeLane()


func _input(event):
	# Bow aiming
	if event is InputEventMouseMotion:
		# set projectile spawn point between player and mouse
		bowAngle = get_angle_to(get_global_mouse_position())
		$Shoulder/BowLoc.position =  Vector2(cos(bowAngle), sin(bowAngle)) * 15
		#print("Mouse Motion at: ", event.position)
		print("Bow Angle: ", rad2deg(bowAngle) )
		$Shoulder/BowLoc/BowSprite.rotation_degrees = rad2deg(bowAngle + 135)

	# action buttons are handled by readButtons() which is called by the state machine
	# system buttons (pause, menu) can be handled here because they are state independent


func _physics_process(delta) -> void:
	# call a state-specific function
	match state:
		STATES.IDLE: _stateIdle(delta)
		STATES.SHOOTING: _stateShoot(delta)
		STATES.WALKING: _stateWalking(delta)

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
	# space bar or right mouse button
	if Input.is_action_just_pressed("ui_accept"):
		changeLane()
	# Z or left mouse button
	if Input.is_action_just_pressed("ui_select"):
		lastState = state
		state = STATES.SHOOTING


# return normalized movement input from keyboard or gamepad
func readMovement() -> Vector2:
	var _i = Vector2.ZERO
	_i.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	_i.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	# normalize fast/distorted diagonals
	_i = _i.normalized()
	return _i


# state function for no input
func _stateIdle(delta) -> void:
	var _i = readMovement()
	readButtons()
	if _i != Vector2.ZERO:
		state = STATES.WALKING
	else:
		velocity = velocity.move_toward(Vector2(0, 0), FRICTION * delta)


func _stateShoot(_delta) -> void:
	# create arrow instance
	var _arrow = Arrow.instance()
	# set position to player's shoulder
	_arrow.position = self.position + Vector2(0, -10)
	# set velocity to last non-zero movement input
	_arrow.velocity = lastVelocity
	# add to scene
	get_parent().add_child(_arrow)
	# reset state
	lastState = state
	state = STATES.IDLE


# state function for player moving vertically
func _stateWalking(delta) -> void:
	var _i = readMovement()
	readButtons()
	if _i != Vector2.ZERO:
		var _nv : Vector2 = Vector2(0, _i.y)
		lastVelocity = _i
		velocity = move_and_slide(_nv * MAX_SPEED)
	else:
		velocity = velocity.move_toward(Vector2(0, 0), FRICTION * delta)
		lastState = state
		state = STATES.IDLE
