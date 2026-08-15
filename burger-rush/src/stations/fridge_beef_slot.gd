## Compartimento de Carne Bovina da Geladeira
## StaticBody3D posicionado no lado esquerdo do interior.
## Só responde interação quando a porta está aberta.
extends StaticBody3D

func get_interaction_prompt(player: Node = null) -> String:
	var fridge = _get_fridge()
	if not fridge or not fridge.is_open:
		return ""
	if player and player.get("held_item") != null:
		return ""
	var inv = InventoryManager.get_instance()
	var stock = inv.get_stock("patty_beef") if inv else 0
	if stock <= 0:
		return "🔴 Carne Bovina Esgotada! (Reabasteça no Computador)"
	return "🥩 E — Pegar Carne Bovina (%d em estoque)" % stock

func interact(player: Node3D) -> void:
	var fridge = _get_fridge()
	if fridge:
		fridge.pick_meat(player, "patty_beef")

func _get_fridge() -> MeatRefrigerator:
	var parent = get_parent()
	if parent and parent is MeatRefrigerator:
		return parent as MeatRefrigerator
	return null
