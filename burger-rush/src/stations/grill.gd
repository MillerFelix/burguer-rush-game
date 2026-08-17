class_name Grill
extends StaticBody3D

# ================================================================
# GRELHA INDUSTRIAL PROFISSIONAL (SISTEMA DE ÁUDIO 3D COMPLETO)
#
# Recursos de Áudio & Física:
#  - Tecla [E]: Ligar / Desligar interruptor com som tátil e ignição
#  - Aquecimento contínuo com som ambiente sutil (Hum térmico 3D)
#  - Feedback acústico discreto ao atingir temperatura ideal de operação
#  - Som de impacto ao colocar alimentos (carne, bacon, ovo)
#  - Fritura com loop de chiado dinâmico e estalos de óleo quente
#  - Variação natural de volume e frequência conforme quantidade e estado dos alimentos
#  - Som característico da espátula ao virar (raspagem + tombo) e retirar (deslize)
#  - Áudio 3D posicional com atenuação suave por distância
# ================================================================

const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")
const PowerManager = preload("res://src/core/power_manager.gd")

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

# ================================================================
# PLAYERS DE ÁUDIO 3D POSICIONAL
# ================================================================
var hum_audio: AudioStreamPlayer3D = null
var sizzle_audio: AudioStreamPlayer3D = null
var oneshot_audio: AudioStreamPlayer3D = null
var spatula_audio: AudioStreamPlayer3D = null

var _has_played_ready_chime: bool = false
var _target_sizzle_vol: float = -80.0
var _target_hum_vol: float = -80.0

var active_items: Array[Dictionary] = [] # Array de { "item": Node3D, "type": String, "timer": float, "slot_index": int }
var dirt_level: float = 0.0

const SLOT_OFFSETS = [
	Vector3(-0.65, 0.0, 0.0),
	Vector3(-0.22, 0.0, 0.0),
	Vector3(0.22, 0.0, 0.0),
	Vector3(0.65, 0.0, 0.0)
]

func _ready() -> void:
	add_to_group("cleanable_stations")
	_setup_audio()
	var pm = PowerManager.get_instance()
	if pm:
		pm.register_appliance(self, "grill", "Chapa / Grelha Comercial", 3.0, is_on)
		if not pm.power_state_changed.is_connected(on_power_state_changed):
			pm.power_state_changed.connect(on_power_state_changed)
	_update_visuals_instant()

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
		hum_audio = _create_audio_player_3d("HumAudioPlayer", -80.0)
	if not sizzle_audio:
		sizzle_audio = _create_audio_player_3d("SizzleAudioPlayer", -80.0)
	if not oneshot_audio:
		oneshot_audio = _create_audio_player_3d("OneShotAudioPlayer", -8.0)
	if not spatula_audio:
		spatula_audio = _create_audio_player_3d("SpatulaAudioPlayer", -6.0)

