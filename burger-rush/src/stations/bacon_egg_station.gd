class_name BaconEggStation
extends StaticBody3D

# ================================================================
# BANCADA DE ARMAZENAMENTO DE BACON & OVO — ESTOQUE VISUAL DINÂMICO
# Regra: CHEIO | MÉDIO | BAIXO | ZERO (Independente para Bacon e Ovos)
# Sem textos ou labels 3D flutuantes
#
# REGRA DE CONTROLE:
#  - E: Reabastecer com caixa de mercadoria / Equipamentos
#  - CLIQUE ESQUERDO: Pegar / manipular bacon e ovos
# ================================================================

# Nós de Estoque Visual Dinâmico (3 Estágios)
@onready var bacon_full: Node3D = get_node_or_null("Model/BaconArea/Packs/Full")
@onready var bacon_med: Node3D = get_node_or_null("Model/BaconArea/Packs/Medium")
@onready var bacon_low: Node3D = get_node_or_null("Model/BaconArea/Packs/Low")

@onready var egg_full: Node3D = get_node_or_null("Model/EggArea/Eggs/Full")
@onready var egg_med: Node3D = get_node_or_null("Model/EggArea/Eggs/Medium")
@onready var egg_low: Node3D = get_node_or_null("Model/EggArea/Eggs/Low")

var items_data: Array[Dictionary] = [
	{
		"id": "bacon",
		"name": "Tirinha de Bacon",
		"icon": "🥓",
		"scene": preload("res://src/items/bacon.tscn")
	},
	{
		"id": "egg",
		"name": "Ovo",
		"icon": "🥚",
		"scene": preload("res://src/items/egg.tscn")
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
		# Lado esquerdo (X < 0) -> Bacon (index 0)
		# Lado direito (X >= 0) -> Ovo (index 1)
		if col_pt.x < 0.0:
			return 0
		else:
			return 1
	return active_item_index

func get_interaction_prompt(player: Node = null) -> String:
	var inv = InventoryManager.get_instance()
	if not inv:
		return ""

	var aimed_idx = get_aimed_item_index(player)
	var itm = items_data[aimed_idx]
	var item_id = itm["id"]

	# 1. Se o jogador estiver segurando item para devolução ou caixa para reabastecimento
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		var held_id = str(held.get("item_id"))

		# Devolução de item cru individual
		if held is Bacon and held.state == Bacon.State.RAW:
			return "🥓 🖱️ Devolver Tirinha de Bacon ao Estoque"
		elif held is Egg and held.state == Egg.State.RAW:
			return "🥚 🖱️ Devolver Ovo ao Cesto"
		elif held_id == item_id and held.get("state") == 0:
			return "%s 🖱️ Devolver %s ao Estoque" % [itm["icon"], itm["name"]]

		# Reabastecimento com caixa/entrega
		if held.get("ingredient_id") == item_id or str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
			var qty: int = held.get("quantity") if held.get("quantity") != null else 10
			return "📦 🖱️ Armazenar %s (+%d un.)" % [itm["name"], qty]

		return ""

	# 2. Jogador de mãos vazias -> pegar ingrediente (EXCLUSIVAMENTE clique esquerdo)
	var stock = inv.get_stock(item_id)
	if stock <= 0:
		return "🔴 %s Esgotado" % itm["name"]

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

	# 1. Devolução de item cru individual
	if held != null:
		var held_id = str(held.get("item_id"))
		if (held is Bacon and held.state == Bacon.State.RAW) or (held is Egg and held.state == Egg.State.RAW) or (held_id == item_id and held.get("state") == 0):
			if player.has_method("take_held_item"):
				var returned_item = player.take_held_item()
				inv.add_stock(item_id, 1)
				_show_feedback(player, "%s %s devolvido à bancada" % [itm["icon"], itm["name"]])
				returned_item.queue_free()
				_update_all_visual_stocks()
				return

		# Reabastecimento com Caixa de Entrega
		if held.get("ingredient_id") == item_id or str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
			if player.has_method("take_held_item"):
				var crate = player.take_held_item()
				var qty: int = crate.get("quantity") if crate.get("quantity") != null else 10
				inv.add_stock(item_id, qty)
				_show_feedback(player, "📦 %s armazenado na bancada (+%d un.)!" % [itm["name"], qty])
				crate.queue_free()
				_update_all_visual_stocks()
				return

		_show_feedback(player, "Mãos ocupadas! Devolva o item atual antes de pegar outro.")
		return

	# 2. Pegar ingrediente com clique esquerdo (Mãos Livres)
	if held == null:
		if not inv.has_stock(item_id, 1):
			_show_feedback(player, "❌ Sem estoque de %s! Compre no computador." % itm["name"])
			return

		var item_scene: PackedScene = itm["scene"]
		if item_scene:
			inv.consume_stock(item_id, 1)
			var item = item_scene.instantiate()
			if "state" in item:
				item.state = 0 # RAW
			if is_inside_tree() and get_tree().root:
				get_tree().root.add_child(item)
			else:
				add_child(item)
			if player.has_method("pick_up"):
				player.pick_up(item)
			_show_feedback(player, "%s Pegou %s" % [itm["icon"], itm["name"]])
			_update_all_visual_stocks()

# [E] — Interação com Equipamento (NÃO pega ingrediente; apenas reabastecimento com caixa)
func interact(player: Node3D) -> void:
	var held = player.get("held_item")
	var inv = InventoryManager.get_instance()
	if not inv:
		return

	var aimed_idx = get_aimed_item_index(player)
	var itm = items_data[aimed_idx]
	var item_id = itm["id"]

	# Reabastecimento com Caixa de Entrega acionado com E
	if held != null and (held.get("ingredient_id") == item_id or str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]):
		if player.has_method("take_held_item"):
			var crate = player.take_held_item()
			var qty: int = crate.get("quantity") if crate.get("quantity") != null else 10
			inv.add_stock(item_id, qty)
			_show_feedback(player, "📦 %s armazenado na bancada (+%d un.)!" % [itm["name"], qty])
			crate.queue_free()
			_update_all_visual_stocks()
			return

	if held == null:
		_show_feedback(player, "ℹ️ Use o Clique Esquerdo do mouse para pegar ingredientes.")

func _on_stock_changed(_changed_id: String, _new_qty: int) -> void:
	_update_all_visual_stocks()

func _update_all_visual_stocks() -> void:
	var inv = InventoryManager.get_instance()
	var b_stock = inv.get_stock("bacon") if inv else 15
	var e_stock = inv.get_stock("egg") if inv else 15

	_update_section_visual(b_stock, bacon_full, bacon_med, bacon_low, 15, 6)
	_update_section_visual(e_stock, egg_full, egg_med, egg_low, 15, 6)

func _update_section_visual(
	stock_qty: int,
	node_full: Node3D,
	node_med: Node3D,
	node_low: Node3D,
	full_thresh: int = 15,
	med_thresh: int = 6
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
