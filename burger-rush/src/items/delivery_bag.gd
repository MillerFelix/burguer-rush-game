class_name DeliveryBag
extends Item

# ================================================================
# SACO DE DELIVERY (EMBALAGEM DE PAPEL KRAFT PARA TRANSPORTE)
# Utilizado exclusivamente para pedidos de delivery
# Agrupa lanche na caixinha, batata frita no pacote e copo cheio
# ================================================================

@export var max_items: int = 4
var contained_items: Array[Dictionary] = []

@onready var model_root: Node3D = get_node_or_null("Model")
@onready var fold_top: MeshInstance3D = get_node_or_null("Model/FoldTop")
@onready var seal_mesh: MeshInstance3D = get_node_or_null("Model/Seal")
@onready var burger_visual: MeshInstance3D = get_node_or_null("Model/BurgerVisual")
@onready var fries_visual: Node3D = get_node_or_null("Model/FriesVisual")
@onready var drink_visual: Node3D = get_node_or_null("Model/DrinkVisual")

func _ready() -> void:
	item_id = "delivery_bag"
	display_name = "Saco de Delivery"
	item_type = "packaging"
	prompt_text = "🖱️ Pegar Saco de Delivery"
	_update_bag_visuals()

func get_display_name() -> String:
	if contained_items.is_empty():
		return "Saco de Delivery (Vazio)"
	var names: Array[String] = []
	for it in contained_items:
		names.append(str(it.get("name", "Item")))
	return "Saco de Delivery (%s)" % ", ".join(names)

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD:
		return ""
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if _is_unpackaged_burger(held):
			return "⚠️ Embale na Caixinha antes de colocar na Sacola"
		if held is DrinkCup and (held.fill_amount <= 0.001 or held.state == DrinkCup.State.EMPTY):
			return "⚠️ Encha o Copo antes de colocar na Sacola"
		if can_accept_item(held):
			var d_name = held.get_display_name() if held.has_method("get_display_name") else held.name
			return "🖱️ Colocar %s no Saco de Delivery" % d_name
		return ""
	return "🖱️ Pegar %s" % get_display_name()

func _is_unpackaged_burger(item: Node3D) -> bool:
	if not item:
		return false
	if item is PackagedBurger:
		return false
	if item.has_node("BurgerAssembly") or item.get("assembly") != null:
		return true
	var i_id = str(item.get("item_id"))
	if i_id in ["bread_bottom", "cheeseburger", "burger", "x_bacon", "x_salada"] and not item is PackagedBurger:
		return true
	return false

func can_accept_item(item: Node3D) -> bool:
	if item == null or contained_items.size() >= max_items:
		return false

	# Lanches NÃO embalados são estritamente rejeitados
	if _is_unpackaged_burger(item):
		return false

	# 1. Copo de bebida (deve estar cheio/com conteúdo)
	if item is DrinkCup:
		return item.fill_amount > 0.001 or item.state != DrinkCup.State.EMPTY
	if str(item.get("item_id")).begins_with("soda_") or str(item.get("item_id")).begins_with("juice_"):
		return true

	# 2. Lanche devidamente embalado na caixinha
	if item is PackagedBurger:
		return true
	if item is BurgerBox and str(item.get("item_type")) == "final_product":
		return true

	# 3. Batata frita ou Cebola frita na embalagem
	if item is FriesPack or str(item.get("item_id")) in ["fries_pack", "potato_box", "fries", "onion_rings", "fried_onions"]:
		return true

	return false

