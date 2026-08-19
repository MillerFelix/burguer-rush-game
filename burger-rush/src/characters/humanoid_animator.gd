class_name HumanoidAnimator
extends Node

enum AnimState {
	IDLE,
	WALK,
	SIT,
	EAT,
	CARRY_WALK,
	CARRY_IDLE
}

@export var current_state: AnimState = AnimState.IDLE

# Referências das partes do corpo
var root_model: Node3D = null
var torso: Node3D = null
var head: Node3D = null
var arm_left: Node3D = null
var arm_right: Node3D = null
var leg_left: Node3D = null
var leg_right: Node3D = null

# Referências faciais
var eye_left: Node3D = null
var eye_right: Node3D = null
var mouth: Node3D = null

# Fases e temporizadores
var walk_phase: float = 0.0
var idle_timer: float = 0.0
var blink_timer: float = 0.0
var next_blink_interval: float = 3.5
var is_blinking: bool = false
var blink_elapsed: float = 0.0
var blink_duration: float = 0.12

var glance_timer: float = 0.0
var next_glance_interval: float = 4.0
var target_head_yaw: float = 0.0
var current_head_yaw: float = 0.0

var eat_phase: float = 0.0

# Posições originais (Escala igual ao Jogador ~1.70m)
var orig_torso_pos: Vector3 = Vector3(0, 0.95, 0)
var orig_head_pos: Vector3 = Vector3(0, 1.48, 0)
var orig_arm_l_pos: Vector3 = Vector3(-0.29, 1.14, 0)
var orig_arm_r_pos: Vector3 = Vector3(0.29, 1.14, 0)
var orig_leg_l_pos: Vector3 = Vector3(-0.13, 0.60, 0)
var orig_leg_r_pos: Vector3 = Vector3(0.13, 0.60, 0)

func setup(p_model: Node3D) -> void:
	root_model = p_model
	if not root_model:
		return

	torso = root_model.get_node_or_null("Torso")
	head = root_model.get_node_or_null("Head")
	arm_left = root_model.get_node_or_null("ArmLeft")
	arm_right = root_model.get_node_or_null("ArmRight")
	leg_left = root_model.get_node_or_null("LegLeft")
	leg_right = root_model.get_node_or_null("LegRight")

	if torso:
		orig_torso_pos = torso.position
	if head:
		orig_head_pos = head.position
		eye_left = head.get_node_or_null("EyeLeft")
		eye_right = head.get_node_or_null("EyeRight")
		mouth = head.get_node_or_null("Mouth")

	if arm_left:
		orig_arm_l_pos = arm_left.position
	if arm_right:
		orig_arm_r_pos = arm_right.position
	if leg_left:
		orig_leg_l_pos = leg_left.position
	if leg_right:
		orig_leg_r_pos = leg_right.position

	next_blink_interval = randf_range(3.0, 5.0)
	next_glance_interval = randf_range(3.5, 6.0)

func update_animation(delta: float, velocity: Vector3, is_seated: bool, is_eating: bool, is_carrying: bool, raising_hand: bool = false, extending_hand: bool = false) -> void:
	var horiz_speed = Vector2(velocity.x, velocity.z).length()

	if is_seated:
		current_state = AnimState.EAT if is_eating else AnimState.SIT
	elif horiz_speed > 0.15:
		current_state = AnimState.CARRY_WALK if is_carrying else AnimState.WALK
	else:
		current_state = AnimState.CARRY_IDLE if is_carrying else AnimState.IDLE

	_update_face(delta)

	match current_state:
		AnimState.WALK:
			_animate_walk(delta, horiz_speed, false)
		AnimState.CARRY_WALK:
			_animate_walk(delta, horiz_speed, true)
		AnimState.IDLE:
			_animate_idle(delta, false, extending_hand)
		AnimState.CARRY_IDLE:
			_animate_idle(delta, true, extending_hand)
		AnimState.SIT:
			_animate_sit(delta, false, raising_hand)
		AnimState.EAT:
			_animate_sit(delta, true, false)

