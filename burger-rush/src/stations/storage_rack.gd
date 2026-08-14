class_name StorageRack
extends StaticBody3D

@onready var status_label: Label3D = $StatusLabel

var items_data: Array[Dictionary] = [
	{
		"id": "bread_bottom",
		"name": "Base do Pão",
		"icon": "🍞",
		"scene": preload("res://src/items/bread_bottom.tscn"),
		"tier": "Superior (Esq)"
	},
	{
		"id": "bread_top",
		"name": "Tampa do Pão",
		"icon": "🥯",
		"scene": preload("res://src/items/bread_top.tscn"),
		"tier": "Superior (Centro)"
	},
	{
		"id": "cheese",
		"name": "Queijo Cheddar",
		"icon": "🧀",
		"scene": preload("res://src/items/cheese.tscn"),
		"tier": "Superior (Dir)"
	},
	{
		"id": "potato_raw",
		"name": "Batata Crua",
		"icon": "🥔",
		"scene": preload("res://src/items/potato.tscn"),
		"tier": "Inferior (Esq)"
	},
	{
		"id": "tomato",
		"name": "Tomate Fresco",
		"icon": "🍅",
		"scene": preload("res://src/items/tomato.tscn"),
		"tier": "Inferior (Centro)"
	},
	{
		"id": "lettuce",
		"name": "Alface Crocante",
		"icon": "🥬",
		"scene": preload("res://src/items/lettuce.tscn"),
		"tier": "Inferior (Dir)"
	},
	{
		"id": "bread",
		"name": "Pão (Compatibilidade)",
		"icon": "🍞",
		"scene": preload("res://src/items/bread_bottom.tscn"),
		"tier": "Reserva"
	}
]
var active_item_index: int = 0

func _ready() -> void:
	var inv = InventoryManager.get_instance()
	if inv and not inv.stock_changed.is_connected(_on_stock_changed):
		inv.stock_changed.connect(_on_stock_changed)
	_update_label()

func get_aimed_item_index(player: Node = null) -> int:
	if not player:
		return active_item_index
	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if ray and ray is RayCast3D and ray.is_colliding():
		var col_pt = to_local(ray.get_collision_point())
		if col_pt.y > 0.65:
			if col_pt.x < -0.6:
				return 0 # Base Pão
			elif col_pt.x < 0.6:
				return 1 # Tampa Pão
			else:
				return 2 # Queijo
		else:
			if col_pt.x < -0.6:
				return 3 # Batata
			elif col_pt.x < 0.6:
				return 4 # Tomate
			else:
				return 5 # Alface
	return active_item_index

func cycle_item(worker: Node3D = null) -> String:
	active_item_index = (active_item_index + 1) % (items_data.size() - 1)
	var itm = items_data[active_item_index]
	if worker:
		_show_feedback(worker, "📦 Prateleira: %s %s (%s)" % [itm["icon"], itm["name"], itm["tier"]])
	_update_label()
	return itm["name"]

func get_interaction_prompt(player: Node = null) -> String:
	var inv = InventoryManager.get_instance()
	if not inv:
		return ""

	var aimed_idx = get_aimed_item_index(player)
	var itm = items_data[aimed_idx]
	var item_id = itm["id"]

	# Reabastecimento com caixa
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held.get("ingredient_id") == item_id or (item_id.begins_with("bread") and held.get("ingredient_id") == "bread") or str(held.get("item_type")) == "crate":
			var qty: int = held.get("quantity") if held.get("quantity") != null else 10
			return "E — Armazenar %s (+%d unidades)" % [itm["name"], qty]
		return ""

	var stock = inv.get_stock(item_id)
	if stock == 0 and item_id.begins_with("bread"):
		stock = inv.get_stock("bread")
	var max_cap = inv.get_max_capacity(item_id)
	if max_cap == 0:
		max_cap = 50

	if stock <= 0:
		return "🔴 %s Esgotado! Compre no Computador" % itm["name"]

	return "E — Pegar %s %s (%d/%d) | [F] Alternar Ingrediente" % [itm["icon"], itm["name"], stock, max_cap]

func interact(player: Node3D) -> void:
	var inv = InventoryManager.get_instance()
	if not inv:
		return

	var aimed_idx = get_aimed_item_index(player)
	active_item_index = aimed_idx
	var itm = items_data[aimed_idx]
	var item_id = itm["id"]

	# 1. Abastecimento com Caixa
	var held = player.get("held_item")
	if held != null and (held.get("ingredient_id") == item_id or (item_id.begins_with("bread") and held.get("ingredient_id") == "bread") or str(held.get("item_type")) == "crate"):
		if player.has_method("take_held_item"):
			var crate = player.take_held_item()
			var qty: int = crate.get("quantity") if crate.get("quantity") != null else 10
			inv.add_stock(item_id, qty)
			if item_id == "bread_bottom" or item_id == "bread_top":
				inv.add_stock("bread", qty)
			_show_feedback(player, "📦 %s armazenado nas prateleiras (+%d un.)!" % [itm["name"], qty])
			crate.queue_free()
			_update_label()
			return

	# 2. Pegar ingrediente com as mãos livres
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
			_show_feedback(player, "📦 Pegou %s (Estoque: %d)" % [itm["name"], inv.get_stock(item_id)])
			_update_label()

func _on_stock_changed(_changed_id: String, _new_qty: int) -> void:
	_update_label()

func _update_label() -> void:
	if not status_label:
		return

	var inv = InventoryManager.get_instance()
	var b_bot = inv.get_stock("bread_bottom") if inv else 0
	var b_top = inv.get_stock("bread_top") if inv else 0
	var cheese_stock = inv.get_stock("cheese") if inv else 0
	var potato_stock = inv.get_stock("potato_raw") if inv else 0
	var tomato_stock = inv.get_stock("tomato") if inv else 0
	var lettuce_stock = inv.get_stock("lettuce") if inv else 0

	var itm = items_data[active_item_index]

	status_label.text = "📦 ESTANTE EM L (2 NÍVEIS)\n🍞 Base: %d │ 🥯 Tampa: %d │ 🧀 Queijo: %d │ 🥔 Batata: %d │ 🍅 Tomate: %d │ 🥬 Alface: %d\n[E] Pegar %s │ [F] Alternar" % [
		b_bot, b_top, cheese_stock, potato_stock, tomato_stock, lettuce_stock, itm["name"]
	]
	status_label.modulate = Color(0.9, 0.9, 0.9, 1.0)

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
