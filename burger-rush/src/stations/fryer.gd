class_name Fryer
extends StaticBody3D

# ================================================================
# FRITADEIRA INDUSTRIAL PROFISSIONAL (ÓLEO INTEGRADO & CUBAS PROFUNDAS)
#
# Recursos:
#  - 4 Cubas profundas de aço inoxidável com óleo dourado líquido visível permanente
#  - Cestos de grade metálica vazada que descem fisicamente e submergem as batatas no óleo
#  - Ondulações e borbulhamento na superfície líquida durante a fritura
#  - Termômetro horizontal amplo e luz piloto verde de temperatura ideal (>= 150°C)
#  - Botão de energia Liga/Desliga com luz piloto própria no canto esquerdo
#  - 4 Alavancas independentes para subir/descer cada cesto
# ================================================================

@export var is_on: bool = false
@export var current_temperature: float = 25.0
@export var target_temperature: float = 180.0
@export var ambient_temperature: float = 25.0
@export var heating_rate: float = 11.0 # °C/s (~11.5s para atingir 150°C)
@export var cooling_rate: float = 8.0 # °C/s

const IDEAL_TEMP_MIN: float = 150.0
const IDEAL_TEMP_MAX: float = 200.0

@export var cook_time: float = 8.0 # 8 segundos para fritar
@export var burn_time: float = 12.0 # 12 segundos adicionais até queimar
@export var max_capacity: int = 4

var fries_pack_scene: PackedScene = preload("res://src/items/fries_pack.tscn")

# Estrutura dos 4 compartimentos (óleo pré-existente e permanente)
var compartments: Array[Dictionary] = [
	{ "basket_down": false, "food_state": "empty", "timer": 0.0, "oil_level": 1.0, "drain_timer": 0.0 },
	{ "basket_down": false, "food_state": "empty", "timer": 0.0, "oil_level": 1.0, "drain_timer": 0.0 },
	{ "basket_down": false, "food_state": "empty", "timer": 0.0, "oil_level": 1.0, "drain_timer": 0.0 },
	{ "basket_down": false, "food_state": "empty", "timer": 0.0, "oil_level": 1.0, "drain_timer": 0.0 },
]

# Posições dos 4 compartimentos
const SLOT_X = [-0.54, -0.18, 0.18, 0.54]
const BASKET_Y_UP = 0.98
const BASKET_Y_DOWN = 0.70

# Posição do botão liga/desliga isolado à esquerda
const POWER_BUTTON_X = -0.78
const POWER_BUTTON_Y_MIN = 0.70

@onready var fluid_column_pivot: Node3D = get_node_or_null("Model/ControlPanel/HorizontalThermometer/FluidColumnPivot")
@onready var temp_pilot_light: MeshInstance3D = get_node_or_null("Model/ControlPanel/TempPilotLight")
@onready var power_knob: MeshInstance3D = get_node_or_null("Model/ControlPanel/PowerControl/PowerKnob")
@onready var power_pilot_light: MeshInstance3D = get_node_or_null("Model/ControlPanel/PowerControl/PowerPilotLight")

# Compatibilidade com sistemas anteriores
var active_potatoes: Array[Dictionary]:
	get:
		var list: Array[Dictionary] = []
		for i in range(4):
			if compartments[i]["food_state"] != "empty":
				list.append({ "slot_index": i, "timer": compartments[i]["timer"], "state": compartments[i]["food_state"] })
		return list

func _ready() -> void:
	_update_all_visuals_instant()

func is_ideal_temp() -> bool:
	return current_temperature >= IDEAL_TEMP_MIN

func get_cooking_speed_factor() -> float:
	if current_temperature < 100.0:
		return 0.0
	elif current_temperature < IDEAL_TEMP_MIN:
		return (current_temperature / IDEAL_TEMP_MIN) * 0.5
	else:
		return 1.0

