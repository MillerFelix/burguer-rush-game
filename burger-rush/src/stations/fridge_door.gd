## Porta da Geladeira de Carnes
## StaticBody3D que faz parte do DoorPivot.
## Chama toggle_door() no nó raiz da geladeira.
extends StaticBody3D

func get_interaction_prompt(_player: Node = null) -> String:
	var fridge = _get_fridge()
	if not fridge:
		return ""
	if fridge.is_animating:
		return ""
	if fridge.is_open:
		return "E — Fechar Geladeira"
	return "E — Abrir Geladeira de Carnes"

func interact(player: Node3D) -> void:
	var fridge = _get_fridge()
	if fridge:
		fridge.toggle_door(player)

func _get_fridge() -> MeatRefrigerator:
	# DoorPivot -> MeatRefrigerator (pai do pivot)
	var pivot = get_parent()
	if pivot:
		var root = pivot.get_parent()
		if root and root is MeatRefrigerator:
			return root as MeatRefrigerator
	return null
