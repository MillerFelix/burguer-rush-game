## Slot do Andar 3: Cebola Normal
## Responde ao [Clique do Mouse] para pegar/devolver cebola normal fatiada.
extends StaticBody3D

func get_interaction_prompt(player: Node = null) -> String:
	var fridge = _get_fridge()
	if not fridge:
		return ""
	return fridge.get_ingredient_prompt(player, "onion")

func interact_item(player: Node3D) -> void:
	var fridge = _get_fridge()
	if fridge:
		fridge.handle_ingredient_interaction(player, "onion")

func _get_fridge() -> IngredientRefrigerator:
	var parent = get_parent()
	if parent and parent is IngredientRefrigerator:
		return parent as IngredientRefrigerator
	return null