func _create_audio_player_3d(player_name: String, initial_db: float) -> AudioStreamPlayer3D:
	var player = get_node_or_null("Audio/" + player_name) as AudioStreamPlayer3D
	if not player:
		var audio_root = get_node_or_null("Audio")
		if not audio_root:
			audio_root = Node3D.new()
			audio_root.name = "Audio"
			add_child(audio_root)
			audio_root.position = Vector3(0.0, 0.90, 0.0) # Posicionado na superfície da chapa

		player = AudioStreamPlayer3D.new()
		player.name = player_name
		player.unit_size = 2.8
		player.max_distance = 18.0
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		player.volume_db = initial_db
		player.bus = "Master"
		audio_root.add_child(player)
	return player

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
	var pm = PowerManager.get_instance()
	var has_power = pm.is_main_power_on if pm else false
	var is_actively_heating = is_on and has_power

	# 1. Simulação física contínua da temperatura
	var prev_temp = current_temperature
	if is_actively_heating:
		current_temperature = move_toward(current_temperature, target_temperature, heating_rate * delta)
	else:
		current_temperature = move_toward(current_temperature, ambient_temperature, cooling_rate * delta)

	# 2. Feedback de temperatura ideal atingida
	if is_on and prev_temp < IDEAL_TEMP_MIN and current_temperature >= IDEAL_TEMP_MIN:
		if not _has_played_ready_chime:
			_has_played_ready_chime = true
			_play_ready_sound()

	# 3. Movimento suave da barra horizontal do termômetro e luz indicadora
	_update_thermometer(delta)

	# 4. Processamento da cocção dos alimentos na chapa
	var speed = get_cooking_speed_factor()
	var cooking_items_count = 0
	var any_burning = false

	if not active_items.is_empty():
		for item_data in active_items:
			var node = item_data["item"] as Node3D
			if not is_instance_valid(node):
				continue

			if speed > 0.0:
				cooking_items_count += 1
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
									any_burning = true
								elif timer > (patty_side_cook_time * 2.0 + patty_burn_time * 0.7):
									any_burning = true
					"cheese":
						var cheese = node as Cheese
						if cheese:
							var progress_delta = (100.0 / 6.0) * delta * speed
							cheese.advance_cooking(progress_delta)
							if cheese.is_melted():
								if timer > (6.0 + 7.0):
									cheese.set_burnt()
									any_burning = true
								elif timer > (6.0 + 7.0 * 0.7):
									any_burning = true
					"bacon":
						var bacon = node as Bacon
						if bacon:
							if timer >= bacon_cook_time + bacon_burn_time:
								bacon.set_state(Bacon.State.BURNT)
								any_burning = true
							elif timer >= bacon_cook_time:
								bacon.set_state(Bacon.State.COOKED)
							else:
								bacon.set_state(Bacon.State.COOKING)
					"egg":
						var egg = node as Egg
						if egg:
							if timer >= egg_cook_time + egg_dry_time + 4.0:
								egg.set_state(Egg.State.BURNT)
								any_burning = true
							elif timer >= egg_cook_time + egg_dry_time:
								egg.set_state(Egg.State.DRYING)
							elif timer >= egg_cook_time:
								egg.set_state(Egg.State.COOKED)
							elif timer >= 0.3:
								egg.set_state(Egg.State.COOKING)
							else:
								egg.set_state(Egg.State.CRACKED)

	# 5. Efeitos de partículas de fritura e respingos de óleo
	var any_cooking = (cooking_items_count > 0)
	if smoke_particles and smoke_particles.is_inside_tree():
		smoke_particles.emitting = (any_cooking and is_ideal_temp())
	if oil_particles and oil_particles.is_inside_tree():
		oil_particles.emitting = (any_cooking and is_ideal_temp())

	# 6. Atualização do Áudio 3D da Chapa
	_process_audio(delta, cooking_items_count, any_burning)

func _safe_play(player: AudioStreamPlayer3D) -> void:
	if player and player.is_inside_tree():
		player.play()

