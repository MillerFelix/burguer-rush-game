class_name PackagingStation
extends StaticBody3D

# =============================================================================
# BURGER RUSH - ESTAÇÃO DE EMBALAGENS COM ESTOQUE VISUAL DINÂMICO
# Regra dos 3 Estágios: CHEIO (35-50) | MÉDIO (15-34) | BAIXO (1-14) | ZERO (0)
# Limite máximo rigoroso: 50 unidades por tipo de embalagem
# Sem textos ou labels 3D flutuantes na mesa
# =============================================================================

@onready var packaging_slot: Node3D = get_node_or_null("PackagingSlot")

# Nós de visual de estoque por seção
@onready var burger_box_full: Node3D = get_node_or_null("Model/BurgerBoxes/Full")
@onready var burger_box_med: Node3D = get_node_or_null("Model/BurgerBoxes/Medium")
@onready var burger_box_low: Node3D = get_node_or_null("Model/BurgerBoxes/Low")

@onready var potato_box_full: Node3D = get_node_or_null("Model/PotatoBoxes/Full")
@onready var potato_box_med: Node3D = get_node_or_null("Model/PotatoBoxes/Medium")
@onready var potato_box_low: Node3D = get_node_or_null("Model/PotatoBoxes/Low")

@onready var cups_full: Node3D = get_node_or_null("Model/Cups/Full")
@onready var cups_med: Node3D = get_node_or_null("Model/Cups/Medium")
@onready var cups_low: Node3D = get_node_or_null("Model/Cups/Low")

@onready var delivery_bags_full: Node3D = get_node_or_null("Model/DeliveryBags/Full")
@onready var delivery_bags_med: Node3D = get_node_or_null("Model/DeliveryBags/Medium")
@onready var delivery_bags_low: Node3D = get_node_or_null("Model/DeliveryBags/Low")

var packaged_item: Node3D = null

const MAX_STOCK_PER_ITEM: int = 50

var items_config: Dictionary = {
	"burger_box": {
		"name": "Caixa de Hambúrguer",
		"icon": "📦",
		"scene": preload("res://src/items/burger_box.tscn"),
		"z_min": -1.2,
		"z_max": -0.50
	},
	"potato_box": {
		"name": "Embalagem de Batata",
		"icon": "🍟",
		"scene": preload("res://src/items/potato_box.tscn"),
		"z_min": -0.50,
		"z_max": 0.0
	},
	"cup_empty": {
		"name": "Copo Vazio",
		"icon": "🥤",
		"scene": preload("res://src/items/drink_cup.tscn"),
		"z_min": 0.0,
		"z_max": 0.50
	},
	"delivery_bag": {
		"name": "Saco de Delivery",
		"icon": "🛍️",
		"scene": preload("res://src/items/delivery_bag.tscn"),
		"z_min": 0.50,
		"z_max": 1.2
	}
}

func _ready() -> void:
	# Conecta sinal de estoque para atualização visual em tempo real
	var inv = InventoryManager.get_instance()
	if inv:
		if not inv.stock_changed.is_connected(_on_stock_changed):
			inv.stock_changed.connect(_on_stock_changed)
	_update_all_visual_stocks()

func _on_stock_changed(_item_id: String, _new_qty: int) -> void:
	_update_all_visual_stocks()

func get_aimed_item_id(player: Node = null) -> String:
	if not player:
		return "burger_box"
	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if ray and ray is RayCast3D and ray.is_colliding():
		var col_pt = to_local(ray.get_collision_point())
		if col_pt.z < -0.50:
			return "burger_box"
		elif col_pt.z < 0.0:
			return "potato_box"
		elif col_pt.z < 0.50:
			return "cup_empty"
		else:
			return "delivery_bag"
	var rel_z = (player.global_position.z - global_position.z) if is_inside_tree() else player.position.z
	if rel_z < -0.50:
		return "burger_box"
	elif rel_z < 0.0:
		return "potato_box"
	elif rel_z < 0.50:
		return "cup_empty"
	else:
		return "delivery_bag"

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""

	var held = player.get("held_item")

	# 1. Se houver item embalado pronto para retirar da bancada
	if packaged_item != null:
		var d_name = packaged_item.get_display_name() if packaged_item.has_method("get_display_name") else packaged_item.name
		if held == null:
			return "🖱️ Pegar %s Embalado" % d_name
		return ""

	# 2. Devolução de embalagem vazia ao estoque da mesa
	if held != null:
		var return_id = _get_matching_stock_id_from_item(held)
		if return_id != "":
			var inv = InventoryManager.get_instance()
			var current_stock = inv.get_stock(return_id) if inv else 50
			if current_stock < MAX_STOCK_PER_ITEM:
				var itm_cfg = items_config.get(return_id, {})
				var itm_name = itm_cfg.get("name", "Item")
				return "🖱️ Devolver %s ao Estoque" % itm_name
			else:
				return "⚠️ Estoque Cheio (%d/%d)" % [current_stock, MAX_STOCK_PER_ITEM]

	# 3. Selar Copo de Bebida com Tampa
	if held != null and held.has_method("has_lid") and not held.has_lid():
		var flv = held.get("flavor") if held.get("flavor") != null else "Bebida"
		return "🖱️ / [E] Selar %s com Tampa" % flv

	# 4. Embalar sanduíche / batata na bancada
	if held != null and (held.has_method("can_be_packaged") or str(held.get("item_type")) in ["final_product", "food", "burger", "fries"]):
		var d_name = held.get_display_name() if held.has_method("get_display_name") else held.name
		return "🖱️ / [E] Embalar %s para Viagem" % d_name

	# 5. Mão vazia: pode pegar embalagem diretamente com o CLIQUE ESQUERDO
	if held == null:
		var aimed_id = get_aimed_item_id(player)
		var inv = InventoryManager.get_instance()
		var stock = inv.get_stock(aimed_id) if inv else 50
		var itm_cfg = items_config.get(aimed_id, {})
		var itm_name = itm_cfg.get("name", "Embalagem")
		var itm_icon = itm_cfg.get("icon", "📦")

		if stock > 0:
			return "🖱️ Pegar %s %s" % [itm_icon, itm_name]
		else:
			return "⚠️ %s Esgotado" % itm_name

	return ""

