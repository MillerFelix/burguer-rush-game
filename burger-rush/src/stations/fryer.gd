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

@export var cook_time: float = 84.0 # 84 segundos para fritar (aumentado em mais 200% / 3x de 28.0s)
@export var burn_time: float = 126.0 # 126 segundos adicionais até queimar (3x de 42.0s)
@export var max_capacity: int = 4

var fries_pack_scene: PackedScene = load("res://src/items/fries_pack.tscn")

# Estrutura dos 4 compartimentos (óleo pré-existente e permanente)
# 1 saco de batata = 5 porções | 1 saco de cebola = 3 porções
var compartments: Array[Dictionary] = [
	{ "basket_down": false, "food_state": "empty", "food_type": "potato", "timer": 0.0, "oil_level": 1.0, "drain_timer": 0.0, "portions_remaining": 0 },
	{ "basket_down": false, "food_state": "empty", "food_type": "potato", "timer": 0.0, "oil_level": 1.0, "drain_timer": 0.0, "portions_remaining": 0 },
	{ "basket_down": false, "food_state": "empty", "food_type": "potato", "timer": 0.0, "oil_level": 1.0, "drain_timer": 0.0, "portions_remaining": 0 },
	{ "basket_down": false, "food_state": "empty", "food_type": "potato", "timer": 0.0, "oil_level": 1.0, "drain_timer": 0.0, "portions_remaining": 0 },
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

# Nós de Áudio 3D Posicional
@onready var hum_audio: AudioStreamPlayer3D = get_node_or_null("Audio/HumAudioPlayer")
@onready var sizzle_audio: AudioStreamPlayer3D = get_node_or_null("Audio/SizzleAudioPlayer")
@onready var oneshot_audio: AudioStreamPlayer3D = get_node_or_null("Audio/OneShotAudioPlayer")
@onready var basket_audio: AudioStreamPlayer3D = get_node_or_null("Audio/BasketAudioPlayer")

const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")
const PowerManager = preload("res://src/core/power_manager.gd")

var _has_played_ready_chime: bool = false
var _target_hum_vol: float = -80.0
var _target_sizzle_vol: float = -80.0
var _cached_basket_nodes: Array[Node3D] = []
var _cached_lever_arms: Array[Node3D] = []
var _cached_oil_meshes: Array[MeshInstance3D] = []
var _cached_bubbles: Array[CPUParticles3D] = []
var _cached_steams: Array[CPUParticles3D] = []
var _cached_drips: Array[CPUParticles3D] = []

# Compatibilidade com sistemas anteriores
var active_potatoes: Array[Dictionary]:
	get:
		var list: Array[Dictionary] = []
		for i in range(4):
			if compartments[i]["food_state"] != "empty":
				list.append({ "slot_index": i, "timer": compartments[i]["timer"], "state": compartments[i]["food_state"], "portions": compartments[i].get("portions_remaining", 5) })
		return list

func _ready() -> void:
	add_to_group("cleanable_stations")
	_setup_audio()
	_cached_basket_nodes.clear()
	_cached_lever_arms.clear()
	_cached_oil_meshes.clear()
	_cached_bubbles.clear()
	_cached_steams.clear()
	_cached_drips.clear()
	for j in range(4):
		_cached_basket_nodes.append(get_node_or_null("Model/Basket%d" % j))
		_cached_lever_arms.append(get_node_or_null("Model/Lever%d/LeverArm" % j))
		_cached_oil_meshes.append(get_node_or_null("Model/OilMesh%d" % j))
		_cached_bubbles.append(get_node_or_null("Model/Bubbles%d" % j))
		_cached_steams.append(get_node_or_null("Model/Steam%d" % j))
		_cached_drips.append(get_node_or_null("Model/Drips%d" % j))

	var pm = PowerManager.get_instance()
	if pm:
		pm.register_appliance(self, "fryer", "Fritadeira Industrial Dupla", 3.5, is_on)
		if not pm.power_state_changed.is_connected(on_power_state_changed):
			pm.power_state_changed.connect(on_power_state_changed)
	_update_all_visuals_instant()

func _exit_tree() -> void:
	var pm = PowerManager.get_instance()
	if pm:
		pm.unregister_appliance(self)

func on_power_state_changed(main_power_on: bool) -> void:
	var pm = PowerManager.get_instance()
	if pm:
		pm.set_appliance_state(self, is_on and main_power_on)

func _setup_audio() -> void:
	if not hum_audio:
		hum_audio = get_node_or_null("Audio/HumAudioPlayer")
	if not sizzle_audio:
		sizzle_audio = get_node_or_null("Audio/SizzleAudioPlayer")
	if not oneshot_audio:
		oneshot_audio = get_node_or_null("Audio/OneShotAudioPlayer")
	if not basket_audio:
		basket_audio = get_node_or_null("Audio/BasketAudioPlayer")

	# Cria nós dinamicamente se a cena for instanciada programaticamente sem nós de áudio
	if not hum_audio:
		var audio_root = get_node_or_null("Audio")
		if not audio_root:
			audio_root = Node3D.new()
			audio_root.name = "Audio"
			audio_root.position = Vector3(0, 0.88, 0)
			add_child(audio_root)

		hum_audio = AudioStreamPlayer3D.new()
		hum_audio.name = "HumAudioPlayer"
		hum_audio.unit_size = 2.8
		hum_audio.max_distance = 18.0
		audio_root.add_child(hum_audio)

		sizzle_audio = AudioStreamPlayer3D.new()
		sizzle_audio.name = "SizzleAudioPlayer"
		sizzle_audio.unit_size = 2.8
		sizzle_audio.max_distance = 18.0
		audio_root.add_child(sizzle_audio)

		oneshot_audio = AudioStreamPlayer3D.new()
		oneshot_audio.name = "OneShotAudioPlayer"
		oneshot_audio.unit_size = 2.8
		oneshot_audio.max_distance = 18.0
		audio_root.add_child(oneshot_audio)

		basket_audio = AudioStreamPlayer3D.new()
		basket_audio.name = "BasketAudioPlayer"
		basket_audio.unit_size = 2.8
		basket_audio.max_distance = 18.0
		audio_root.add_child(basket_audio)

	hum_audio.volume_db = -80.0
	sizzle_audio.volume_db = -80.0

func _safe_play(player: AudioStreamPlayer3D) -> void:
	if player and player.is_inside_tree():
		player.play()

func _play_oneshot(sound_id: String, vol_db: float = -6.0) -> void:
	if not oneshot_audio:
		_setup_audio()
	if oneshot_audio:
		oneshot_audio.stream = SoundSynthesizer.get_stream(sound_id)
		oneshot_audio.volume_db = vol_db
		_safe_play(oneshot_audio)

func _play_basket_move(is_lowering: bool) -> void:
	if not basket_audio:
		_setup_audio()
	if basket_audio:
		var sound_id = "fryer_basket_lower" if is_lowering else "fryer_basket_raise"
		basket_audio.stream = SoundSynthesizer.get_stream(sound_id)
		basket_audio.volume_db = -14.0
		_safe_play(basket_audio)

func is_ideal_temp() -> bool:
	return current_temperature >= IDEAL_TEMP_MIN

func _is_tutorial_active() -> bool:
	if not is_inside_tree() or not get_tree() or not get_tree().root:
		return false
	var tut = get_tree().root.find_child("Tutorial", true, false)
	return tut != null and is_instance_valid(tut) and not tut.get("tutorial_completed")

func get_cooking_speed_factor() -> float:
	var tut_mult = 3.5 if _is_tutorial_active() else 1.0
	if current_temperature < 100.0:
		return 0.0
	elif current_temperature < IDEAL_TEMP_MIN:
		return (current_temperature / IDEAL_TEMP_MIN) * 0.5 * tut_mult
	else:
		return 1.0 * tut_mult

func _process(delta: float) -> void:
	var pm = PowerManager.get_instance()
	var has_power = pm.is_main_power_on if pm != null else true
	var is_actively_heating = is_on and has_power

	# 1. Simulação física contínua da temperatura
	if is_actively_heating:
		current_temperature = move_toward(current_temperature, target_temperature, heating_rate * delta)
	else:
		current_temperature = move_toward(current_temperature, ambient_temperature, cooling_rate * delta)

	# 2. Atualiza termômetro horizontal e luz piloto
	_update_thermometer(delta)

	# 3. Disparo único do Feedback Sonoro (Chime de Prontidão) ao atingir 150°C
	if is_actively_heating and is_ideal_temp():
		if not _has_played_ready_chime:
			_has_played_ready_chime = true
			_play_oneshot("fryer_ready_chime", -7.0)
	elif not is_on or current_temperature < (IDEAL_TEMP_MIN - 10.0):
		_has_played_ready_chime = false

	# 4. Processa cada um dos 4 compartimentos de forma 100% independente
	var speed = get_cooking_speed_factor()

	for i in range(4):
		var comp = compartments[i]
		var basket_down: bool = comp["basket_down"]
		var food_state: String = comp["food_state"]

		# Animação suave da posição do cesto (entra e sai da cuba e do óleo)
		var basket_node = _cached_basket_nodes[i] if i < _cached_basket_nodes.size() else null
		if basket_node and is_instance_valid(basket_node):
			var target_y = BASKET_Y_DOWN if basket_down else BASKET_Y_UP
			basket_node.position.y = lerpf(basket_node.position.y, target_y, 1.0 - exp(-12.0 * delta))

		# Animação suave da alavanca
		var lever_arm = _cached_lever_arms[i] if i < _cached_lever_arms.size() else null
		if lever_arm and is_instance_valid(lever_arm):
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
				if not comp.has("portions_remaining") or comp["portions_remaining"] <= 0:
					comp["portions_remaining"] = 3 if comp.get("food_type") == "onion" else 5
			else:
				comp["food_state"] = "cooking"

		# Atualização visual do alimento, ondulação líquida do óleo e partículas
		_update_compartment_visuals(i, is_frying)

	# 5. Processamento Sonoro Contínuo (Hum de Aquecimento e Sizzle de Fritura)
	_process_audio(delta)

func _process_audio(delta: float) -> void:
	if not hum_audio or not sizzle_audio:
		_setup_audio()

	# 1. Zumbido contínuo de aquecimento e funcionamento (Hum Loop suave e discreto)
	if is_on:
		if not hum_audio.playing:
			hum_audio.stream = SoundSynthesizer.get_stream("fryer_hum_loop")
			_safe_play(hum_audio)
		_target_hum_vol = -36.0
	else:
		_target_hum_vol = -80.0

	var w_hum = 1.0 - exp(-6.0 * delta)
	hum_audio.volume_db = lerpf(hum_audio.volume_db, _target_hum_vol, w_hum)
	if not is_on and hum_audio.volume_db <= -60.0 and hum_audio.playing:
		hum_audio.stop()

	# 2. Chiado e borbulhamento dinâmico do óleo (Sizzle Loop moderado e equilibrado)
	var frying_baskets_count = 0
	var any_burnt = false
	var speed = get_cooking_speed_factor()

	for comp in compartments:
		if comp["basket_down"] and speed > 0.0 and comp["food_state"] != "empty":
			frying_baskets_count += 1
			if comp["food_state"] == "burnt":
				any_burnt = true

	if frying_baskets_count > 0 and current_temperature >= 80.0:
		if not sizzle_audio.playing:
			sizzle_audio.stream = SoundSynthesizer.get_stream("fryer_sizzle_loop")
			_safe_play(sizzle_audio)

		# Volume base equilibrado conforme temperatura do óleo
		var temp_ratio = clampf((current_temperature - 80.0) / (IDEAL_TEMP_MIN - 80.0), 0.3, 1.0)
		var base_vol = lerpf(-27.0, -19.0, temp_ratio)

		# Escalação natural com múltiplos cestos (+1.0 dB por cesto adicional)
		var multi_bonus = (frying_baskets_count - 1) * 1.0
		_target_sizzle_vol = minf(-15.0, base_vol + multi_bonus)

		# Pitch dinâmico: mais borbulhante e agressivo quando muito quente ou queimando
		var target_pitch = 1.08 if any_burnt else (1.02 if is_ideal_temp() else 0.96)
		var w_pitch = 1.0 - exp(-4.0 * delta)
		sizzle_audio.pitch_scale = lerpf(sizzle_audio.pitch_scale, target_pitch, w_pitch)
	else:
		_target_sizzle_vol = -80.0

	var w_sizzle = 1.0 - exp(-8.0 * delta)
	sizzle_audio.volume_db = lerpf(sizzle_audio.volume_db, _target_sizzle_vol, w_sizzle)
	if frying_baskets_count == 0 and sizzle_audio.volume_db <= -60.0 and sizzle_audio.playing:
		sizzle_audio.stop()

func _update_compartment_visuals(i: int, is_frying: bool) -> void:
	var comp = compartments[i]
	var food_state: String = comp["food_state"]
	var timer: float = comp["timer"]

	# Malha do alimento no cesto (Batata ou Cebola) com evolução de cor e redução física por porção
	var fries_mesh = get_node_or_null("Model/Basket%d/FriesMesh" % i) as MeshInstance3D
	if fries_mesh:
		var f_type = comp.get("food_type", "potato")
		var max_p = 3.0 if f_type == "onion" else 5.0
		var portions = comp.get("portions_remaining", int(max_p))
		if food_state == "empty" or portions <= 0:
			fries_mesh.visible = false
		else:
			fries_mesh.visible = true
			var port_ratio = clampf(float(portions) / max_p, 0.25, 1.0)
			fries_mesh.scale = Vector3(1.0, port_ratio, 1.0)
			fries_mesh.position.y = -0.04 - (1.0 - port_ratio) * 0.02

			var mat = fries_mesh.material_override as StandardMaterial3D
			if not mat:
				mat = StandardMaterial3D.new()
				fries_mesh.material_override = mat

			match food_state:
				"frozen":
					mat.albedo_color = Color(0.96, 0.93, 0.76, 1.0) if f_type == "potato" else Color(0.94, 0.88, 0.82, 1.0)
					mat.roughness = 0.65
				"cooking":
					# Transição gradual suave de cor conforme o tempo de fritura
					var prog = clampf(timer / cook_time, 0.0, 1.0)
					var target_col = Color(0.95, 0.72, 0.18, 1.0) if f_type == "potato" else Color(0.92, 0.68, 0.16, 1.0)
					mat.albedo_color = (Color(0.96, 0.93, 0.76, 1.0) if f_type == "potato" else Color(0.94, 0.88, 0.82, 1.0)).lerp(target_col, prog)
					mat.roughness = lerpf(0.65, 0.40, prog)
				"cooked":
					# Dourado apetitoso pronto
					mat.albedo_color = Color(0.95, 0.72, 0.18, 1.0) if f_type == "potato" else Color(0.92, 0.68, 0.16, 1.0)
					mat.roughness = 0.40
				"burnt":
					# Escurecido queimado
					mat.albedo_color = Color(0.18, 0.12, 0.08, 1.0)
					mat.roughness = 0.85

	# Superfície líquida de óleo dourado com ondulações suaves
	var oil_mesh = _cached_oil_meshes[i] if i < _cached_oil_meshes.size() else null
	if oil_mesh:
		oil_mesh.visible = true
		var wave_amp = 0.004 if is_frying else 0.0015
		var wave = sin(Time.get_ticks_msec() * 0.004 + i * 1.5) * wave_amp
		oil_mesh.position.y = 0.74 + wave

	# Partículas de Fritura e Borbulhamento ao redor das batatas
	var bubbles = _cached_bubbles[i] if i < _cached_bubbles.size() else null
	if bubbles and bubbles.is_inside_tree():
		if bubbles.emitting != is_frying:
			bubbles.emitting = is_frying

	var steam = _cached_steams[i] if i < _cached_steams.size() else null
	if steam and steam.is_inside_tree():
		var target_steam = is_frying or (is_on and is_ideal_temp())
		if steam.emitting != target_steam:
			steam.emitting = target_steam

	var drips = _cached_drips[i] if i < _cached_drips.size() else null
	if drips and drips.is_inside_tree():
		var target_drips = (comp["drain_timer"] > 0.0 and not comp["basket_down"] and food_state != "empty")
		if drips.emitting != target_drips:
			drips.emitting = target_drips

# Atualiza termômetro horizontal e luz piloto
func _update_thermometer(delta: float) -> void:
	if not fluid_column_pivot:
		fluid_column_pivot = get_node_or_null("Model/ControlPanel/HorizontalThermometer/FluidColumnPivot")
	if fluid_column_pivot:
		var t = clampf((current_temperature - 25.0) / (180.0 - 25.0), 0.04, 1.0)
		if absf(fluid_column_pivot.scale.x - t) > 0.001:
			fluid_column_pivot.scale.x = lerpf(fluid_column_pivot.scale.x, t, 1.0 - exp(-6.0 * delta))

	if not temp_pilot_light:
		temp_pilot_light = get_node_or_null("Model/ControlPanel/TempPilotLight")
	if temp_pilot_light:
		var mat = temp_pilot_light.material_override as StandardMaterial3D
		if not mat:
			mat = StandardMaterial3D.new()
			temp_pilot_light.material_override = mat

		if not is_on:
			if mat.emission_enabled:
				mat.albedo_color = Color(0.2, 0.2, 0.22, 1.0)
				mat.emission_enabled = false
		elif is_ideal_temp():
			if not mat.emission_enabled or mat.albedo_color != Color(0.12, 0.95, 0.25, 1.0):
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
		_play_oneshot("fryer_switch_on", -6.0)
		_show_feedback(player, "♨️ Fritadeira Ligada! Aquecendo os 4 compartimentos...")
	else:
		_play_oneshot("fryer_switch_off", -6.0)
		_show_feedback(player, "⚪ Fritadeira Desligada.")

# Alterna subir/descer alavanca e cesto
func toggle_basket(slot_idx: int, player: Node3D = null) -> void:
	if slot_idx < 0 or slot_idx >= 4:
		return

	var comp = compartments[slot_idx]
	comp["basket_down"] = !comp["basket_down"]
	_play_basket_move(comp["basket_down"])

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

	# CASO 1: Jogador segurando Saco de Batata
	if held is Potato or (held != null and str(held.get("item_id")) == "potato_raw"):
		if comp["basket_down"]:
			_show_feedback(player, "⚠️ Levante o Cesto %d [E] antes de abastecer com o saco de batata!" % (slot_idx + 1))
			return

		if comp["food_state"] != "empty":
			_show_feedback(player, "⚠️ O Cesto %d já contém alimento!" % (slot_idx + 1))
			return

		comp["food_state"] = "frozen"
		comp["food_type"] = "potato"
		comp["portions_remaining"] = 5
		comp["timer"] = 0.0
		var pot_item = player.take_held_item()
		if pot_item:
			pot_item.queue_free()
		_play_oneshot("fryer_place_potatoes", -6.0)
		_update_compartment_visuals(slot_idx, false)
		_show_feedback(player, "🍟 Cesto %d abastecido com saco de batata! Cesto cheio pronto para fritar (5 porções)." % (slot_idx + 1))
		return

	# CASO 1B: Jogador segurando Saco de Cebola
	var is_held_onion = held != null and (held.get("item_id") in ["onion_rings_raw", "onion_bag"] or str(held.get("display_name")) == "Saco de Cebola")
	if is_held_onion:
		if comp["basket_down"]:
			_show_feedback(player, "⚠️ Levante o Cesto %d [E] antes de abastecer com o saco de cebola!" % (slot_idx + 1))
			return

		if comp["food_state"] != "empty":
			_show_feedback(player, "⚠️ O Cesto %d já contém alimento!" % (slot_idx + 1))
			return

		comp["food_state"] = "frozen"
		comp["food_type"] = "onion"
		comp["portions_remaining"] = 3
		comp["timer"] = 0.0
		var on_item = player.take_held_item()
		if on_item:
			on_item.queue_free()
		_play_oneshot("fryer_place_potatoes", -6.0)
		_update_compartment_visuals(slot_idx, false)
		_show_feedback(player, "🧅 Cesto %d abastecido com saco de cebola! Cesto cheio pronto para fritar (3 porções)." % (slot_idx + 1))
		return

	# CASO 2: Jogador retirando Comida Pronta (com Recipiente ou Mão Livre)
	if comp["food_state"] == "cooked":
		if comp["basket_down"]:
			_show_feedback(player, "⚠️ Levante o Cesto %d [E] para retirar as porções prontas!" % (slot_idx + 1))
			return

		var inv = InventoryManager.get_instance()
		if held is FriesPack or held is PotatoBoxItem or (held != null and str(held.get("item_id")) == "potato_box"):
			_finish_and_pack_fries(slot_idx, player, held)
			return
		elif held == null:
			if inv and not inv.has_stock("potato_box", 1):
				_show_feedback(player, "❌ Sem recipientes de batata/cebola no estoque! Compre no computador.")
				return
			if inv:
				inv.consume_stock("potato_box", 1)
			_finish_and_pack_fries(slot_idx, player, null)
			return

	# CASO 3: Retirar Comida Queimada
	if comp["food_state"] == "burnt" and held == null:
		comp["food_state"] = "empty"
		comp["portions_remaining"] = 0
		comp["timer"] = 0.0
		_update_compartment_visuals(slot_idx, false)
		_show_feedback(player, "🗑️ Alimento queimado descartado do Cesto %d." % (slot_idx + 1))
		return

func _finish_and_pack_fries(slot_idx: int, player: Node3D, existing_box: Node = null) -> void:
	var comp = compartments[slot_idx]
	var num = slot_idx + 1
	var is_onion = (comp.get("food_type") == "onion")
	var max_p = 3 if is_onion else 5
	var portions = comp.get("portions_remaining", max_p) - 1
	comp["portions_remaining"] = max(0, portions)
	if comp["portions_remaining"] <= 0:
		comp["food_state"] = "empty"
		comp["timer"] = 0.0
	_update_compartment_visuals(slot_idx, false)
	_play_oneshot("fryer_pack_fries", -5.0)

	var pack: FriesPack = null
	if existing_box != null and (existing_box is FriesPack or existing_box.has_method("set_side_type")):
		pack = existing_box as FriesPack
		if is_onion:
			pack.set_side_type("onion_rings")
		else:
			pack.set_side_type("fries")
	else:
		pack = fries_pack_scene.instantiate() as FriesPack
		if is_onion:
			pack.set_side_type("onion_rings")
		else:
			pack.set_side_type("fries")

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

	var name_pt = "cebola frita" if is_onion else "batata frita"
	var icon_pt = "🧅" if is_onion else "🍟"
	if comp["portions_remaining"] > 0:
		_show_feedback(player, "%s Porção de %s embalada! Restam %d/%d porções no Cesto %d." % [icon_pt, name_pt, comp["portions_remaining"], max_p, num])
	else:
		_show_feedback(player, "%s Última porção de %s embalada! Cesto %d agora está vazio." % [icon_pt, name_pt, num])

# Posicionamento de batata para compatibilidade com testes anteriores
func place_potato(pot: Node) -> void:
	var free_slot = 0
	for i in range(4):
		if compartments[i]["food_state"] == "empty":
			free_slot = i
			break

	var is_onion = (pot != null and (pot.get("item_id") in ["onion_rings_raw", "onion_bag"] or str(pot.get("display_name")) == "Saco de Cebola"))
	compartments[free_slot]["food_state"] = "frozen"
	compartments[free_slot]["food_type"] = "onion" if is_onion else "potato"
	compartments[free_slot]["portions_remaining"] = 3 if is_onion else 5
	compartments[free_slot]["timer"] = 0.0
	compartments[free_slot]["basket_down"] = true
	if is_instance_valid(pot):
		pot.queue_free()

func _find_most_relevant_slot() -> int:
	for i in range(4):
		if compartments[i]["food_state"] == "cooked" and not compartments[i]["basket_down"]:
			return i
	for i in range(4):
		if compartments[i]["food_state"] == "cooking" or (compartments[i]["basket_down"] and compartments[i]["food_state"] != "empty"):
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
	if slot_idx == -1 and player_3d:
		slot_idx = _find_most_relevant_slot()

	if slot_idx != -1:
		var comp = compartments[slot_idx]
		var num = slot_idx + 1
		var is_onion = (comp.get("food_type") == "onion")
		var max_p = 3 if is_onion else 5

		# Se segurando saco de batata e cesto está vazio
		if (held is Potato or (held != null and str(held.get("item_id")) == "potato_raw")) and comp["food_state"] == "empty":
			if comp["basket_down"]:
				return "⬆️ [E] Levantar Cesto %d para abastecer" % num
			else:
				return "🍟 [Clique] Abastecer Cesto %d (1 Saco = 5 Porções)" % num

		# Se segurando saco de cebola e cesto está vazio
		var is_held_onion = held != null and (held.get("item_id") in ["onion_rings_raw", "onion_bag"] or str(held.get("display_name")) == "Saco de Cebola")
		if is_held_onion and comp["food_state"] == "empty":
			if comp["basket_down"]:
				return "⬆️ [E] Levantar Cesto %d para abastecer" % num
			else:
				return "🧅 [Clique] Abastecer Cesto %d com Cebola (1 Saco = 3 Porções)" % num

		# Se cesto está fritando (mesmo modelo do hambúrguer: discreto, no HUD ao olhar)
		if comp["food_state"] == "cooking" or (comp["basket_down"] and comp["food_state"] in ["frozen", "cooking"]):
			var prog_pct = clampf((comp["timer"] / cook_time) * 100.0, 0.0, 100.0)
			if is_onion:
				return "🧅 Cebola Fritando (%d%%)" % int(prog_pct)
			else:
				return "🍟 Batata Fritando (%d%%)" % int(prog_pct)

		# Se cesto tem comida pronta
		if comp["food_state"] == "cooked":
			var rem = comp.get("portions_remaining", max_p)
			if comp["basket_down"]:
				return "⬆️ [E] Levantar Cesto %d (%s Pronta!)" % [num, ("Cebola" if is_onion else "Batata")]
			else:
				if is_onion:
					return "🧅 [Clique] Embalar Porção de Cebola Frita (%d/3 restantes)" % rem
				else:
					return "🍟 [Clique] Embalar Porção de Batata Frita (%d/5 restantes)" % rem

		# Se cesto tem comida queimada
		if comp["food_state"] == "burnt":
			if comp["basket_down"]:
				return "⬆️ [E] Levantar Cesto %d (Queimada)" % num
			else:
				return "🗑️ [Clique] Retirar Alimento Queimado (Cesto %d)" % num

		# Alavanca do cesto
		if comp["basket_down"]:
			return "⬆️ [E] Levantar Cesto %d" % num
		else:
			return "⬇️ [E] Abaixar Cesto %d no Óleo" % num

	if is_dirty():
		var tool_holder = player.get_node_or_null("Head/Camera3D/ToolHolder") if player else null
		var sponge = tool_holder.get_node_or_null("Sponge") if tool_holder else null
		if sponge:
			if sponge.is_dirty:
				return "⚠️ Bucha suja! Lave na pia antes de limpar a fritadeira"
			else:
				return "🖱️ [Segurar Clique Esquerdo] Limpar Fritadeira com a Bucha"
		else:
			return "Fritadeira suja de óleo (Equipe a Bucha [2] para limpar)"

	# Prompt geral da máquina
	if not is_on:
		return "♨️ [E] Ligar Fritadeira Industrial"
	else:
		return "⚪ [E] Desligar Fritadeira Industrial"

var dirt_level: float = 0.0

func is_dirty() -> bool:
	return dirt_level >= 0.70

func get_dirt_level() -> float:
	return dirt_level

func add_dirt(amount: float = 0.20) -> void:
	dirt_level = clampf(dirt_level + amount, 0.0, 1.0)
	_update_dirt_visuals()

func _update_dirt_visuals() -> void:
	var dirt_mesh = get_node_or_null("Model/FryerDirt")
	if dirt_mesh:
		dirt_mesh.visible = (dirt_level > 0.001)
		var sc = lerpf(0.20, 1.0, dirt_level) if dirt_level > 0.001 else 0.0
		dirt_mesh.scale = Vector3(sc, sc, sc)
		for child in dirt_mesh.get_children():
			if child is MeshInstance3D:
				var mat = child.get_active_material(0)
				if mat is StandardMaterial3D and mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					mat.albedo_color.a = clampf(dirt_level * 0.95, 0.0, 0.95)

func clean_station(player: Node3D = null) -> void:
	dirt_level = 0.0
	_update_dirt_visuals()
	if player:
		_show_feedback(player, "✨ Fritadeira limpa e higienizada!")

func clean_progress(delta: float, player: Node3D = null) -> bool:
	if dirt_level <= 0.0:
		return true

	dirt_level = maxf(0.0, dirt_level - (delta / 1.5))
	_update_dirt_visuals()

	if dirt_level <= 0.0:
		if player:
			_show_feedback(player, "✨ Fritadeira limpa e higienizada!")
			var th = player.get_node_or_null("Head/Camera3D/ToolHolder") if player.has_node("Head/Camera3D/ToolHolder") else null
			var sp = th.get_node_or_null("Sponge") if th else null
			if sp and sp.has_method("set_dirty"):
				sp.set_dirty()
			elif "sponge_is_dirty" in player:
				player.set("sponge_is_dirty", true)
		return true

	return false

func _show_feedback(player: Node3D, message: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback(message)

