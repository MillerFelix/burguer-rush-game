class_name Player
extends CharacterBody3D

@export var walk_speed: float = 4.0
@export var sprint_speed: float = 6.5
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.002
@export var acceleration: float = 12.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var hold_position: Node3D = $Head/Camera3D/HoldPosition
@onready var hud: CanvasLayer = $HUD

var held_item: Node3D = null

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89.0), deg_to_rad(89.0))
	
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event.is_action_pressed("interact"):
		_try_interact()

func _physics_process(delta: float) -> void:
	# Aplica gravidade padrão da Godot
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Pulo
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Velocidade alvo (caminhada vs corrida)
	var speed: float = sprint_speed if Input.is_action_pressed("sprint") else walk_speed

	# Direção de movimento baseada nos inputs
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if direction:
		velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, acceleration * delta)

	move_and_slide()
	_update_interaction_detection()

func _update_interaction_detection() -> void:
	if not hud:
		return

	if raycast and raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.has_method("get_interaction_prompt"):
			var prompt: String = collider.get_interaction_prompt(self)
			if prompt != "":
				hud.show_prompt(prompt)
				return

	if held_item != null:
		hud.show_prompt("E — Soltar")
		return

	hud.hide_prompt()

func _try_interact() -> void:
	if raycast and raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.has_method("get_interaction_prompt") and collider.has_method("interact"):
			var prompt: String = collider.get_interaction_prompt(self)
			if prompt != "":
				collider.interact(self)
				return

	if held_item != null:
		drop_item()
		return

	if raycast and raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.has_method("interact"):
			collider.interact(self)

func pick_up(item: Node3D) -> void:
	if held_item != null:
		return

	held_item = item
	var previous_parent = item.get_parent()
	if previous_parent:
		previous_parent.remove_child(item)

	hold_position.add_child(item)
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO

	if item.has_method("on_picked_up"):
		item.on_picked_up()

	_update_interaction_detection()

func take_held_item() -> Node3D:
	if not held_item:
		return null

	var item := held_item
	held_item = null
	hold_position.remove_child(item)

	_update_interaction_detection()
	return item

func drop_item() -> void:
	if not held_item:
		return

	var item := held_item
	held_item = null

	var drop_transform := item.global_transform
	hold_position.remove_child(item)

	var world: Node = get_parent()
	if not world:
		world = get_tree().current_scene
	if not world:
		world = get_tree().root

	world.add_child(item)
	item.global_transform = drop_transform

	if item.has_method("on_dropped"):
		item.on_dropped()

	_update_interaction_detection()
