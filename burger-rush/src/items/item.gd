class_name Item
extends StaticBody3D

enum ItemLocation {
	WORLD,
	PLAYER_HAND,
	STATION,
	TRAY,
	TABLE,
	FRIDGE,
	CONSUMED
}

enum QualityLevel {
	BASIC = 1,
	GOOD = 2,
	PREMIUM = 3,
	ARTISAN = 4
}

@export var item_id: String = "generic"
@export var display_name: String = ""
@export var item_type: String = "ingredient" # ingredient, processed, final_product, packaging, tool, storage_box
@export var prompt_text: String = ""
@export var is_packaged: bool = false
@export var is_grillable: bool = false
@export var quality: QualityLevel = QualityLevel.GOOD

var location: ItemLocation = ItemLocation.WORLD
var is_held: bool = false
var _is_falling: bool = false

func is_cookable_on_grill() -> bool:
	return is_grillable

func get_quality_name() -> String:
	match quality:
		QualityLevel.BASIC:
			return "Básico"
		QualityLevel.GOOD:
			return "Bom"
		QualityLevel.PREMIUM:
			return "Premium"
		QualityLevel.ARTISAN:
			return "Artesanal"
	return "Padrão"

@export var bottom_offset: float = 0.002

func _ready() -> void:
	if not _is_falling:
		set_physics_process(false)

var _cached_col_rids: Array[RID] = []

func _get_self_col_rids() -> Array[RID]:
	if _cached_col_rids.is_empty():
		_cached_col_rids.append(get_rid())
		for child in find_children("*", "CollisionObject3D", true, false):
			if child is CollisionObject3D:
				_cached_col_rids.append(child.get_rid())
	return _cached_col_rids

func _physics_process(delta: float) -> void:
	if location != ItemLocation.WORLD or not _is_falling:
		_is_falling = false
		set_physics_process(false)
		return

	var world_3d = get_world_3d()
	if not world_3d:
		_is_falling = false
		set_physics_process(false)
		return

	var space_state = world_3d.direct_space_state
	var ray_start = global_position + Vector3.UP * 0.1
	var ray_end = global_position + Vector3.DOWN * 10.0
	var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
	query.exclude = _get_self_col_rids()

	var result = space_state.intersect_ray(query)
	if result:
		var target_y = result.position.y + bottom_offset
		if global_position.y > target_y + 0.03:
			global_position.y = move_toward(global_position.y, target_y, 9.8 * delta)
		else:
			global_position.y = target_y
			_is_falling = false
			set_physics_process(false)
	else:
		if global_position.y > bottom_offset:
			global_position.y = move_toward(global_position.y, bottom_offset, 9.8 * delta)
		else:
			global_position.y = bottom_offset
			_is_falling = false
			set_physics_process(false)

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD and location != ItemLocation.TRAY and location != ItemLocation.TABLE and location != ItemLocation.STATION:
		return ""

	if player and player.get("held_item") != null:
		return ""

	return "🖱️ Pegar %s" % get_display_name()

func interact(player: Node3D) -> void:
	if (location == ItemLocation.WORLD or location == ItemLocation.TRAY or location == ItemLocation.TABLE or location == ItemLocation.STATION) and player.has_method("pick_up"):
		player.pick_up(self)

func on_picked_up() -> void:
	is_held = true
	location = ItemLocation.PLAYER_HAND
	_is_falling = false
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	_set_all_colliders_disabled(self, true)

func on_dropped() -> void:
	is_held = false
	location = ItemLocation.WORLD
	_is_falling = true
	set_physics_process(true)
	collision_layer = 1
	collision_mask = 1
	_set_all_colliders_disabled(self, false)

func on_placed_in_station() -> void:
	is_held = false
	location = ItemLocation.STATION
	_is_falling = false
	set_physics_process(false)
	collision_layer = 1
	collision_mask = 1
	_set_all_colliders_disabled(self, false)

func on_placed_in_tray() -> void:
	is_held = false
	location = ItemLocation.TRAY
	_is_falling = false
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	_set_all_colliders_disabled(self, true)

func on_placed_on_table() -> void:
	is_held = false
	location = ItemLocation.TABLE
	_is_falling = false
	set_physics_process(false)
	collision_layer = 1
	collision_mask = 1
	_set_all_colliders_disabled(self, false)

func on_stored_in_fridge() -> void:
	is_held = false
	location = ItemLocation.FRIDGE
	_is_falling = false
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	_set_all_colliders_disabled(self, true)

func _set_all_colliders_disabled(node: Node, is_disabled: bool) -> void:
	if node is CollisionShape3D:
		node.disabled = is_disabled
	if node is CollisionObject3D:
		node.collision_layer = 0 if is_disabled else 1
		node.collision_mask = 0 if is_disabled else 1
	for child in node.get_children():
		_set_all_colliders_disabled(child, is_disabled)

func get_ingredient_key() -> String:
	return item_id

func get_display_name() -> String:
	if display_name != "":
		return display_name

	match item_id:
		"patty":
			return "Carne"
		"bread":
			return "Pão"
		"cheese":
			return "Queijo"
		"burger":
			return "Hambúrguer"
		"cheeseburger":
			return "Cheeseburger"
		"x_salada":
			return "X-Salada"
		"x_bacon":
			return "X-Bacon"
		"lettuce":
			return "Alface"
		"tomato":
			return "Tomate"
		"onion":
			return "Cebola"
		"bacon":
			return "Bacon"
		"sauce":
			return "Molho Ketchup"
		"potato_raw":
			return "Batata Crua"
		"potato_box":
			return "Recipiente de Batata"
		"fries":
			return "Batata Frita"
		"cup_empty":
			return "Copo Descartável"
		"cup_lid":
			return "Tampa de Copo"
		"syrup_soda":
			return "Xarope de Refrigerante"
		"soda":
			return "Refrigerante"
		"burger_box":
			return "Caixa de Hambúrguer"
		"delivery_box":
			return "Caixa de Mercadoria"
		"order_tray":
			return "Bandeja"
		"generic":
			return "Item"
		_:
			return name if item_id == "" else item_id.capitalize()
