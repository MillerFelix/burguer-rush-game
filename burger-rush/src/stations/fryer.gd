class_name Fryer
extends StaticBody3D

enum OilQuality {
	NEW,
	GOOD,
	USED,
	BAD
}

@export var cook_time: float = 4.0
@export var burn_time: float = 8.0
@export var max_capacity: int = 4

@onready var slot: Node3D = $FryerSlot
@onready var status_label: Label3D = $StatusLabel

var active_potatoes: Array[Dictionary] = [] # Array de { "potato": Potato, "timer": float, "slot_index": int }
var oil_uses: int = 0
var fries_pack_scene: PackedScene = preload("res://src/items/fries_pack.tscn")

# Offsets dos 4 cestos de fritura (largura 1.8m)
const SLOT_OFFSETS = [
	Vector3(-0.585, 0.0, 0.0),
	Vector3(-0.195, 0.0, 0.0),
	Vector3(0.195, 0.0, 0.0),
	Vector3(0.585, 0.0, 0.0)
]

# Getters de compatibilidade
var current_potato: Potato:
	get:
		if active_potatoes.is_empty():
			return null
		for item in active_potatoes:
			var p = item["potato"] as Potato
			if is_instance_valid(p) and (p.state == Potato.State.COOKED or p.state == Potato.State.BURNT):
				return p
		return active_potatoes[0]["potato"] if is_instance_valid(active_potatoes[0]["potato"]) else null
	set(value):
		if value == null:
			active_potatoes.clear()
		else:
			if active_potatoes.is_empty():
				place_potato(value)

var cooking_timer: float:
	get:
		if active_potatoes.is_empty():
			return 0.0
		return active_potatoes[0]["timer"]
	set(val):
		if not active_potatoes.is_empty():
			active_potatoes[0]["timer"] = val

func _ready() -> void:
	_update_visual_status()

func get_oil_quality() -> OilQuality:
	if oil_uses < 6:
		return OilQuality.NEW
	elif oil_uses < 12:
		return OilQuality.GOOD
	elif oil_uses < 20:
		return OilQuality.USED
	else:
		return OilQuality.BAD

func get_oil_quality_name() -> String:
	match get_oil_quality():
		OilQuality.NEW:
			return "🟢 Novo"
		OilQuality.GOOD:
			return "🟢 Bom"
		OilQuality.USED:
			return "🟡 Usado"
		OilQuality.BAD:
			return "🔴 Saturado / Troca Necessária"
	return "Desconhecido"

func is_oil_bad() -> bool:
	return get_oil_quality() == OilQuality.BAD

func get_effective_cook_time() -> float:
	return cook_time + (2.0 if is_oil_bad() else 0.0)

func _process(delta: float) -> void:
	if active_potatoes.is_empty():
		return

	var eff_cook = get_effective_cook_time()

	for item in active_potatoes:
		var potato = item["potato"] as Potato
		if not is_instance_valid(potato):
			continue

		item["timer"] += delta
		var timer = item["timer"] as float

		if timer >= burn_time:
			if potato.state != Potato.State.BURNT:
				potato.set_state(Potato.State.BURNT)
		elif timer >= eff_cook:
			if potato.state != Potato.State.COOKED:
				potato.set_state(Potato.State.COOKED)

	_update_visual_status()

func get_interaction_prompt(player: Node = null) -> String:
	# 1. Se houver batata frita pronta ou queimada
	if not active_potatoes.is_empty():
		var ready_count = 0
		var burnt_count = 0
		for item in active_potatoes:
			var p = item["potato"] as Potato
			if is_instance_valid(p):
				if p.state == Potato.State.COOKED:
					ready_count += 1
				elif p.state == Potato.State.BURNT:
					burnt_count += 1

		if burnt_count > 0 and (player == null or player.get("held_item") == null):
			return "E — Retirar Batata Queimada (%d queimadas)" % burnt_count

		if ready_count > 0:
			if player and player.get("held_item") != null:
				var held = player.get("held_item")
				if held is PotatoBoxItem or (held != null and str(held.get("item_id")) == "potato_box"):
					return "E — Embalar Batata Frita (%d pronta)" % ready_count
				return ""

			var inv = InventoryManager.get_instance()
			var box_stock = inv.get_stock("potato_box") if inv else 0
			if box_stock > 0:
				return "E — Embalar Batata Frita (%d pronta - Consome 1 Recipiente)" % ready_count
			else:
				return "🔴 Sem Recipientes de Batata! (Comprar no PC)"

		# Se todas ainda estão fritando
		var eff_cook = get_effective_cook_time()
		var remain = maxf(0.0, eff_cook - (active_potatoes[0]["timer"] as float))
		return "⏳ Fritando (%d/%d Cestos - %.1fs)" % [active_potatoes.size(), max_capacity, remain]

	# 2. Se segurando óleo ou batata crua
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held is CookingOil or (held != null and str(held.get("item_id")) == "cooking_oil"):
			return "E — Trocar Óleo da Fritadeira (%s)" % get_oil_quality_name()

		if held is Potato and held.state == Potato.State.RAW:
			if active_potatoes.size() < max_capacity:
				return "E — Colocar Batata no Cesto (%d/%d)" % [active_potatoes.size(), max_capacity]
			else:
				return "Fritadeira Cheia (4/4 Cestos Ocupados)"

	# 3. Se o óleo estiver saturado e mãos livres
	if oil_uses >= 12:
		return "E — Trocar Óleo da Fritadeira (%s)" % get_oil_quality_name()

	return ""

