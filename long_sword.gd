extends RigidBody2D
class_name Sword

@export var damage := 1

@export var swing_angle_degrees := 120.0     # total arc
@export var swing_time := 0.12              # seconds
@export var recover_time := 0.18            # seconds
@export var hitbox_active_time := 0.10      # seconds (inside swing)
@export var cooldown := 0.25

@onready var hitbox: Area2D = $HitBox

var _can_use := true
var _already_hit := {}   # instance_id -> true during a swing

func _ready() -> void:
	hitbox.monitoring = false

func use(user: Node) -> void:
	if not _can_use:
		return

	_can_use = false
	_already_hit.clear()

	# Swing around the hold point by rotating the sword node itself.
	# Because the sword is parented under the Hand, local rotation is perfect.
	await _do_swing()

	await get_tree().create_timer(cooldown).timeout
	_can_use = true

func _do_swing() -> void:
	# Start position
	var start_rot := rotation
	var half := deg_to_rad(swing_angle_degrees * 0.5)
	var left_rot := start_rot - half
	var right_rot := start_rot + half

	# Put sword at one extreme before swinging through
	rotation = left_rot

	# Enable hitbox during the swing
	hitbox.monitoring = true
	get_tree().create_timer(hitbox_active_time).timeout.connect(func():
		hitbox.monitoring = false
	)

	# Tween rotation through the arc
	var tw := create_tween()
	tw.tween_property(self, "rotation", right_rot, swing_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "rotation", start_rot, recover_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await tw.finished

func _on_hit_box_area_entered(area: Area2D) -> void:
		# Prevent multi-hits on the same enemy in one swing
	var id := area.get_instance_id()
	if _already_hit.has(id):
		return
	_already_hit[id] = true

	# If enemy root is the body itself:
	if area.has_method("take_damage"):
		area.take_damage(damage, self)
		return

	# If the hurtbox is a child Area2D and the body is something else,
	# you can also check parent:
	if area.get_parent() != null and area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage, self)
