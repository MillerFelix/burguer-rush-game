## Compartimento de Frango da Geladeira
## StaticBody3D no cesto direito.
## Responde ao [Clique do Mouse] para pegar ou devolver hambúrguer de frango cru.
extends StaticBody3D

func get_interaction_prompt(player: Node = null) -> String:
	var fridge = _get_fridge()
	if not fridge or not fridge.is_open:
		return ""

	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held is Patty and held.meat_type == Patty.MeatType.CHICKEN and held.state == Patty.State.RAW:
			return "🍗 🖱️ Devolver Frango"
		return ""

	var inv = InventoryManager.get_instance()
	var stock = inv.get_stock("patty_chicken") if inv else 0
	if stock <= 0:
		return "🔴 Frango Esgotado"
	return "🍗 🖱️ Pegar Hambúrguer de Frango"

func interact_item(player: Node3D) -> void:
	var fridge = _get_fridge()
	if not fridge or not fridge.is_open:
		return

	var inv = InventoryManager.get_instance()
	if not inv:
		return

	# Devolução de item
	if player.get("held_item") != null:
		var held = player.get("held_item")
		if held is Patty and held.meat_type == Patty.MeatType.CHICKEN and held.state == Patty.State.RAW:
			player.take_held_item().queue_free()
			inv.add_stock("patty_chicken", 1)
			fridge._show_feedback(player, "🍗 Devolveu Frango ao freezer")
			fridge._update_patty_visuals()
		else:
			fridge._show_feedback(player, "Mãos ocupadas! Devolva o item atual antes de pegar outro.")
		return

	# Retirada de item com mãos livres
	fridge.pick_meat(player, "patty_chicken")

func _get_fridge() -> MeatRefrigerator:
	var parent = get_parent()
	if parent and parent is MeatRefrigerator:
		return parent as MeatRefrigerator
	return null
