## Compartimento de Frango da Geladeira
## StaticBody3D no cesto direito.
## Responde ao [Clique do Mouse] para pegar ou devolver hambúrguer de frango cru.
extends StaticBody3D

func get_interaction_prompt(player: Node = null) -> String:
	var fridge = _get_fridge()
	if not fridge or not fridge.is_open:
		return ""

	var inv = InventoryManager.get_instance()
	var stock = inv.get_stock("patty_chicken") if inv else 0
	var prompt = ""

	if stock > 0:
		prompt = "🍗 🖱️ [Esq] Pegar Hambúrguer de Frango (%d un.)" % stock
	else:
		prompt = "🔴 Frango Esgotado"

	if player and player.has_method("has_matching_ingredient") and player.has_matching_ingredient("patty_chicken"):
		prompt += " | 🖱️ [Dir] Devolver 1x"

	return prompt

# Clique Esquerdo (LMB) — APENAS PEGAR / REABASTECER CAIXA (NUNCA DEVOLVER)
func interact_item(player: Node3D) -> void:
	var fridge = _get_fridge()
	if not fridge or not fridge.is_open:
		return

	var inv = InventoryManager.get_instance()
	if not inv:
		return

	var held = player.get("held_item") if player else null
	if held != null and str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
		fridge.pick_meat(player, "patty_chicken")
		return

	if player.has_method("has_empty_quick_slot") and not player.has_empty_quick_slot():
		fridge._show_feedback(player, "⚠️ Slots rápidos cheios (3/3)! Use os ingredientes atuais antes de pegar outros.")
		return

	if not inv.has_stock("patty_chicken", 1):
		fridge._show_feedback(player, "❌ Sem estoque de Hambúrguer de Frango! Compre no computador.")
		return

	fridge.pick_meat(player, "patty_chicken")

# Clique Direito (RMB) — APENAS DEVOLVER 1 UNIDADE
func interact_return(player: Node3D) -> void:
	return_item(player)

func return_item(player: Node3D) -> void:
	var fridge = _get_fridge()
	if not fridge or not fridge.is_open:
		return

	var inv = InventoryManager.get_instance()
	if not inv:
		return

	if player.has_method("has_matching_ingredient") and player.has_matching_ingredient("patty_chicken"):
		var returned = player.return_one_matching_ingredient("patty_chicken")
		if returned:
			inv.add_stock("patty_chicken", 1)
			fridge._show_feedback(player, "🍗 Devolveu 1x Frango ao freezer")
			fridge._update_patty_visuals()
			return

	fridge._show_feedback(player, "⚠️ Armazenamento incompatível! Este compartimento aceita apenas Hambúrguer de Frango.")

func _get_fridge() -> MeatRefrigerator:
	var parent = get_parent()
	if parent and parent is MeatRefrigerator:
		return parent as MeatRefrigerator
	return null
