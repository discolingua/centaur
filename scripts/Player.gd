class_name Player
extends KinematicBody2D


# initialize state machine
enum STATES {IDLE, WALKING, POWERING, ATTACKING}


const ACCELERATION = 30
const MAX_SPEED = 400
const FRICTION = .1

# camera offsets for front and back lanes
const FORWARD_LANE = 180
const BACK_LANE = -10


# main state variable
var state : int = STATES.IDLE

# lane toggle
var isFront : bool = false

var forwardSpeed : float = 1

# store most recent non-zero movement input for setting attack direction
var velocity : Vector2 = Vector2.ZERO
var lastVelocity : Vector2 = Vector2.ZERO

# reference to HUD components
onready var cameraNode : Node = get_node("/root/GameWorld/RootCamera")
# onready var powerUpGauge = get_node("/root/World/HUD_GUI/PowerUpBar")
# onready var toolDisplay = get_node("/root/World/HUD_GUI/ActiveToolDisplay")



func _ready() -> void:
	pass


# simple state machine called every frame
func _physics_process(delta) -> void:
	match state:
		STATES.IDLE: idle(delta)
		STATES.WALKING: walking(delta)
	self.position.x += forwardSpeed
	cameraNode.position.x += forwardSpeed



func changeLane() -> void:
	# change lane
	if isFront:
		isFront = false
		cameraNode.offset.x = BACK_LANE
	else:
		isFront = true
		cameraNode.offset.x = FORWARD_LANE


func readButtons() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		changeLane()


func readMovement() -> Vector2:
	var _i = Vector2.ZERO

	_i.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	_i.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	# normalize vector fixes fast/distorted diagonals
	_i = _i.normalized()
	return _i


func walking(delta) -> void:
	var _i = readMovement()
	readButtons()
	if _i != Vector2.ZERO:
		var _nv : Vector2 = Vector2(0, _i.y)
		lastVelocity = _i
		velocity = move_and_slide(_nv * MAX_SPEED)
		cameraNode.position.x = self.position.x

	else:
		velocity = velocity.move_toward(Vector2(ACCELERATION, 0), FRICTION * delta)
		state = STATES.IDLE


func idle(delta) -> void:
	var _i = readMovement()
	readButtons()
	if _i != Vector2.ZERO:
		state = STATES.WALKING
	else:
		velocity = velocity.move_toward(Vector2(ACCELERATION, 0), FRICTION * delta)

