class_name PrepTable
extends StaticBody3D

@export var max_items: int = 6

@onready var item_slot: Node3D = $ItemSlot
@onready var status_label: Label3D = $StatusLabel

var placed_items: Array[Node3D] = []

# Propriedade de compatibilidade reversa
var current_item: Node3D:
	get:
		return placed_items[0] if not placed_items.is_empty() else null
	set(value):
		if value == null:
			placed_items.clear()
		else:
			placed_items = [value]

func _ready() -> void:
	_update_status_display()

func get_interaction_prompt(player: Node = null) -> String:
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		return _get_place_prompt(held)

	# Jogador com mão vazia
	if not placed_items.is_empty():
		var top_item = placed_items.back()
		if placed_items.size() == 1 and _is_finished_product(top_item):
			return "E — Pegar %s" % _get_item_label(top_item)
		elif placed_items.size() == 1:
			return "E — Pegar %s" % _get_item_label(top_item)
		else:
			return "E — Retirar %s (Desfazer)" % _get_item_label(top_item)

	return ""

func _get_place_prompt(held_item: Node3D) -> String:
	if not held_item:
		return ""

	var item_name = _get_item_label(held_item)

	if placed_items.is_empty():
		return "E — Colocar %s na Mesa" % item_name

	# Se a mesa atingiu o limite
	if placed_items.size() >= max_items:
		return ""

	return "E — Adicionar %s na Mesa" % item_name

func interact(player: Node3D) -> void:
	# Mão vazia -> Retira item da mesa
	if player.get("held_item") == null:
		if not placed_items.is_empty():
			_give_top_item_to_player(player)
		return

	# Mão ocupada -> Tenta colocar item na mesa
	var held = player.get("held_item")
	var prompt = _get_place_prompt(held)
	if prompt != "" and player.has_method("take_held_item"):
		var item: Node3D = player.take_held_item()
		if item:
			_place_item(item)

func _place_item(item: Node3D) -> void:
	var previous_parent = item.get_parent()
	if previous_parent:
		previous_parent.remove_child(item)

	item_slot.add_child(item)
	item.position = Vector3(0, placed_items.size() * 0.04, 0)
	item.rotation = Vector3.ZERO

	if item.has_method("on_picked_up"):
		item.on_picked_up()
	elif item.get("collision_shape") != null:
		item.collision_shape.disabled = true

	placed_items.append(item)
	_check_recipe_assembly()
	_update_status_display()

func _check_recipe_assembly() -> void:
	var keys: Array[String] = []
	for it in placed_items:
		keys.append(_get_item_ingredient_key(it))

	var matching_recipe = RecipeDatabase.find_matching_recipe(keys)
	if matching_recipe and matching_recipe.result_scene:
		var total_q = 0
		for it in placed_items:
			total_q += it.get("quality") if it.get("quality") != null else 2
		var avg_q = maxi(1, int(round(float(total_q) / float(maxi(1, placed_items.size())))))

		# Remove e libera os ingredientes consumidos
		for it in placed_items:
			if it.get_parent() == item_slot:
				item_slot.remove_child(it)
			it.queue_free()
		placed_items.clear()

		# Instancia e posiciona o produto final resultante
		var product = matching_recipe.result_scene.instantiate() as Node3D
		if "quality" in product:
			product.quality = avg_q

		item_slot.add_child(product)
		product.position = Vector3.ZERO
		product.rotation = Vector3.ZERO

		if product.has_method("on_picked_up"):
			product.on_picked_up()
		elif product.get("collision_shape") != null:
			product.collision_shape.disabled = true

		placed_items.append(product)

func _give_top_item_to_player(player: Node3D) -> void:
	if placed_items.is_empty():
		return

	var item = placed_items.pop_back()
	if item.get_parent() == item_slot:
		item_slot.remove_child(item)

	if player.has_method("pick_up"):
		player.pick_up(item)

	_update_status_display()

func _update_status_display() -> void:
	if not status_label:
		return

	if placed_items.is_empty():
		status_label.text = "🥪 MESA DE MONTAGEM"
		status_label.modulate = Color(0.7, 0.7, 0.7, 1.0)
		return

	if placed_items.size() == 1 and _is_finished_product(placed_items[0]):
		status_label.text = "✨ %s Pronto!" % _get_item_label(placed_items[0])
		status_label.modulate = Color(0.3, 1.0, 0.4, 1.0)
		return

	var names: Array[String] = []
	for it in placed_items:
		names.append(_get_item_label(it))
	status_label.text = "Montando:\n" + " + ".join(names)
	status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)

func _is_finished_product(item: Node3D) -> bool:
	var id: String = str(item.get("item_id")) if item.get("item_id") != null else ""
	var t: String = str(item.get("item_type")) if item.get("item_type") != null else ""
	return t == "final_product" or id in ["burger", "cheeseburger"]

func _get_item_ingredient_key(item: Node3D) -> String:
	if not item:
		return ""
	if item.has_method("get_ingredient_key"):
		return item.get_ingredient_key()
	if item.get("item_id") != null:
		return str(item.get("item_id"))
	return ""

func _get_item_label(item: Node3D) -> String:
	if not item:
		return "Item"
	if item.has_method("get_display_name"):
		return item.get_display_name()

	var item_id: String = str(item.get("item_id")) if item.get("item_id") != null else ""
	match item_id:
		"bread":
			return "Pão"
		"cheese":
			return "Queijo"
		"patty":
			return "Carne"
		"burger":
			return "Hambúrguer"
		"cheeseburger":
			return "Cheeseburger"
		_:
			return item.name if item_id == "" else item_id.capitalize()
