class_name SodaRefillRack
extends StaticBody3D

# ================================================================
# SUPORTE METÁLICO DE REFIS DE REFRIGERANTE NO ARMAZÉM
#
# Armazena exatamente 1 unidade de reserva para cada um dos
# 4 sabores de xarope da máquina de refrigerantes:
#  - Slot 0: Cola        (syrup_cola)
#  - Slot 1: Cola Zero   (syrup_cola_zero)
#  - Slot 2: Soda Limão  (syrup_lemon)
#  - Slot 3: Citrus      (syrup_orange)
#
# Itens físicos manipuláveis:
#  - Clique Esquerdo: Pegar / Colocar no suporte
#  - Limite estrito: Máximo 1 refil de cada sabor na reserva
# ================================================================

var SYRUP_CANISTER_SCENE = load("res://src/items/syrup_canister.tscn")
const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

const SLOTS_CONFIG: Array[Dictionary] = [
	{ "id": "cola", "name": "Cola", "item_id": "syrup_cola", "flavor_type": "soda_cola", "pos": Vector3(-0.54, 0.17, 0.0) },
	{ "id": "cola_zero", "name": "Cola Zero", "item_id": "syrup_cola_zero", "flavor_type": "soda_cola_zero", "pos": Vector3(-0.18, 0.17, 0.0) },
	{ "id": "soda", "name": "Soda", "item_id": "syrup_lemon", "flavor_type": "soda_lime", "pos": Vector3(0.18, 0.17, 0.0) },
	{ "id": "citrus", "name": "Citrus", "item_id": "syrup_orange", "flavor_type": "soda_citrus", "pos": Vector3(0.54, 0.17, 0.0) }
]

var canisters: Array[SyrupCanister] = [null, null, null, null]
@onready var slots_container: Node3D = $Model/Slots

func _ready() -> void:
	_init_default_reserves()

func _init_default_reserves() -> void:
	for i in range(4):
		var slot_node = slots_container.get_node_or_null("Slot%d" % i) if slots_container else null
		if not slot_node:
			continue

		# Se já houver um nó filho instanciado na cena
		var existing_can: SyrupCanister = null
		for child in slot_node.get_children():
			if child is SyrupCanister:
				existing_can = child
				break

		if not existing_can:
			var new_can: SyrupCanister = SYRUP_CANISTER_SCENE.instantiate() as SyrupCanister
			new_can.flavor_type = SLOTS_CONFIG[i].flavor_type
			new_can.current_amount = 25.0
			slot_node.add_child(new_can)
			new_can.position = Vector3.ZERO
			new_can.rotation = Vector3(0, PI, 0)
			if new_can is CollisionObject3D:
				new_can.collision_layer = 1
				new_can.collision_mask = 1
			canisters[i] = new_can
		else:
			canisters[i] = existing_can

func get_slot_index_from_raycast(player: Node3D) -> int:
	if not player:
		return 0
	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if ray and ray is RayCast3D and ray.is_colliding():
		var col_pt = to_local(ray.get_collision_point())
		# Distribuição ao longo do eixo X local (-0.72 a +0.72)
		if col_pt.x < -0.36:
			return 0
		elif col_pt.x < 0.0:
			return 1
		elif col_pt.x < 0.36:
			return 2
		else:
			return 3
	return 0

func get_slot_for_canister(can: SyrupCanister) -> int:
	if not can:
		return -1
	var cid = can.item_id
	var flav = can.flavor_type
	for i in range(4):
		if cid == SLOTS_CONFIG[i].item_id or flav == SLOTS_CONFIG[i].flavor_type:
			return i
	# Aliases
	if flav.contains("cola_zero") or flav.contains("zero"):
		return 1
	elif flav.contains("cola"):
		return 0
	elif flav.contains("soda") or flav.contains("lemon") or flav.contains("lime"):
		return 2
	elif flav.contains("citrus") or flav.contains("orange"):
		return 3
	return -1

func has_reserve(slot_idx: int) -> bool:
	if slot_idx < 0 or slot_idx >= 4:
		return false
	return canisters[slot_idx] != null and is_instance_valid(canisters[slot_idx])

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""

	var held = player.get("held_item")
	var target_slot = get_slot_index_from_raycast(player)

	if held is SyrupCanister:
		var slot_for_held = get_slot_for_canister(held)
		if slot_for_held != -1:
			if has_reserve(slot_for_held):
				return "Refil de %s já em estoque (Máx. 1)" % SLOTS_CONFIG[slot_for_held].name
			else:
				return "🛢️ 🖱️ [Dir] Devolver Refil de %s ao suporte" % SLOTS_CONFIG[slot_for_held].name
		return ""

	if held != null and str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
		return "📦 🖱️ [Esq] Armazenar Refil no suporte"

	if held == null:
		if has_reserve(target_slot):
			return "🛢️ 🖱️ [Esq] Pegar Refil de %s" % SLOTS_CONFIG[target_slot].name
		else:
			return "Espaço de %s Vazio" % SLOTS_CONFIG[target_slot].name

	return ""

