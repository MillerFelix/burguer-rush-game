class_name BurgerAssembly
extends Node3D

# ================================================================
# BURGER ASSEMBLY — ENTIDADE UNIFICADA DE MONTAGEM FÍSICA
#
# Hierarquia lógica:
#  BreadBottom (base_bun)
#   └── BurgerAssembly (self)
#        ├── Patty (filho local)
#        ├── Cheese (filho local)
#        ├── Vegetables (filhos locais)
#        ├── Sauces (mesh instanciados como filhos locais)
#        └── TopBun (filho local)
#
# Todos os ingredientes e molhos acompanham o lanche quando ele é:
#  - movido
#  - pego na mão
#  - solto com [E] em qualquer superfície
#  - embalado na caixa
# ================================================================

enum State {
	EMPTY,
	ASSEMBLING,
	CLOSED,
	PACKAGED
}

@export var state: State = State.EMPTY

var base_bun: Item = null
var ingredients: Array[Item] = []
var ingredient_keys: Array[String] = []
var top_bun: Item = null

var applied_sauces: Dictionary = {} # {"ketchup": 45.0, "mustard": 30.0}
var sauce_visuals: Array[Node3D] = []

var matched_recipe: Recipe = null
var is_valid_recipe: bool = false

var current_stack_height: float = 0.038
const PACKAGED_BURGER_SCENE = preload("res://src/items/packaged_burger.tscn")

@onready var status_label: Label3D = get_node_or_null("StatusLabel")

func _ready() -> void:
	_update_status()

# Adiciona um ingrediente físico como filho da montagem do lanche
func add_ingredient(item: Item, hit_pos: Vector3, player_rot_y: float = 0.0) -> bool:
	if state == State.CLOSED or state == State.PACKAGED:
		return false
	if not item or item == base_bun or item == self or ingredients.has(item):
		return false

	var ing_key = _extract_ingredient_key(item)
	if ing_key == "":
		return false

	var prev_parent = item.get_parent()
	if prev_parent:
		item.owner = null
		prev_parent.remove_child(item)

	# Adiciona diretamente como filho do BurgerAssembly
	add_child(item)
	item.owner = null

	var local_hit = to_local(hit_pos) if is_inside_tree() else (hit_pos - position)
	var offset_x = clampf(local_hit.x, -0.07, 0.07)
	var offset_z = clampf(local_hit.z, -0.07, 0.07)
	var base_rot = (base_bun.global_rotation.y if base_bun.is_inside_tree() else base_bun.rotation.y) if base_bun else 0.0
	item.position = Vector3(offset_x, current_stack_height, offset_z)
	item.rotation = Vector3(0, player_rot_y - base_rot, 0)

	# Mantém colisão ativada para raycast e meta tags para identificar o conjunto
	if item.get("collision_shape") != null and item.collision_shape:
		item.collision_shape.disabled = false
	item.collision_layer = 1
	item.collision_mask = 1
	item.set_meta("burger_assembly", self)
	item.set_meta("burger_base", base_bun)

	if "location" in item:
		item.location = Item.ItemLocation.WORLD

	var thickness = _get_ingredient_thickness(ing_key)
	current_stack_height += thickness

	ingredients.append(item)
	ingredient_keys.append(ing_key)
	state = State.ASSEMBLING

	_check_recipe_match()
	_update_status()
	return true

# Aplicação de molho: o molho pertence ao lanche e é instanciado como filho
var _last_sauce_pos: Dictionary = {} # { "ketchup": Vector3, ... }

func apply_sauce(sauce_type: String, sauce_color: Color, hit_world_pos: Vector3, delta: float) -> void:
	if state == State.CLOSED or state == State.PACKAGED:
		return

	var current_qty: float = applied_sauces.get(sauce_type, 0.0)
	if current_qty >= 100.0:
		return # Quantidade máxima já atingida para este molho

	current_qty = minf(100.0, current_qty + delta * 35.0)
	applied_sauces[sauce_type] = current_qty

	var norm_sauce_key = sauce_type
	if not ingredient_keys.has(norm_sauce_key) and current_qty >= 20.0:
		ingredient_keys.append(norm_sauce_key)

	var local_hit = to_local(hit_world_pos) if is_inside_tree() else (hit_world_pos - position)
	var h_dist = Vector2(local_hit.x, local_hit.z).length()
	if h_dist > 0.072:
		var n_dir = Vector2(local_hit.x, local_hit.z).normalized()
		local_hit.x = n_dir.x * 0.072
		local_hit.z = n_dir.y * 0.072

	var target_local = Vector3(local_hit.x, current_stack_height + 0.002, local_hit.z)
	_add_rich_sauce_element(sauce_type, sauce_color, target_local)

	state = State.ASSEMBLING
	_check_recipe_match()
	_update_status()