# [Clique Esquerdo do Mouse] — Manipulação de Itens / Embalagens
func interact_item(player: Node3D) -> void:
	_handle_left_click(player)

# [E] — Interação com Equipamentos e Armazenamento com [E]
func interact(player: Node3D) -> void:
	var held = player.get("held_item")
	if held != null and str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
		_handle_left_click(player)
		return
	# Permite selar copos ou embalar lanche na bancada com [E]
	if held != null and (held.has_method("has_lid") or held.has_method("can_be_packaged") or str(held.get("item_type")) in ["final_product", "food", "burger", "fries"]):
		_handle_packaging_action(player)

func _handle_left_click(player: Node3D) -> void:
	var held = player.get("held_item")

	# 1. Retirar item embalado da bancada
	if packaged_item != null and held == null:
		var item = packaged_item
		packaged_item = null
		if packaging_slot and item.get_parent() == packaging_slot:
			packaging_slot.remove_child(item)
		if player.has_method("pick_up"):
			player.pick_up(item)
		_show_feedback(player, "📦 Pegou %s embalado!" % (item.get_display_name() if item.has_method("get_display_name") else item.name))
		return

	# 2. Devolução de embalagem vazia ou Armazenamento de Caixa de Entrega
	if held != null:
		var return_id = _get_matching_stock_id_from_item(held)
		if return_id != "":
			var inv = InventoryManager.get_instance()
			var current_stock = inv.get_stock(return_id) if inv else 50
			if current_stock < MAX_STOCK_PER_ITEM:
				if player.has_method("take_held_item"):
					var removed_item = player.take_held_item()
					if removed_item:
						removed_item.queue_free()
				if inv:
					inv.add_stock(return_id, 1)
				_update_all_visual_stocks()
				_show_feedback(player, "📥 Devolveu %s ao estoque (%d/%d)" % [items_config[return_id]["name"], current_stock + 1, MAX_STOCK_PER_ITEM])
				return
			else:
				_show_feedback(player, "⚠️ Estoque de %s já está no limite máximo (%d/%d)!" % [items_config[return_id]["name"], MAX_STOCK_PER_ITEM, MAX_STOCK_PER_ITEM])
				return

		if str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
			var box_item_id = str(held.get("contained_item_id"))
			if items_config.has(box_item_id):
				var qty: int = held.get("quantity") if held.get("quantity") != null else 10
				var inv = InventoryManager.get_instance()
				if inv:
					inv.add_stock(box_item_id, qty)
				player.take_held_item().queue_free()
				_update_all_visual_stocks()
				_show_feedback(player, "📦 %s armazenado no estoque (+%d un.)!" % [items_config[box_item_id]["name"], qty])
				return
			else:
				_show_feedback(player, "⚠️ Local incorreto! Esta caixa contém %s. Leve até a estação correta." % str(held.get("contained_item_name")))
				return

	# 3. Selar Copo ou Embalar Comida
	if held != null:
		_handle_packaging_action(player)
		return

	# 4. Pegar Embalagem / Copo com as mãos livres (Clique Esquerdo)
	if held == null:
		var aimed_id = get_aimed_item_id(player)
		var inv = InventoryManager.get_instance()
		var stock = inv.get_stock(aimed_id) if inv else 50
		var itm_cfg = items_config.get(aimed_id, {})

		if stock <= 0:
			_show_feedback(player, "⚠️ %s está esgotado no estoque!" % itm_cfg.get("name", "Item"))
			return

		# Consome 1 unidade do estoque
		if inv:
			inv.consume_stock(aimed_id, 1)

		var item_scene: PackedScene = itm_cfg.get("scene")
		if item_scene:
			var new_item = item_scene.instantiate()
			if is_inside_tree() and get_tree().root:
				get_tree().root.add_child(new_item)
			else:
				add_child(new_item)
			if player.has_method("pick_up"):
				player.pick_up(new_item)
			_show_feedback(player, "📦 Pegou %s" % itm_cfg.get("name", "Item"))
		
		_update_all_visual_stocks()

