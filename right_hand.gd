extends Area2D

@onready var hold_point: Node2D = $HoldPoint
var held_item: RigidBody2D = null
#var to prevent instant pickup after dropping
@export var repickup_block_time := 0.15
var _ignore_item: RigidBody2D = null
var _ignore_until_time := 0.0

func _on_body_entered(body: Node) -> void:
	if held_item != null:
		return

	var item := body as RigidBody2D
	if item == null:
		return

	if not item.is_in_group("items"):
		return

	# Optional: if item already held by the other hand, skip
	if item.get_meta("held", false) == true:
		return

# Block re-pickup for a short time after dropping
	if item == _ignore_item and Time.get_ticks_msec() / 1000.0 < _ignore_until_time:
		return

	_pickup(item)

func _pickup(item: RigidBody2D) -> void:
	print("pickup")
	held_item = item
	item.set_meta("held", true)

	# Stop physics so it doesn't fight the attachment.
	item.freeze = true
	item.linear_velocity = Vector2.ZERO
	item.angular_velocity = 0.0

	# Disable collisions while held (prevents re-triggering / jitter)
	item.collision_layer = 0
	item.collision_mask = 0

	# Reparent under the hand so it follows position + rotation automatically.
	var old_global := item.global_transform
	item.get_parent().remove_child(item)
	add_child(item)
	item.global_transform = old_global

	# Snap into the hand at HoldPoint.
	item.global_position = hold_point.global_position
	item.global_rotation = hold_point.global_rotation

func drop() -> void:
	print("drop")
	if held_item == null:
		return

	var item := held_item
	held_item = null
	item.set_meta("held", false)

	item.freeze = false
	# IMPORTANT: set these to whatever you actually use for items
	item.collision_layer = 4
	item.collision_mask = 4

	var world := get_tree().current_scene
	var old_global := item.global_transform
	remove_child(item)
	world.add_child(item)
	item.global_transform = old_global

# Prevent immediate re-pickup while still overlapping
	_ignore_item = item
	_ignore_until_time = Time.get_ticks_msec() / 1000.0 + repickup_block_time

func use_item(user: Node) -> void:
	if held_item == null:
		return

	if held_item.has_method("use"):
		held_item.use(user)
