class_name PrepIsland
extends StaticBody3D

# ================================================================
# ILHA CENTRAL DE PREPARO E MONTAGEM (ÁREA DE TRABALHO LIVRE)
#
# Oferece superfície ampla e conveniente para colocação de itens,
# organização livre e montagem de sanduíches.
# ================================================================

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

const SURFACE_TOP_Y: float = 0.88
const BOUNDS_X_MIN: float = -1.80
const BOUNDS_X_MAX: float = 1.80
const BOUNDS_Z_MIN: float = -0.85
const BOUNDS_Z_MAX: float = 0.85

var placed_items: Array[Node3D] = []
var dirt_level: float = 0.0

func _ready() -> void:
	add_to_group("cleanable_stations")
	_update_dirt_visuals()

func is_dirty() -> bool:
	return dirt_level >= 0.70

func get_dirt_level() -> float:
	return dirt_level

func clean_station(player: Node3D = null) -> void:
	dirt_level = 0.0
	_update_dirt_visuals()
	if player:
		_show_feedback(player, "✨ Ilha de preparo limpa e higienizada!")

func add_dirt(amount: float = 0.15) -> void:
	dirt_level = clampf(dirt_level + amount, 0.0, 1.0)
	_update_dirt_visuals()

func _update_dirt_visuals() -> void:
	var dirt_mesh = get_node_or_null("Model/IslandDirt")
	if dirt_mesh:
		dirt_mesh.visible = (dirt_level > 0.001)
		var sc = lerpf(0.20, 1.0, dirt_level) if dirt_level > 0.001 else 0.0
		dirt_mesh.scale = Vector3(sc, sc, sc)
		for child in dirt_mesh.get_children():
			if child is MeshInstance3D:
				var mat = child.get_active_material(0)
				if mat is StandardMaterial3D and mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					mat.albedo_color.a = clampf(dirt_level * 0.95, 0.0, 0.95)

func clean_progress(delta: float, player: Node3D = null) -> bool:
	if dirt_level <= 0.0:
		return true

	dirt_level = maxf(0.0, dirt_level - (delta / 1.5))
	_update_dirt_visuals()

	if dirt_level <= 0.0:
		if player:
			_show_feedback(player, "✨ Ilha de preparo limpa e higienizada!")
			var th = player.get_node_or_null("Head/Camera3D/ToolHolder") if player.has_node("Head/Camera3D/ToolHolder") else null
			var sp = th.get_node_or_null("Sponge") if th else null
			if sp and sp.has_method("set_dirty"):
				sp.set_dirty()
			elif "sponge_is_dirty" in player:
				player.set("sponge_is_dirty", true)
		return true

	return false

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""

	if is_dirty():
		var tool_holder = player.get_node_or_null("Head/Camera3D/ToolHolder") if player else null
		var sponge = tool_holder.get_node_or_null("Sponge") if tool_holder else null
		if sponge:
			if sponge.is_dirty:
				return "⚠️ Bucha suja! Lave na pia antes de limpar a bancada"
			else:
				return "🖱️ [Segurar Clique Esquerdo] Limpar Bancada com a Bucha"
		else:
			return "Bancada suja (Equipe a Bucha [2] para limpar)"

	var tool_slot = player.get("active_tool_slot") if player else 3
	if tool_slot == 2 and dirt_level > 0.0:
		return "🖱️ [Segurar Clique Esquerdo] Limpar Bancada com a Bucha"

	var held = player.get("held_item")
	if held != null:
		var d_name = held.get_display_name() if held.has_method("get_display_name") else held.name
		return "🖱️ Colocar %s na Ilha" % d_name
	elif player.has_method("has_active_ingredient") and player.has_active_ingredient():
		var act = player.get_active_ingredient()
		var d_name = act.get("display_name", "Ingrediente")
		return "🖱️ Colocar %s na Ilha" % d_name

	return ""

