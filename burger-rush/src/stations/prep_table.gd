class_name PrepTable
extends StaticBody3D

# ================================================================
# ESTAÇÃO DE MOLHOS DA COZINHA (LIMPA E ORGANIZADA)
#
# Bancada limpa contendo as bisnagas de Ketchup, Mostarda,
# Maionese e Molho Especial centralizadas e organizadas.
# ================================================================

var placed_items: Array[Node3D] = []

func _ready() -> void:
	pass

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""

	var held = player.get("held_item")
	if held != null:
		var d_name = held.get_display_name() if held.has_method("get_display_name") else held.name
		return "🖱️ Colocar %s na Bancada de Molhos" % d_name
	elif player.has_method("has_active_ingredient") and player.has_active_ingredient():
		var act = player.get_active_ingredient()
		var d_name = act.get("display_name", "Ingrediente")
		return "🖱️ Colocar %s na Bancada de Molhos" % d_name

	return ""

func interact_item(player: Node3D) -> void:
	var held = player.get("held_item")

	# Colocar item/bisnaga na bancada
	if held != null and player.has_method("take_held_item"):
		var item = player.take_held_item()
		if item:
			var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
			var hit_pos = ray.get_collision_point() if (ray and ray is RayCast3D and ray.is_colliding()) else (global_position + Vector3(0, 0.94, 0))
			_place_item_on_table(item, hit_pos, player.rotation.y)
			var d_name = item.get_display_name() if item.has_method("get_display_name") else item.name
			_show_feedback(player, "%s colocado na bancada de molhos" % d_name)
		return

func interact(player: Node3D) -> void:
	interact_item(player)

func _place_item_on_table(item: Node3D, world_pos: Vector3, player_rot_y: float) -> void:
	var prev_parent = item.get_parent()
	if prev_parent:
		prev_parent.remove_child(item)

	var world_node: Node = get_parent()
	if not world_node:
		world_node = get_tree().current_scene
	if not world_node:
		world_node = get_tree().root

	world_node.add_child(item)
	item.global_position = Vector3(world_pos.x, 0.94, world_pos.z)
	item.rotation = Vector3(0, player_rot_y, 0)

	if item.has_method("on_dropped"):
		item.on_dropped()
	elif item.get("collision_shape") != null and item.collision_shape:
		item.collision_shape.disabled = false

	if "location" in item:
		item.location = Item.ItemLocation.WORLD

	placed_items.append(item)

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