func _update_face(delta: float) -> void:
	# Sistema de piscar rápido e natural (mantendo olhos abertos 98% do tempo)
	blink_timer += delta
	if not is_blinking and blink_timer >= next_blink_interval:
		is_blinking = true
		blink_timer = 0.0
		blink_elapsed = 0.0
		next_blink_interval = randf_range(3.0, 5.5)

	if is_blinking:
		blink_elapsed += delta
		var p = blink_elapsed / blink_duration
		var scale_y = 1.0
		if p < 0.5:
			scale_y = lerpf(1.0, 0.15, p * 2.0)
		else:
			scale_y = lerpf(0.15, 1.0, (p - 0.5) * 2.0)

		if eye_left:
			eye_left.scale.y = scale_y
		if eye_right:
			eye_right.scale.y = scale_y

		if blink_elapsed >= blink_duration:
			is_blinking = false
			if eye_left:
				eye_left.scale.y = 1.0
			if eye_right:
				eye_right.scale.y = 1.0
	else:
		if eye_left:
			eye_left.scale.y = 1.0
		if eye_right:
			eye_right.scale.y = 1.0

	# Olhar suave
	glance_timer += delta
	if glance_timer >= next_glance_interval:
		glance_timer = 0.0
		next_glance_interval = randf_range(3.5, 6.0)
		var r = randi() % 3
		if r == 0:
			target_head_yaw = randf_range(-0.20, 0.20)
		elif r == 1:
			target_head_yaw = randf_range(-0.12, 0.12)
		else:
			target_head_yaw = 0.0

	current_head_yaw = lerpf(current_head_yaw, target_head_yaw, delta * 4.0)

func _animate_walk(delta: float, speed: float, carrying: bool) -> void:
	var freq = 8.5 * maxf(0.5, speed / 2.5)
	walk_phase += delta * freq

	var leg_angle = sin(walk_phase) * 0.65
	var arm_angle = -sin(walk_phase) * 0.55
	var bob_y = absf(sin(walk_phase)) * 0.04
	var body_roll = cos(walk_phase) * 0.03

	if torso:
		torso.position.y = orig_torso_pos.y - bob_y
		torso.position.z = 0.0
		torso.rotation.y = -leg_angle * 0.08
		torso.rotation.z = body_roll * 0.5
		torso.rotation.x = deg_to_rad(4.0)
	if head:
		head.position.y = orig_head_pos.y - bob_y
		head.position.z = 0.0
		head.rotation.y = current_head_yaw
		head.rotation.z = -body_roll * 0.3
		head.rotation.x = 0.0

	if leg_left:
		leg_left.position = orig_leg_l_pos + Vector3(0, maxf(0.0, sin(walk_phase) * 0.04), 0)
		leg_left.rotation.x = leg_angle
		leg_left.rotation.z = 0.0
	if leg_right:
		leg_right.position = orig_leg_r_pos + Vector3(0, maxf(0.0, -sin(walk_phase) * 0.04), 0)
		leg_right.rotation.x = -leg_angle
		leg_right.rotation.z = 0.0

	if carrying:
		if arm_left:
			arm_left.position = orig_arm_l_pos
			arm_left.rotation.x = deg_to_rad(-45.0) + sin(walk_phase * 0.5) * 0.04
			arm_left.rotation.y = deg_to_rad(12.0)
			arm_left.rotation.z = deg_to_rad(-8.0)
		if arm_right:
			arm_right.position = orig_arm_r_pos
			arm_right.rotation.x = deg_to_rad(-45.0) - sin(walk_phase * 0.5) * 0.04
			arm_right.rotation.y = deg_to_rad(-12.0)
			arm_right.rotation.z = deg_to_rad(8.0)
	else:
		if arm_left:
			arm_left.position = orig_arm_l_pos
			arm_left.rotation.x = arm_angle
			arm_left.rotation.y = 0.0
			arm_left.rotation.z = deg_to_rad(3.0)
		if arm_right:
			arm_right.position = orig_arm_r_pos
			arm_right.rotation.x = -arm_angle
			arm_right.rotation.y = 0.0
			arm_right.rotation.z = deg_to_rad(-3.0)

func _animate_idle(delta: float, carrying: bool, extending_hand: bool = false) -> void:
	idle_timer += delta * 1.8
	var breath = sin(idle_timer) * 0.005

	if torso:
		torso.position = orig_torso_pos + Vector3(0, breath, 0)
		torso.rotation = Vector3.ZERO
	if head:
		head.position = orig_head_pos + Vector3(0, breath * 0.5, 0)
		head.rotation.y = current_head_yaw
		head.rotation.x = 0.0
		head.rotation.z = 0.0

	if leg_left:
		leg_left.position = orig_leg_l_pos
		leg_left.rotation = Vector3(0, 0, deg_to_rad(-1.0))
	if leg_right:
		leg_right.position = orig_leg_r_pos
		leg_right.rotation = Vector3(0, 0, deg_to_rad(1.0))

	if extending_hand:
		# Mão direita estendida para frente na direção do balcão/jogador
		if arm_left:
			arm_left.position = orig_arm_l_pos
			arm_left.rotation.x = deg_to_rad(-12.0) + breath
			arm_left.rotation.y = deg_to_rad(6.0)
			arm_left.rotation.z = deg_to_rad(-4.0)
		if arm_right:
			arm_right.position = orig_arm_r_pos + Vector3(-0.04, -0.02, -0.08)
			arm_right.rotation.x = deg_to_rad(78.0) + sin(idle_timer * 2.0) * 0.02
			arm_right.rotation.y = deg_to_rad(-10.0)
			arm_right.rotation.z = deg_to_rad(-4.0)
	elif carrying:
		if arm_left:
			arm_left.position = orig_arm_l_pos
			arm_left.rotation.x = deg_to_rad(-40.0) + breath
			arm_left.rotation.y = deg_to_rad(12.0)
			arm_left.rotation.z = deg_to_rad(-8.0)
		if arm_right:
			arm_right.position = orig_arm_r_pos
			arm_right.rotation.x = deg_to_rad(-40.0) + breath
			arm_right.rotation.y = deg_to_rad(-12.0)
			arm_right.rotation.z = deg_to_rad(8.0)
	else:
		if arm_left:
			arm_left.position = orig_arm_l_pos
			arm_left.rotation.x = sin(idle_timer) * 0.03
			arm_left.rotation.y = 0.0
			arm_left.rotation.z = deg_to_rad(3.0) + breath
		if arm_right:
			arm_right.position = orig_arm_r_pos
			arm_right.rotation.x = -sin(idle_timer) * 0.03
			arm_right.rotation.y = 0.0
			arm_right.rotation.z = deg_to_rad(-3.0) - breath

