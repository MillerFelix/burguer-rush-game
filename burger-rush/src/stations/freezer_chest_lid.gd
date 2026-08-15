## Tampa Articulada do Freezer de Queijos
## StaticBody3D que faz parte do LidPivot.
## Responde à tecla [E] para abrir e fechar a tampa.
extends StaticBody3D

func get_interaction_prompt(_player: Node = null) -> String:
	var freezer = _get_freezer()
	if not freezer or freezer.is_animating:
		return ""
	if freezer.is_door_open():
		return "E — Fechar Tampa do Freezer"
	return "E — Abrir Freezer de Queijos"

func interact_equipment(player: Node3D) -> void:
	var freezer = _get_freezer()
	if freezer:
		freezer.toggle_lid(player)

func interact(player: Node3D) -> void:
	interact_equipment(player)

func _get_freezer() -> CommercialChestFreezer:
	var pivot = get_parent()
	if pivot:
		var root = pivot.get_parent()
		if root and root is CommercialChestFreezer:
			return root as CommercialChestFreezer
	return null
