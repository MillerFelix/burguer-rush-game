class_name ServingTray
extends Item

# ================================================================
# BANDEJA DE SERVIÇO PARA PEDIDOS NO SALÃO (BURGER RUSH)
#
# Item físico de restaurante com alta capacidade de acomodação
# (até 16 produtos). Suporta montagens de grandes banquetes
# com múltiplos lanches, copos e batatas, acomodando itens
# em camadas sobrepostas e agrupadas de forma realista.
#
# Estados:
#  - CLEAN:   Bandeja limpa e pronta para uso
#  - IN_USE:  Bandeja com itens sendo montados
#  - READY:   Pedido completo pronto para entrega na mesa
#  - USED:    Bandeja usada na mesa após cliente consumir a refeição
# ================================================================

enum TrayState {
	CLEAN,
	IN_USE,
	READY,
	USED
}

@export var tray_state: TrayState = TrayState.CLEAN
@export var max_capacity: int = 16

@onready var tray_slot: Node3D = get_node_or_null("TraySlot")

var carried_items: Array[Node3D] = []

# Posições predefinidas de acomodação para empilhamento inteligente
const BURGER_POSITIONS: Array[Vector3] = [
	Vector3(-0.19, 0.000, 0.09),   # Lanche 1 (Frente Esquerda)
	Vector3(0.00,  0.000, 0.09),   # Lanche 2 (Frente Centro)
	Vector3(0.19,  0.000, 0.09),   # Lanche 3 (Frente Direita)
	Vector3(-0.095, 0.032, 0.06),  # Lanche 4 (Sobreposto 1-2)
	Vector3(0.095,  0.032, 0.06),  # Lanche 5 (Sobreposto 2-3)
	Vector3(0.00,   0.058, 0.04),  # Lanche 6 (Topo Central)
	Vector3(-0.19, 0.032, 0.06),   # Lanche 7 (Sobreposto Esquerda)
	Vector3(0.19,  0.032, 0.06)    # Lanche 8 (Sobreposto Direita)
]

const DRINK_POSITIONS: Array[Vector3] = [
	Vector3(0.00,  0.000, -0.09),  # Copo 1 (Traseira Centro)
	Vector3(0.19,  0.000, -0.09),  # Copo 2 (Traseira Direita)
	Vector3(-0.09, 0.000, -0.11),  # Copo 3 (Traseira Centro-Esquerda)
	Vector3(0.10,  0.000, -0.11),  # Copo 4 (Traseira Centro-Direita)
	Vector3(0.19,  0.000, 0.00),   # Copo 5 (Lateral Direita)
	Vector3(-0.09, 0.000, -0.02)   # Copo 6 (Meio Traseiro)
]

const SIDE_POSITIONS: Array[Vector3] = [
	Vector3(-0.19, 0.000, -0.09),  # Batata 1 (Traseira Esquerda)
	Vector3(-0.19, 0.028, -0.07),  # Batata 2 (Sobreposta Esquerda)
	Vector3(-0.19, 0.000, 0.00),   # Batata 3 (Lateral Esquerda)
	Vector3(0.00,  0.028, -0.07)   # Batata 4 (Sobreposta Centro)
]

func _ready() -> void:
	item_id = "serving_tray"
	display_name = "Bandeja"
	item_type = "tray"
	prompt_text = "🖱️ Pegar Bandeja"

	if not tray_slot:
		tray_slot = get_node_or_null("TraySlot")
		if not tray_slot:
			tray_slot = Node3D.new()
			tray_slot.name = "TraySlot"
			add_child(tray_slot)

func is_used() -> bool:
	return tray_state == TrayState.USED

func is_clean() -> bool:
	return tray_state == TrayState.CLEAN and carried_items.is_empty()

func has_items() -> bool:
	return not carried_items.is_empty()

func get_products() -> Array[Node3D]:
	return carried_items

func add_item(item: Node3D) -> bool:
	return add_product(item)

