class_name IngredientDispenser
extends StaticBody3D

@export var ingredient_id: String = "patty"

@onready var label_3d: Label3D = $Label3D

func _ready() -> void:
	var inv = InventoryManager.get_instance()
	if inv:
		inv.stock_changed.connect(_on_stock_changed)
	_update_visual_label()

func get_interaction_prompt(player: Node = null) -> String:
	var prog = ProgressionManager.get_instance()
	if prog and not prog.is_unlocked(ingredient_id):
		return "🔒 Ingrediente Bloqueado (Progresso)"

	var inv = InventoryManager.get_instance()
	if not inv:
		return ""

	var stock = inv.get_stock(ingredient_id)
	var max_cap = inv.get_max_capacity(ingredient_id)
	var item_name = _get_ingredient_display_name()

	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		# Se jogador estiver segurando a caixa de ingredientes para reabastecimento
		if held.get("ingredient_id") == ingredient_id or str(held.get("item_type")) == "crate":
			var qty: int = held.get("quantity") if held.get("quantity") != null else 10
			return "E — Reabastecer %s (+%d unidades)" % [item_name, qty]
		# Se jogador estiver com as mãos ocupadas
		return ""

	if stock <= 0:
		return "🔴 %s Esgotado! Compre no Computador" % item_name

	return "E — Pegar %s (%d/%d)" % [item_name, stock, max_cap]

func interact(player: Node3D) -> void:
	var prog = ProgressionManager.get_instance()
	if prog and not prog.is_unlocked(ingredient_id):
		_show_feedback(player, "🔒 Este ingrediente ainda não foi desbloqueado!")
		return

	var inv = InventoryManager.get_instance()
	if not inv:
		return

	# 1. Reabastecimento com Caixa de Ingredientes na mão
	var held = player.get("held_item")
	if held != null and (held.get("ingredient_id") == ingredient_id or str(held.get("item_type")) == "crate"):
		if player.has_method("take_held_item"):
			var crate = player.take_held_item()
			var qty: int = crate.get("quantity") if crate.get("quantity") != null else 10
			inv.add_stock(ingredient_id, qty)
			_show_feedback(player, "📦 %s reabastecido com +%d unidades!" % [_get_ingredient_display_name(), qty])
			crate.queue_free()
			_update_visual_label()
			return

	# 2. Pegar ingrediente se mão estiver livre
	if held == null:
		if not inv.has_stock(ingredient_id, 1):
			_show_feedback(player, "❌ Sem estoque de %s! Compre no computador." % _get_ingredient_display_name())
			return

		var item_data = inv.get_item_data(ingredient_id)
		var item_scene: PackedScene = item_data.get("scene", null)
		if not item_scene:
			# Fallback padrão
			match ingredient_id:
				"patty": item_scene = load("res://src/items/patty.tscn")
				"bread": item_scene = load("res://src/items/bread.tscn")
				"cheese": item_scene = load("res://src/items/cheese.tscn")
				"lettuce": item_scene = load("res://src/items/lettuce.tscn")
				"tomato": item_scene = load("res://src/items/tomato.tscn")
				"onion": item_scene = load("res://src/items/onion.tscn")
				"bacon": item_scene = load("res://src/items/bacon.tscn")
				"sauce": item_scene = load("res://src/items/sauce.tscn")
				"potato_raw": item_scene = load("res://src/items/potato.tscn")

		if item_scene:
			inv.consume_stock(ingredient_id, 1)
			var item = item_scene.instantiate()
			player.get_tree().root.add_child(item)
			if player.has_method("pick_up"):
				player.pick_up(item)
			_show_feedback(player, "📦 Pegou %s (Restam %d)" % [_get_ingredient_display_name(), inv.get_stock(ingredient_id)])
			_update_visual_label()

func _on_stock_changed(changed_id: String, _new_qty: int) -> void:
	if changed_id == ingredient_id:
		_update_visual_label()

func _update_visual_label() -> void:
	if not label_3d:
		return

	var prog = ProgressionManager.get_instance()
	if prog and not prog.is_unlocked(ingredient_id):
		label_3d.text = "🔒 %s\nBLOQUEADO" % ingredient_id.capitalize()
		label_3d.modulate = Color(0.6, 0.6, 0.6, 1)
		return

	var inv = InventoryManager.get_instance()
	if not inv:
		return

	var stock = inv.get_stock(ingredient_id)
	var max_cap = inv.get_max_capacity(ingredient_id)
	var item_name = _get_ingredient_display_name()

	if stock <= 0:
		label_3d.text = "🔴 %s\nESGOTADO" % item_name
		label_3d.modulate = Color(1, 0.3, 0.3, 1)
	elif inv.is_low_stock(ingredient_id):
		label_3d.text = "🟡 %s\nQtd: %d/%d" % [item_name, stock, max_cap]
		label_3d.modulate = Color(1, 0.85, 0.2, 1)
	else:
		label_3d.text = "📦 %s\nQtd: %d/%d" % [item_name, stock, max_cap]
		label_3d.modulate = Color(0.9, 0.9, 0.9, 1)

func _get_ingredient_display_name() -> String:
	match ingredient_id:
		"patty": return "Carne"
		"bread": return "Pão"
		"cheese": return "Queijo"
		"lettuce": return "Alface"
		"tomato": return "Tomate"
		"onion": return "Cebola"
		"bacon": return "Bacon"
		"sauce": return "Molho"
		"potato_raw": return "Saco de Batata"
		_: return ingredient_id.capitalize()

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
