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
		"scene": load("res://src/items/bread_top.tscn")
	},
	{
		"id": "bread_bottom",
		"name": "Base do Pão",
		"icon": "🍞",
		"scene": load("res://src/items/bread_bottom.tscn")
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

	# Reabastecimento com caixa de entrega
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held.get("ingredient_id") == item_id or (item_id.begins_with("bread") and (held.get("ingredient_id") == "bread" or held.get("ingredient_id") == "bread_bottom" or held.get("ingredient_id") == "bread_top")) or str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
			var qty: int = held.get("quantity") if held.get("quantity") != null else 10
			return "📦 🖱️ [Esq] Armazenar %s (+%d un.)" % [itm["name"], qty]

	var stock = inv.get_stock(item_id)
	var prompt = ""
	if stock <= 0:
		prompt = "🔴 %s Esgotado" % itm["name"]
	else:
		prompt = "%s 🖱️ [Esq] Pegar %s (%d un.)" % [itm["icon"], itm["name"], stock]

	if player and player.has_method("has_matching_ingredient") and player.has_matching_ingredient(item_id):
		prompt += " | 🖱️ [Dir] Devolver 1x"

	return prompt

# [Clique Esquerdo do Mouse] — Apenas Pegar / Reabastecer (NUNCA Devolver)
func interact_item(player: Node3D) -> void:
	var inv = InventoryManager.get_instance()
	if not inv:
		return

	var aimed_idx = get_aimed_item_index(player)
	active_item_index = aimed_idx
	var itm = items_data[aimed_idx]
	var item_id = itm["id"]

	# 1. Mão ocupada com objeto grande (caixa de entrega)
	if player and player.has_method("is_holding_large_item") and player.is_holding_large_item():
		var held = player.get("held_item")
		if held.get("ingredient_id") == item_id or (item_id.begins_with("bread") and (held.get("ingredient_id") == "bread" or held.get("ingredient_id") == "bread_bottom" or held.get("ingredient_id") == "bread_top")) or str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
			if player.has_method("take_held_item"):
				var crate = player.take_held_item()
				var qty: int = crate.get("quantity") if crate.get("quantity") != null else 10
				inv.add_stock(item_id, qty)
				_show_feedback(player, "📦 %s armazenado na mesa (+%d un.)!" % [itm["name"], qty])
				crate.queue_free()
				_update_all_visual_stocks()
				return

		_show_feedback(player, "⚠️ Mãos ocupadas com %s! Solte antes de pegar ingredientes." % (held.get_display_name() if held.has_method("get_display_name") else held.name))
		return

	# 2. Pegar pão para os slots rápidos
	if player.has_method("has_empty_quick_slot") and not player.has_empty_quick_slot():
		_show_feedback(player, "⚠️ Slots rápidos cheios (3/3)! Use os ingredientes atuais antes de pegar outros.")
		return

	var has_it = inv.has_stock(item_id, 1)
	if not has_it:
		_show_feedback(player, "❌ Sem estoque de %s! Compre no computador." % itm["name"])
		return

	var item_scene: PackedScene = itm["scene"]
	if item_scene:
		inv.consume_stock(item_id, 1)

		var item = item_scene.instantiate()
		if is_inside_tree() and get_tree().root:
			get_tree().root.add_child(item)
		else:
			add_child(item)
		if player.has_method("pick_up"):
			player.pick_up(item)
		_show_feedback(player, "🍞 Pegou %s" % itm["name"])
		_update_all_visual_stocks()

# [Clique Direito do Mouse] — DEVOLVER 1 UNIDADE
func interact_return(player: Node3D) -> void:
	return_item(player)

func return_item(player: Node3D) -> void:
	var inv = InventoryManager.get_instance()
	if not inv:
		return

	var aimed_idx = get_aimed_item_index(player)
	var itm = items_data[aimed_idx]
	var item_id = itm["id"]

	if player and player.has_method("has_matching_ingredient") and player.has_matching_ingredient(item_id):
		var returned = player.return_one_matching_ingredient(item_id)
		if returned:
			inv.add_stock(item_id, 1)
			_show_feedback(player, "🍞 Devolveu 1x %s ao estoque" % itm["name"])
			_update_all_visual_stocks()
			return

	_show_feedback(player, "⚠️ Armazenamento incompatível! Este local armazena %s." % itm["name"])

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

	_update_section_visual(b_top, bread_top_full, bread_top_med, bread_top_low, 15, 6)
	_update_section_visual(b_bot, bread_bot_full, bread_bot_med, bread_bot_low, 15, 6)

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