# ================================================================
# PROCESSAMENTO CONTÍNUO DE ÁUDIO 3D
# ================================================================
func _process_audio(delta: float, cooking_count: int, is_burning: bool) -> void:
	if not hum_audio or not sizzle_audio:
		_setup_audio()

	# 1. Zumbido térmico / funcionamento da grelha (Hum Loop)
	if is_on:
		_target_hum_vol = -26.0 if is_ideal_temp() else -28.0
		if not hum_audio.playing:
			hum_audio.stream = SoundSynthesizer.get_stream("grill_hum_loop")
			_safe_play(hum_audio)
	else:
		_target_hum_vol = -80.0

	var w_hum = 1.0 - exp(-6.0 * delta)
	hum_audio.volume_db = lerpf(hum_audio.volume_db, _target_hum_vol, w_hum)
	if not is_on and hum_audio.volume_db <= -60.0 and hum_audio.playing:
		hum_audio.stop()

	# 2. Chiado dinâmico de fritura (Sizzle Loop)
	if cooking_count > 0 and current_temperature >= 80.0:
		if not sizzle_audio.playing:
			sizzle_audio.stream = SoundSynthesizer.get_stream("grill_sizzle_loop")
			_safe_play(sizzle_audio)

		# Volume base moderado conforme a temperatura
		var temp_ratio = clampf((current_temperature - 80.0) / (IDEAL_TEMP_MIN - 80.0), 0.2, 1.0)
		var base_vol = lerpf(-24.0, -15.0, temp_ratio)

		# Variação natural de volume com múltiplos itens (+1.0 dB por item extra)
		var multi_item_bonus = (cooking_count - 1) * 1.0
		_target_sizzle_vol = minf(-12.0, base_vol + multi_item_bonus)

		# Pitch dinâmico: mais estalado e agressivo quando está muito quente ou queimando
		var target_pitch = 1.08 if is_burning else (1.02 if is_ideal_temp() else 0.95)
		var w_pitch = 1.0 - exp(-4.0 * delta)
		sizzle_audio.pitch_scale = lerpf(sizzle_audio.pitch_scale, target_pitch, w_pitch)
	else:
		_target_sizzle_vol = -80.0

	var w_sizzle = 1.0 - exp(-8.0 * delta)
	sizzle_audio.volume_db = lerpf(sizzle_audio.volume_db, _target_sizzle_vol, w_sizzle)
	if (cooking_count == 0 or current_temperature < 80.0) and sizzle_audio.volume_db <= -60.0 and sizzle_audio.playing:
		sizzle_audio.stop()

func _play_ready_sound() -> void:
	if not oneshot_audio:
		_setup_audio()
	oneshot_audio.stream = SoundSynthesizer.get_stream("grill_ready_chime")
	oneshot_audio.volume_db = -10.0
	_safe_play(oneshot_audio)

func _update_thermometer(delta: float) -> void:
	if not fluid_column_pivot:
		fluid_column_pivot = get_node_or_null("Model/ControlPanel/HorizontalThermometer/FluidColumnPivot")
	if fluid_column_pivot:
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

	if not oneshot_audio:
		_setup_audio()

	if is_on:
		_has_played_ready_chime = (current_temperature >= IDEAL_TEMP_MIN)
		oneshot_audio.stream = SoundSynthesizer.get_stream("grill_switch_on")
		oneshot_audio.volume_db = -6.0
		_safe_play(oneshot_audio)
		_show_feedback(player, "♨️ Grelha Ligada! Acompanhe o indicador e a luz verde...")
	else:
		_has_played_ready_chime = false
		oneshot_audio.stream = SoundSynthesizer.get_stream("grill_switch_off")
		oneshot_audio.volume_db = -6.0
		_safe_play(oneshot_audio)
		_show_feedback(player, "⚪ Grelha Desligada.")

# Interação com tecla [E] — Ligar / Desligar Grelha
func interact_equipment(player: Node3D) -> void:
	toggle_power(player)

func interact(player: Node3D) -> void:
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held is Patty or held is Bacon or held is Egg or str(held.get("item_type")) == "ingredient":
			interact_item(player)
			return
	toggle_power(player)

func can_cook_item(item: Node) -> bool:
	if not item:
		return false
	if item is Patty or item is Cheese or item is Bacon or item is Egg:
		return true
	if item.has_method("is_cookable_on_grill"):
		return item.is_cookable_on_grill()
	if item.get("is_grillable") == true:
		return true
	return false

