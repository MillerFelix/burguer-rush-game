class_name Player
extends CharacterBody3D

# ================================================================
# CONTROLADOR DO JOGADOR — SISTEMA DE MOVIMENTAÇÃO E FERRAMENTAS
#
# Ferramentas:
#  - Tecla 1: Espátula de Grelha (virar / retirar alimentos)
#  - Tecla 2: Bucha de Limpeza
#  - Tecla 3: Mão Livre (pegar ingredientes e manipular objetos)
# ================================================================

enum ToolSlot {
	SPATULA = 1,
	SPONGE = 2,
	HANDS = 3
}

@export var walk_speed: float = 4.0
@export var sprint_speed: float = 7.0
@export var acceleration: float = 12.0
@export var mouse_sensitivity: float = 0.002
@export var jump_velocity: float = 4.5

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var hold_position: Node3D = $Head/Camera3D/HoldPosition
@onready var tool_holder: Node3D = get_node_or_null("Head/Camera3D/ToolHolder")
@onready var hud = $HUD

var held_item: Node3D = null
var active_tool_slot: int = ToolSlot.HANDS

const SCENE_SPATULA = preload("res://src/tools/spatula.tscn")
const SCENE_SPONGE = preload("res://src/tools/sponge.tscn")

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	select_tool_slot(ToolSlot.HANDS, false)
	_update_interaction_detection()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	# Seleção de ferramentas por teclas numéricas (1, 2, 3)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_KP_1:
				select_tool_slot(ToolSlot.SPATULA)
			KEY_2, KEY_KP_2:
				select_tool_slot(ToolSlot.SPONGE)
			KEY_3, KEY_KP_3:
				select_tool_slot(ToolSlot.HANDS)

	# Tecla E — Interagir com equipamentos / portas / máquinas
	if event.is_action_pressed("interact"):
		_try_interact_equipment()

	# Clique Esquerdo — Manipulação de itens, ferramentas e ingredientes
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_interact_item()

	if event.is_action_pressed("secondary_interact"):
		_try_secondary_interact()

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func select_tool_slot(slot: int, show_feedback: bool = true) -> void:
	var transferring_item: Node3D = held_item
	if transferring_item and transferring_item.get_parent():
		transferring_item.get_parent().remove_child(transferring_item)

	active_tool_slot = slot

	if not tool_holder:
		tool_holder = get_node_or_null("Head/Camera3D/ToolHolder")

	if tool_holder:
		for child in tool_holder.get_children():
			tool_holder.remove_child(child)
			child.queue_free()

	match active_tool_slot:
		ToolSlot.SPATULA:
			if tool_holder:
				var spatula = SCENE_SPATULA.instantiate()
				tool_holder.add_child(spatula)
			if show_feedback and hud and hud.has_method("show_temporary_feedback"):
				hud.show_temporary_feedback("🍳 Espátula equipada [1]")

		ToolSlot.SPONGE:
			if tool_holder:
				var sponge = SCENE_SPONGE.instantiate()
				tool_holder.add_child(sponge)
			if show_feedback and hud and hud.has_method("show_temporary_feedback"):
				hud.show_temporary_feedback("🧽 Bucha de limpeza equipada [2]")

		ToolSlot.HANDS:
			if show_feedback and hud and hud.has_method("show_temporary_feedback"):
				hud.show_temporary_feedback("✋ Mão livre [3]")

	# Reanexa o item segurado ao ponto correto (BladeRestPoint da espátula ou HoldPosition da mão)
	if transferring_item:
		if active_tool_slot == ToolSlot.SPATULA and tool_holder and tool_holder.get_child_count() > 0:
			var spatula = tool_holder.get_child(0)
			var rest_pt = spatula.get_node_or_null("Model/BladeRestPoint")
			if rest_pt:
				rest_pt.add_child(transferring_item)
				transferring_item.position = Vector3.ZERO
				transferring_item.rotation = Vector3.ZERO
			else:
				hold_position.add_child(transferring_item)
				transferring_item.position = Vector3.ZERO
				transferring_item.rotation = Vector3.ZERO
		else:
			hold_position.add_child(transferring_item)
			transferring_item.position = Vector3.ZERO
			transferring_item.rotation = Vector3.ZERO

	if hud and hud.has_method("update_active_tool"):
		hud.update_active_tool(active_tool_slot)

	_update_interaction_detection()

func _try_interact_equipment() -> void:
	if raycast and raycast.is_colliding():
		var raw_collider = raycast.get_collider()
		if raw_collider:
			var collider = _get_target_interactable(raw_collider)
			if collider:
				if held_item != null:
					if collider is TrashBin or (collider.get_parent() and collider.get_parent() is TrashBin):
						var tb = collider if collider is TrashBin else collider.get_parent()
						tb.interact(self)
						return
					elif collider is RestaurantTable:
						var tbl = collider as RestaurantTable
						if tbl.table_state == RestaurantTable.TableState.DIRTY or (not tbl.seated_customers.is_empty() and tbl.seated_customers[0].state == Customer.State.WAITING_FOR_FOOD):
							tbl.interact(self)
							return
					elif collider is IngredientDispenser:
						if held_item.get("ingredient_id") == collider.get("ingredient_id") or str(held_item.get("item_type")) == "crate":
							collider.interact(self)
							return
					elif collider.has_method("interact_equipment"):
						collider.interact_equipment(self)
						return
					elif collider.has_method("interact"):
						collider.interact(self)
						return
				else:
					if collider.has_method("interact_equipment"):
						collider.interact_equipment(self)
						return
					elif collider.has_method("interact"):
						collider.interact(self)
						return

	if held_item != null:
		# Pressionar E solta o item segurado livremente na superfície física
		drop_item()
		return