func add_product(item: Node3D) -> bool:
	if not item or carried_items.size() >= max_capacity:
		return false

	var prev_parent = item.get_parent()
	if prev_parent:
		prev_parent.remove_child(item)

	if not tray_slot:
		tray_slot = get_node_or_null("TraySlot")
		if not tray_slot:
			tray_slot = Node3D.new()
			tray_slot.name = "TraySlot"
			add_child(tray_slot)

	var i_id = str(item.get("item_id"))
	var i_type = str(item.get("item_type"))

	var is_burger = i_id.contains("burger") or i_id.contains("sandwich") or i_id == "cheeseburger" or i_id == "burger_box" or i_id == "packaged_burger" or i_type == "burger"
	var is_drink = i_id.contains("cup") or i_id.contains("drink") or i_id.contains("juice") or i_id.contains("soda") or i_type == "drink"
	var is_side = i_id.contains("potato") or i_id.contains("fries") or i_id == "potato_box" or i_id == "fries_pack" or i_type == "fries"

	# Conta itens do mesmo tipo já na bandeja para calcular posição escalonada/amontoada
	var same_type_count = 0
	for existing in carried_items:
		var eid = str(existing.get("item_id"))
		var etype = str(existing.get("item_type"))
		if is_burger and (eid.contains("burger") or eid.contains("sandwich") or eid == "cheeseburger" or eid == "burger_box" or eid == "packaged_burger" or etype == "burger"):
			same_type_count += 1
		elif is_drink and (eid.contains("cup") or eid.contains("drink") or eid.contains("juice") or eid.contains("soda") or etype == "drink"):
			same_type_count += 1
		elif is_side and (eid.contains("potato") or eid.contains("fries") or eid == "potato_box" or eid == "fries_pack" or etype == "fries"):
			same_type_count += 1

	var target_pos = Vector3.ZERO

	if is_burger:
		var b_idx = same_type_count % BURGER_POSITIONS.size()
		target_pos = BURGER_POSITIONS[b_idx]
	elif is_drink:
		var d_idx = same_type_count % DRINK_POSITIONS.size()
		target_pos = DRINK_POSITIONS[d_idx]
	elif is_side:
		var s_idx = same_type_count % SIDE_POSITIONS.size()
		target_pos = SIDE_POSITIONS[s_idx]
	else:
		# Item genérico: posiciona na grade com elevação em camadas
		var count = carried_items.size()
		var col = count % 3
		var row = (count / 3) % 2
		var layer = count / 6
		target_pos = Vector3((col - 1.0) * 0.19, layer * 0.035, 0.09 if row == 0 else -0.09)

	tray_slot.add_child(item)
	item.position = target_pos
	item.rotation = Vector3.ZERO

	if item.has_method("on_placed_in_tray"):
		item.on_placed_in_tray()
	elif item.has_method("on_picked_up"):
		item.on_picked_up()
	elif item is CollisionObject3D:
		item.collision_layer = 0
		item.collision_mask = 0

	carried_items.append(item)
	tray_state = TrayState.IN_USE
	return true

func remove_product(item: Node3D) -> bool:
	if carried_items.has(item):
		carried_items.erase(item)
		if item.get_parent():
			item.get_parent().remove_child(item)
		if carried_items.is_empty() and tray_state != TrayState.USED:
			tray_state = TrayState.CLEAN
		return true
	return false

func remove_top_product() -> Node3D:
	if carried_items.is_empty():
		return null
	var item = carried_items.pop_back()
	if item.get_parent():
		item.get_parent().remove_child(item)
	if carried_items.is_empty() and tray_state != TrayState.USED:
		tray_state = TrayState.CLEAN
	return item

func clear_tray() -> void:
	for item in carried_items:
		if is_instance_valid(item):
			item.queue_free()
	carried_items.clear()
	tray_state = TrayState.CLEAN

func consume_food_items() -> void:
	for item in carried_items:
		if is_instance_valid(item):
			item.queue_free()
	carried_items.clear()
	tray_state = TrayState.USED

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD and location != ItemLocation.TABLE and location != ItemLocation.STATION:
		return ""

	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held != self:
			var h_name = held.get_display_name() if held.has_method("get_display_name") else held.name
			if carried_items.size() < max_capacity:
				return "🖱️ Colocar %s na Bandeja" % h_name
		return ""

	if tray_state == TrayState.USED:
		return "🖱️ Recolher Bandeja Usada"
	elif carried_items.size() > 0:
		return "🖱️ Pegar Bandeja com Pedido (%d itens)" % carried_items.size()
	return "🖱️ Pegar Bandeja"

# Clique Esquerdo — manipulação exclusiva de itens
func interact_item(player: Node3D) -> void:
	if not player:
		return

	var held = player.get("held_item")

	# Se o jogador estiver segurando um alimento/embalagem: coloca sobre a bandeja
	if held != null and held != self:
		if carried_items.size() < max_capacity:
			var taken = player.take_held_item()
			if taken:
				add_product(taken)
				_show_feedback(player, "🍱 %s colocado na bandeja" % taken.display_name)
		else:
			_show_feedback(player, "Bandeja cheia!")
		return

	# Se o jogador estiver de mãos livres: pega a bandeja física com tudo o que estiver em cima
	if held == null:
		if player.has_method("pick_up"):
			player.pick_up(self)
			if tray_state == TrayState.USED:
				_show_feedback(player, "🍽️ Bandeja usada recolhida")
			elif carried_items.size() > 0:
				_show_feedback(player, "🍱 Pegou bandeja com %d itens" % carried_items.size())
			else:
				_show_feedback(player, "🍽️ Pegou bandeja")

func interact(player: Node3D) -> void:
	# Tecla E solta se segurada ou orienta
	if player.get("held_item") == self:
		player.drop_item()
	elif player.get("held_item") == null:
		_show_feedback(player, "ℹ️ Use o [Clique Esquerdo] para pegar a bandeja.")
	else:
		_show_feedback(player, "ℹ️ Use o [Clique Esquerdo] para colocar o item na bandeja.")

func _show_feedback(player: Node3D, message: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback(message)
