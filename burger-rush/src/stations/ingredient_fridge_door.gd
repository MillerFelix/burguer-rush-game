## Porta da Geladeira de Hortifrúti e Batatas
## StaticBody3D que faz parte do DoorPivot.
## Responde à tecla [E] para abrir e fechar a porta.
extends StaticBody3D

func get_interaction_prompt(_player: Node = null) -> String:
	var fridge = _get_fridge()
	if not fridge or fridge.is_animating:
		return ""
	if fridge.is_door_open():
		return "E — Fechar Geladeira de Hortifrúti"
	return "E — Abrir Geladeira de Hortifrúti & Batatas"

func interact_equipment(player: Node3D) -> void:
	var fridge = _get_fridge()
	if fridge:
		fridge.toggle_door(player)

func interact(player: Node3D) -> void:
	interact_equipment(player)

func _get_fridge() -> IngredientRefrigerator:
	var pivot = get_parent()
	if pivot:
		var root = pivot.get_parent()
		if root and root is IngredientRefrigerator:
			return root as IngredientRefrigerator
	return null
