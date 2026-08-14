class_name Item
extends StaticBody3D

enum ItemLocation {
	WORLD,
	PLAYER_HAND,
	STATION,
	TRAY,
	TABLE,
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
@export var quality: QualityLevel = QualityLevel.GOOD

var location: ItemLocation = ItemLocation.WORLD
var _is_falling: bool = false

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

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

func _physics_process(delta: float) -> void:
	if location == ItemLocation.WORLD and _is_falling:
		var world_3d = get_world_3d()
		if not world_3d:
			_is_falling = false
			return

		var space_state = world_3d.direct_space_state
		var ray_start = global_position + Vector3.UP * 0.1
		var ray_end = global_position + Vector3.DOWN * 10.0
		var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		query.exclude = [get_rid()]

		var result = space_state.intersect_ray(query)
		if result:
			var target_y = result.position.y + 0.02
			if global_position.y > target_y + 0.04:
				global_position.y = move_toward(global_position.y, target_y, 9.8 * delta)
			else:
				global_position.y = target_y
				_is_falling = false
		else:
			if global_position.y > 0.02:
				global_position.y = move_toward(global_position.y, 0.02, 9.8 * delta)
			else:
				global_position.y = 0.02
				_is_falling = false

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD:
		return ""

	if player and player.get("held_item") != null:
		return ""

	if prompt_text != "":
		return prompt_text
	return "E — Pegar %s" % get_display_name()

func interact(player: Node3D) -> void:
	if location == ItemLocation.WORLD and player.has_method("pick_up"):
		player.pick_up(self)

func on_picked_up() -> void:
	location = ItemLocation.PLAYER_HAND
	_is_falling = false
	if collision_shape:
		collision_shape.disabled = true

func on_dropped() -> void:
	location = ItemLocation.WORLD
	_is_falling = true
	if collision_shape:
		collision_shape.disabled = false

func on_placed_in_station() -> void:
	location = ItemLocation.STATION
	_is_falling = false
	if collision_shape:
		collision_shape.disabled = true

func on_placed_in_tray() -> void:
	location = ItemLocation.TRAY
	_is_falling = false
	if collision_shape:
		collision_shape.disabled = true

func on_placed_on_table() -> void:
	location = ItemLocation.TABLE
	_is_falling = false
	if collision_shape:
		collision_shape.disabled = true

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
