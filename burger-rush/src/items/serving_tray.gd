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

	if item is CollisionObject3D:
		item.collision_layer = 1
		item.collision_mask = 1

	for child in item.find_children("*", "CollisionObject3D", true, false):
		if child is CollisionObject3D:
			child.collision_layer = 1
			child.collision_mask = 1

	if item.has_method("on_placed_in_tray"):
		item.on_placed_in_tray()

	if item is Item:
		item.is_held = false
		item.location = Item.ItemLocation.TRAY
		item._is_falling = false

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

	var held = player.get("held_item") if player else null
	var has_act = player.has_active_ingredient() if (player and player.has_method("has_active_ingredient")) else false

	if (held != null and held != self) or has_act:
		if carried_items.size() < max_capacity:
			return "🖱️ [Dir] Colocar na Bandeja  │  [E] Pegar Bandeja"
		else:
			return "⚠️ Bandeja Cheia  │  [E] Pegar Bandeja"

	if tray_state == TrayState.USED:
		return "[E] Recolher Bandeja Usada"
	elif carried_items.size() > 0:
		return "[E] Pegar Bandeja com Pedido (%d itens)" % carried_items.size()
	return "[E] Pegar Bandeja"

# Clique Esquerdo — NÃO pega a bandeja inteira (para pegar a bandeja inteira usa-se E)
func interact_item(player: Node3D) -> void:
	if not player:
		return
	_show_feedback(player, "ℹ️ Pressione [E] para pegar a bandeja.")

# Tecla E — PEGAR A BANDEJA INTEIRA COM TODOS OS PRODUTOS DENTRO
func interact(player: Node3D) -> void:
	if not player:
		return

	if player.get("held_item") == self:
		player.drop_item()
		return

	if player.has_method("is_holding_large_item") and player.is_holding_large_item():
		_show_feedback(player, "⚠️ Mãos ocupadas! Solte o item atual antes de pegar a bandeja.")
		return

	var p = get_parent()
	while p != null:
		if p is RestaurantTable:
			p.served_items.erase(self)
			break
		p = p.get_parent()

	if player.has_method("pick_up"):
		player.pick_up(self)
		if tray_state == TrayState.USED:
			_show_feedback(player, "🍽️ Bandeja usada recolhida")
		elif carried_items.size() > 0:
			_show_feedback(player, "🍱 Pegou bandeja com %d itens" % carried_items.size())
		else:
			_show_feedback(player, "🍽️ Pegou bandeja")

func _show_feedback(player: Node3D, message: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback(message)
