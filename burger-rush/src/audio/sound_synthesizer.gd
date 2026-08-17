class_name SoundSynthesizer
extends RefCounted

# ================================================================
# GERADOR DE EFEITOS SONOROS PROCEDURAIS (BURGER RUSH AUDIO SYSTEM)
# Sintetiza buffers de áudio PCM 16-bits para equipamentos e interações
# ================================================================

static var _cached_streams: Dictionary = {}

static func get_stream(sound_id: String) -> AudioStreamWAV:
	if _cached_streams.has(sound_id):
		return _cached_streams[sound_id]

	var stream: AudioStreamWAV = null
	match sound_id:
		"grill_switch_on":
			stream = _generate_switch_click(true)
		"grill_switch_off":
			stream = _generate_switch_click(false)
		"grill_hum_loop":
			stream = _generate_grill_hum_loop()
		"grill_ready_chime":
			stream = _generate_ready_chime()
		"grill_sizzle_loop":
			stream = _generate_grill_sizzle_loop()
		"grill_place_patty":
			stream = _generate_place_meat(0)
		"grill_place_bacon":
			stream = _generate_place_meat(1)
		"grill_place_egg":
			stream = _generate_place_meat(2)
		"grill_flip_spatula":
			stream = _generate_spatula_flip()
		"grill_remove_item":
			stream = _generate_spatula_remove()
		"fryer_switch_on":
			stream = _generate_switch_click(true)
		"fryer_switch_off":
			stream = _generate_switch_click(false)
		"fryer_hum_loop":
			stream = _generate_fryer_hum_loop()
		"fryer_ready_chime":
			stream = _generate_ready_chime()
		"fryer_basket_lower":
			stream = _generate_fryer_basket_move(true)
		"fryer_basket_raise":
			stream = _generate_fryer_basket_move(false)
		"fryer_place_potatoes":
			stream = _generate_fryer_place_potatoes()
		"fryer_sizzle_loop":
			stream = _generate_fryer_sizzle_loop()
		"fryer_pack_fries":
			stream = _generate_fryer_pack_fries()
		# --- MÁQUINA DE REFRIGERANTES ---
		"soda_switch_on":
			stream = _generate_switch_click(true)
		"soda_switch_off":
			stream = _generate_switch_click(false)
		"soda_fridge_loop":
			stream = _generate_refrigeration_loop()
		"soda_door_open":
			stream = _generate_door_sound(true)
		"soda_door_close":
			stream = _generate_door_sound(false)
		"soda_canister_remove":
			stream = _generate_canister_sound(false)
		"soda_canister_insert":
			stream = _generate_canister_sound(true)
		"soda_lever_pull":
			stream = _generate_lever_click(true)
		"soda_lever_release":
			stream = _generate_lever_click(false)
		"soda_dispense_loop":
			stream = _generate_liquid_dispense_loop(true)
		"soda_cup_place":
			stream = _generate_cup_sound(true)
		"soda_cup_remove":
			stream = _generate_cup_sound(false)
		# --- MÁQUINA DE SUCOS ---
		"juice_switch_on":
			stream = _generate_switch_click(true)
		"juice_switch_off":
			stream = _generate_switch_click(false)
		"juice_hum_loop":
			stream = _generate_refrigeration_loop()
		"juice_drawer_open":
			stream = _generate_drawer_sound(true)
		"juice_drawer_close":
			stream = _generate_drawer_sound(false)
		"juice_pulp_place":
			stream = _generate_pulp_place_sound()
		"juice_pulp_reject":
			stream = _generate_reject_beep()
		"juice_process_loop":
			stream = _generate_juice_process_loop()
		"juice_fill_reservoir":
			stream = _generate_reservoir_fill_sound()
		"juice_dispense_loop":
			stream = _generate_liquid_dispense_loop(false)
		# --- JOGADOR & INTERAÇÕES ---
		"player_footstep":
			stream = _generate_footstep()
		"item_pickup":
			stream = _generate_item_pickup()
		"item_drop":
			stream = _generate_item_drop()
		"tool_spatula_equip":
			stream = _generate_tool_equip("spatula")
		"tool_sponge_equip":
			stream = _generate_tool_equip("sponge")
		"tool_hands_equip":
			stream = _generate_tool_equip("hands")
		# --- AMBIENTE ---
		"kitchen_hood_ambience":
			stream = _generate_kitchen_hood_ambience()
		"outside_traffic_ambience":
			stream = _generate_outside_traffic_ambience()
		"diner_bg_music":
			stream = _generate_diner_bg_music()
		"warehouse_ambience":
			stream = _generate_warehouse_ambience()
		# --- GELADEIRAS E FREEZERS ---
		"fridge_door_open":
			stream = _generate_fridge_door_sound(true)
		"fridge_door_close":
			stream = _generate_fridge_door_sound(false)
		"freezer_lid_open":
			stream = _generate_freezer_lid_sound(true)
		"freezer_lid_close":
			stream = _generate_freezer_lid_sound(false)
		"fridge_hum_loop":
			stream = _generate_refrigeration_loop()
		"freezer_hum_loop":
			stream = _generate_refrigeration_loop()
		# --- CARROS & DELIVERY ---
		"car_engine_approach":
			stream = _generate_car_engine(0)
		"car_engine_idle":
			stream = _generate_car_engine(1)
		"car_engine_leave":
			stream = _generate_car_engine(2)
		"car_horn_beep":
			stream = _generate_car_horn()
		# --- CLIENTES ---
		"customer_arrive":
			stream = _generate_customer_arrive()
		"customer_call_hey":
			stream = _generate_customer_call(0)
		"customer_call_hello":
			stream = _generate_customer_call(1)
		"customer_call_whistle":
			stream = _generate_customer_call(2)
		"customer_call_excuse":
			stream = _generate_customer_call(3)
		"customer_call_regular":
			stream = _generate_customer_call(0)
		"customer_call_impatient":
			stream = _generate_customer_call(0)
		"customer_call_child":
			stream = _generate_customer_call(1)
		"customer_call_elder":
			stream = _generate_customer_call(3)
		"customer_attend":
			stream = _generate_customer_attend()
		"customer_thank":
			stream = _generate_customer_thank()
		"customer_leave":
			stream = _generate_customer_leave()
		_:
			stream = _generate_generic_click()

	if stream:
		_cached_streams[sound_id] = stream
	return stream

