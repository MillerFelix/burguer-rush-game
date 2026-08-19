## Slot do Compartimento de Muçarela
## Responde ao [Clique do Mouse] para pegar/devolver fatias de muçarela.
extends StaticBody3D

func get_interaction_prompt(player: Node = null) -> String:
	var freezer = _get_freezer()
	if not freezer:
		return ""
	return freezer.get_slot_prompt(player, Cheese.CheeseType.MOZZARELLA)

func interact_item(player: Node3D) -> void:
	var freezer = _get_freezer()
	if freezer:
		freezer.handle_slot_item_interaction(player, Cheese.CheeseType.MOZZARELLA)

func interact_return(player: Node3D) -> void:
	return_item(player)

func return_item(player: Node3D) -> void:
	var freezer = _get_freezer()
	if freezer:
		freezer.handle_slot_item_return(player, Cheese.CheeseType.MOZZARELLA)

func _get_freezer() -> CommercialChestFreezer:
	var parent = get_parent()
	if parent and parent is CommercialChestFreezer:
		return parent as CommercialChestFreezer
	return null