func interact(player: Node3D) -> void:
	var inv = InventoryManager.get_instance()
	var held = player.get("held_item")

	# 1. Troca de óleo se segurando galão
	if held is CookingOil or (held != null and str(held.get("item_id")) == "cooking_oil"):
		if player.has_method("take_held_item"):
			var oil_bottle = player.take_held_item()
			oil_bottle.queue_free()
			change_oil(player)
			return

	# 2. Se segurando batata crua: colocar no primeiro cesto livre
	if held is Potato and held.state == Potato.State.RAW:
		if active_potatoes.size() < max_capacity and player.has_method("take_held_item"):
			var pot = player.take_held_item() as Potato
			if pot:
				place_potato(pot)
				_show_feedback(player, "🔥 Batata colocada no cesto da fritadeira!")
		return

	# 3. Embalar batata pronta
	if not active_potatoes.is_empty():
		# Procurar batata pronta
		var ready_index = -1
		var burnt_index = -1
		for i in range(active_potatoes.size()):
			var p = active_potatoes[i]["potato"] as Potato
			if is_instance_valid(p):
				if p.state == Potato.State.COOKED and ready_index == -1:
					ready_index = i
				elif p.state == Potato.State.BURNT and burnt_index == -1:
					burnt_index = i

		# Se segurando o recipiente de batata
		if held is PotatoBoxItem or (held != null and str(held.get("item_id")) == "potato_box"):
			if ready_index != -1 and player.has_method("take_held_item") and player.has_method("pick_up"):
				var used_box = player.take_held_item()
				used_box.queue_free()

				_finish_and_pack_potato(ready_index, player)
				return

		# Se mãos livres
		if held == null and player.has_method("pick_up"):
			if burnt_index != -1:
				var chosen = active_potatoes[burnt_index]
				active_potatoes.remove_at(burnt_index)
				var pot = chosen["potato"] as Potato
				if is_instance_valid(pot):
					slot.remove_child(pot)
					player.pick_up(pot)
					_show_feedback(player, "🗑️ Batata queimada retirada. Descarte na lixeira!")
				_update_visual_status()
				return

			if ready_index != -1:
				if not inv or not inv.has_stock("potato_box", 1):
					_show_feedback(player, "❌ Sem recipientes de batata no estoque! Compre no computador.")
					return

				inv.consume_stock("potato_box", 1)
				_finish_and_pack_potato(ready_index, player)
				return

	# 4. Trocar óleo com estoque se vazio
	if oil_uses >= 12 and held == null:
		if inv and inv.consume_stock("cooking_oil", 1):
			change_oil(player)
			return
		else:
			_show_feedback(player, "❌ Sem Galão de Óleo no estoque! Compre no computador.")
			return

func place_potato(pot: Potato) -> void:
	if active_potatoes.size() >= max_capacity:
		return

	var used_slots: Array[int] = []
	for item in active_potatoes:
		used_slots.append(item["slot_index"])

	var free_slot = 0
	for i in range(max_capacity):
		if not used_slots.has(i):
			free_slot = i
			break

	slot.add_child(pot)
	pot.position = SLOT_OFFSETS[free_slot]
	pot.rotation = Vector3.ZERO
	pot.set_state(Potato.State.COOKING)

	active_potatoes.append({
		"potato": pot,
		"timer": 0.0,
		"slot_index": free_slot
	})

	_update_visual_status()

func _finish_and_pack_potato(index: int, player: Node3D) -> void:
	var chosen = active_potatoes[index]
	active_potatoes.remove_at(index)

	var pot = chosen["potato"] as Potato
	if is_instance_valid(pot):
		pot.queue_free()

	oil_uses += 1
	var pack = fries_pack_scene.instantiate() as FriesPack
	player.get_tree().root.add_child(pack)
	player.pick_up(pack)
	_show_feedback(player, "🍟 Batata frita crocante embalada com sucesso!")
	_update_visual_status()

func change_oil(worker: Node3D = null) -> void:
	oil_uses = 0
	if worker:
		_show_feedback(worker, "✨ Óleo da fritadeira renovado com sucesso! (100% Novo)")
	_update_visual_status()

func _update_visual_status() -> void:
	if not status_label:
		return

	var q_str = get_oil_quality_name()

	if active_potatoes.is_empty():
		if is_oil_bad():
			status_label.text = "🍟 FRITADEIRA (4 CESTOS)\n🔴 ÓLEO SATURADO\n[E] Trocar Óleo"
			status_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
		else:
			status_label.text = "🍟 FRITADEIRA (4 CESTOS)\nÓleo: %s\n🟢 4 Cestos Livres" % q_str
			status_label.modulate = Color(0.4, 1.0, 0.4, 1.0)
		return

	var ready_count = 0
	var burnt_count = 0
	for item in active_potatoes:
		var p = item["potato"] as Potato
		if is_instance_valid(p):
			if p.state == Potato.State.COOKED:
				ready_count += 1
			elif p.state == Potato.State.BURNT:
				burnt_count += 1

	if burnt_count > 0:
		status_label.text = "🍟 FRITADEIRA\n🔥 QUEIMADA (%d)!\n[E] Retirar" % burnt_count
		status_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
	elif ready_count > 0:
		status_label.text = "🍟 FRITADEIRA\n✨ %d PRONTAS! (%d/%d Cestos)\n[E] Embalar" % [ready_count, active_potatoes.size(), max_capacity]
		status_label.modulate = Color(0.3, 1.0, 0.5, 1.0)
	else:
		var eff_cook = get_effective_cook_time()
		var remain = maxf(0.0, eff_cook - (active_potatoes[0]["timer"] as float))
		status_label.text = "🍟 FRITADEIRA\n⏳ Fritando (%d/%d Cestos - %.1fs)\nÓleo: %s" % [active_potatoes.size(), max_capacity, remain, q_str]
		status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)

func _show_feedback(worker: Node3D, message: String) -> void:
	var hud = worker.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