func _process(delta: float) -> void:
	# 1. Simulação física contínua da temperatura
	if is_on:
		current_temperature = move_toward(current_temperature, target_temperature, heating_rate * delta)
	else:
		current_temperature = move_toward(current_temperature, ambient_temperature, cooling_rate * delta)

	# 2. Atualiza termômetro horizontal e luz piloto
	_update_thermometer(delta)

	# 3. Processa cada um dos 4 compartimentos de forma 100% independente
	var speed = get_cooking_speed_factor()

	for i in range(4):
		var comp = compartments[i]
		var basket_down: bool = comp["basket_down"]
		var food_state: String = comp["food_state"]

		# Animação suave da posição do cesto (entra e sai da cuba e do óleo)
		var basket_node = get_node_or_null("Model/Basket%d" % i)
		if basket_node:
			var target_y = BASKET_Y_DOWN if basket_down else BASKET_Y_UP
			basket_node.position.y = lerpf(basket_node.position.y, target_y, 1.0 - exp(-12.0 * delta))

		# Animação suave da alavanca
		var lever_arm = get_node_or_null("Model/Lever%d/LeverArm" % i)
		if lever_arm:
			var target_rot_x = deg_to_rad(45.0) if basket_down else 0.0
			lever_arm.rotation.x = lerpf(lever_arm.rotation.x, target_rot_x, 1.0 - exp(-12.0 * delta))

		# Drenagem pós-fritura
		if comp["drain_timer"] > 0.0:
			comp["drain_timer"] = maxf(0.0, comp["drain_timer"] - delta)

		# Lógica de Fritura: Somente ocorre se ABAIXADO (submerso no óleo), QUENTE e com ALIMENTO
		var is_frying = false
		if basket_down and speed > 0.0 and food_state != "empty":
			is_frying = true
			comp["timer"] += delta * speed
			var timer: float = comp["timer"]

			if timer >= (cook_time + burn_time):
				comp["food_state"] = "burnt"
			elif timer >= cook_time:
				comp["food_state"] = "cooked"
			else:
				comp["food_state"] = "cooking"

		# Atualização visual do alimento, ondulação líquida do óleo e partículas
		_update_compartment_visuals(i, is_frying)

func _update_compartment_visuals(i: int, is_frying: bool) -> void:
	var comp = compartments[i]
	var food_state: String = comp["food_state"]

	# Malha das batatas palito visíveis dentro do cesto aramado
	var fries_mesh = get_node_or_null("Model/Basket%d/FriesMesh" % i) as MeshInstance3D
	if fries_mesh:
		if food_state == "empty":
			fries_mesh.visible = false
		else:
			fries_mesh.visible = true
			var mat = fries_mesh.material_override as StandardMaterial3D
			if not mat:
				mat = StandardMaterial3D.new()
				fries_mesh.material_override = mat

			match food_state:
				"frozen":
					mat.albedo_color = Color(0.96, 0.93, 0.76, 1.0)
					mat.roughness = 0.65
				"cooking":
					mat.albedo_color = Color(0.95, 0.82, 0.35, 1.0)
					mat.roughness = 0.5
				"cooked":
					mat.albedo_color = Color(0.95, 0.72, 0.18, 1.0)
					mat.roughness = 0.4
				"burnt":
					mat.albedo_color = Color(0.18, 0.12, 0.08, 1.0)
					mat.roughness = 0.8

	# Superfície líquida de óleo dourado com ondulações suaves
	var oil_mesh = get_node_or_null("Model/OilMesh%d" % i) as MeshInstance3D
	if oil_mesh:
		oil_mesh.visible = true
		var wave = sin(Time.get_ticks_msec() * 0.003 + i * 1.5) * 0.002
		oil_mesh.position.y = 0.74 + wave

	# Partículas de Fritura e Borbulhamento ao redor das batatas
	var bubbles = get_node_or_null("Model/Bubbles%d" % i) as CPUParticles3D
	if bubbles and bubbles.is_inside_tree():
		bubbles.emitting = is_frying

	var steam = get_node_or_null("Model/Steam%d" % i) as CPUParticles3D
	if steam and steam.is_inside_tree():
		steam.emitting = is_frying or (is_on and is_ideal_temp())

	var drips = get_node_or_null("Model/Drips%d" % i) as CPUParticles3D
	if drips and drips.is_inside_tree():
		drips.emitting = (comp["drain_timer"] > 0.0 and not comp["basket_down"] and food_state != "empty")