func _animate_sit(delta: float, eating: bool, raising_hand: bool = false) -> void:
	idle_timer += delta * 2.0
	var breath = sin(idle_timer) * 0.006

	# Postura Sentada Precisa:
	# O quadril (base de Hips) desce exatamente para o assento a 0.48m.
	# Torso y = 0.85m -> Hips bottom = 0.85 - 0.31 - 0.07 = 0.47m (contato perfeito).
	# O tronco recua ligeiramente (z = +0.08m) para encostar confortavelmente no encosto da cadeira.
	if torso:
		torso.position = Vector3(0, 0.85 + breath, 0.08)
		torso.rotation = Vector3(deg_to_rad(3.0), 0, 0)
	if head:
		head.position = Vector3(0, 1.38 + breath, 0.08)
		head.rotation.y = current_head_yaw
		head.rotation.x = deg_to_rad(-4.0) if eating else 0.0
		head.rotation.z = 0.0

	# Coxas flexionadas horizontalmente para frente (-Z)
	if leg_left:
		leg_left.position = Vector3(-0.13, 0.54, -0.06)
		leg_left.rotation.x = deg_to_rad(88.0)
		leg_left.rotation.z = deg_to_rad(-2.0)
	if leg_right:
		leg_right.position = Vector3(0.13, 0.54, -0.06)
		leg_right.rotation.x = deg_to_rad(88.0)
		leg_right.rotation.z = deg_to_rad(2.0)

	if eating:
		eat_phase += delta * 3.5
		var eat_gesture = absf(sin(eat_phase))
		if arm_right:
			arm_right.position = Vector3(orig_arm_r_pos.x, 1.04, 0.08)
			arm_right.rotation.x = deg_to_rad(-50.0) - eat_gesture * deg_to_rad(35.0)
			arm_right.rotation.y = deg_to_rad(-20.0)
			arm_right.rotation.z = deg_to_rad(12.0)
		if arm_left:
			arm_left.position = Vector3(orig_arm_l_pos.x, 1.04, 0.08)
			arm_left.rotation.x = deg_to_rad(-40.0)
			arm_left.rotation.y = deg_to_rad(12.0)
			arm_left.rotation.z = deg_to_rad(-8.0)
	elif raising_hand:
		# Mão direita levantada chamando atendimento
		if arm_left:
			arm_left.position = Vector3(orig_arm_l_pos.x, 1.04, 0.08)
			arm_left.rotation.x = deg_to_rad(-28.0)
			arm_left.rotation.y = deg_to_rad(8.0)
			arm_left.rotation.z = deg_to_rad(-4.0)
		if arm_right:
			arm_right.position = Vector3(orig_arm_r_pos.x, 1.18, 0.08)
			arm_right.rotation.x = deg_to_rad(-145.0) + sin(idle_timer * 2.5) * 0.06
			arm_right.rotation.y = deg_to_rad(-5.0)
			arm_right.rotation.z = deg_to_rad(14.0)
	else:
		if arm_left:
			arm_left.position = Vector3(orig_arm_l_pos.x, 1.04, 0.08)
			arm_left.rotation.x = deg_to_rad(-28.0)
			arm_left.rotation.y = deg_to_rad(8.0)
			arm_left.rotation.z = deg_to_rad(-4.0)
		if arm_right:
			arm_right.position = Vector3(orig_arm_r_pos.x, 1.04, 0.08)
			arm_right.rotation.x = deg_to_rad(-28.0)
			arm_right.rotation.y = deg_to_rad(-8.0)
			arm_right.rotation.z = deg_to_rad(4.0)
