class_name Grill
extends StaticBody3D

@export var cook_time: float = 4.0
@export var burn_time: float = 5.0
@export var max_capacity: int = 4

@onready var cooking_slot: Node3D = $CookingSlot
@onready var status_label: Label3D = $StatusLabel

# Suporte a múltiplas carnes na chapa dupla larga
var active_patties: Array[Dictionary] = [] # Array de { "patty": Patty, "timer": float, "slot_index": int }
var dirt_level: float = 0.0 # 0.0 a 5.0+

# Getter de compatibilidade
var current_patty: Patty:
	get:
		if active_patties.is_empty():
			return null
		# Prioriza carne pronta ou queimada para interação rápida
		for item in active_patties:
			var p = item["patty"] as Patty
			if is_instance_valid(p) and (p.state == Patty.State.COOKED or p.state == Patty.State.BURNT):
				return p
		return active_patties[0]["patty"] if is_instance_valid(active_patties[0]["patty"]) else null
	set(value):
		if value == null:
			active_patties.clear()
		else:
			if active_patties.is_empty():
				place_patty(value)

var cooking_timer: float:
	get:
		if active_patties.is_empty():
			return 0.0
		return active_patties[0]["timer"]
	set(val):
		if not active_patties.is_empty():
			active_patties[0]["timer"] = val

# Posições dos 4 slots na superfície larga da chapa (largura 1.94m)
const SLOT_OFFSETS = [
	Vector3(-0.65, 0.0, 0.0),
	Vector3(-0.22, 0.0, 0.0),
	Vector3(0.22, 0.0, 0.0),
	Vector3(0.65, 0.0, 0.0)
]

func _ready() -> void:
	_update_status_display()

func is_dirty() -> bool:
	return dirt_level >= 4.0

func get_effective_cook_time() -> float:
	return cook_time + (1.5 if is_dirty() else 0.0)

func _process(delta: float) -> void:
	if active_patties.is_empty():
		return

	var eff_cook_time = get_effective_cook_time()

	for item in active_patties:
		var patty = item["patty"] as Patty
		if not is_instance_valid(patty):
			continue

		item["timer"] += delta
		var timer = item["timer"] as float

		if timer >= eff_cook_time + burn_time:
			if patty.state != Patty.State.BURNT:
				patty.set_state(Patty.State.BURNT)
		elif timer >= eff_cook_time:
			if patty.state != Patty.State.COOKED:
				patty.set_state(Patty.State.COOKED)

	_update_status_display()

func get_interaction_prompt(player: Node = null) -> String:
	# 1. Se o jogador tiver mãos vazias e houver carne na chapa: prompt de retirar
	if not active_patties.is_empty() and player and player.get("held_item") == null:
		var ready_count = 0
		var burnt_count = 0
		for item in active_patties:
			var p = item["patty"] as Patty
			if is_instance_valid(p):
				if p.state == Patty.State.COOKED:
					ready_count += 1
				elif p.state == Patty.State.BURNT:
					burnt_count += 1

		if burnt_count > 0:
			return "E — Retirar Carne Queimada (%d pronta, %d queimada)" % [ready_count, burnt_count]
		elif ready_count > 0:
			return "E — Retirar Carne Pronta (%d/%d na Chapa)" % [ready_count, active_patties.size()]
		else:
			var eff_cook = get_effective_cook_time()
			var oldest_timer = active_patties[0]["timer"] as float
			var pct = int(clampf((oldest_timer / eff_cook) * 100.0, 0.0, 99.0))
			return "E — Retirar Carne (Cozinhando %d%% - %d na Chapa)" % [pct, active_patties.size()]

	# 2. Se o jogador estiver segurando carne crua e houver espaço na chapa
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held is Patty or (held != null and str(held.get("item_id")) == "patty"):
			if held.get("state") != Patty.State.BURNT:
				if active_patties.size() < max_capacity:
					return "E — Colocar Carne na Chapa (%d/%d)" % [active_patties.size(), max_capacity]
				else:
					return "Chapa Dupla Cheia (Máx %d Carnes)" % max_capacity
		return ""

	# 3. Se a chapa estiver vazia e tiver sujeira
	if active_patties.is_empty() and dirt_level > 0.0:
		var pct = int(clampf((dirt_level / 5.0) * 100.0, 10.0, 100.0))
		return "E — Raspar e Limpar Chapa (Gordura: %d%%)" % pct

	return ""

func interact(player: Node3D) -> void:
	# 1. Se segurando carne: tentar colocar na chapa
	if player.get("held_item") != null:
		var held = player.get("held_item")
		if held is Patty or (held != null and str(held.get("item_id")) == "patty"):
			if held.get("state") != Patty.State.BURNT and active_patties.size() < max_capacity:
				if player.has_method("take_held_item"):
					var patty: Patty = player.take_held_item() as Patty
					if patty:
						place_patty(patty)
		return

	# 2. Se mãos vazias e há carnes na chapa: retirar a melhor carne disponível
	if not active_patties.is_empty() and player.get("held_item") == null:
		_remove_best_patty_to_worker(player)
		return

	# 3. Limpar se vazia
	if active_patties.is_empty() and dirt_level > 0.0:
		clean_grill(player)

