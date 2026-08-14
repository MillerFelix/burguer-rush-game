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
		var cost = prog.get_unlock_cost(ingredient_id)
		return "🔒 Bloqueado (Desbloqueie no Cardápio por $%.2f)" % cost

	var inv = InventoryManager.get_instance()
	if not inv:
		return ""

	var item = inv.get_item(ingredient_id)
	if not item:
		return ""

	# Se o jogador estiver segurando uma caixa de mercadorias compatível
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held is DeliveryBox:
			var box = held as DeliveryBox
			if box.contained_item_id == ingredient_id:
				return "E — Guardar %s no Estoque (+%d un)" % [item.display_name, box.quantity]
		return ""

	# Se as mãos do jogador estiverem livres
	if item.quantity > 0:
		return "E — Pegar %s (Estoque: %d/%d)" % [item.display_name, item.quantity, item.max_capacity]
	else:
		return "🔴 %s ESGOTADO (Comprar no Computador)" % item.display_name

func interact(player: Node3D) -> void:
	var prog = ProgressionManager.get_instance()
	if prog and not prog.is_unlocked(ingredient_id):
		_show_feedback(player, "Este ingrediente está bloqueado! Desbloqueie no computador.")
		return

	var inv = InventoryManager.get_instance()
	if not inv:
		return

	var item_data = inv.get_item(ingredient_id)
	if not item_data:
		return

	# Se o jogador estiver segurando uma caixa de mercadorias
	if player.get("held_item") != null:
		var held = player.get("held_item")
		if held is DeliveryBox:
			var box = held as DeliveryBox
			if box.contained_item_id == ingredient_id:
				if player.has_method("take_held_item"):
					var removed_box = player.take_held_item()
					var added = inv.add_stock(ingredient_id, box.quantity)
					removed_box.queue_free()
					_show_feedback(player, "✅ %d %s guardados no estoque com sucesso!" % [added, item_data.display_name])
					_update_visual_label()
					return
		return

	# Se as mãos estiverem livres -> Retira 1 ingrediente
	if item_data.quantity <= 0:
		_show_feedback(player, "Estoque de %s esgotado! Compre mais pelo computador." % item_data.display_name)
		return

	var physical_item = inv.spawn_physical_item(ingredient_id)
	if physical_item and player.has_method("pick_up"):
		player.pick_up(physical_item)
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

	var item = inv.get_item(ingredient_id)
	if not item:
		return

	if item.quantity <= 0:
		label_3d.text = "🔴 %s\nESGOTADO" % item.display_name
		label_3d.modulate = Color(1, 0.3, 0.3, 1)
	elif item.is_low_stock():
		label_3d.text = "🟡 %s\nQtd: %d/%d" % [item.display_name, item.quantity, item.max_capacity]
		label_3d.modulate = Color(1, 0.85, 0.2, 1)
	else:
		label_3d.text = "📦 %s\nQtd: %d/%d" % [item.display_name, item.quantity, item.max_capacity]
		label_3d.modulate = Color(0.9, 0.9, 0.9, 1)

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