func add_contained_item(item: Node3D) -> bool:
	if not can_accept_item(item):
		return false

	var rec_id = ""
	if item is PackagedBurger and item.get("recipe_id") != null:
		rec_id = str(item.recipe_id)
	elif item is DrinkCup and item.get("flavor") != null and item.flavor != "":
		rec_id = str(item.flavor)

	var itm_id = item.get("item_id") if "item_id" in item else item.name
	if item is DrinkCup and item.get("flavor") != null and item.flavor != "":
		itm_id = str(item.flavor)

	var itm_name = item.get_display_name() if item.has_method("get_display_name") else item.name

	var item_dict = {
		"id": itm_id,
		"recipe_id": rec_id,
		"name": itm_name,
		"type": item.get("item_type") if "item_type" in item else "food"
	}
	contained_items.append(item_dict)

	if item.is_inside_tree():
		item.queue_free()

	display_name = get_display_name()
	_update_bag_visuals()
	return true

func add_item_data(data: Dictionary) -> void:
	contained_items.append(data)
	display_name = get_display_name()
	_update_bag_visuals()

func get_products() -> Array:
	return contained_items

func get_contained_product_ids() -> Array[String]:
	var ids: Array[String] = []
	for it in contained_items:
		var id = str(it.get("id", ""))
		if id != "":
			ids.append(id)
		var rec = str(it.get("recipe_id", ""))
		if rec != "" and not ids.has(rec):
			ids.append(rec)
	return ids

func is_empty() -> bool:
	return contained_items.is_empty()

func has_drink() -> bool:
	for itm in contained_items:
		var id: String = itm.get("id", "")
		if id.begins_with("soda_") or id.begins_with("juice_") or id == "drink_cup":
			return true
	return false

func has_burger() -> bool:
	for itm in contained_items:
		var id: String = itm.get("id", "")
		var rec: String = itm.get("recipe_id", "")
		if id in ["packaged_burger", "burger_box", "cheeseburger", "burger", "x_bacon", "x_salada"] or rec != "":
			return true
	return false

func has_fries() -> bool:
	for itm in contained_items:
		var id: String = itm.get("id", "")
		if id in ["fries_pack", "potato_box", "fries"]:
			return true
	return false

func interact_item(player: Node3D) -> void:
	if not player:
		return

	var held = player.get("held_item")

	# Se jogador estiver segurando item: tenta colocar na sacola
	if held != null and held != self:
		if _is_unpackaged_burger(held):
			_show_feedback(player, "⚠️ Embale o hambúrguer na caixinha antes de colocar na sacola!")
			return

		if held is DrinkCup and (held.fill_amount <= 0.001 or held.state == DrinkCup.State.EMPTY):
			_show_feedback(player, "⚠️ Encha o copo de bebida antes de colocar na sacola!")
			return

		if can_accept_item(held):
			var taken = player.take_held_item()
			if taken:
				var d_name = taken.get_display_name() if taken.has_method("get_display_name") else taken.name
				add_contained_item(taken)
				_show_feedback(player, "🛍️ %s colocado na sacola de delivery" % d_name)
		else:
			_show_feedback(player, "⚠️ Este item não pode ser colocado na sacola.")
		return

	# Se estiver de mãos livres: pega a sacola
	if held == null:
		if player.has_method("pick_up"):
			player.pick_up(self)
			_show_feedback(player, "🛍️ Pegou %s" % get_display_name())

func _update_bag_visuals() -> void:
	if not burger_visual:
		burger_visual = get_node_or_null("Model/BurgerVisual")
	if not fries_visual:
		fries_visual = get_node_or_null("Model/FriesVisual")
	if not drink_visual:
		drink_visual = get_node_or_null("Model/DrinkVisual")
	if not fold_top:
		fold_top = get_node_or_null("Model/FoldTop")
	if not seal_mesh:
		seal_mesh = get_node_or_null("Model/Seal")

	var has_b = has_burger()
	var has_f = has_fries()
	var has_d = has_drink()

	if burger_visual:
		burger_visual.visible = has_b
	if fries_visual:
		fries_visual.visible = has_f
	if drink_visual:
		drink_visual.visible = has_d

	# Se houver itens dentro, a sacola mostra os produtos no topo aberto
	if fold_top:
		fold_top.visible = contained_items.is_empty()
	if seal_mesh:
		seal_mesh.visible = contained_items.is_empty()

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
