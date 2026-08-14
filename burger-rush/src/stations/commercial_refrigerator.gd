class_name CommercialRefrigerator
extends StaticBody3D

@onready var status_label: Label3D = $StatusLabel

var compartments: Array[Dictionary] = [
	{
		"id": "patty",
		"name": "Carne Bovina",
		"icon": "🥩",
		"scene": preload("res://src/items/patty.tscn"),
		"active": true
	},
	{
		"id": "patty_chicken",
		"name": "Frango (Em Breve)",
		"icon": "🍗",
		"scene": preload("res://src/items/patty.tscn"), # Preparado para expansão futura
		"active": false
	},
	{
		"id": "bacon",
		"name": "Bacon / Defumados",
		"icon": "🥓",
		"scene": preload("res://src/items/bacon.tscn"),
		"active": true
	}
]
var active_compartment_index: int = 0

func _ready() -> void:
	var inv = InventoryManager.get_instance()
	if inv and not inv.stock_changed.is_connected(_on_stock_changed):
		inv.stock_changed.connect(_on_stock_changed)
	_update_label()

func _process(_delta: float) -> void:
	pass

func get_aimed_compartment_index(player: Node = null) -> int:
	if not player:
		return active_compartment_index
	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if ray and ray is RayCast3D and ray.is_colliding():
		var col_pt = to_local(ray.get_collision_point())
		if col_pt.y > 1.3:
			return 0 # Compartimento Superior: Bovina
		elif col_pt.y > 0.7:
			return 1 # Compartimento Médio: Frango
		else:
			return 2 # Compartimento Inferior: Bacon
	return active_compartment_index

func cycle_compartment(worker: Node3D = null) -> String:
	active_compartment_index = (active_compartment_index + 1) % compartments.size()
	var comp = compartments[active_compartment_index]
	if worker:
		_show_feedback(worker, "❄️ Compartimento selecionado: %s %s" % [comp["icon"], comp["name"]])
	_update_label()
	return comp["name"]

func get_interaction_prompt(player: Node = null) -> String:
	var inv = InventoryManager.get_instance()
	if not inv:
		return ""

	var aimed_idx = get_aimed_compartment_index(player)
	var comp = compartments[aimed_idx]
	var item_id = comp["id"]

	# Reabastecimento com caixa
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held.get("ingredient_id") == item_id or str(held.get("item_type")) == "crate":
			var qty: int = held.get("quantity") if held.get("quantity") != null else 10
			return "E — Armazenar %s (+%d unidades)" % [comp["name"], qty]
		return ""

	if not comp["active"]:
		return "🔒 %s (Bloqueado / Expansão Futura)" % comp["name"]

	var stock = inv.get_stock(item_id)
	var max_cap = inv.get_max_capacity(item_id)

	if stock <= 0:
		return "🔴 %s Esgotada! Compre no Computador" % comp["name"]

	return "E — Pegar %s %s (%d/%d) | [F] Trocar Seção" % [comp["icon"], comp["name"], stock, max_cap]

func interact(player: Node3D) -> void:
	var inv = InventoryManager.get_instance()
	if not inv:
		return

	var aimed_idx = get_aimed_compartment_index(player)
	active_compartment_index = aimed_idx
	var comp = compartments[aimed_idx]
	var item_id = comp["id"]

	# 1. Abastecimento com Caixa de Ingredientes
	var held = player.get("held_item")
	if held != null and (held.get("ingredient_id") == item_id or str(held.get("item_type")) == "crate"):
		if player.has_method("take_held_item"):
			var crate = player.take_held_item()
			var qty: int = crate.get("quantity") if crate.get("quantity") != null else 10
			inv.add_stock(item_id, qty)
			_show_feedback(player, "❄️ %s armazenada no freezer (+%d unidades)!" % [comp["name"], qty])
			crate.queue_free()
			_update_label()
			return

	if not comp["active"]:
		_show_feedback(player, "🔒 Este compartimento será liberado em expansões futuras!")
		return

	# 2. Pegar carne com as mãos livres
	if held == null:
		if not inv.has_stock(item_id, 1):
			_show_feedback(player, "❌ Sem estoque de %s! Compre no computador." % comp["name"])
			return

		var item_scene: PackedScene = comp["scene"]
		if item_scene:
			inv.consume_stock(item_id, 1)
			var item = item_scene.instantiate()
			if is_inside_tree() and get_tree().root:
				get_tree().root.add_child(item)
			else:
				add_child(item)
			if player.has_method("pick_up"):
				player.pick_up(item)
			_show_feedback(player, "🥩 Pegou %s (Estoque: %d)" % [comp["name"], inv.get_stock(item_id)])
			_update_label()

func _on_stock_changed(_changed_id: String, _new_qty: int) -> void:
	_update_label()

func _update_label() -> void:
	if not status_label:
		return

	var inv = InventoryManager.get_instance()
	var patty_stock = inv.get_stock("patty") if inv else 0
	var patty_cap = inv.get_max_capacity("patty") if inv else 50
	var bacon_stock = inv.get_stock("bacon") if inv else 0
	var bacon_cap = inv.get_max_capacity("bacon") if inv else 50

	var active_comp = compartments[active_compartment_index]

	status_label.text = "❄️ GELADEIRA DE CARNES (3 SEÇÕES)\n🥩 Bovina: %d/%d │ 🍗 Frango: [Expansão] │ 🥓 Bacon: %d/%d\n[E] Pegar %s │ [F] Alternar" % [
		patty_stock, patty_cap, bacon_stock, bacon_cap, active_comp["name"]
	]
	status_label.modulate = Color(0.4, 0.85, 1.0, 1.0)

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
