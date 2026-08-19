## Compartimento de Carne Bovina da Geladeira
## StaticBody3D no cesto esquerdo.
## Responde ao [Clique do Mouse] para pegar ou devolver carne crua.
extends StaticBody3D

func get_interaction_prompt(player: Node = null) -> String:
	var fridge = _get_fridge()
	if not fridge or not fridge.is_open:
		return ""

	var inv = InventoryManager.get_instance()
	var stock = inv.get_stock("patty_beef") if inv else 0
	var prompt = ""

	if stock > 0:
		prompt = "🥩 🖱️ [Esq] Pegar Carne Bovina (%d un.)" % stock
	else:
		prompt = "🔴 Carne Bovina Esgotada"

	if player and player.has_method("has_matching_ingredient") and player.has_matching_ingredient("patty_beef"):
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
		fridge.pick_meat(player, "patty_beef")
		return

	if player.has_method("has_empty_quick_slot") and not player.has_empty_quick_slot():
		fridge._show_feedback(player, "⚠️ Slots rápidos cheios (3/3)! Use os ingredientes atuais antes de pegar outros.")
		return

	if not inv.has_stock("patty_beef", 1):
		fridge._show_feedback(player, "❌ Sem estoque de Carne Bovina! Compre no computador.")
		return

	fridge.pick_meat(player, "patty_beef")

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

	if player.has_method("has_matching_ingredient") and player.has_matching_ingredient("patty_beef"):
		var returned = player.return_one_matching_ingredient("patty_beef")
		if returned:
			inv.add_stock("patty_beef", 1)
			fridge._show_feedback(player, "🥩 Devolveu 1x Carne Bovina ao freezer")
			fridge._update_patty_visuals()
			return

	fridge._show_feedback(player, "⚠️ Armazenamento incompatível! Este compartimento aceita apenas Carne Bovina.")

func _get_fridge() -> MeatRefrigerator:
	var parent = get_parent()
	if parent and parent is MeatRefrigerator:
		return parent as MeatRefrigerator
	return null
