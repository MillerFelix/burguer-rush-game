class_name BurgerBox
extends Item

# ================================================================
# CAIXA DE HAMBÚRGUER (EMBALAGEM VAZIA)
# Usada pelo jogador para embalar lanches prontos na bancada
# ================================================================

func _ready() -> void:
	item_id = "burger_box"
	display_name = "Caixa de Hambúrguer"
	item_type = "packaging"
	prompt_text = "🖱️ Pegar Caixa de Hambúrguer"

func get_display_name() -> String:
	return "Caixa de Hambúrguer"

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD and location != ItemLocation.TRAY and location != ItemLocation.TABLE and location != ItemLocation.STATION:
		return ""
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		var assembly = _get_burger_assembly(held)
		if assembly:
			return "🖱️ Colocar Hambúrguer na Caixa"
		return ""
	return "🖱️ Pegar Caixa de Hambúrguer"

func interact_item(player: Node3D) -> void:
	if not player:
		return

	var held = player.get("held_item")
	if held == null:
		if player.has_method("pick_up"):
			player.pick_up(self)
		return

	var assembly = _get_burger_assembly(held)
	if assembly:
		if assembly.has_method("can_package") and assembly.can_package():
			player.take_held_item() # Solta o hambúrguer segurado
			assembly.package_burger(self, player)
		else:
			_show_feedback(player, "⚠️ Feche o hambúrguer com a tampa do pão antes de embalar.")
		return

func _get_burger_assembly(item: Node3D) -> Node:
	if not item:
		return null
	if item.has_node("BurgerAssembly"):
		return item.get_node("BurgerAssembly")
	if "assembly" in item and item.assembly != null:
		return item.assembly
	if item is BurgerAssembly:
		return item
	return null

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