func _add_rich_sauce_element(sauce_type: String, col: Color, local_pt: Vector3) -> void:
	# Material ultra-brilhante, viscoso e molhado
	var mat = StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.06
	mat.clearcoat_enabled = true
	mat.clearcoat = 1.0
	mat.clearcoat_roughness = 0.03
	mat.metallic_specular = 0.85

	# 1. Verifica se há uma gota recente próxima para expandir seu volume
	var expanded = false
	for vis in sauce_visuals:
		if is_instance_valid(vis) and vis.has_meta("sauce_type") and vis.get_meta("sauce_type") == sauce_type:
			if absf(vis.position.y - local_pt.y) < 0.008:
				var dist_2d = Vector2(vis.position.x - local_pt.x, vis.position.z - local_pt.z).length()
				if dist_2d < 0.022:
					if vis.scale.x < 1.7:
						vis.scale += Vector3(0.08, 0.04, 0.08)
					expanded = true
					break

	# 2. Se não expandiu e não atingiu o limite de nós visuais, instancia nova gota 3D espessa
	if not expanded and sauce_visuals.size() < 50:
		var dollop = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.022
		sphere_mesh.height = 0.012
		sphere_mesh.radial_segments = 14
		sphere_mesh.rings = 6
		dollop.mesh = sphere_mesh
		dollop.material_override = mat
		dollop.set_meta("sauce_type", sauce_type)

		add_child(dollop)
		dollop.position = local_pt
		sauce_visuals.append(dollop)

		# 3. Se houver ponto anterior próximo, conecta com uma faixa/cordão espesso e fluido
		if _last_sauce_pos.has(sauce_type):
			var prev_pt: Vector3 = _last_sauce_pos[sauce_type]
			var seg_vec = local_pt - prev_pt
			var seg_len = seg_vec.length()
			if seg_len > 0.015 and seg_len < 0.06 and absf(prev_pt.y - local_pt.y) < 0.008:
				var ribbon = MeshInstance3D.new()
				var cyl_mesh = CylinderMesh.new()
				cyl_mesh.top_radius = 0.012
				cyl_mesh.bottom_radius = 0.012
				cyl_mesh.height = seg_len
				cyl_mesh.radial_segments = 10
				ribbon.mesh = cyl_mesh
				ribbon.material_override = mat
				ribbon.set_meta("sauce_type", sauce_type)

				add_child(ribbon)
				ribbon.position = prev_pt.lerp(local_pt, 0.5)

				var up_dir = seg_vec.normalized()
				if absf(up_dir.dot(Vector3.UP)) < 0.99:
					ribbon.look_at_from_position(ribbon.position, ribbon.position + seg_vec, Vector3.UP)
					ribbon.rotate_object_local(Vector3.RIGHT, deg_to_rad(90.0))
				sauce_visuals.append(ribbon)

	_last_sauce_pos[sauce_type] = local_pt

# Fecha o lanche colocando o pão superior (bread_top) como filho da montagem
func close_burger(bun_top_item: Item, hit_pos: Vector3, player_rot_y: float = 0.0) -> bool:
	if state == State.CLOSED or state == State.PACKAGED:
		return false
	if not bun_top_item:
		return false

	var prev_parent = bun_top_item.get_parent()
	if prev_parent:
		bun_top_item.owner = null
		prev_parent.remove_child(bun_top_item)

	add_child(bun_top_item)
	bun_top_item.owner = null

	var local_hit = to_local(hit_pos) if is_inside_tree() else (hit_pos - position)
	var offset_x = clampf(local_hit.x, -0.06, 0.06)
	var offset_z = clampf(local_hit.z, -0.06, 0.06)
	var base_rot = (base_bun.global_rotation.y if base_bun.is_inside_tree() else base_bun.rotation.y) if base_bun else 0.0
	bun_top_item.position = Vector3(offset_x, current_stack_height, offset_z)
	bun_top_item.rotation = Vector3(0, player_rot_y - base_rot, 0)

	if bun_top_item.get("collision_shape") != null and bun_top_item.collision_shape:
		bun_top_item.collision_shape.disabled = false
	bun_top_item.collision_layer = 1
	bun_top_item.collision_mask = 1
	bun_top_item.set_meta("burger_assembly", self)
	bun_top_item.set_meta("burger_base", base_bun)

	if "location" in bun_top_item:
		bun_top_item.location = Item.ItemLocation.WORLD

	top_bun = bun_top_item
	state = State.CLOSED

	_check_recipe_match()
	_update_status()
	return true