func _handle_packaging_action(player: Node3D) -> void:
	var held = player.get("held_item")
	if held == null:
		return

	# Selar Copo de Bebida
	if held.has_method("has_lid") and not held.has_lid():
		if held.has_method("seal_cup"):
			held.seal_cup()
		elif held.get("lid_mesh") != null:
			held.lid_mesh.visible = true
			if "is_sealed" in held:
				held.is_sealed = true
		_show_feedback(player, "🥤 Bebida selada com sucesso!")
		return

	# Embalar comida na bancada
	if held.has_method("can_be_packaged") or str(held.get("item_type")) in ["final_product", "food", "burger", "fries"]:
		if player.has_method("take_held_item"):
			var food_item = player.take_held_item()
			if food_item:
				_package_item_on_station(food_item)
				_show_feedback(player, "📦 %s embalado para viagem!" % (food_item.get_display_name() if food_item.has_method("get_display_name") else food_item.name))

const DeliveryBagScript = preload("res://src/items/delivery_bag.gd")

func _get_matching_stock_id_from_item(item: Node3D) -> String:
	if not item:
		return ""
	var item_id = item.get("item_id") if "item_id" in item else item.name
	if item is DrinkCup or item_id in ["drink_cup", "cup_empty", "cup"]:
		# Apenas copos vazios podem ser devolvidos à pilha de copos limpos
		if item.has_method("is_empty") and item.is_empty():
			return "cup_empty"
		elif "fill_amount" in item and item.fill_amount <= 0.01:
			return "cup_empty"
		return ""
	elif item is PotatoBoxItem or item_id in ["potato_box", "fries_box"]:
		return "potato_box"
	elif item is BurgerBox or item_id in ["burger_box"]:
		return "burger_box"
	elif item is DeliveryBagScript or item_id in ["delivery_bag"]:
		if item.has_method("is_empty") and item.is_empty():
			return "delivery_bag"
	return ""

func _package_item_on_station(food_item: Node3D) -> void:
	if packaging_slot:
		var prev_p = food_item.get_parent()
		if prev_p:
			prev_p.remove_child(food_item)
		packaging_slot.add_child(food_item)
		food_item.position = Vector3.ZERO
		food_item.rotation = Vector3.ZERO
		packaged_item = food_item

# =============================================================================
# ATUALIZAÇÃO VISUAL DO ESTOQUE (3 ESTÁGIOS: CHEIO / MÉDIO / BAIXO / VAZIO)
# =============================================================================
func _update_all_visual_stocks() -> void:
	var inv = InventoryManager.get_instance()
	_update_section_visual("burger_box", inv.get_stock("burger_box") if inv else 50, burger_box_full, burger_box_med, burger_box_low)
	_update_section_visual("potato_box", inv.get_stock("potato_box") if inv else 50, potato_box_full, potato_box_med, potato_box_low)
	_update_section_visual("cup_empty", inv.get_stock("cup_empty") if inv else 50, cups_full, cups_med, cups_low)
	_update_section_visual("delivery_bag", inv.get_stock("delivery_bag") if inv else 50, delivery_bags_full, delivery_bags_med, delivery_bags_low)

func _update_section_visual(
	_item_id: String,
	stock_qty: int,
	node_full: Node3D,
	node_med: Node3D,
	node_low: Node3D
) -> void:
	if not node_full and not node_med and not node_low:
		return

	# CHEIO: >= 35
	# MÉDIO: 15 a 34
	# BAIXO: 1 a 14
	# ZERO: 0
	if stock_qty >= 35:
		if node_full: node_full.visible = true
		if node_med: node_med.visible = false
		if node_low: node_low.visible = false
	elif stock_qty >= 15:
		if node_full: node_full.visible = false
		if node_med: node_med.visible = true
		if node_low: node_low.visible = false
	elif stock_qty > 0:
		if node_full: node_full.visible = false
		if node_med: node_med.visible = false
		if node_low: node_low.visible = true
	else:
		# ZERO: Nada visível no slot
		if node_full: node_full.visible = false
		if node_med: node_med.visible = false
		if node_low: node_low.visible = false

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
