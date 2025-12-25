extends CharacterBody2D

# --- TUNABLES (start here) ----------------------------------------------------
@onready var left_hand: Area2D = $Hands/LeftHand
@onready var right_hand: Area2D = $Hands/RightHand

@export var max_speed_forward: float = 260.0
@export var max_speed_strafe: float  = 210.0
@export var max_speed_backward: float = 140.0

@export var accel_forward: float = 1400.0
@export var accel_strafe: float  = 1150.0
@export var accel_backward: float = 850.0

# Deceleration when no input (coast to stop)
@export var decel: float = 1800.0

# Stronger decel when input is opposite current velocity (braking)
@export var brake: float = 2600.0

# Facing / turn behavior
@export var use_mouse_aim: bool = true
@export var turn_speed_deg: float = 720.0  # degrees/second (lower = heavier turning)

# Small deadzone for analog sticks (if you use them)
@export var input_deadzone: float = 0.15

# --- INTERNAL ---------------------------------------------------------------

var _facing: Vector2 = Vector2.RIGHT  # normalized facing direction

func _ready() -> void:
	_facing = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	var move_input := _get_move_input()  # normalized (or zero)
	_update_facing(delta, move_input)

	# Build target velocity based on move + facing
	var target_velocity := Vector2.ZERO
	if move_input != Vector2.ZERO:
		var dot := _facing.dot(move_input)  # [-1..1], forward=1, back=-1

		# Map dot to a "mode" and choose speed/accel.
		# You can make this smoother (blend) if you prefer.
		var max_speed: float
		var accel: float

		if dot > 0.35:
			max_speed = max_speed_forward
			accel = accel_forward
		elif dot < -0.35:
			max_speed = max_speed_backward
			accel = accel_backward
		else:
			max_speed = max_speed_strafe
			accel = accel_strafe

		target_velocity = move_input * max_speed

		# If we're trying to reverse direction, use stronger braking.
		var opposing := velocity.dot(target_velocity) < 0.0
		var rate := brake if opposing else accel

		# Move current velocity toward the target with a capped acceleration rate.
		velocity = velocity.move_toward(target_velocity, rate * delta)
	else:
		# No input: coast to stop.
		velocity = velocity.move_toward(Vector2.ZERO, decel * delta)

	# Actually move (CharacterBody2D)
	move_and_slide()

# --- INPUT / FACING ----------------------------------------------------------

func _get_move_input() -> Vector2:
	# Define these actions in Project Settings > Input Map:
	# "move_left", "move_right", "move_up", "move_down"
	var x := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y := Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	var v := Vector2(x, y)

	# Deadzone for analog inputs (safe for keyboard too)
	if v.length() < input_deadzone:
		return Vector2.ZERO
	return v.normalized()

func _update_facing(delta: float, move_input: Vector2) -> void:
	var desired: Vector2 = _facing

	if use_mouse_aim:
		# Face the mouse. This gives the clearest "forward/back" behavior.
		var mouse_pos := get_global_mouse_position()
		var to_mouse := mouse_pos - global_position
		if to_mouse.length_squared() > 0.0001:
			desired = to_mouse.normalized()
	else:
		# If not aiming with mouse, face movement direction (only when moving).
		# This reduces the "backpedal" mechanic; use mouse/twin-stick for best effect.
		if move_input != Vector2.ZERO:
			desired = move_input

	# Turn inertia: rotate _facing toward desired at a limited rate.
	_facing = _rotate_toward_dir(_facing, desired, deg_to_rad(turn_speed_deg) * delta)

	# Apply visual rotation so the sprite looks where it's facing.
	rotation = _facing.angle()

func _rotate_toward_dir(from_dir: Vector2, to_dir: Vector2, max_radians: float) -> Vector2:
	if to_dir == Vector2.ZERO:
		return from_dir

	var from_angle := from_dir.angle()
	var to_angle := to_dir.angle()

	var delta := wrapf(to_angle - from_angle, -PI, PI)
	delta = clamp(delta, -max_radians, max_radians)

	var new_angle := from_angle + delta
	return Vector2(cos(new_angle), sin(new_angle)).normalized()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_left_ctrl"):
		left_hand.drop()
	if event.is_action_pressed("mouse_right_ctrl"):
		right_hand.drop()

	if event.is_action_pressed("mouse_left"):
		left_hand.use_item(self) 
	if event.is_action_pressed("mouse_right"):
		right_hand.use_item(self)