func clean_grill(worker: Node3D = null) -> void:
	dirt_level = 0.0
	if worker:
		_show_feedback(worker, "✨ Chapa dupla raspada e higienizada com sucesso!")
	_update_status_display()

func place_patty(patty: Patty) -> void:
	if active_patties.size() >= max_capacity:
		return

	# Encontra primeiro índice de slot livre
	var used_slots: Array[int] = []
	for item in active_patties:
		used_slots.append(item["slot_index"])

	var free_slot = 0
	for i in range(max_capacity):
		if not used_slots.has(i):
			free_slot = i
			break

	cooking_slot.add_child(patty)
	patty.position = SLOT_OFFSETS[free_slot]
	patty.rotation = Vector3.ZERO

	if patty.collision_shape:
		patty.collision_shape.disabled = true

	var eff_cook_time = get_effective_cook_time()
	var initial_timer = 0.0
	match patty.state:
		Patty.State.RAW:
			patty.set_state(Patty.State.COOKING)
			initial_timer = 0.0
		Patty.State.COOKING:
			initial_timer = 0.0
		Patty.State.COOKED:
			initial_timer = eff_cook_time
		Patty.State.BURNT:
			initial_timer = eff_cook_time + burn_time

	active_patties.append({
		"patty": patty,
		"timer": initial_timer,
		"slot_index": free_slot
	})

	_update_status_display()

func _remove_best_patty_to_worker(worker: Node3D) -> void:
	if active_patties.is_empty():
		return

	# Prioriza carne pronta -> depois queimada -> depois a mais antiga
	var target_index = 0
	for i in range(active_patties.size()):
		var p = active_patties[i]["patty"] as Patty
		if is_instance_valid(p) and p.state == Patty.State.COOKED:
			target_index = i
			break
		elif is_instance_valid(p) and p.state == Patty.State.BURNT:
			target_index = i

	var chosen = active_patties[target_index]
	active_patties.remove_at(target_index)

	var patty = chosen["patty"] as Patty
	if is_instance_valid(patty):
		cooking_slot.remove_child(patty)
		dirt_level = minf(6.0, dirt_level + 0.5)

		if worker.has_method("pick_up"):
			worker.pick_up(patty)

	_update_status_display()

func _update_status_display() -> void:
	if not status_label:
		return

	if active_patties.is_empty():
		if is_dirty():
			status_label.text = "🍳 CHAPA DUPLA\n🔴 SUJA DE GORDURA\n[E] Raspar"
			status_label.modulate = Color(1.0, 0.4, 0.2, 1.0)
		elif dirt_level > 0.0:
			status_label.text = "🍳 CHAPA DUPLA\n🟡 Gordura: %.0f%%\n[E] Limpar" % ((dirt_level / 5.0) * 100.0)
			status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
		else:
			status_label.text = "🍳 CHAPA DUPLA LIVRE\n🟢 Limpa (Capacidade: 4)"
			status_label.modulate = Color(0.4, 1.0, 0.4, 1.0)
		return

	var ready_count = 0
	var burnt_count = 0
	for item in active_patties:
		var p = item["patty"] as Patty
		if is_instance_valid(p):
			if p.state == Patty.State.COOKED:
				ready_count += 1
			elif p.state == Patty.State.BURNT:
				burnt_count += 1

	if burnt_count > 0:
		status_label.text = "🔴 CARNE QUEIMADA (%d)!\n[E] Retirar" % burnt_count
		status_label.modulate = Color(1.0, 0.2, 0.2, 1.0)
	elif ready_count > 0:
		status_label.text = "🟢 %d CARNES PRONTAS!\n(%d/%d na Chapa)" % [ready_count, active_patties.size(), max_capacity]
		status_label.modulate = Color(0.3, 1.0, 0.4, 1.0)
	else:
		var eff_cook = get_effective_cook_time()
		var oldest_timer = active_patties[0]["timer"] as float
		var pct = int(clampf((oldest_timer / eff_cook) * 100.0, 0.0, 99.0))
		var dirty_txt = " (+Gordura)" if is_dirty() else ""
		status_label.text = "🟡 COZINHANDO... (%d%%)%s\n(%d/%d Carnes)" % [pct, dirty_txt, active_patties.size(), max_capacity]
		status_label.modulate = Color(1.0, 0.85, 0.2, 1.0)

func _show_feedback(worker: Node3D, message: String) -> void:
	var hud = worker.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