# [Clique Esquerdo do Mouse] — Colocar item/ingrediente no ponto exato da mira
func interact_item(player: Node3D) -> void:
	if not player:
		return

	var held = player.get("held_item")
	if held == null:
		return

	# Se for bisnaga de molho, o clique é para espremer (não soltar)
	if held is SauceBottle or str(held.get("item_type")) == "sauce_bottle":
		return

	var hit_pos = _calculate_placement_position(player)

	# 1. Verifica se há uma base de pão ou montagem próxima ao ponto clicado
	var nearby_bread = _find_nearby_bread(hit_pos, 0.22)
	if nearby_bread:
		nearby_bread.interact_item(player)
		add_dirt(0.12)
		return

	# 2. Solta o item fisicamente no ponto exato clicado sobre a bancada
	if player.has_method("take_held_item"):
		var item: Node3D = player.take_held_item()
		if item:
			_place_item_on_surface(item, hit_pos, player.rotation.y)
			add_dirt(0.12)
			var d_name = item.get_display_name() if item.has_method("get_display_name") else item.name
			_show_feedback(player, "🥪 %s colocado na ilha de preparo" % d_name)

func interact(player: Node3D) -> void:
	interact_item(player)

func _find_nearby_bread(world_pos: Vector3, max_dist: float) -> Node3D:
	var world_node = get_parent() if get_parent() else get_tree().current_scene
	if not world_node:
		return null

	var closest: Node3D = null
	var closest_dist: float = max_dist

	for child in world_node.get_children():
		if child is Item and (child.get("assembly") != null or child.item_id == "bread_bottom" or child.has_node("BurgerAssembly")):
			var d = Vector2(child.global_position.x - world_pos.x, child.global_position.z - world_pos.z).length()
			if d < closest_dist:
				closest_dist = d
				closest = child
	return closest

func _calculate_placement_position(player: Node3D) -> Vector3:
	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if ray and ray is RayCast3D and ray.is_colliding():
		var col_pt = to_local(ray.get_collision_point())
		var clamped_x = clampf(col_pt.x, BOUNDS_X_MIN, BOUNDS_X_MAX)
		var clamped_z = clampf(col_pt.z, BOUNDS_Z_MIN, BOUNDS_Z_MAX)
		return to_global(Vector3(clamped_x, SURFACE_TOP_Y + 0.02, clamped_z))

	var forward_dir = -player.transform.basis.z
	var approx_pos = to_local(player.global_position + forward_dir * 1.0)
	var clamped_x = clampf(approx_pos.x, BOUNDS_X_MIN, BOUNDS_X_MAX)
	var clamped_z = clampf(approx_pos.z, BOUNDS_Z_MIN, BOUNDS_Z_MAX)
	return to_global(Vector3(clamped_x, SURFACE_TOP_Y + 0.02, clamped_z))

func _place_item_on_surface(item: Node3D, target_world_pos: Vector3, player_rot_y: float) -> void:
	var prev_parent = item.get_parent()
	if prev_parent:
		prev_parent.remove_child(item)

	var world_node: Node = get_parent()
	if not world_node:
		world_node = get_tree().current_scene
	if not world_node:
		world_node = get_tree().root

	world_node.add_child(item)
	item.global_position = target_world_pos
	item.rotation = Vector3(0, player_rot_y, 0)

	if item.has_method("on_dropped"):
		item.on_dropped()
	elif item.get("collision_shape") != null and item.collision_shape:
		item.collision_shape.disabled = false

	if "location" in item:
		item.location = Item.ItemLocation.WORLD
	if "_is_falling" in item:
		item._is_falling = false

	placed_items.append(item)
	_cleanup_placed_items()

func _process(_delta: float) -> void:
	_cleanup_placed_items()

func _cleanup_placed_items() -> void:
	var valid: Array[Node3D] = []
	for it in placed_items:
		if is_instance_valid(it) and it.is_inside_tree():
			if "location" in it and it.location == Item.ItemLocation.WORLD:
				var local_p = to_local(it.global_position)
				if absf(local_p.x) <= 2.0 and absf(local_p.z) <= 1.05 and local_p.y >= 0.7 and local_p.y <= 1.3:
					valid.append(it)
	placed_items = valid

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