func _get_target_interactable(collider: Object) -> Object:
	if not collider:
		return null
	if collider is BreadBottom:
		return collider
	if collider.has_meta("burger_base"):
		var base = collider.get_meta("burger_base")
		if base and is_instance_valid(base):
			return base
	if collider.get_parent() is BurgerAssembly:
		var ass = collider.get_parent() as BurgerAssembly
		if ass.base_bun and is_instance_valid(ass.base_bun):
			return ass.base_bun
	if collider.get_parent() is BreadBottom:
		return collider.get_parent()

	# Se for um item manipulável (ex: copo, barril, bisnaga, ingrediente): retorna o próprio item
	if collider is Item:
		return collider

	# Se o colisor for parte de uma estação / equipamento (ex: colisor de porta ou alavanca de DrinkMachine):
	var curr = collider
	while curr != null:
		if curr is Node and curr.has_method("get_interaction_prompt") and curr.has_method("interact"):
			return curr
		curr = curr.get_parent() if curr is Node else null

	return collider

func _try_interact_item() -> void:
	if held_item != null and (held_item is SauceBottle or str(held_item.get("item_type")) == "sauce_bottle"):
		return

	if raycast and raycast.is_colliding():
		var raw_collider = raycast.get_collider()
		if not raw_collider:
			return

		if raw_collider == held_item or (held_item != null and held_item.is_ancestor_of(raw_collider)):
			return

		var collider = _get_target_interactable(raw_collider)
		if not collider:
			return

		if collider.has_method("interact_item"):
			collider.interact_item(self)
			return

		elif collider is Item and held_item != null:
			var parent_station = collider.get_parent()
			if parent_station and parent_station != held_item and parent_station.has_method("interact_item"):
				parent_station.interact_item(self)
				return

		elif collider is Item and held_item == null:
			if "is_held" in collider and collider.is_held:
				return

			if active_tool_slot == ToolSlot.SPATULA and collider is Patty:
				var parent_grill = collider.get_parent()
				if parent_grill and parent_grill.get_parent() is Grill:
					parent_grill.get_parent().interact_item(self)
					return

			if active_tool_slot == ToolSlot.HANDS:
				pick_up(collider as Item)
				return
			elif active_tool_slot == ToolSlot.SPATULA:
				if hud and hud.has_method("show_temporary_feedback"):
					hud.show_temporary_feedback("✋ Pressione [3] para pegar itens com a mão livre.")
				return

func _try_secondary_interact() -> void:
	if raycast and raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider:
			if collider.has_method("cycle_flavor"):
				collider.cycle_flavor(self)
			elif collider.has_method("secondary_interact"):
				collider.secondary_interact(self)

func _physics_process(delta: float) -> void:
	if held_item != null and held_item is SauceBottle:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			held_item.start_squeezing(raycast)
		else:
			held_item.stop_squeezing()

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity += get_gravity() * delta
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var speed: float = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
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
		var raw_collider = raycast.get_collider()
		if raw_collider and raw_collider != held_item and (held_item == null or not held_item.is_ancestor_of(raw_collider)):
			var collider = _get_target_interactable(raw_collider)
			if collider and collider.has_method("get_interaction_prompt"):
				var prompt: String = collider.get_interaction_prompt(self)
				if prompt != "":
					hud.show_prompt(prompt)
					return
			elif collider is Item and held_item != null:
				var parent_ass = collider.get_parent()
				if parent_ass and parent_ass != held_item and parent_ass.has_method("get_interaction_prompt"):
					var prompt: String = parent_ass.get_interaction_prompt(self)
					if prompt != "":
						hud.show_prompt(prompt)
						return

	if held_item != null:
		if held_item is SauceBottle:
			hud.show_prompt("🖱️ (Segurar) Aplicar %s  │  [E] Soltar" % held_item.display_name)
		else:
			var d_name = held_item.get_display_name() if held_item.has_method("get_display_name") else held_item.name
			hud.show_prompt("🖱️ / [E] Soltar %s" % d_name)
		return

	hud.hide_prompt()

