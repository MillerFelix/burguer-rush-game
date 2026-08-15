## Compartimento de Carne Bovina da Geladeira
## StaticBody3D no cesto esquerdo.
## Responde ao [Clique do Mouse] para pegar ou devolver carne crua.
extends StaticBody3D

func get_interaction_prompt(player: Node = null) -> String:
	var fridge = _get_fridge()
	if not fridge or not fridge.is_open:
		return ""

	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held is Patty and held.meat_type == Patty.MeatType.BEEF and held.state == Patty.State.RAW:
			return "🖱️ Clique para Devolver Carne Bovina"
		return ""

	var inv = InventoryManager.get_instance()
	var stock = inv.get_stock("patty_beef") if inv else 0
	if stock <= 0:
		return "🔴 Carne Bovina Esgotada! (Reabasteça no Computador)"
	return "🥩 🖱️ Clique para Pegar Carne Bovina (%d em estoque)" % stock

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
		if held is Patty and held.meat_type == Patty.MeatType.BEEF and held.state == Patty.State.RAW:
			player.take_held_item().queue_free()
			inv.add_stock("patty_beef", 1)
			fridge._show_feedback(player, "🥩 Devolveu Carne Bovina ao freezer (Estoque: %d)" % inv.get_stock("patty_beef"))
			fridge._update_label()
			fridge._update_patty_visuals()
		else:
			fridge._show_feedback(player, "Mãos ocupadas! Devolva o item atual antes de pegar outro.")
		return

	# Retirada de item com mãos livres
	fridge.pick_meat(player, "patty_beef")

func _get_fridge() -> MeatRefrigerator:
	var parent = get_parent()
	if parent and parent is MeatRefrigerator:
		return parent as MeatRefrigerator
	return null
