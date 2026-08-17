class_name StorageRack
extends StaticBody3D

# ================================================================
# ÁREA DE PÃES DO ARMAZÉM — ESTOQUE VISUAL DINÂMICO DE 3 ESTÁGIOS
# Regra: CHEIO | MÉDIO | BAIXO | ZERO
# Sem textos ou labels 3D flutuantes
#
# REGRA DE CONTROLE:
#  - E: Reabastecer com caixa de mercadoria / Equipamentos
#  - CLIQUE ESQUERDO: Pegar / manipular pães
# ================================================================

# Nós de Estoque Visual Dinâmico (3 Estágios)
@onready var bread_top_full: Node3D = get_node_or_null("Model/BoxBreadTop/Full")
@onready var bread_top_med: Node3D = get_node_or_null("Model/BoxBreadTop/Medium")
@onready var bread_top_low: Node3D = get_node_or_null("Model/BoxBreadTop/Low")

@onready var bread_bot_full: Node3D = get_node_or_null("Model/BoxBreadBottom/Full")
@onready var bread_bot_med: Node3D = get_node_or_null("Model/BoxBreadBottom/Medium")
@onready var bread_bot_low: Node3D = get_node_or_null("Model/BoxBreadBottom/Low")

var items_data: Array[Dictionary] = [
	{
		"id": "bread_top",
		"name": "Tampa do Pão",
		"icon": "🥯",
		"scene": preload("res://src/items/bread_top.tscn")
	},
	{
		"id": "bread_bottom",
		"name": "Base do Pão",
		"icon": "🍞",
		"scene": preload("res://src/items/bread_bottom.tscn")
	}
]

var active_item_index: int = 0

func _ready() -> void:
	var inv = InventoryManager.get_instance()
	if inv and not inv.stock_changed.is_connected(_on_stock_changed):
		inv.stock_changed.connect(_on_stock_changed)
	_update_all_visual_stocks()

func get_aimed_item_index(player: Node = null) -> int:
	if not player:
		return active_item_index
	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if ray and ray is RayCast3D and ray.is_colliding():
		var col_pt = to_local(ray.get_collision_point())
		# Lado esquerdo (X < 0) -> Tampa do Pão (index 0)
		# Lado direito (X >= 0) -> Base do Pão (index 1)
		if col_pt.x < 0.0:
			return 0
		else:
			return 1
	return active_item_index

func cycle_item(worker: Node3D = null) -> String:
	active_item_index = (active_item_index + 1) % items_data.size()
	var itm = items_data[active_item_index]
	if worker:
		_show_feedback(worker, "📦 Pão Selecionado: %s %s" % [itm["icon"], itm["name"]])
	_update_all_visual_stocks()
	return itm["name"]

func get_interaction_prompt(player: Node = null) -> String:
	var inv = InventoryManager.get_instance()
	if not inv:
		return ""

	var aimed_idx = get_aimed_item_index(player)
	var itm = items_data[aimed_idx]
	var item_id = itm["id"]

	# Reabastecimento com caixa de entrega ou devolução de pão
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		var held_id = str(held.get("item_id"))

		# Devolução de pão individual
		if held_id == item_id or (item_id.begins_with("bread") and (held_id == "bread_bottom" or held_id == "bread_top" or held_id == "bread")):
			return "%s 🖱️ Devolver %s ao Estoque" % [itm["icon"], itm["name"]]

		# Reabastecimento com caixa
		if held.get("ingredient_id") == item_id or (item_id.begins_with("bread") and (held.get("ingredient_id") == "bread" or held.get("ingredient_id") == "bread_bottom" or held.get("ingredient_id") == "bread_top")) or str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
			var qty: int = held.get("quantity") if held.get("quantity") != null else 10
			return "📦 🖱️ Armazenar %s (+%d un.)" % [itm["name"], qty]

		return ""

	var stock = inv.get_stock(item_id)
	if stock == 0 and item_id.begins_with("bread"):
		stock = inv.get_stock("bread")

	if stock <= 0:
		return "🔴 %s Esgotado" % itm["name"]

	# Interação EXCLUSIVA com clique esquerdo para pegar ingredientes
	return "%s 🖱️ Pegar %s" % [itm["icon"], itm["name"]]

