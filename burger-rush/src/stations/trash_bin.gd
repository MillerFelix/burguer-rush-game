class_name TrashBin
extends StaticBody3D

@onready var status_label: Label3D = $StatusLabel

func _ready() -> void:
	_update_label()

func get_interaction_prompt(player: Node = null) -> String:
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		var name_str = held.get_display_name() if held.has_method("get_display_name") else "Item"
		return "E — Descartar %s no Lixo" % name_str
	return ""

func interact(player: Node3D) -> void:
	if player and player.get("held_item") != null and player.has_method("take_held_item"):
		var held = player.take_held_item()
		if not held:
			return

		var item_id = str(held.get("item_id"))
		var item_name = held.get_display_name() if held.has_method("get_display_name") else "Item"

		# Calcula custo do item descartado para o WasteManager
		var cost = 1.0
		var inv = InventoryManager.get_instance()
		if inv and inv.get_item(item_id):
			cost = inv.get_item(item_id).unit_cost
		else:
			var recipe = RecipeDatabase.get_recipe_by_id(item_id)
			if recipe:
				cost = recipe.calculate_cost()

		var reason = "Descarte Manual"
		if held is Patty and (held as Patty).state == Patty.State.BURNT:
			reason = "Carne Queimada"

		var waste_mgr = WasteManager.get_instance()
		if waste_mgr:
			waste_mgr.register_waste(item_id, item_name, 1, cost, reason)

		held.queue_free()
		_show_feedback(player, "🗑️ %s descartado no lixo (-$%.2f de perda)." % [item_name, cost])
		_update_label()

func _update_label() -> void:
	if not status_label:
		return
	var waste_mgr = WasteManager.get_instance()
	var daily_loss = waste_mgr.get_daily_waste_cost() if waste_mgr else 0.0
	status_label.text = "🗑️ LIXEIRA\nPerda Hoje: $%.2f" % daily_loss
	status_label.modulate = Color(1.0, 0.4, 0.4, 1.0) if daily_loss > 0 else Color(0.7, 0.7, 0.7, 1.0)

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
