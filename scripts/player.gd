extends CharacterBody2D

@export var speed: float = 300.0
var target_position: Vector2
var moving: bool = false
const STOP_THRESHOLD: float = 2.0  # Distance in pixels to stop

signal movement_finished

func _ready():
	target_position = global_position

func _physics_process(delta):
	if moving:
		var direction = (target_position - global_position)
		var distance = direction.length()

		# If close enough, stop cleanly
		if distance <= STOP_THRESHOLD:
			global_position = target_position
			moving = false
			velocity = Vector2.ZERO
			emit_signal("movement_finished")
			return

		# Move smoothly towards target
		direction = direction.normalized()
		velocity = direction * speed
		move_and_slide()

	else:
		velocity = Vector2.ZERO