# [Clique Esquerdo do Mouse] — Manipulação de Itens (Pegar / Devolver)
func interact_item(player: Node3D) -> void:
	var inv = InventoryManager.get_instance()
	if not inv:
		return

	var aimed_idx = get_aimed_item_index(player)
	active_item_index = aimed_idx
	var itm = items_data[aimed_idx]
	var item_id = itm["id"]

	var held = player.get("held_item")

	# 1. Devolução de pão individual com as mãos ocupadas
	if held != null:
		var held_id = str(held.get("item_id"))
		if held_id == item_id or (item_id.begins_with("bread") and (held_id == "bread_bottom" or held_id == "bread_top" or held_id == "bread")):
			if player.has_method("take_held_item"):
				var returned_bread = player.take_held_item()
				inv.add_stock(item_id, 1)
				if item_id == "bread_bottom" or item_id == "bread_top":
					inv.add_stock("bread", 1)
				_show_feedback(player, "🍞 %s devolvido à bancada" % itm["name"])
				returned_bread.queue_free()
				_update_all_visual_stocks()
				return

		# Reabastecimento com Caixa de Entrega
		if held.get("ingredient_id") == item_id or (item_id.begins_with("bread") and (held.get("ingredient_id") == "bread" or held.get("ingredient_id") == "bread_bottom" or held.get("ingredient_id") == "bread_top")) or str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
			if player.has_method("take_held_item"):
				var crate = player.take_held_item()
				var qty: int = crate.get("quantity") if crate.get("quantity") != null else 10
				inv.add_stock(item_id, qty)
				if item_id == "bread_bottom" or item_id == "bread_top":
					inv.add_stock("bread", qty)
				_show_feedback(player, "📦 %s armazenado na mesa (+%d un.)!" % [itm["name"], qty])
				crate.queue_free()
				_update_all_visual_stocks()
				return

		_show_feedback(player, "Mãos ocupadas! Devolva o item atual antes de pegar outro.")
		return

	# 2. Pegar pão com clique esquerdo (Mãos Livres)
	if held == null:
		var has_it = inv.has_stock(item_id, 1) or (item_id.begins_with("bread") and inv.has_stock("bread", 1))
		if not has_it:
			_show_feedback(player, "❌ Sem estoque de %s! Compre no computador." % itm["name"])
			return

		var item_scene: PackedScene = itm["scene"]
		if item_scene:
			if inv.has_stock(item_id, 1):
				inv.consume_stock(item_id, 1)
			elif item_id.begins_with("bread") and inv.has_stock("bread", 1):
				inv.consume_stock("bread", 1)

			var item = item_scene.instantiate()
			if is_inside_tree() and get_tree().root:
				get_tree().root.add_child(item)
			else:
				add_child(item)
			if player.has_method("pick_up"):
				player.pick_up(item)
			_show_feedback(player, "🍞 Pegou %s" % itm["name"])
			_update_all_visual_stocks()

# [E] — Interação com Equipamento (NÃO pega pão; apenas reabastecimento com caixa)
func interact(player: Node3D) -> void:
	var held = player.get("held_item")
	var inv = InventoryManager.get_instance()
	if not inv:
		return

	var aimed_idx = get_aimed_item_index(player)
	var itm = items_data[aimed_idx]
	var item_id = itm["id"]

	# Reabastecimento com Caixa de Entrega acionado com E
	if held != null and (held.get("ingredient_id") == item_id or (item_id.begins_with("bread") and (held.get("ingredient_id") == "bread" or held.get("ingredient_id") == "bread_bottom" or held.get("ingredient_id") == "bread_top")) or str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]):
		if player.has_method("take_held_item"):
			var crate = player.take_held_item()
			var qty: int = crate.get("quantity") if crate.get("quantity") != null else 10
			inv.add_stock(item_id, qty)
			if item_id == "bread_bottom" or item_id == "bread_top":
				inv.add_stock("bread", qty)
			_show_feedback(player, "📦 %s armazenado na mesa (+%d un.)!" % [itm["name"], qty])
			crate.queue_free()
			_update_all_visual_stocks()
			return

	if held == null:
		_show_feedback(player, "ℹ️ Use o Clique Esquerdo do mouse para pegar pães.")

func _on_stock_changed(_changed_id: String, _new_qty: int) -> void:
	_update_all_visual_stocks()

func _update_all_visual_stocks() -> void:
	var inv = InventoryManager.get_instance()
	var b_top = inv.get_stock("bread_top") if inv else 20
	var b_bot = inv.get_stock("bread_bottom") if inv else 20

	_update_section_visual(b_top, bread_top_full, bread_top_med, bread_top_low, 20, 8)
	_update_section_visual(b_bot, bread_bot_full, bread_bot_med, bread_bot_low, 20, 8)

func _update_section_visual(
	stock_qty: int,
	node_full: Node3D,
	node_med: Node3D,
	node_low: Node3D,
	full_thresh: int = 20,
	med_thresh: int = 8
) -> void:
	if not node_full and not node_med and not node_low:
		return

	if stock_qty >= full_thresh:
		if node_full: node_full.visible = true
		if node_med: node_med.visible = false
		if node_low: node_low.visible = false
	elif stock_qty >= med_thresh:
		if node_full: node_full.visible = false
		if node_med: node_med.visible = true
		if node_low: node_low.visible = false
	elif stock_qty > 0:
		if node_full: node_full.visible = false
		if node_med: node_med.visible = false
		if node_low: node_low.visible = true
	else:
		if node_full: node_full.visible = false
		if node_med: node_med.visible = false
		if node_low: node_low.visible = false

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