# Interação com Clique Esquerdo — Manipulação de Alimentos com Ferramentas ou Mãos
func interact_item(player: Node3D) -> void:
	if not player:
		return

	var tool_slot = player.get("active_tool_slot") if player else 3
	var held = player.get("held_item")

	# CASO 1: Jogador segurando um item (Tentando colocar na chapa)
	if held != null:
		if can_cook_item(held):
			if active_items.size() >= max_capacity:
				_show_feedback(player, "⚠️ A grelha está cheia (%d/%d itens)!" % [active_items.size(), max_capacity])
				return
			var item = player.take_held_item()
			if item:
				place_item(item)
				_show_feedback(player, "♨️ %s colocado na chapa" % item.get_display_name())
			return
		else:
			# ITEM INVÁLIDO: chapa bloqueia e o item é solto para cair no chão naturalmente
			_play_reject_sound()
			if player.has_method("drop_item"):
				player.drop_item()
			return

	# CASO 2: Jogador com ESPÁTULA (Slot 1) ou MÃO LIVRE (Slot 3)
	if tool_slot in [1, 3]:
		if active_items.is_empty():
			if tool_slot == 1:
				_show_feedback(player, "🍳 Espátula pronta. Nenhum alimento na chapa.")
			return

		var target_item_data = _get_aimed_item(player)
		if target_item_data.is_empty():
			target_item_data = active_items[0]

		var node = target_item_data["item"]
		if not is_instance_valid(node):
			return

		if player.has_node("Head/Camera3D/ToolHolder"):
			var tool_holder = player.get_node("Head/Camera3D/ToolHolder")
			if tool_holder and tool_holder.get_child_count() > 0:
				var spatula = tool_holder.get_child(0)
				if spatula and spatula.has_method("play_action_animation"):
					spatula.play_action_animation()

		# Interação com Hambúrguer (Virar com espátula se precisar, ou retirar)
		if node is Patty:
			var patty = node as Patty
			if tool_slot == 1 and (patty.state == Patty.State.READY_SIDE_1 or (patty.state == Patty.State.COOKING_SIDE_1 and not patty.is_flipped)):
				patty.flip()
				_play_spatula_sound(true)
				_show_feedback(player, "🔄 Hambúrguer virado! Grelhando Lado 2.")
				return
			else:
				_play_spatula_sound(false)
				_remove_item_from_grill(node, player)
				var state_txt = "Pronto!" if patty.is_fully_cooked() else ("Queimado" if patty.state == Patty.State.BURNT else "Cru")
				_show_feedback(player, "🍳 Retirou %s da grelha (%s)" % [patty.get_display_name(), state_txt])
				return

		# Interação com Queijo, Bacon, Ovo ou qualquer outro ingrediente da chapa
		_play_spatula_sound(false)
		_remove_item_from_grill(node, player)
		_show_feedback(player, "✋ Retirou %s da chapa" % node.get_display_name())
		return

	# CASO 3: Jogador com BUCHA DE LIMPEZA (Slot 2)
	if tool_slot == 2:
		if is_dirty():
			clean_progress(1.5, player)
		else:
			_show_feedback(player, "✨ A chapa da grelha já está limpa e brilhando!")
		return

func is_dirty() -> bool:
	return dirt_level >= 1.0

func add_dirt(amount: float = 0.25) -> void:
	dirt_level = clampf(dirt_level + amount, 0.0, 1.0)
	_update_dirt_visuals()

func _update_dirt_visuals() -> void:
	var grill_dirt = get_node_or_null("Model/GrillPlate/GrillDirt")
	if grill_dirt:
		grill_dirt.visible = (dirt_level > 0.001)
		grill_dirt.scale.y = clampf(dirt_level, 0.02, 1.0)
		grill_dirt.scale.x = lerpf(0.80, 1.0, dirt_level)
		grill_dirt.scale.z = lerpf(0.80, 1.0, dirt_level)
		if grill_dirt is MeshInstance3D and grill_dirt.material_override:
			var mat = grill_dirt.material_override as StandardMaterial3D
			if mat:
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.albedo_color.a = clampf(dirt_level, 0.0, 1.0)

