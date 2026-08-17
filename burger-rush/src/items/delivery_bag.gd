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

func _ready() -> void:
	item_id = "delivery_bag"
	display_name = "Saco de Delivery"
	item_type = "packaging"
	prompt_text = "🖱️ Pegar Saco de Delivery"
	_update_bag_visuals()

func get_display_name() -> String:
	if contained_items.is_empty():
		return "Saco de Delivery (Vazio)"
	return "Saco de Delivery (%d itens)" % contained_items.size()

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD:
		return ""
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if can_accept_item(held):
			var d_name = held.get_display_name() if held.has_method("get_display_name") else held.name
			return "🖱️ Colocar %s no Saco de Delivery" % d_name
		return ""
	return "🖱️ Pegar %s" % get_display_name()

func can_accept_item(item: Node3D) -> bool:
	if item == null or contained_items.size() >= max_items:
		return false
	
	# 1. Copo cheio/selado
	if item is DrinkCup or (item.has_method("has_lid") and item.has_lid()) or str(item.get("item_id")).begins_with("soda_") or str(item.get("item_id")).begins_with("juice_"):
		return true
	
	# 2. Lanche embalado na caixinha
	if item is PackagedBurger or item is BurgerBox or item.is_in_group("packaged_burger") or str(item.get("item_id")) in ["packaged_burger", "burger_box", "cheeseburger", "burger", "x_bacon", "x_salada"]:
		return true
		
	# 3. Batata frita na embalagem
	if item is FriesPack or str(item.get("item_id")) in ["fries_pack", "potato_box", "fries"]:
		return true
		
	return false

func add_contained_item(item: Node3D) -> bool:
	if not can_accept_item(item):
		return false
	
	var item_dict = {
		"id": item.get("item_id") if "item_id" in item else item.name,
		"name": item.get_display_name() if item.has_method("get_display_name") else item.name,
		"type": item.get("item_type") if "item_type" in item else "food"
	}
	contained_items.append(item_dict)
	
	# Remove da cena o item que entrou na sacola
	if item.is_inside_tree():
		item.queue_free()
	
	display_name = get_display_name()
	_update_bag_visuals()
	return true

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
		if id in ["packaged_burger", "burger_box", "cheeseburger", "burger", "x_bacon", "x_salada"]:
			return true
	return false

func has_fries() -> bool:
	for itm in contained_items:
		var id: String = itm.get("id", "")
		if id in ["fries_pack", "potato_box", "fries"]:
			return true
	return false

func _update_bag_visuals() -> void:
	# Ajuste sutil de estufamento ou fechamento conforme itens dentro
	pass
