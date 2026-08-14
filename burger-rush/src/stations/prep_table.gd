class_name PrepTable
extends StaticBody3D

@onready var item_slot: Node3D = $ItemSlot

var current_item: Node3D = null

func get_interaction_prompt(player: Node = null) -> String:
	if current_item:
		# Mesa ocupada: só permite retirar se o jogador estiver de mãos vazias
		if player and player.get("held_item") != null:
			return ""
		return "E — Pegar " + _item_label()

	# Mesa vazia: só permite colocar se o jogador estiver segurando algo
	if player and player.get("held_item") != null:
		return "E — Colocar na Mesa"

	return ""

func interact(player: Node3D) -> void:
	if current_item:
		if player.get("held_item") == null:
			_give_item_to_player(player)
		return

	if player.get("held_item") != null:
		if player.has_method("take_held_item"):
			var item: Node3D = player.take_held_item()
			if item:
				_place_item(item)

func _place_item(item: Node3D) -> void:
	current_item = item
	item_slot.add_child(item)
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO

	if item.has_method("on_picked_up"):
		# Mantém colisão desativada enquanto na estação
		pass
	if item.get("collision_shape") != null:
		item.collision_shape.disabled = true

func _give_item_to_player(player: Node3D) -> void:
	var item := current_item
	current_item = null
	item_slot.remove_child(item)

	if player.has_method("pick_up"):
		player.pick_up(item)

func _item_label() -> String:
	if current_item == null:
		return "Item"

	var item_id: String = current_item.get("item_id") if current_item.get("item_id") != null else ""
	match item_id:
		"patty":
			var state = current_item.get("state")
			if state == Patty.State.COOKED:
				return "Carne Pronta"
			elif state == Patty.State.BURNT:
				return "Carne Queimada"
			elif state == Patty.State.COOKING:
				return "Carne (Em Preparo)"
			return "Carne Crua"
		"generic":
			return "Item"
		_:
			return current_item.name if item_id == "" else item_id.capitalize()