func clean_progress(delta: float, player: Node3D = null) -> bool:
	if dirt_level <= 0.0:
		return true

	dirt_level = maxf(0.0, dirt_level - (delta / 1.5))
	_update_dirt_visuals()

	if dirt_level <= 0.0:
		if player:
			_show_feedback(player, "✨ Grelha limpa e pronta para uso!")
		return true
	return false

func place_item(item: Node3D) -> bool:
	if not can_cook_item(item):
		return false

	if is_dirty():
		return false

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
	if item is Cheese:
		itm_type = "cheese"
	elif item is Bacon:
		itm_type = "bacon"
		if item.has_method("set_state"):
			item.set_state(Bacon.State.COOKING)
	elif item is Egg:
		itm_type = "egg"
		if item.has_method("set_state"):
			item.set_state(Egg.State.CRACKED)
	elif item is Patty:
		itm_type = "patty"
	else:
		itm_type = "patty"

	active_items.append({
		"item": item,
		"type": itm_type,
		"timer": 0.0,
		"slot_index": slot_idx
	})

	if item.has_method("on_placed_in_station"):
		item.on_placed_in_station()

	# Reproduz som específico de impacto/contato com a chapa quente
	_play_contact_sound(itm_type)
	return true

func _play_contact_sound(itm_type: String) -> void:
	if not oneshot_audio:
		_setup_audio()

	var sound_key = "grill_place_patty"
	if itm_type == "bacon":
		sound_key = "grill_place_bacon"
	elif itm_type == "egg":
		sound_key = "grill_place_egg"
	elif itm_type == "cheese":
		sound_key = "grill_place_patty"

	oneshot_audio.stream = SoundSynthesizer.get_stream(sound_key)
	oneshot_audio.volume_db = -6.0
	_safe_play(oneshot_audio)

func _play_reject_sound() -> void:
	if not oneshot_audio:
		_setup_audio()
	oneshot_audio.stream = SoundSynthesizer.get_stream("box_place")
	oneshot_audio.volume_db = -8.0
	_safe_play(oneshot_audio)

func _play_spatula_sound(is_flip: bool) -> void:
	if not spatula_audio:
		_setup_audio()

	var stream = SoundSynthesizer.get_stream("spatula_flip" if is_flip else "spatula_scrape")
	spatula_audio.stream = stream
	spatula_audio.volume_db = -4.0 if is_flip else -6.0
	_safe_play(spatula_audio)

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

	# Uso da chapa acumula sujeira
	add_dirt(0.25)

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

	if is_dirty():
		var tool_holder = player.get_node_or_null("Head/Camera3D/ToolHolder") if player else null
		var sponge = tool_holder.get_node_or_null("Sponge") if tool_holder else null
		if sponge:
			if sponge.is_dirty:
				return "⚠️ Bucha suja! Lave na pia antes de limpar a grelha"
			else:
				return "🖱️ [Segurar Clique Esquerdo] Limpar Grelha com a Bucha"
		else:
			return "Grelha suja (Equipe a Bucha [2] para limpar)"

	var tool_slot = player.get("active_tool_slot") if player else 3
	var held = player.get("held_item")

	if tool_slot == 2:
		if dirt_level > 0.0:
			return "🖱️ [Segurar Clique Esquerdo] Limpar Grelha com a Bucha"
		else:
			return "Grelha Limpa"

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
			elif node is Cheese:
				var c = node as Cheese
				if c.is_ready():
					return "🍳 [Clique] RETIRAR Queijo Derretido!"
				else:
					return "🍳 [Clique] Retirar %s" % c.get_display_name()
			elif node is Bacon or node is Egg:
				return "🍳 [Clique] Retirar %s" % node.get_display_name()
		return "🍳 Espátula — Nenhum alimento na chapa"

	# Se estiver com a mão livre e segurando alimento fritável
	if tool_slot == 3 and held != null:
		if can_cook_item(held):
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
