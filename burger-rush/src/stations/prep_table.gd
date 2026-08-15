class_name PrepTable
extends StaticBody3D

@export var max_items: int = 8

@onready var item_slot: Node3D = $ItemSlot
@onready var status_label: Label3D = $StatusLabel

var placed_items: Array[Node3D] = []

func _ready() -> void:
	_update_status_display()

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""

	var held = player.get("held_item")

	# 1. Se a mesa tiver um produto finalizado pronto
	if placed_items.size() == 1 and _is_finished_product(placed_items[0]):
		var prod_name = _get_item_label(placed_items[0])
		if held == null:
			return "E — Pegar %s Pronto" % prod_name
		return ""

	# 2. Se o jogador estiver segurando algo para colocar na mesa
	if held:
		return _get_place_prompt(held)

	# 3. Se a mesa tiver ingredientes e jogador estiver com mãos vazias
	if not placed_items.is_empty():
		var top_item = placed_items.back()
		return "E — Retirar %s" % _get_item_label(top_item)

	return ""

func _get_place_prompt(held_item: Node3D) -> String:
	if not held_item:
		return ""

	# Caso especial: Jogador segurando Bisnaga de Molho
	if held_item.has_method("consume_dose") or str(held_item.get("item_type")) == "sauce_bottle":
		var bottle = held_item
		var d_name = bottle.get_display_name() if bottle.has_method("get_display_name") else "Molho"
		var cur_charges: int = bottle.get("current_charges") if bottle.get("current_charges") != null else 5
		var max_charges: int = bottle.get("max_charges") if bottle.get("max_charges") != null else 5

		if not placed_items.is_empty() and not _is_finished_product(placed_items[0]):
			var can_ap = bottle.can_apply() if bottle.has_method("can_apply") else (cur_charges > 0)
			if can_ap:
				return "E — Aplicar %s no Lanche (%d/%d)" % [d_name, cur_charges, max_charges]
			else:
				return "🔴 %s Vazia! (Recarregar no Estoque)" % d_name
		elif placed_items.is_empty():
			return "E — Colocar %s na Bancada" % d_name
		return ""

	var item_name = _get_item_label(held_item)
	var held_id = str(held_item.get("item_id"))

	if placed_items.is_empty():
		if held_id == "bread_bottom":
			return "E — Colocar Base do Pão na Mesa"
		elif held_id == "bread":
			return "E — Colocar Pão na Mesa"
		return "E — Colocar %s na Mesa" % item_name

	if placed_items.size() >= max_items:
		return ""

	if held_id == "bread_top":
		return "E — Colocar Tampa do Pão e Fechar Lanche"

	return "E — Adicionar %s na Mesa" % item_name

func interact(player: Node3D) -> void:
	# 1. Mão vazia -> Retira item da mesa
	if player.get("held_item") == null:
		if not placed_items.is_empty():
			_give_top_item_to_player(player)
		return

	# 2. Mão ocupada com Bisnaga de Molho
	var held = player.get("held_item")
	if held.has_method("consume_dose") or str(held.get("item_type")) == "sauce_bottle":
		var bottle = held
		var d_name = bottle.get_display_name() if bottle.has_method("get_display_name") else "Molho"
		# Se há lanche em montagem na mesa, aplica molho sobre o lanche
		if not placed_items.is_empty() and not _is_finished_product(placed_items[0]):
			var ok = bottle.consume_dose() if bottle.has_method("consume_dose") else false
			if ok:
				# Cria um nó de molho aplicado para a receita
				var sauce_item = load("res://src/items/sauce.tscn").instantiate() as Node3D
				_place_item(sauce_item)
				var cur_c: int = bottle.get("current_charges") if bottle.get("current_charges") != null else 0
				_show_feedback(player, "🥫 %s aplicado no hambúrguer! (Restam %d doses)" % [d_name, cur_c])
			else:
				_show_feedback(player, "❌ Bisnaga vazia! Reabasteça no armazém.")
			return
		elif placed_items.is_empty():
			# Coloca a bisnaga na mesa
			if player.has_method("take_held_item"):
				var item = player.take_held_item()
				if item:
					_place_item(item)
			return

	# 3. Mão ocupada com ingrediente normal
	var prompt = _get_place_prompt(held)
	if prompt != "" and player.has_method("take_held_item"):
		var item: Node3D = player.take_held_item()
		if item:
			_place_item(item)

func _place_item(item: Node3D) -> void:
	var previous_parent = item.get_parent()
	if previous_parent:
		previous_parent.remove_child(item)

	if item_slot:
		item_slot.add_child(item)
	else:
		add_child(item)

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
			if item_slot and it.get_parent() == item_slot:
				item_slot.remove_child(it)
			it.queue_free()
		placed_items.clear()

		# Instancia e posiciona o produto final resultante
		var product = matching_recipe.result_scene.instantiate() as Node3D
		if "quality" in product:
			product.quality = avg_q

		if item_slot:
			item_slot.add_child(product)
		else:
			add_child(product)

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
	if item_slot and item.get_parent() == item_slot:
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
	if t == "final_product":
		return true
	# Legacy IDs
	if id in ["burger", "cheeseburger", "x_salada", "x_bacon"]:
		return true
	# Novos IDs do cardápio
	if id in [
		"burger_classic", "burger_double", "burger_cheddar", "burger_bacon",
		"burger_salad", "burger_onion", "burger_chicken", "burger_supreme",
		"burger_cheese", "burger_vegan", "burger_egg"
	]:
		return true
	return false

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
		# Pão
		"bread":
			return "Pão Brioche"
		"bread_bottom":
			return "Base do Pão"
		"bread_top":
			return "Tampa do Pão"
		# Carnes
		"patty", "patty_beef", "patty_beef:cooked", "patty_beef:raw":
			return "Carne Bovina"
		"patty_chicken", "patty_chicken:cooked", "patty_chicken:raw":
			return "Hamburguer de Frango"
		# Queijos
		"cheese", "cheese_cheddar":
			return "Queijo Cheddar"
		"cheese_mozzarella":
			return "Queijo Muçarela"
		"cheese_prato":
			return "Queijo Prato"
		# Vegetais
		"lettuce":
			return "Alface"
		"tomato":
			return "Tomate"
		"onion":
			return "Cebola"
		"red_onion":
			return "Cebola Roxa"
		"pickle":
			return "Picles"
		# Extras
		"bacon":
			return "Bacon"
		"egg":
			return "Ovo"
		# Molhos
		"sauce", "sauce_ketchup", "ketchup":
			return "Ketchup"
		"sauce_mustard", "mustard":
			return "Mostarda"
		"sauce_mayo", "mayo":
			return "Maionese"
		"sauce_special", "special_sauce":
			return "Molho Especial"
		# Produtos finais (legacy)
		"burger":
			return "Hambúrguer"
		"cheeseburger":
			return "Cheeseburger"
		"x_salada":
			return "X-Salada"
		"x_bacon":
			return "X-Bacon"
		# Produtos finais (novos)
		"burger_classic":
			return "Burger Clássico"
		"burger_double":
			return "Burger Duplo"
		"burger_cheddar":
			return "Burger Cheddar"
		"burger_bacon":
			return "Burger Bacon"
		"burger_salad":
			return "Burger Salada"
		"burger_onion":
			return "Burger Onion"
		"burger_chicken":
			return "Burger Chicken"
		"burger_supreme":
			return "Burger Supreme"
		"burger_cheese":
			return "Burger Três Queijos"
		"burger_vegan":
			return "Burger Vegano"
		"burger_egg":
			return "Burger Egg"
		_:
			return item.name if item_id == "" else item_id.capitalize()

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
