class_name Grill
extends StaticBody3D

# ================================================================
# GRELHA INDUSTRIAL PROFISSIONAL (TERMÔMETRO HORIZONTAL AMPLO & LUZ VERDE)
#
# Recursos:
#  - Tecla [E]: Ligar / Desligar interruptor rotativo
#  - Termômetro Horizontal Amplo integrado ao painel frontal
#  - Barra de fluido térmico com progressão visual clara da esquerda para a direita
#  - Luz Piloto de Prontidão: Apagada (Fria) -> Âmbar Pulsante (Aquecendo) -> Verde Radiante (Ideal)
#  - Aquecimento calibrado e perceptível (~12s para atingir temperatura ideal)
#  - Fritura equilibrada em dois lados (hambúrguer)
#  - Interação exclusiva com Espátula [1] para virar e retirar
# ================================================================

@export var is_on: bool = false
@export var current_temperature: float = 25.0
@export var target_temperature: float = 200.0
@export var ambient_temperature: float = 25.0
@export var heating_rate: float = 11.0 # °C/s (atinge 160°C em ~12.5s)
@export var cooling_rate: float = 8.0 # °C/s quando desligada

const IDEAL_TEMP_MIN: float = 160.0
const IDEAL_TEMP_MAX: float = 220.0

@export var max_capacity: int = 4

# Tempos de fritura realistas e equilibrados (segundos)
@export var patty_side_cook_time: float = 10.0 # 10s por lado = 20s total
@export var patty_burn_time: float = 10.0 # tempo adicional até queimar
@export var bacon_cook_time: float = 6.0
@export var bacon_burn_time: float = 7.0
@export var egg_cook_time: float = 6.5
@export var egg_dry_time: float = 5.0

@onready var cooking_slot: Node3D = $CookingSlot
@onready var fluid_column_pivot: Node3D = get_node_or_null("Model/ControlPanel/HorizontalThermometer/FluidColumnPivot")
@onready var temp_pilot_light: MeshInstance3D = get_node_or_null("Model/ControlPanel/TempPilotLight")
@onready var knob_mesh: MeshInstance3D = get_node_or_null("Model/ControlPanel/PowerControl/PowerKnob")
@onready var smoke_particles: CPUParticles3D = get_node_or_null("SizzleParticles")
@onready var oil_particles: CPUParticles3D = get_node_or_null("OilSplatterParticles")

var active_items: Array[Dictionary] = [] # Array de { "item": Node3D, "type": String, "timer": float, "slot_index": int }
var dirt_level: float = 0.0

const SLOT_OFFSETS = [
	Vector3(-0.65, 0.0, 0.0),
	Vector3(-0.22, 0.0, 0.0),
	Vector3(0.22, 0.0, 0.0),
	Vector3(0.65, 0.0, 0.0)
]

func _ready() -> void:
	_update_visuals_instant()

func is_ideal_temp() -> bool:
	return current_temperature >= IDEAL_TEMP_MIN

func get_cooking_speed_factor() -> float:
	if current_temperature < 100.0:
		return 0.0
	elif current_temperature < IDEAL_TEMP_MIN:
		return (current_temperature / IDEAL_TEMP_MIN) * 0.45
	else:
		return 1.0

func _process(delta: float) -> void:
	# 1. Simulação física contínua da temperatura
	if is_on:
		current_temperature = move_toward(current_temperature, target_temperature, heating_rate * delta)
	else:
		current_temperature = move_toward(current_temperature, ambient_temperature, cooling_rate * delta)

	# 2. Movimento suave da barra horizontal do termômetro e luz indicadora
	_update_thermometer(delta)

	# 3. Processamento da cocção dos alimentos na chapa
	var speed = get_cooking_speed_factor()
	var any_cooking = false

	if speed > 0.0 and not active_items.is_empty():
		for item_data in active_items:
			var node = item_data["item"] as Node3D
			if not is_instance_valid(node):
				continue

			any_cooking = true
			item_data["timer"] += delta * speed
			var timer: float = item_data["timer"]
			var type: String = item_data["type"]

			match type:
				"patty":
					var patty = node as Patty
					if patty:
						var progress_delta = (100.0 / patty_side_cook_time) * delta * speed
						patty.advance_cooking(progress_delta)

						if patty.is_fully_cooked():
							if timer > (patty_side_cook_time * 2.0 + patty_burn_time):
								patty.set_burnt()
				"bacon":
					var bacon = node as Bacon
					if bacon:
						if timer >= bacon_cook_time + bacon_burn_time:
							bacon.set_state(Bacon.State.BURNT)
						elif timer >= bacon_cook_time:
							bacon.set_state(Bacon.State.COOKED)
						else:
							bacon.set_state(Bacon.State.COOKING)
				"egg":
					var egg = node as Egg
					if egg:
						if timer >= egg_cook_time + egg_dry_time + 4.0:
							egg.set_state(Egg.State.BURNT)
						elif timer >= egg_cook_time + egg_dry_time:
							egg.set_state(Egg.State.DRYING)
						elif timer >= egg_cook_time:
							egg.set_state(Egg.State.COOKED)
						elif timer >= 0.8:
							egg.set_state(Egg.State.COOKING)
						else:
							egg.set_state(Egg.State.CRACKED)

	# 4. Efeitos de partículas de fritura e respingos de óleo
	if smoke_particles and smoke_particles.is_inside_tree():
		smoke_particles.emitting = (any_cooking and is_ideal_temp())
	if oil_particles and oil_particles.is_inside_tree():
		oil_particles.emitting = (any_cooking and is_ideal_temp())