func can_package() -> bool:
	return state == State.CLOSED

# Converte o conjunto inteiro no produto final embalado
func package_burger(box_item: Item, player: Node3D = null) -> PackagedBurger:
	if not can_package():
		return null

	var spawn_pos = (base_bun.global_position if (base_bun and base_bun.is_inside_tree()) else (base_bun.position if base_bun else position))

	var world_node: Node = null
	if base_bun and base_bun.get_parent():
		world_node = base_bun.get_parent()
	if not world_node and is_inside_tree():
		world_node = get_tree().current_scene
	if not world_node and is_inside_tree():
		world_node = get_tree().root

	var packaged: PackagedBurger = PACKAGED_BURGER_SCENE.instantiate() as PackagedBurger
	if world_node:
		world_node.add_child(packaged)
	if packaged.is_inside_tree():
		packaged.global_position = spawn_pos
	else:
		packaged.position = spawn_pos
	if base_bun:
		packaged.rotation = base_bun.rotation
	if "location" in packaged:
		packaged.location = Item.ItemLocation.WORLD

	packaged.setup_from_recipe(matched_recipe, ingredient_keys, is_valid_recipe)

	if player and player.has_method("get_node_or_null"):
		var hud = player.get_node_or_null("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback("📦 %s embalado com sucesso!" % packaged.burger_name)

	# Limpa os objetos físicos da montagem convertida
	for ing in ingredients:
		if is_instance_valid(ing):
			ing.queue_free()
	for s_vis in sauce_visuals:
		if is_instance_valid(s_vis):
			s_vis.queue_free()
	if top_bun and is_instance_valid(top_bun):
		top_bun.queue_free()
	if box_item and is_instance_valid(box_item):
		box_item.queue_free()

	state = State.PACKAGED

	if base_bun and is_instance_valid(base_bun):
		base_bun.queue_free()
	else:
		queue_free()

	return packaged

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""

	var held = player.get("held_item")
	if held != null:
		var held_id = str(held.get("item_id"))

		if held is SauceBottle or str(held.get("item_type")) == "sauce_bottle":
			var d_name = held.get_display_name() if held.has_method("get_display_name") else "Molho"
			return "🖱️ (Segurar) Aplicar %s no Lanche" % d_name

		if held is BurgerBox or held_id == "burger_box" or str(held.get("item_type")) == "packaging":
			if state == State.CLOSED:
				var b_name = matched_recipe.display_name if matched_recipe else "Burger Artesanal"
				return "🖱️ Embalar %s na Caixa" % b_name
			else:
				return "⚠️ Feche o lanche com a tampa do pão antes de embalar"

		if held_id == "bread_top" or (held_id == "bread" and state == State.ASSEMBLING):
			return "🖱️ Fechar Lanche com Tampa do Pão"

		if str(held.get("item_type")) == "ingredient" or held.has_method("get_ingredient_key"):
			var d_name = held.get_display_name() if held.has_method("get_display_name") else held.name
			return "🖱️ Adicionar %s ao Lanche" % d_name

	if state == State.CLOSED:
		var b_name = matched_recipe.display_name if matched_recipe else "Burger"
		return "🍔 %s (Fechado) — [Clique] Pegar Lanche" % b_name
	elif state == State.ASSEMBLING:
		return "🥪 Lanche em Montagem (%d ing.) — [Clique] Pegar Lanche" % ingredients.size()

	return "🖱️ Pegar Base do Pão"

func interact_item(player: Node3D) -> void:
	if not player:
		return

	var held = player.get("held_item")
	if held == null or held == base_bun or held == self:
		# Mãos livres -> pega o lanche inteiro
		if base_bun and is_instance_valid(base_bun) and player.has_method("pick_up"):
			player.pick_up(base_bun)
		return

	var held_id = str(held.get("item_id"))
	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	var hit_pos = ray.get_collision_point() if (ray and ray is RayCast3D and ray.is_colliding()) else (global_position if is_inside_tree() else Vector3.ZERO)

	if held is SauceBottle or str(held.get("item_type")) == "sauce_bottle":
		return

	if held is BurgerBox or held_id == "burger_box" or str(held.get("item_type")) == "packaging":
		if state == State.CLOSED:
			var box = player.take_held_item()
			package_burger(box, player)
		else:
			_show_player_feedback(player, "⚠️ Coloque o pão superior para fechar o lanche antes de embalar.")
		return

	if held_id == "bread_top" or (held_id == "bread" and state == State.ASSEMBLING):
		var bun_top = player.take_held_item()
		close_burger(bun_top, hit_pos, player.rotation.y)
		var b_name = matched_recipe.display_name if matched_recipe else "Burger Artesanal"
		_show_player_feedback(player, "🍔 %s finalizado! Pronto para embalar." % b_name)
		return

	if str(held.get("item_type")) == "ingredient" or held.has_method("get_ingredient_key"):
		var ing = player.take_held_item()
		add_ingredient(ing, hit_pos, player.rotation.y)
		var d_name = ing.get_display_name() if ing.has_method("get_display_name") else ing.name
		_show_player_feedback(player, "+ %s adicionado ao lanche" % d_name)
		return

func _extract_ingredient_key(item: Item) -> String:
	if not item:
		return ""
	if item.has_method("get_ingredient_key"):
		return item.get_ingredient_key()
	var raw_id = item.item_id
	if "state" in item and raw_id in ["patty", "bacon", "egg"]:
		var st = item.get("state")
		if raw_id == "patty":
			return "patty_beef:cooked" if st == 2 else "patty_beef:raw"
		elif raw_id == "bacon":
			return "bacon" if st == 2 else "bacon:raw"
		elif raw_id == "egg":
			return "egg" if st == 3 else "egg:raw"
	return raw_id

func _get_ingredient_thickness(ing_key: String) -> float:
	var base = ing_key.split(":")[0]
	match base:
		"patty", "patty_beef", "patty_chicken":
			return 0.024
		"cheese", "cheese_cheddar", "cheese_prato", "cheese_mozzarella":
			return 0.008
		"lettuce":
			return 0.016
		"tomato":
			return 0.015
		"onion", "red_onion":
			return 0.012
		"pickle":
			return 0.008
		"bacon":
			return 0.008
		"egg":
			return 0.018
		"bread_top":
			return 0.035
		_:
			return 0.014

func _check_recipe_match() -> void:
	var all_keys: Array[String] = ["bread"]
	all_keys.append_array(ingredient_keys)

	matched_recipe = null
	is_valid_recipe = false

	var recipes = RecipeDatabase.get_all_recipes()
	for r in recipes:
		if r.category == "burger" and r.matches(all_keys):
			matched_recipe = r
			is_valid_recipe = true
			break

func _update_status() -> void:
	if not status_label:
		status_label = get_node_or_null("StatusLabel")
	if not status_label:
		return

	match state:
		State.EMPTY:
			status_label.text = ""
		State.ASSEMBLING:
			var txt = "🍔 Montando (" + str(ingredients.size()) + " ing.)"
			if not applied_sauces.is_empty():
				txt += "\n"
				var sauce_txts: Array[String] = []
				for s_type in applied_sauces.keys():
					sauce_txts.append("🥫 %s" % s_type.capitalize())
				txt += " │ ".join(sauce_txts)
			if matched_recipe:
				txt += "\n✓ " + matched_recipe.display_name
			status_label.text = txt
			status_label.modulate = Color(1.0, 0.9, 0.4, 0.9)
		State.CLOSED:
			if matched_recipe:
				status_label.text = "✓ %s\n📦 Pegue uma caixa para embalar" % matched_recipe.display_name
				status_label.modulate = Color(0.3, 1.0, 0.4, 1.0)
			else:
				status_label.text = "🍔 Burger Personalizado\n📦 Pegue uma caixa para embalar"
				status_label.modulate = Color(1.0, 0.7, 0.2, 1.0)
		State.PACKAGED:
			status_label.text = ""

func _show_player_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)

func get_summary() -> Dictionary:
	return {
		"state": state,
		"ingredient_keys": ingredient_keys.duplicate(),
		"applied_sauces": applied_sauces.duplicate(),
		"recipe_id": matched_recipe.id if matched_recipe else "",
		"recipe_name": matched_recipe.display_name if matched_recipe else "Custom",
		"is_valid": is_valid_recipe,
		"is_closed": (state == State.CLOSED),
		"is_packaged": (state == State.PACKAGED)
	}
