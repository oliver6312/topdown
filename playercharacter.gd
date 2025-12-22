extends CharacterBody2D

#var for movement
@export var speed = 250
@export var acceleration = 0.04
@export var friction = 0.2
#var for hands
@onready var left_hand: Area2D = $Hands/LeftHand
@onready var right_hand: Area2D = $Hands/RightHand
@onready var left_hold: Marker2D = $Hands/LeftHand/Marker2D
@onready var right_hold: Marker2D = $Hands/RightHand/Marker2D
#lists of items currently overlapping that hand’s area.
var left_candidates: Array[Node2D] = []
var right_candidates: Array[Node2D] = []
#the item currently held in each hand.
var left_held: Node2D = null
var right_held: Node2D = null


func get_input():
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if (Input.get_vector("move_left", "move_right", "move_up", "move_down") != Vector2.ZERO):
		velocity = velocity.lerp(input_direction * speed, acceleration)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction)

func _physics_process(delta):
	var mouse_pos := get_global_mouse_position()
	look_at(mouse_pos)
	get_input()
	move_and_slide()