# [Clique Esquerdo] — Pegar Refil ou Armazenar Caixa de Entrega (NUNCA Devolver Refil solto)
func interact_item(player: Node3D) -> void:
	if not player:
		return

	var held = player.get("held_item")

	# 1. Jogador segurando caixa de entrega: armazena no suporte
	if held != null and str(held.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
		var box_item_id = str(held.get("contained_item_id"))
		var slot_idx = -1
		match box_item_id:
			"cylinder_cola", "syrup_cola": slot_idx = 0
			"cylinder_cola_zero", "syrup_cola_zero": slot_idx = 1
			"cylinder_soda", "syrup_lemon", "syrup_soda": slot_idx = 2
			"cylinder_citrus", "syrup_orange", "syrup_citrus": slot_idx = 3

		if slot_idx != -1:
			if has_reserve(slot_idx):
				_show_feedback(player, "⚠️ Já existe 1 refil de %s na reserva! (Limite máximo atingido)" % SLOTS_CONFIG[slot_idx].name)
				return
			player.take_held_item().queue_free()
			var new_can: SyrupCanister = SYRUP_CANISTER_SCENE.instantiate() as SyrupCanister
			new_can.flavor_type = SLOTS_CONFIG[slot_idx].flavor_type
			new_can.current_amount = 25.0
			place_canister(slot_idx, new_can)
			var inv = InventoryManager.get_instance()
			if inv:
				inv.add_stock(box_item_id, 1)
			_show_feedback(player, "📦 Refil de %s armazenado no suporte (+1 un.)!" % SLOTS_CONFIG[slot_idx].name)
			return
		else:
			_show_feedback(player, "⚠️ Local incorreto! Esta caixa contém %s. Leve até a estação correta." % str(held.get("contained_item_name")))
			return

	# Se está segurando o refil solto, LMB não devolve!
	if held is SyrupCanister:
		_show_feedback(player, "ℹ️ Use o [Clique Direito] para devolver o refil ao suporte.")
		return

	# 2. Jogador de mãos livres: pega o refil do slot apontado
	if held == null:
		var slot_idx = get_slot_index_from_raycast(player)
		if has_reserve(slot_idx):
			var can = take_canister(slot_idx)
			if can and player.has_method("pick_up"):
				player.pick_up(can)
				_show_feedback(player, "🛢️ Pegou refil de %s" % SLOTS_CONFIG[slot_idx].name)
		else:
			_show_feedback(player, "O espaço de %s está vazio." % SLOTS_CONFIG[slot_idx].name)

# [Clique Direito] — DEVOLVER Refil ao Suporte
func interact_return(player: Node3D) -> void:
	return_item(player)

func return_item(player: Node3D) -> void:
	if not player:
		return

	var held = player.get("held_item")
	if held is SyrupCanister:
		var slot_idx = get_slot_for_canister(held)
		if slot_idx == -1:
			_show_feedback(player, "⚠️ Refil incompatível com este suporte.")
			return

		if has_reserve(slot_idx):
			_show_feedback(player, "⚠️ Já existe 1 refil de %s na reserva! (Limite máximo atingido)" % SLOTS_CONFIG[slot_idx].name)
			return

		var taken = player.take_held_item() as SyrupCanister
		if taken:
			place_canister(slot_idx, taken)
			_show_feedback(player, "🛢️ Devolveu 1x Refil de %s ao suporte" % SLOTS_CONFIG[slot_idx].name)
		return

	_show_feedback(player, "⚠️ Armazenamento incompatível! Segure um refil de refrigerante para devolver.")

func interact(player: Node3D) -> void:
	interact_item(player)

func take_canister(slot_idx: int) -> SyrupCanister:
	if slot_idx < 0 or slot_idx >= 4:
		return null
	var can = canisters[slot_idx]
	if not can or not is_instance_valid(can):
		return null

	canisters[slot_idx] = null
	if can.get_parent():
		can.get_parent().remove_child(can)
	return can

func place_canister(slot_idx: int, can: SyrupCanister) -> bool:
	if slot_idx < 0 or slot_idx >= 4 or not can:
		return false

	var expected_slot = get_slot_for_canister(can)
	if expected_slot != slot_idx:
		return false

	if has_reserve(slot_idx):
		return false

	if can.get_parent():
		can.get_parent().remove_child(can)

	var slot_node = slots_container.get_node_or_null("Slot%d" % slot_idx) if slots_container else null
	if not slot_node:
		return false

	slot_node.add_child(can)
	can.position = Vector3.ZERO
	can.rotation = Vector3(0, PI, 0)
	can.is_held = false
	can.location = Item.ItemLocation.STATION
	if can is CollisionObject3D:
		can.collision_layer = 1
		can.collision_mask = 1

	canisters[slot_idx] = can
	return true

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