# Atualiza a barra de temperatura horizontal e a luz indicadora
func _update_thermometer(delta: float) -> void:
	if not fluid_column_pivot:
		fluid_column_pivot = get_node_or_null("Model/ControlPanel/HorizontalThermometer/FluidColumnPivot")
	if fluid_column_pivot:
		# Escala normalizada de 25°C até 200°C
		var t = clampf((current_temperature - 25.0) / (200.0 - 25.0), 0.04, 1.0)
		var weight = 1.0 - exp(-6.0 * delta)
		fluid_column_pivot.scale.x = lerpf(fluid_column_pivot.scale.x, t, weight)

	if not temp_pilot_light:
		temp_pilot_light = get_node_or_null("Model/ControlPanel/TempPilotLight")
	if temp_pilot_light:
		var mat = temp_pilot_light.material_override as StandardMaterial3D
		if not mat:
			mat = StandardMaterial3D.new()
			temp_pilot_light.material_override = mat

		if not is_on:
			mat.albedo_color = Color(0.2, 0.2, 0.22, 1.0)
			mat.emission_enabled = false
		elif is_ideal_temp():
			# LUZ VERDE RADIANTE INDICANDO QUE A GRELHA ESTÁ PRONTA
			mat.albedo_color = Color(0.12, 0.95, 0.25, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.12, 0.95, 0.25, 1.0)
			mat.emission_energy_multiplier = 1.6
		else:
			# LUZ ÂMBAR PULSANTE INDICANDO PROCESSO DE AQUECIMENTO
			var pulse = (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5
			mat.albedo_color = Color(0.95, 0.55, 0.1, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.95, 0.55, 0.1, 1.0)
			mat.emission_energy_multiplier = 0.5 + pulse * 0.5

func _update_visuals_instant() -> void:
	if not fluid_column_pivot:
		fluid_column_pivot = get_node_or_null("Model/ControlPanel/HorizontalThermometer/FluidColumnPivot")
	if fluid_column_pivot:
		var t = clampf((current_temperature - 25.0) / (200.0 - 25.0), 0.04, 1.0)
		fluid_column_pivot.scale.x = t

	if knob_mesh:
		knob_mesh.rotation.y = deg_to_rad(90.0) if is_on else 0.0

	_update_thermometer(0.1)

func toggle_power(player: Node3D = null) -> void:
	is_on = !is_on
	_update_visuals_instant()
	if is_on:
		_show_feedback(player, "♨️ Grelha Ligada! Acompanhe o indicador e a luz verde...")
	else:
		_show_feedback(player, "⚪ Grelha Desligada.")

# Interação com tecla [E] — Ligar / Desligar Grelha
func interact_equipment(player: Node3D) -> void:
	toggle_power(player)

func interact(player: Node3D) -> void:
	toggle_power(player)

# Interação com Clique Esquerdo — Manipulação de Alimentos com Ferramentas ou Mãos
func interact_item(player: Node3D) -> void:
	if not player:
		return

	var tool_slot = player.get("active_tool_slot") if player else 3
	var held = player.get("held_item")

	# CASO 1: Jogador com MÃO LIVRE (Slot 3)
	if tool_slot == 3:
		# Se está segurando ingrediente cru, coloca na grelha
		if held != null and (held is Patty or held is Bacon or held is Egg or str(held.get("item_type")) == "ingredient"):
			if active_items.size() >= max_capacity:
				_show_feedback(player, "⚠️ A grelha está cheia (%d/%d itens)!" % [active_items.size(), max_capacity])
				return
			var item = player.take_held_item()
			if item:
				place_item(item)
				_show_feedback(player, "🥩 %s colocado na chapa" % item.get_display_name())
			return

		# Se tentar pegar com a mão alimento quente na chapa
		if not active_items.is_empty():
			_show_feedback(player, "⚠️ Chapa quente! Equipe a Espátula [1] para virar ou retirar.")
		return

	# CASO 2: Jogador com ESPÁTULA (Slot 1)
	if tool_slot == 1:
		if active_items.is_empty():
			_show_feedback(player, "🍳 Espátula pronta. Nenhum alimento na chapa.")
			return

		var target_item_data = _get_aimed_item(player)
		if target_item_data.is_empty():
			target_item_data = active_items[0]

		var node = target_item_data["item"]
		if not is_instance_valid(node):
			return

		if player.has_node("Head/Camera3D/ToolHolder"):
			var spatula = player.get_node("Head/Camera3D/ToolHolder").get_child(0)
			if spatula and spatula.has_method("play_action_animation"):
				spatula.play_action_animation()

		# Interação com Hambúrguer
		if node is Patty:
			var patty = node as Patty
			if patty.state == Patty.State.READY_SIDE_1 or (patty.state == Patty.State.COOKING_SIDE_1 and not patty.is_flipped):
				patty.flip()
				_show_feedback(player, "🔄 Hambúrguer virado! Grelhando Lado 2.")
				return
			else:
				_remove_item_from_grill(node, player)
				var state_txt = "Pronto!" if patty.is_fully_cooked() else ("Queimado" if patty.state == Patty.State.BURNT else "Cru")
				_show_feedback(player, "🍳 Retirou %s da grelha (%s)" % [patty.get_display_name(), state_txt])
				return

		# Interação com Bacon / Ovo
		if node is Bacon or node is Egg:
			_remove_item_from_grill(node, player)
			_show_feedback(player, "🍳 Retirou %s da grelha" % node.get_display_name())
			return

	# CASO 3: Jogador com BUCHA DE LIMPEZA (Slot 2)
	if tool_slot == 2:
		if dirt_level > 0.0:
			dirt_level = maxf(0.0, dirt_level - 1.5)
			_show_feedback(player, "🧽 Limpou a grelha com a bucha! (Nível de sujeira: %.1f)" % dirt_level)
		else:
			_show_feedback(player, "✨ A chapa da grelha já está limpa e brilhando!")
		return

func place_item(item: Node3D) -> bool:
	if active_items.size() >= max_capacity:
		return false

	var slot_idx = _find_free_slot_index()
	if slot_idx == -1:
		return false

	var prev_parent = item.get_parent()
	if prev_parent:
		prev_parent.remove_child(item)

	cooking_slot.add_child(item)
	item.position = SLOT_OFFSETS[slot_idx] + Vector3(0, 0.015, 0)
	item.rotation = Vector3.ZERO

	var itm_type = "patty"
	if item is Bacon:
		itm_type = "bacon"
	elif item is Egg:
		itm_type = "egg"

	active_items.append({
		"item": item,
		"type": itm_type,
		"timer": 0.0,
		"slot_index": slot_idx
	})

	if item.has_method("on_placed_in_station"):
		item.on_placed_in_station()

	return true

func _remove_item_from_grill(item: Node3D, player: Node3D) -> void:
	for i in range(active_items.size() - 1, -1, -1):
		if active_items[i]["item"] == item:
			active_items.remove_at(i)
			break

	if cooking_slot.is_ancestor_of(item):
		cooking_slot.remove_child(item)

	if "is_held" in item:
		item.is_held = false

	if player and player.has_method("pick_up"):
		player.pick_up(item)
	elif is_inside_tree():
		var scene_root = get_tree().current_scene if get_tree() else get_tree().root
		if scene_root:
			scene_root.add_child(item)
			item.global_position = global_position + Vector3(0, 1.0, 0)
			if item.has_method("on_dropped"):
				item.on_dropped()

func _find_free_slot_index() -> int:
	var used_slots: Array[int] = []
	for it in active_items:
		used_slots.append(it["slot_index"])
	for i in range(max_capacity):
		if not used_slots.has(i):
			return i
	return -1

func _get_aimed_item(player: Node3D) -> Dictionary:
	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if ray and ray is RayCast3D and ray.is_colliding():
		var col = ray.get_collider()
		for item_data in active_items:
			if item_data["item"] == col or item_data["item"].is_ancestor_of(col):
				return item_data
	return {}

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""

	var tool_slot = player.get("active_tool_slot") if player else 3
	var held = player.get("held_item")

	# Se estiver com a espátula
	if tool_slot == 1:
		if not active_items.is_empty():
			var target = _get_aimed_item(player)
			if target.is_empty():
				target = active_items[0]
			var node = target["item"]
			if node is Patty:
				var p = node as Patty
				if p.state == Patty.State.READY_SIDE_1 or (p.state == Patty.State.COOKING_SIDE_1 and not p.is_flipped):
					return "🍳 [Clique] VIRAR %s" % p.get_display_name()
				elif p.is_fully_cooked():
					return "🍳 [Clique] RETIRAR Hambúrguer Pronto!"
				else:
					return "🍳 [Clique] Virar/Retirar %s" % p.get_display_name()
			elif node is Bacon or node is Egg:
				return "🍳 [Clique] Retirar %s" % node.get_display_name()
		return "🍳 Espátula — Nenhum alimento na chapa"

	# Se estiver com a mão livre e segurando carne/bacon/ovo
	if tool_slot == 3 and held != null:
		if held is Patty or held is Bacon or held is Egg or str(held.get("item_type")) == "ingredient":
			return "✋ [Clique] Colocar %s na Chapa" % held.get_display_name()

	# Interação com botão de ligar/desligar
	if not is_on:
		return "♨️ [E] Ligar Grelha"
	else:
		return "⚪ [E] Desligar Grelha"

func _show_feedback(player: Node3D, message: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback(message)
