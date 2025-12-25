extends CharacterBody2D
class_name Enemy

var dead := false

enum State {
	ATTACK,
	CHASE,
	STARE
}

@export var speed := 120.0
@export var strafe_speed := 40.0
@export var flee_speed := 150.0

@export var chase_distance := 320.0
@export var strafe_distance := 120.0
@export var attack_distance := 30.0

@export var strafe_direction := 1  # 1 or -1

@export var max_hp := 3
var hp: int


@onready var hurtbox: Area2D = $HurtBox

var state: State = State.CHASE
var player: Node2D

func _ready() -> void:
	strafe_direction = [-1, 1].pick_random()
	player = get_tree().get_first_node_in_group("player")
	hp = max_hp
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()

	_update_state(distance)
	_apply_movement(to_player.normalized(), delta)

	move_and_slide()

	look_at(player.global_position)

func _on_timer_timeout() -> void:
	pass # Replace with function body.

func _update_state(distance: float) -> void:
	if distance < attack_distance:
		state = State.ATTACK
	elif distance < strafe_distance:
		state = State.STARE
	else:
		state = State.CHASE

func _apply_movement(dir_to_player: Vector2, delta: float) -> void:
	match state:
		State.CHASE:
			velocity = dir_to_player * speed

		State.STARE:
			velocity = Vector2.ZERO

		State.ATTACK:
			velocity = -dir_to_player * flee_speed

func take_damage(amount: int, from: Node = null) -> void:
	if dead:
		return

	hp -= amount
	if hp <= 0:
		_die()

func _die() -> void:
	dead = true

	self.queue_free()
