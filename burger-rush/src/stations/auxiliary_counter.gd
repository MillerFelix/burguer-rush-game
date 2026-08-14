class_name AuxiliaryCounter
extends StaticBody3D

@onready var item_slot: Node3D = $ItemSlot
@onready var status_label: Label3D = $StatusLabel

var placed_item: Node3D = null

func _ready() -> void:
	_update_label()

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""
	var held = player.get("held_item")
	if held != null and placed_item == null:
		var d_name = held.get_display_name() if held.has_method("get_display_name") else held.name
		return "E — Colocar %s na Bancada Auxiliar" % d_name
	elif held == null and placed_item != null:
		var d_name = placed_item.get_display_name() if placed_item.has_method("get_display_name") else placed_item.name
		return "E — Pegar %s" % d_name
	return ""

func interact(player: Node3D) -> void:
	var held = player.get("held_item")

	# 1. Colocar item na bancada vazia
	if held != null and placed_item == null:
		if player.has_method("take_held_item"):
			var item = player.take_held_item()
			if item:
				var prev_parent = item.get_parent()
				if prev_parent:
					prev_parent.remove_child(item)
				if item_slot:
					item_slot.add_child(item)
				else:
					add_child(item)
				item.position = Vector3.ZERO
				item.rotation = Vector3.ZERO
				placed_item = item
				_update_label()
				_show_feedback(player, "Bancada Auxiliar: %s colocado" % (item.get_display_name() if item.has_method("get_display_name") else item.name))
		return

	# 2. Pegar item da bancada com mãos livres
	if held == null and placed_item != null:
		var item = placed_item
		placed_item = null
		if item_slot and item.get_parent() == item_slot:
			item_slot.remove_child(item)
		if player.has_method("pick_up"):
			player.pick_up(item)
		_update_label()
		_show_feedback(player, "Pegou %s da bancada" % (item.get_display_name() if item.has_method("get_display_name") else item.name))

func _update_label() -> void:
	if not status_label:
		return
	if placed_item:
		var d_name = placed_item.get_display_name() if placed_item.has_method("get_display_name") else placed_item.name
		status_label.text = "🍽️ %s" % d_name
		status_label.modulate = Color(0.3, 1.0, 0.4, 1.0)
	else:
		status_label.text = ""

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