# 1. Clique de interruptor liga/desliga com estalo mecânico e centelha
static func _generate_switch_click(is_on: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.16 if is_on else 0.10
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)
		var env = exp(-progress * 28.0)

		# Frequência de clique mecânico
		var freq = (1400.0 - progress * 800.0) if is_on else (900.0 - progress * 500.0)
		var click = sin(2.0 * PI * freq * t) * env

		# Ruído de contato metálico
		var noise = randf_range(-1.0, 1.0) * exp(-progress * 40.0) * 0.4

		# Centelha / zumbido inicial ao ligar
		var hum = 0.0
		if is_on and progress > 0.15:
			var hum_env = exp(-(progress - 0.15) * 12.0)
			hum = sin(2.0 * PI * 120.0 * t) * hum_env * 0.35

		var sample = clampf(click * 0.65 + noise + hum, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 2. Zumbido ambiente sutil da chapa aquecendo / ligada (Loop)
static func _generate_grill_hum_loop() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 2.0
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		# Tom térmico de 60Hz + harmônico 120Hz + ruído suave de ar quente
		var tone1 = sin(2.0 * PI * 60.0 * t) * 0.30
		var tone2 = sin(2.0 * PI * 120.0 * t) * 0.15
		var tone3 = sin(2.0 * PI * 180.0 * t) * 0.06
		var air_draft = randf_range(-0.04, 0.04)

		var sample = clampf(tone1 + tone2 + tone3 + air_draft, -1.0, 1.0) * 0.6
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	return stream

# 3. Pequeno feedback sonoro discreto de temperatura ideal atingida
static func _generate_ready_chime() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.35
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)
		var env = exp(-progress * 10.0)

		# Acorde suave de prontidão (Mi5 659Hz + Si5 987Hz) com decaimento suave
		var tone1 = sin(2.0 * PI * 659.25 * t) * 0.4
		var tone2 = sin(2.0 * PI * 987.77 * t) * 0.3
		var ping = (tone1 + tone2) * env

		var sample = clampf(ping, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 4. Som contínuo e orgânico de fritura na chapa quente (Loop Sizzle)
static func _generate_grill_sizzle_loop() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 3.0
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	var lp_val = 0.0
	var crackle_cooldown = 0

	for i in range(num_samples):
		# Ruído branco filtrado passa-baixa e passa-banda para textura de gordura fervente
		var white = randf_range(-1.0, 1.0)
		lp_val = (lp_val * 0.72) + (white * 0.28)

		# Estalos de óleo quente aleatórios e orgânicos
		var crackle = 0.0
		if crackle_cooldown <= 0:
			if randf() < 0.018:
				crackle = randf_range(0.5, 1.0) * (1.0 if randf() > 0.5 else -1.0)
				crackle_cooldown = randi_range(60, 280)
		else:
			crackle_cooldown -= 1

		var combined = (lp_val * 0.55) + (crackle * 0.45)
		var s16 = int(clampf(combined * 0.75, -1.0, 1.0) * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	return stream

# 5. Colocar alimento na chapa: impacto carnoso + chiado inicial
static func _generate_place_meat(type_idx: int) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.35
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		# Impacto carnoso inicial (grave e encorpado)
		var thud_env = exp(-progress * 35.0)
		var freq = 160.0 - progress * 100.0 if type_idx == 0 else (220.0 - progress * 140.0)
		var thud = sin(2.0 * PI * freq * t) * thud_env * 0.7

		# Chiado inicial de contato com ferro quente
		var sizzle_env = 0.0
		if progress > 0.03:
			sizzle_env = exp(-(progress - 0.03) * 7.0) * 0.65
		var sizzle = randf_range(-1.0, 1.0) * sizzle_env

		var sample = clampf(thud + sizzle, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 6. Virar alimento com espátula: raspagem metálica + tombo do hambúrguer
static func _generate_spatula_flip() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.32
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		# 1ª metade: raspagem de aço na chapa (som áspero metálico)
		var scrape = 0.0
		if progress < 0.55:
			var scrape_env = sin(progress / 0.55 * PI)
			scrape = randf_range(-1.0, 1.0) * scrape_env * 0.65 * (0.6 + 0.4 * sin(2.0 * PI * 2400.0 * t))

		# 2ª metade: carne batendo de volta na chapa quente
		var slap = 0.0
		if progress >= 0.45:
			var slap_p = (progress - 0.45) / 0.55
			var slap_env = exp(-slap_p * 22.0)
			var meat_thud = sin(2.0 * PI * 180.0 * t) * slap_env * 0.6
			var meat_sizzle = randf_range(-1.0, 1.0) * slap_env * 0.5
			slap = meat_thud + meat_sizzle

		var sample = clampf(scrape + slap, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 7. Retirar alimento da chapa com espátula: deslizar metálico e suspensão
static func _generate_spatula_remove() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.24
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		# Deslize rápido e suave da lâmina de aço sob o alimento
		var env = sin(progress * PI)
		var metallic_ring = sin(2.0 * PI * 3100.0 * t) * 0.25 * env
		var slide_noise = randf_range(-1.0, 1.0) * 0.45 * env

		var sample = clampf(metallic_ring + slide_noise, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 8. Zumbido industrial contínuo da fritadeira aquecendo (Hum Térmico)
static func _generate_fryer_hum_loop() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 2.0
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		# Zumbido elétrico grave e ressonância de óleo (80Hz e 160Hz)
		var hum80 = sin(2.0 * PI * 80.0 * t) * 0.28
		var hum160 = sin(2.0 * PI * 160.0 * t) * 0.14
		var low_rumble = sin(2.0 * PI * 40.0 * t) * 0.12
		var oil_flow = randf_range(-0.03, 0.03)

		var sample = clampf(hum80 + hum160 + low_rumble + oil_flow, -1.0, 1.0) * 0.6
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	return stream

# 9. Movimento mecânico do cesto (Abaixar e Levantar)
static func _generate_fryer_basket_move(is_lowering: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.32
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		# Deslize suave de grade metálica nos trilhos
		var glide_env = sin(progress * PI)
		var freq = (380.0 - progress * 100.0) if is_lowering else (280.0 + progress * 120.0)
		var rail_glide = sin(2.0 * PI * freq * t) * glide_env * 0.25
		var friction = randf_range(-0.15, 0.15) * glide_env * 0.20

		# Trava amortecida no final do curso
		var latch = 0.0
		if progress > 0.78:
			var latch_p = (progress - 0.78) / 0.22
			var latch_env = exp(-latch_p * 28.0)
			var click_freq = 560.0 if is_lowering else 680.0
			latch = sin(2.0 * PI * click_freq * t) * latch_env * 0.30

		# Borbulhar suave de imersão/remoção do óleo
		var splash = 0.0
		if is_lowering and progress > 0.4:
			var splash_p = (progress - 0.4) / 0.6
			splash = randf_range(-0.25, 0.25) * exp(-splash_p * 8.0) * 0.20

		var sample = clampf((rail_glide + friction + latch + splash) * 0.55, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 10. Colocar saco de batatas no cesto aramado: queda de palitos congelados
static func _generate_fryer_place_potatoes() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.32
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		# Impacto cascata de palitos crocantes/congelados batendo na grade de arame
		var rattle = 0.0
		for k in range(4):
			var delay = float(k) * 0.04
			if progress > delay:
				var p_sub = (progress - delay) / (1.0 - delay)
				var env = exp(-p_sub * 20.0)
				var clatter = sin(2.0 * PI * (900.0 + k * 350.0) * t) * env * 0.25
				var wood_rustle = randf_range(-0.3, 0.3) * env
				rattle += clatter + wood_rustle

		var sample = clampf(rattle, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 11. Som rico, profundo e borbulhante de imersão e fritura em óleo fervente (Loop Sizzle)
static func _generate_fryer_sizzle_loop() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 3.0
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	var lp_val = 0.0
	var bubble_timer = 0

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)

		# Massa contínua de óleo borbulhante (filtro dinâmico de ruído denso)
		var white = randf_range(-1.0, 1.0)
		lp_val = (lp_val * 0.68) + (white * 0.32)

		# Pop de bolhas de óleo estourando na superfície
		var bubble = 0.0
		if bubble_timer <= 0:
			if randf() < 0.035:
				var b_freq = randf_range(300.0, 750.0)
				bubble = sin(2.0 * PI * b_freq * t) * randf_range(0.4, 0.85)
				bubble_timer = randi_range(30, 140)
		else:
			bubble_timer -= 1

		# Fervura subaquática de baixa frequência (borbulhamento encorpado)
		var deep_boil = sin(2.0 * PI * 95.0 * t) * 0.18 + sin(2.0 * PI * 145.0 * t) * 0.12

		var combined = (lp_val * 0.45) + (bubble * 0.35) + deep_boil
		var s16 = int(clampf(combined * 0.85, -1.0, 1.0) * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	return stream

# 12. Embalar batata frita pronta no recipiente de papelão
static func _generate_fryer_pack_fries() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.28
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		# Som crocante de colher batatas + encaixe no papelão
		var env = sin(progress * PI)
		var card_tap = sin(2.0 * PI * 280.0 * t) * exp(-progress * 15.0) * 0.5
		var crunch = randf_range(-1.0, 1.0) * env * 0.45

		var sample = clampf(card_tap + crunch, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 13. Som de compressor e refrigeração ambiente discreto (Loop)
static func _generate_refrigeration_loop() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 2.0
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		# Tom suave de compressor (50Hz e harmônico 100Hz + fluxo de ar suave)
		var hum50 = sin(2.0 * PI * 50.0 * t) * 0.22
		var hum100 = sin(2.0 * PI * 100.0 * t) * 0.12
		var fan_air = randf_range(-0.03, 0.03)

		var sample = clampf(hum50 + hum100 + fan_air, -1.0, 1.0) * 0.45
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	return stream

# 14. Som de pequena porta metálica de aço inox abrindo / fechando (dobradiça + fecho magnético)
static func _generate_door_sound(is_opening: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.12 if is_opening else 0.09
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		var sample = 0.0
		if is_opening:
			# Desengate magnético leve seguido de pequeno atrito de dobradiça de inox
			var mag_release = sin(2.0 * PI * 680.0 * t) * exp(-progress * 35.0) * 0.45
			var hinge_scrape = (sin(2.0 * PI * 1150.0 * t) * 0.25 + randf_range(-0.1, 0.1)) * sin(progress * PI) * 0.35
			sample = mag_release + hinge_scrape
		else:
			# Fechamento rápido e preciso de portinha metálica comercial com trava
			var click = sin(2.0 * PI * 920.0 * t) * exp(-progress * 42.0) * 0.65
			var metal_thud = sin(2.0 * PI * 240.0 * t) * exp(-progress * 28.0) * 0.35
			sample = click + metal_thud

		var s16 = int(clampf(sample * 0.7, -1.0, 1.0) * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 15. Som de manuseio de galão/barril de xarope
static func _generate_canister_sound(is_insert: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.18
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		var env = exp(-progress * 20.0)
		var freq = 260.0 if is_insert else 340.0
		var plastic_thud = sin(2.0 * PI * freq * t) * env * 0.45
		var latch_click = sin(2.0 * PI * (1200.0 if is_insert else 900.0) * t) * exp(-progress * 32.0) * 0.35

		var sample = clampf(plastic_thud + latch_click, -1.0, 1.0) * 0.7
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 16. Som mecânico de alavanca de torneira (Pull / Release)
static func _generate_lever_click(is_pull: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.08
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		var env = exp(-progress * 35.0)
		var freq = 750.0 if is_pull else 820.0
		var click = sin(2.0 * PI * freq * t) * env * 0.55
		var spring = sin(2.0 * PI * 1600.0 * t) * exp(-progress * 50.0) * 0.25

		var sample = clampf(click + spring, -1.0, 1.0) * 0.65
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 17. Som contínuo, leve e natural de água / líquido caindo e enchendo o copo (Loop)
static func _generate_liquid_dispense_loop(is_soda: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 2.0
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	var lp_val = 0.0
	var lp_val2 = 0.0
	var drip_timer = 0
	var droplet_phase = 0.0
	var droplet_freq = 420.0

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)

		# Cascata suave de água correndo (filtro passa-baixas suave de ruído natural)
		var white = randf_range(-1.0, 1.0)
		lp_val = (lp_val * 0.78) + (white * 0.22)
		lp_val2 = (lp_val2 * 0.82) + (lp_val * 0.18)

		# Ondulações de líquido caindo no recipiente (ressonância de copo 280Hz - 360Hz)
		var cup_resonance = sin(2.0 * PI * 310.0 * t) * 0.09 * (1.0 + 0.3 * sin(2.0 * PI * 7.5 * t))
		var stream_body = lp_val2 * 0.38 + cup_resonance

		# Gotículas/gotejos orgânicos e borbulhas de água corrente
		var droplet = 0.0
		if drip_timer <= 0:
			if randf() < 0.04:
				droplet_freq = randf_range(380.0, 720.0)
				droplet_phase = 0.0
				drip_timer = randi_range(25, 90)
		else:
			drip_timer -= 1
			droplet_phase += 1.0 / float(sample_rate)
			var drop_env = exp(-droplet_phase * 45.0)
			droplet = sin(2.0 * PI * droplet_freq * droplet_phase) * drop_env * 0.22

		# Se refrigerante: leve efervescência de gás
		var fizz = 0.0
		if is_soda:
			fizz = randf_range(-0.06, 0.06) * (1.0 + 0.4 * sin(2.0 * PI * 14.0 * t))

		var combined = stream_body + droplet + fizz
		var s16 = int(clampf(combined * 0.65, -1.0, 1.0) * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	return stream

# 18. Som de copo sendo colocado / retirado na bandeja
static func _generate_cup_sound(is_place: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.12
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		var env = exp(-progress * 28.0)
		var cup_freq = 620.0 if is_place else 780.0
		var plastic_tap = sin(2.0 * PI * cup_freq * t) * env * 0.45
		var tray_res = sin(2.0 * PI * 1800.0 * t) * exp(-progress * 45.0) * 0.2

		var sample = clampf(plastic_tap + tray_res, -1.0, 1.0) * 0.6
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 19. Pequena gaveta metálica de polpa da máquina de sucos (Open / Close)
static func _generate_drawer_sound(is_open: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.14 if is_open else 0.10
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		var sample = 0.0
		if is_open:
			# Deslizar suave do trilho metálico ao puxar
			var env = sin(progress * PI)
			var rail = (sin(2.0 * PI * 850.0 * t) * 0.25 + randf_range(-0.15, 0.15)) * env * 0.35
			var stop_click = sin(2.0 * PI * 1100.0 * t) * exp(-(1.0 - progress) * 20.0) * 0.25
			sample = rail + stop_click
		else:
			# Encaixe metálico preciso ao empurrar e travar
			var slide = randf_range(-0.1, 0.1) * (1.0 - progress) * 0.2
			var latch = sin(2.0 * PI * 880.0 * t) * exp(-progress * 38.0) * 0.55
			sample = slide + latch

		var s16 = int(clampf(sample * 0.65, -1.0, 1.0) * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 20. Colocar pedra de polpa na gaveta
static func _generate_pulp_place_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.12
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		var env = exp(-progress * 24.0)
		var block_thud = sin(2.0 * PI * 260.0 * t) * env * 0.5
		var tray_tap = sin(2.0 * PI * 950.0 * t) * exp(-progress * 35.0) * 0.25

		var sample = clampf(block_thud + tray_tap, -1.0, 1.0) * 0.6
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 21. Bipe/som de rejeição de polpa incompatível
static func _generate_reject_beep() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.14
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)
		var env = exp(-progress * 18.0)
		var buzz = (sin(2.0 * PI * 220.0 * t) + sin(2.0 * PI * 260.0 * t) * 0.4) * env * 0.35

		var s16 = int(clampf(buzz, -1.0, 1.0) * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 22. Motor suave de moagem e processamento da polpa de fruta (Loop)
static func _generate_juice_process_loop() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 2.0
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		# Rotação suave de processador (110Hz + 220Hz + fluxo contínuo de polpa)
		var motor1 = sin(2.0 * PI * 110.0 * t) * 0.22
		var motor2 = sin(2.0 * PI * 220.0 * t) * 0.10
		var crush = randf_range(-0.04, 0.04)

		var sample = clampf(motor1 + motor2 + crush, -1.0, 1.0) * 0.4
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	return stream

# 23. Líquido suave entrando e abastecendo o reservatório acrílico
static func _generate_reservoir_fill_sound() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 1.4
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		# Água suave correndo e enchendo o jarro
		var freq = 280.0 + progress * 120.0
		var gurgle = sin(2.0 * PI * freq * t) * (0.12 + 0.06 * sin(2.0 * PI * 6.0 * t))
		var noise = randf_range(-0.04, 0.04)

		var sample = clampf((gurgle + noise) * 0.45, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 24. Passo do jogador sobre o piso (Discreto, natural e audível)
static func _generate_footstep() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.10
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		# Impacto firme e acolchoado de sola de borracha no piso
		var env = exp(-progress * 30.0)
		var thud = sin(2.0 * PI * 135.0 * t) * env * 0.65
		var snap = sin(2.0 * PI * 360.0 * t) * exp(-progress * 48.0) * 0.25
		var scuff = randf_range(-0.08, 0.08) * sin(progress * PI) * 0.20

		var sample = clampf((thud + snap + scuff) * 0.70, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 24b. Porta de geladeira comercial (Borracha de vedação + estalo magnético de vedação)
static func _generate_fridge_door_sound(is_opening: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.18 if is_opening else 0.14
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		var sample = 0.0
		if is_opening:
			# Descolamento suave da borracha magnética com ar entrando (pop + whoosh leve)
			var seal_pop = sin(2.0 * PI * 160.0 * t) * exp(-progress * 22.0) * 0.65
			var suction = (randf_range(-0.12, 0.12) + sin(2.0 * PI * 340.0 * t) * 0.20) * sin(progress * PI) * 0.40
			sample = clampf((seal_pop + suction) * 0.85, -1.0, 1.0)
		else:
			# Batente com borracha de vedação amortecida + clique do ímã de vedação
			var cushion_thud = sin(2.0 * PI * 130.0 * t) * exp(-progress * 28.0) * 0.75
			var mag_snap = sin(2.0 * PI * 620.0 * t) * exp(-progress * 45.0) * 0.35
			sample = clampf((cushion_thud + mag_snap) * 0.85, -1.0, 1.0)

		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 24c. Tampa do freezer horizontal de queijos (Tampa pesada com vedação de borracha)
static func _generate_freezer_lid_sound(is_opening: bool) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.20 if is_opening else 0.16
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		var sample = 0.0
		if is_opening:
			# Levantamento da tampa pesada com sucção de gaxeta fria
			var suction = sin(2.0 * PI * 120.0 * t) * exp(-progress * 18.0) * 0.70
			var hinge = sin(2.0 * PI * 280.0 * t) * sin(progress * PI) * 0.25
			sample = clampf((suction + hinge) * 0.90, -1.0, 1.0)
		else:
			# Fechamento sólido da tampa com amortecimento de borracha
			var heavy_thud = sin(2.0 * PI * 85.0 * t) * exp(-progress * 24.0) * 0.80
			var seal_squeeze = sin(2.0 * PI * 210.0 * t) * exp(-progress * 35.0) * 0.35
			sample = clampf((heavy_thud + seal_squeeze) * 0.90, -1.0, 1.0)

		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 25. Som tátil de pegar item com a mão
static func _generate_item_pickup() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.08
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		var env = exp(-progress * 32.0)
		var swoosh = sin(2.0 * PI * (520.0 + progress * 280.0) * t) * env * 0.5
		var tap = randf_range(-0.15, 0.15) * env * 0.3

		var sample = clampf((swoosh + tap) * 0.75, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 26. Som de soltar / apoiar item sobre uma bancada ou mesa
static func _generate_item_drop() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.10
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		var env = exp(-progress * 30.0)
		var contact = sin(2.0 * PI * 240.0 * t) * env * 0.6
		var surface = sin(2.0 * PI * 700.0 * t) * exp(-progress * 45.0) * 0.3

		var sample = clampf((contact + surface) * 0.75, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 27. Trocar / equipar ferramentas (Espátula, Bucha, Mãos)
static func _generate_tool_equip(tool_type: String) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.12
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)
		var env = exp(-progress * 25.0)

		var sample = 0.0
		match tool_type:
			"spatula":
				# Brilho metálico sutil de lâmina de aço inox
				var steel = sin(2.0 * PI * 1420.0 * t) * env * 0.55
				var metallic_tap = sin(2.0 * PI * 480.0 * t) * exp(-progress * 35.0) * 0.35
				sample = steel + metallic_tap
			"sponge":
				# Som macio e texturizado de bucha
				var texture = randf_range(-0.2, 0.2) * sin(progress * PI) * 0.5
				var squish = sin(2.0 * PI * 420.0 * t) * env * 0.35
				sample = texture + squish
			_:
				# Mãos livres: movimento ágil
				var swoosh = sin(2.0 * PI * 350.0 * t) * env * 0.5
				sample = swoosh

		var s16 = int(clampf(sample * 0.70, -1.0, 1.0) * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 28. Coifa / ventilação ambiente da cozinha (Zumbido suave e quase inaudível)
static func _generate_kitchen_hood_ambience() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 2.0
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var hum50 = sin(2.0 * PI * 50.0 * t) * 0.10
		var hum100 = sin(2.0 * PI * 100.0 * t) * 0.04
		var sample = clampf((hum50 + hum100) * 0.30, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	return stream

# 29. Trânsito e rua externa (Loop de atmosfera urbana)
static func _generate_outside_traffic_ambience() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 4.0
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		# Rolamento de pneus no asfalto + grave de motores distantes + fluxo de ar
		var road_rumble = sin(2.0 * PI * 48.0 * t) * 0.28 + sin(2.0 * PI * 96.0 * t) * 0.14
		var traffic_flow = randf_range(-0.08, 0.08) * (1.0 + 0.4 * sin(2.0 * PI * 0.35 * t))
		var sample = clampf((road_rumble + traffic_flow) * 0.70, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	return stream

# 30. Motor de carro (Aproximação, Marcha Lenta, Saída)
static func _generate_car_engine(mode: int) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 2.0 if mode == 1 else 1.8
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		var rpm_freq = 50.0
		var amp = 0.6
		if mode == 0: # Aproximação (desacelerando)
			rpm_freq = 70.0 - progress * 25.0
			amp = 0.65 * minf(1.0, progress * 3.0)
		elif mode == 1: # Marcha lenta
			rpm_freq = 42.0
			amp = 0.55
		elif mode == 2: # Saída (acelerando)
			rpm_freq = 45.0 + progress * 45.0
			amp = 0.70 * (1.0 - progress * 0.5)

		var c1 = sin(2.0 * PI * rpm_freq * t)
		var c2 = sin(2.0 * PI * (rpm_freq * 2.0) * t) * 0.5
		var exhaust = randf_range(-0.1, 0.1)

		var sample = clampf((c1 + c2 + exhaust) * amp * 0.75, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	if mode == 1:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = num_samples
	return stream

# 31. Buzina do carro do delivery (Buzina dupla nítida, cortante e chamativa)
static func _generate_car_horn() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.28
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)

		# Padrão bi-tonal em 2 pulsos: pulso 1 (0.00s a 0.10s), pausa (0.10s a 0.14s), pulso 2 (0.14s a 0.28s)
		var env = 0.0
		if t < 0.10:
			var p1 = t / 0.10
			env = sin(p1 * PI)
		elif t >= 0.14 and t < 0.28:
			var p2 = (t - 0.14) / 0.14
			env = sin(p2 * PI)

		# Acorde duplo automotivo clássico (440.0 Hz + 554.37 Hz + harmônico 880.0 Hz)
		var h1 = sin(2.0 * PI * 440.0 * t)
		var h2 = sin(2.0 * PI * 554.37 * t) * 0.90
		var h3 = sin(2.0 * PI * 880.0 * t) * 0.25 # Harmônico para brilho acústico

		var sample = clampf((h1 + h2 + h3) * 0.55 * env, -1.0, 1.0) * 0.98
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 32. Chegada de cliente (presença / passos no salão)
static func _generate_customer_arrive() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.18
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)

		var bell = sin(2.0 * PI * 1650.0 * t) * exp(-progress * 22.0) * 0.25
		var step = sin(2.0 * PI * 140.0 * t) * exp(-progress * 30.0) * 0.35

		var sample = clampf(bell + step, -1.0, 1.0) * 0.4
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 33. Vocalizações orgânicas e acolhedoras de clientes chamando o atendente
static func _generate_customer_call(type_idx: int) -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.28
	match type_idx:
		0: duration = 0.24 # "Ei!"
		1: duration = 0.32 # "Olá!"
		2: duration = 0.22 # Assovio curto de mesa
		3: duration = 0.26 # "Com licença / Hum-hum"

	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)
		var sample = 0.0

		match type_idx:
			0: # "Ei!" - Chamado humano amigável, vocalizado e natural
				var env = sin(progress * PI) * exp(-progress * 2.2)
				var pitch = 215.0 - progress * 40.0
				var glottal = (fmod(t * pitch, 1.0) - 0.5) * 2.0
				var f1 = sin(2.0 * PI * 520.0 * t) * 0.55
				var f2 = sin(2.0 * PI * 1850.0 * t) * 0.35
				var f3 = sin(2.0 * PI * 2600.0 * t) * 0.18
				sample = (glottal * 0.35 + f1 + f2 + f3) * env * 0.85

			1: # "Olá!" - Vocalização melódica de 2 tons com inflexão ascendente
				var env = sin(progress * PI)
				var is_second = (progress > 0.40)
				var pitch = 265.0 if is_second else 205.0
				var f1_freq = 680.0 if is_second else 460.0
				var f2_freq = 1420.0 if is_second else 880.0
				var f3_freq = 2450.0 if is_second else 2200.0
				var glottal = (fmod(t * pitch, 1.0) - 0.5) * 2.0
				var f1 = sin(2.0 * PI * f1_freq * t) * 0.50
				var f2 = sin(2.0 * PI * f2_freq * t) * 0.32
				var f3 = sin(2.0 * PI * f3_freq * t) * 0.16
				sample = (glottal * 0.30 + f1 + f2 + f3) * env * 0.82

			2: # Assovio cortês e alegre de mesa (dois trinados suaves)
				var whistle_env = sin(progress * PI) * (0.85 + 0.15 * sin(progress * TAU * 3.0))
				var w_freq = 1850.0 + sin(progress * PI * 2.0) * 240.0
				var flute = sin(2.0 * PI * w_freq * t)
				var harmonics = sin(2.0 * PI * w_freq * 2.0 * t) * 0.15
				var breath = randf_range(-0.04, 0.04)
				sample = (flute * 0.70 + harmonics + breath) * whistle_env * 0.75

			3: # "Com licença / Hum-hum" - Chamada educada em 2 toques vocais
				var sub_prog = fmod(progress * 2.0, 1.0)
				var env = sin(sub_prog * PI) * exp(-sub_prog * 2.5)
				var p_base = 185.0 if progress < 0.5 else 225.0
				var glottal = (fmod(t * p_base, 1.0) - 0.5) * 2.0
				var f1 = sin(2.0 * PI * 450.0 * t) * 0.50
				var f2 = sin(2.0 * PI * 1250.0 * t) * 0.28
				sample = (glottal * 0.35 + f1 + f2) * env * 0.80

		var s16 = int(clampf(sample, -1.0, 1.0) * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 34. Feedback de atendimento iniciado
static func _generate_customer_attend() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.20
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)
		var env = sin(progress * PI)
		var f0 = sin(2.0 * PI * 240.0 * t) * 0.35
		var f1 = sin(2.0 * PI * 580.0 * t) * 0.25
		var sample = (f0 + f1) * env * 0.26
		var s16 = int(clampf(sample, -1.0, 1.0) * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 35. Agradecimento / satisfação ao receber o pedido
static func _generate_customer_thank() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.30
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)
		var env = sin(progress * PI)
		var pitch = 180.0 + sin(progress * PI) * 25.0
		var f0 = sin(2.0 * PI * pitch * t) * 0.40
		var f1 = sin(2.0 * PI * 360.0 * t) * 0.25
		var sample = (f0 + f1) * env * 0.25
		var s16 = int(clampf(sample, -1.0, 1.0) * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 36. Cliente saindo do restaurante
static func _generate_customer_leave() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 0.22
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var progress = float(i) / float(num_samples)
		var env = sin(progress * PI) * exp(-progress * 2.5)
		var scrape = randf_range(-0.12, 0.12) * env * 0.25
		var s16 = int(clampf(scrape, -1.0, 1.0) * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	return stream

# 37. Trilha sonora ambiente suave e relaxante da lanchonete (Lo-Fi / Diner Lounge Loop)
static func _generate_diner_bg_music() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 8.0 # 4 acordes de 2.0s cada em loop suave
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	# Frequências dos acordes: Fmaj7, Em7, Dm7, Cmaj7
	var chords = [
		[174.61, 220.00, 261.63, 329.63, 87.31], # Fmaj7 + baixo F
		[164.81, 196.00, 246.94, 293.66, 82.41], # Em7 + baixo E
		[146.83, 174.61, 220.00, 261.63, 73.42], # Dm7 + baixo D
		[130.81, 164.81, 196.00, 246.94, 65.41]  # Cmaj7 + baixo C
	]

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var chord_idx = int(t / 2.0) % 4
		var chord_t = fmod(t, 2.0)
		var current_chord = chords[chord_idx]

		# Rhodes / Piano elétrico suave com decaimento aveludado
		var chord_env = exp(-chord_t * 1.6) * 0.28 + 0.08 * (1.0 - chord_t * 0.4)
		var rhodes = 0.0
		for f in range(4):
			var freq = current_chord[f]
			rhodes += sin(2.0 * PI * freq * t) * 0.22
			rhodes += sin(2.0 * PI * (freq * 2.0) * t) * 0.06 # Harmônico sutil

		# Baixo acústico suave
		var bass_freq = current_chord[4]
		var bass = sin(2.0 * PI * bass_freq * t) * exp(-chord_t * 1.2) * 0.35

		# Escovinha rítmica discreta no contratempo (Hi-hat brush)
		var beat_t = fmod(t, 0.5)
		var brush = randf_range(-0.04, 0.04) * exp(-beat_t * 16.0)

		var sample = clampf((rhodes * chord_env + bass + brush) * 0.75, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	return stream

# 38. Som ambiente suave do armazém (Warehouse room tone)
static func _generate_warehouse_ambience() -> AudioStreamWAV:
	var sample_rate = 22050
	var duration = 2.5
	var num_samples = int(sample_rate * duration)
	var pcm = PackedByteArray()
	pcm.resize(num_samples * 2)

	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		# Sub-grave abafado de espaço fechado + leve ar estático
		var room_sub = sin(2.0 * PI * 42.0 * t) * 0.12
		var room_air = randf_range(-0.02, 0.02)
		var sample = clampf((room_sub + room_air) * 0.30, -1.0, 1.0)
		var s16 = int(sample * 32767.0)
		pcm.encode_s16(i * 2, s16)

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = num_samples
	return stream

static func _generate_generic_click() -> AudioStreamWAV:
	return _generate_switch_click(true)