func pick_up(item: Node3D) -> void:
	if held_item != null or item == null:
		return
	if "is_held" in item and item.is_held:
		return
	if item == held_item:
		return

	held_item = item
	if raycast and item is CollisionObject3D:
		raycast.add_exception(item)

	var previous_parent = item.get_parent()
	if previous_parent:
		item.owner = null
		previous_parent.remove_child(item)

	# Se estiver com a Espátula (Slot 1), assenta a carne perfeitamente sobre a lâmina da espátula
	if active_tool_slot == ToolSlot.SPATULA and tool_holder and tool_holder.get_child_count() > 0:
		var spatula = tool_holder.get_child(0)
		var rest_pt = spatula.get_node_or_null("Model/BladeRestPoint")
		if rest_pt:
			rest_pt.add_child(item)
			item.position = Vector3.ZERO
			item.rotation = Vector3.ZERO
		else:
			hold_position.add_child(item)
			item.position = Vector3.ZERO
			item.rotation = Vector3.ZERO
	else:
		hold_position.add_child(item)
		item.position = Vector3.ZERO
		item.rotation = Vector3.ZERO

	if item.has_method("on_picked_up"):
		item.on_picked_up()
	elif item is CollisionObject3D:
		item.collision_layer = 0
		item.collision_mask = 0

	_update_interaction_detection()

func take_held_item() -> Node3D:
	if not held_item:
		return null

	var item := held_item
	held_item = null
	if raycast and item is CollisionObject3D:
		raycast.remove_exception(item)

	if item.get_parent():
		item.get_parent().remove_child(item)

	_update_interaction_detection()
	return item

func drop_item() -> void:
	if not held_item:
		return

	var item := held_item
	held_item = null
	if raycast and item is CollisionObject3D:
		raycast.remove_exception(item)

	var current_item_world_pos: Vector3
	if item.is_inside_tree():
		current_item_world_pos = item.global_position
	elif hold_position and hold_position.is_inside_tree():
		current_item_world_pos = hold_position.global_position
	elif is_inside_tree():
		var forward_dir = -camera.global_transform.basis.z if (camera and camera.is_inside_tree()) else -transform.basis.z
		current_item_world_pos = global_position + forward_dir * 0.5 + Vector3.UP * 0.8
	else:
		current_item_world_pos = position + Vector3(0, 0.8, -0.5)

	# Encontra a superfície física para o drop: mira direta ou chão/bancada abaixo
	var drop_pos = current_item_world_pos
	if is_inside_tree():
		if raycast and raycast.is_colliding():
			var col_pt = raycast.get_collision_point()
			var col_norm = raycast.get_collision_normal()
			var cam_pos = camera.global_position if (camera and camera.is_inside_tree()) else global_position
			if cam_pos.distance_to(col_pt) <= 2.8 and col_norm.y >= 0.2:
				drop_pos = col_pt + Vector3(0, 0.002, 0)
			else:
				var world_3d = get_world_3d()
				if world_3d:
					var space_state = world_3d.direct_space_state
					var query = PhysicsRayQueryParameters3D.create(
						current_item_world_pos + Vector3.UP * 0.1,
						current_item_world_pos + Vector3.DOWN * 3.5
					)
					if item is CollisionObject3D:
						query.exclude = [get_rid(), item.get_rid()]
					else:
						query.exclude = [get_rid()]
					var result = space_state.intersect_ray(query)
					if result:
						drop_pos = Vector3(current_item_world_pos.x, result.position.y + 0.002, current_item_world_pos.z)
		else:
			var world_3d = get_world_3d()
			if world_3d:
				var space_state = world_3d.direct_space_state
				var query = PhysicsRayQueryParameters3D.create(
					current_item_world_pos + Vector3.UP * 0.1,
					current_item_world_pos + Vector3.DOWN * 3.5
				)
				if item is CollisionObject3D:
					query.exclude = [get_rid(), item.get_rid()]
				else:
					query.exclude = [get_rid()]
				var result = space_state.intersect_ray(query)
				if result:
					drop_pos = Vector3(current_item_world_pos.x, result.position.y + 0.002, current_item_world_pos.z)

	if item is DrinkCup:
		# Verifica se o drop foi em direção a uma máquina de bebidas para snap automático
		if raycast and raycast.is_colliding():
			var col_target = raycast.get_collider()
			if col_target:
				var mach = null
				if col_target.has_method("try_snap_cup"):
					mach = col_target
				elif col_target.get_parent() and col_target.get_parent().has_method("try_snap_cup"):
					mach = col_target.get_parent()
				elif col_target.get_parent() and col_target.get_parent().get_parent() and col_target.get_parent().get_parent().has_method("try_snap_cup"):
					mach = col_target.get_parent().get_parent()
				if mach and mach.try_snap_cup(item as DrinkCup, drop_pos):
					_update_interaction_detection()
					return

	var drop_rot_y = rotation.y

	if item.get_parent():
		item.owner = null
		item.get_parent().remove_child(item)

	var world: Node = get_parent()
	if not world and is_inside_tree():
		world = get_tree().current_scene
	if not world and is_inside_tree():
		world = get_tree().root

	if world:
		world.add_child(item)
		if item.is_inside_tree():
			item.global_position = drop_pos
		else:
			item.position = drop_pos
		item.rotation = Vector3(0, drop_rot_y, 0)

	if item.has_method("on_dropped"):
		item.on_dropped()
	elif item.get("collision_shape") != null and item.collision_shape:
		item.collision_shape.disabled = false

	_update_interaction_detection()