# Atualiza termômetro horizontal e luz piloto
func _update_thermometer(delta: float) -> void:
	if not fluid_column_pivot:
		fluid_column_pivot = get_node_or_null("Model/ControlPanel/HorizontalThermometer/FluidColumnPivot")
	if fluid_column_pivot:
		var t = clampf((current_temperature - 25.0) / (180.0 - 25.0), 0.04, 1.0)
		fluid_column_pivot.scale.x = lerpf(fluid_column_pivot.scale.x, t, 1.0 - exp(-6.0 * delta))

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
			mat.albedo_color = Color(0.12, 0.95, 0.25, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.12, 0.95, 0.25, 1.0)
			mat.emission_energy_multiplier = 1.6
		else:
			var pulse = (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5
			mat.albedo_color = Color(0.95, 0.55, 0.1, 1.0)
			mat.emission_enabled = true
			mat.emission = Color(0.95, 0.55, 0.1, 1.0)
			mat.emission_energy_multiplier = 0.5 + pulse * 0.5

func _update_all_visuals_instant() -> void:
	if not fluid_column_pivot:
		fluid_column_pivot = get_node_or_null("Model/ControlPanel/HorizontalThermometer/FluidColumnPivot")
	if fluid_column_pivot:
		var t = clampf((current_temperature - 25.0) / (180.0 - 25.0), 0.04, 1.0)
		fluid_column_pivot.scale.x = t

	if not power_knob:
		power_knob = get_node_or_null("Model/ControlPanel/PowerControl/PowerKnob")
	if power_knob:
		power_knob.rotation.y = deg_to_rad(90.0) if is_on else 0.0

	if not power_pilot_light:
		power_pilot_light = get_node_or_null("Model/ControlPanel/PowerControl/PowerPilotLight")
	if power_pilot_light:
		var p_mat = power_pilot_light.material_override as StandardMaterial3D
		if not p_mat:
			p_mat = StandardMaterial3D.new()
			power_pilot_light.material_override = p_mat

		if is_on:
			p_mat.albedo_color = Color(1.0, 0.25, 0.08, 1.0)
			p_mat.emission_enabled = true
			p_mat.emission = Color(1.0, 0.25, 0.08, 1.0)
			p_mat.emission_energy_multiplier = 1.8
		else:
			p_mat.albedo_color = Color(0.2, 0.2, 0.22, 1.0)
			p_mat.emission_enabled = false

	for i in range(4):
		_update_compartment_visuals(i, false)

func toggle_power(player: Node3D = null) -> void:
	is_on = !is_on
	_update_all_visuals_instant()
	if is_on:
		_show_feedback(player, "♨️ Fritadeira Ligada! Aquecendo os 4 compartimentos...")
	else:
		_show_feedback(player, "⚪ Fritadeira Desligada.")

# Alterna subir/descer alavanca e cesto
func toggle_basket(slot_idx: int, player: Node3D = null) -> void:
	if slot_idx < 0 or slot_idx >= 4:
		return

	var comp = compartments[slot_idx]
	comp["basket_down"] = !comp["basket_down"]

	if not comp["basket_down"]:
		# Levantou o cesto: inicia drenagem se tinha alimento
		if comp["food_state"] != "empty":
			comp["drain_timer"] = 3.5
			_show_feedback(player, "⬆️ Cesto %d levantado! Escorrendo óleo..." % (slot_idx + 1))
		else:
			_show_feedback(player, "⬆️ Cesto %d levantado." % (slot_idx + 1))
	else:
		# Abaixou o cesto
		if not is_on or not is_ideal_temp():
			_show_feedback(player, "⬇️ Cesto %d mergulhado no óleo. Aguardando temperatura ideal..." % (slot_idx + 1))
		else:
			_show_feedback(player, "⬇️ Cesto %d mergulhado no óleo quente! Fritando..." % (slot_idx + 1))

# Interação com tecla [E] — Separação Rigorosa entre Botão Geral e Alavancas
func interact_equipment(player: Node3D) -> void:
	if _is_aiming_at_power_switch(player):
		toggle_power(player)
		return

	var slot_idx = _get_aimed_slot(player)
	if slot_idx != -1:
		toggle_basket(slot_idx, player)
	else:
		toggle_power(player)

func interact(player: Node3D) -> void:
	interact_equipment(player)

# Interação com Clique Esquerdo — Manipulação de Batatas e Embalagens
func interact_item(player: Node3D) -> void:
	if not player:
		return

	var held = player.get("held_item")
	var slot_idx = _get_aimed_slot(player)
	if slot_idx == -1:
		slot_idx = _find_most_relevant_slot()

	var comp = compartments[slot_idx]

	# CASO 1: Jogador segurando Saco de Batata Congelada
	if held is Potato or (held != null and str(held.get("item_id")) == "potato_raw"):
		if comp["basket_down"]:
			_show_feedback(player, "⚠️ Levante o Cesto %d [E] antes de colocar a batata!" % (slot_idx + 1))
			return

		if comp["food_state"] != "empty":
			_show_feedback(player, "⚠️ O Cesto %d já contém alimento!" % (slot_idx + 1))
			return

		comp["food_state"] = "frozen"
		comp["timer"] = 0.0
		var pot_item = player.take_held_item()
		if pot_item:
			pot_item.queue_free()
		_update_compartment_visuals(slot_idx, false)
		_show_feedback(player, "🍟 Batata congelada colocada no Cesto %d! Abaixe a alavanca [E] para fritar." % (slot_idx + 1))
		return

	# CASO 2: Jogador retirando Batata Pronta (com Recipiente ou Mão Livre)
	if comp["food_state"] == "cooked":
		if comp["basket_down"]:
			_show_feedback(player, "⚠️ Levante o Cesto %d [E] para retirar as batatas prontas!" % (slot_idx + 1))
			return

		var inv = InventoryManager.get_instance()
		if held is PotatoBoxItem or (held != null and str(held.get("item_id")) == "potato_box"):
			var used_box = player.take_held_item()
			if used_box:
				used_box.queue_free()
			_finish_and_pack_fries(slot_idx, player)
			return
		elif held == null:
			if inv and not inv.has_stock("potato_box", 1):
				_show_feedback(player, "❌ Sem recipientes de batata no estoque! Compre no computador.")
				return
			if inv:
				inv.consume_stock("potato_box", 1)
			_finish_and_pack_fries(slot_idx, player)
			return

	# CASO 3: Retirar Batata Queimada
	if comp["food_state"] == "burnt" and held == null:
		comp["food_state"] = "empty"
		comp["timer"] = 0.0
		_update_compartment_visuals(slot_idx, false)
		_show_feedback(player, "🗑️ Batata queimada descartada do Cesto %d." % (slot_idx + 1))
		return

func _finish_and_pack_fries(slot_idx: int, player: Node3D) -> void:
	compartments[slot_idx]["food_state"] = "empty"
	compartments[slot_idx]["timer"] = 0.0
	_update_compartment_visuals(slot_idx, false)

	var pack = fries_pack_scene.instantiate() as FriesPack
	var root_node: Node = null
	if is_inside_tree() and get_tree():
		root_node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	if not root_node and player and player.get_parent():
		root_node = player.get_parent()
	if not root_node and get_parent():
		root_node = get_parent()

	if root_node:
		root_node.add_child(pack)
	if player and player.has_method("pick_up"):
		player.pick_up(pack)
	_show_feedback(player, "🍟 Batata frita crocante e sequinha embalada com sucesso!")

# Posicionamento de batata para compatibilidade com testes anteriores
func place_potato(pot: Potato) -> void:
	var free_slot = 0
	for i in range(4):
		if compartments[i]["food_state"] == "empty":
			free_slot = i
			break

	compartments[free_slot]["food_state"] = "frozen"
	compartments[free_slot]["timer"] = 0.0
	compartments[free_slot]["basket_down"] = true
	if is_instance_valid(pot):
		pot.queue_free()

func _find_most_relevant_slot() -> int:
	for i in range(4):
		if compartments[i]["food_state"] == "cooked" and not compartments[i]["basket_down"]:
			return i
	for i in range(4):
		if compartments[i]["food_state"] == "empty" and not compartments[i]["basket_down"]:
			return i
	return 0

# Detecção precisa de mira no botão Liga/Desliga
func _is_aiming_at_power_switch(player: Node3D) -> bool:
	if not player:
		return false
	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if ray and ray is RayCast3D and ray.is_colliding():
		var col_point = ray.get_collision_point()
		var local_point = to_local(col_point)
		if local_point.x < -0.68 and local_point.y > 0.70:
			return true
	return false

# Detecção precisa de mira nas alavancas/cestos 0..3
func _get_aimed_slot(player: Node3D) -> int:
	if not player:
		return -1

	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if ray and ray is RayCast3D and ray.is_colliding():
		var col_point = ray.get_collision_point()
		var local_point = to_local(col_point)

		if local_point.x < -0.68 and local_point.y > 0.70:
			return -1

		var closest_slot = -1
		var min_dist = 999.0
		for i in range(4):
			var dist = absf(local_point.x - SLOT_X[i])
			if dist < min_dist and dist < 0.18:
				min_dist = dist
				closest_slot = i
		return closest_slot
	return -1

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""

	var player_3d = player as Node3D
	var held = player.get("held_item")

	# 1. Se mirou no botão liga/desliga isolado
	if _is_aiming_at_power_switch(player_3d):
		if not is_on:
			return "♨️ [E] Ligar Fritadeira"
		else:
			return "⚪ [E] Desligar Fritadeira"

	# 2. Se mirou em um compartimento/alavanca específico (0..3)
	var slot_idx = _get_aimed_slot(player_3d)
	if slot_idx != -1:
		var comp = compartments[slot_idx]
		var num = slot_idx + 1

		# Se segurando batata crua
		if held is Potato or (held != null and str(held.get("item_id")) == "potato_raw"):
			if comp["basket_down"]:
				return "⬆️ [E] Levantar Cesto %d para colocar batata" % num
			elif comp["food_state"] == "empty":
				return "🍟 [Clique] Colocar Batatas no Cesto %d" % num

		# Se cesto tem batata pronta
		if comp["food_state"] == "cooked":
			if comp["basket_down"]:
				return "⬆️ [E] Levantar Cesto %d (Batata Pronta!)" % num
			else:
				return "🍟 [Clique] Embalar Batata Frita (Cesto %d)" % num

		# Se cesto tem batata queimada
		if comp["food_state"] == "burnt":
			if comp["basket_down"]:
				return "⬆️ [E] Levantar Cesto %d (Queimada)" % num
			else:
				return "🗑️ [Clique] Retirar Batata Queimada (Cesto %d)" % num

		# Alavanca do cesto
		if comp["basket_down"]:
			return "⬆️ [E] Levantar Cesto %d" % num
		else:
			return "⬇️ [E] Abaixar Cesto %d no Óleo" % num

	# Prompt geral da máquina
	if not is_on:
		return "♨️ [E] Ligar Fritadeira Industrial"
	else:
		return "⚪ [E] Desligar Fritadeira Industrial"

func _show_feedback(player: Node3D, message: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback(message)
