extends SceneTree

# ================================================================
# TESTE COMPLETO: PASSOS, EXTERIOR (CAMINHÃO/PORTA) E GELADEIRAS/FREEZERS
# Valida todos os 8 requisitos da nova etapa de áudio
# ================================================================

const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")
const AmbientAudioManager = preload("res://src/audio/ambient_audio_manager.gd")
const CommercialChestFreezer = preload("res://src/stations/commercial_chest_freezer.gd")
const MeatRefrigerator = preload("res://src/stations/commercial_refrigerator.gd")
const IngredientRefrigerator = preload("res://src/stations/ingredient_refrigerator.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE: PASSOS, EXTERIOR E GELADEIRAS/FREEZERS")
	print("============================================================")

	var world = Node3D.new()
	world.name = "TestWorld"
	root.add_child(world)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	world.add_child(player)
	player._ready()

	var ambient_mgr = AmbientAudioManager.new()
	world.add_child(ambient_mgr)
	ambient_mgr._ready()
	ambient_mgr.player_ref = player

	print("\n--- 1. PASSOS DO JOGADOR (Calibrados a -11.0 dB) ---")
	player.velocity = Vector3.ZERO
	player._process_footsteps(0.5, 0.0)
	assert(player._step_timer > 0.0, "Jogador parado não emite passos")

	player.velocity = Vector3(3.0, 0.0, 0.0)
	player._process_footsteps(0.4, 3.0)
	assert(player.footstep_audio.stream == SoundSynthesizer.get_stream("player_footstep"), "Stream de passos correto")
	assert(player.footstep_audio.volume_db >= -12.0 and player.footstep_audio.volume_db <= -10.0, "Passos com volume perceptível e equilibrado (%.1f dB)" % player.footstep_audio.volume_db)
	print("  [PASS] Passos audíveis, sincronizados e com presença natural.")

	print("\n--- 2. PORTA PRINCIPAL E TRANSIÇÃO EXTERNA ---")
	# Centro da cozinha
	player.position = Vector3(0.0, 0.0, 0.0)
	ambient_mgr._process(1.5)
	assert(ambient_mgr.outside_traffic_audio.volume_db <= -50.0, "Centro da cozinha: som externo inaudível (%.1f dB)" % ambient_mgr.outside_traffic_audio.volume_db)
	print("  [PASS] Centro da cozinha: 100% livre de ruído externo.")

	# Aproximando da porta
	player.position = Vector3(0.0, 0.0, 8.5)
	ambient_mgr._process(1.5)
	assert(ambient_mgr.outside_traffic_audio.volume_db > -25.0, "Perto da porta: trânsito começa a ser ouvido (%.1f dB)" % ambient_mgr.outside_traffic_audio.volume_db)
	print("  [PASS] Perto da porta: exterior levemente perceptível.")

	# Rua exterior
	player.position = Vector3(0.0, 0.0, 10.5)
	ambient_mgr._process(1.5)
	assert(ambient_mgr.outside_traffic_audio.volume_db >= -6.0, "Fora do restaurante: exterior claramente audível (%.1f dB)" % ambient_mgr.outside_traffic_audio.volume_db)
	print("  [PASS] Área externa da rua: plenamente audível.")

	print("\n--- 3. ÁREA EXTERNA DO CAMINHÃO / ARMAZÉM ---")
	# Dentro do armazém
	player.position = Vector3(-6.5, 0.0, -4.0)
	ambient_mgr._process(1.5)
	assert(ambient_mgr.outside_traffic_audio.volume_db <= -30.0, "Dentro do armazém: som externo abafado (%.1f dB)" % ambient_mgr.outside_traffic_audio.volume_db)
	print("  [PASS] Armazém: som externo abafado.")

	# Saindo para a área do caminhão (Alley X = -14.0)
	player.position = Vector3(-14.0, 0.0, -4.5)
	ambient_mgr._process(1.5)
	assert(ambient_mgr.outside_traffic_audio.volume_db >= -10.0, "Área externa do caminhão: ambiente externo audível (%.1f dB)" % ambient_mgr.outside_traffic_audio.volume_db)
	print("  [PASS] Área do caminhão: atmosfera externa audível.")

	print("\n--- 4. MÚSICA AMBIENTE GLOBAL 2D ---")
	assert(ambient_mgr.music_audio.volume_db == -16.0, "Música constante em qualquer ponto do mapa")
	print("  [PASS] Música ambiente 2D global tocando continuamente.")

	print("\n--- 5. FREEZER HORIZONTAL DE QUEIJOS ---")
	var freezer = CommercialChestFreezer.new()
	world.add_child(freezer)
	freezer._ready()
	assert(freezer.hum_audio != null and freezer.hum_audio.stream == SoundSynthesizer.get_stream("freezer_hum_loop"), "Hum de refrigeração ativo com stream correto")
	assert(freezer._target_hum_vol <= -25.0, "Freezer fechado: hum discreto e abafado (%.1f dB)" % freezer._target_hum_vol)

	# Abrir freezer
	freezer.open_freezer()
	assert(freezer.door_audio.stream == SoundSynthesizer.get_stream("freezer_lid_open"), "Som de abertura da tampa")
	assert(freezer._target_hum_vol >= -18.0, "Freezer aberto: refrigeração mais perceptível (%.1f dB)" % freezer._target_hum_vol)

	# Simula conclusão da animação e testa fechamento
	freezer.is_animating = false
	freezer.current_state = CommercialChestFreezer.State.OPEN
	freezer.close_freezer()
	assert(freezer.door_audio.stream == SoundSynthesizer.get_stream("freezer_lid_close"), "Som de fechamento da tampa")
	assert(freezer._target_hum_vol <= -25.0, "Freezer fechado: refrigeração volta a ficar abafada (%.1f dB)" % freezer._target_hum_vol)
	print("  [PASS] Freezer de queijos: abertura, fechamento e dinâmica de refrigeração aprovados.")

	print("\n--- 6. GELADEIRA COMERCIAL DE CARNES ---")
	var meat_fridge = MeatRefrigerator.new()
	world.add_child(meat_fridge)
	meat_fridge._ready()
	assert(meat_fridge.hum_audio != null and meat_fridge.hum_audio.stream == SoundSynthesizer.get_stream("fridge_hum_loop"), "Hum da geladeira ativo com stream correto")
	assert(meat_fridge._target_hum_vol <= -25.0, "Geladeira fechada: hum abafado (%.1f dB)" % meat_fridge._target_hum_vol)

	# Abrir geladeira
	meat_fridge.open_door()
	assert(meat_fridge.door_audio.stream == SoundSynthesizer.get_stream("fridge_door_open"), "Som de vedação da porta abrindo")
	assert(meat_fridge._target_hum_vol >= -18.0, "Geladeira aberta: refrigeração perceptível (%.1f dB)" % meat_fridge._target_hum_vol)

	# Simula conclusão e fecha
	meat_fridge.is_animating = false
	meat_fridge.is_open = true
	meat_fridge.close_door()
	assert(meat_fridge.door_audio.stream == SoundSynthesizer.get_stream("fridge_door_close"), "Som de fecho magnético fechando")
	assert(meat_fridge._target_hum_vol <= -25.0, "Geladeira fechada: refrigeração volta a ficar abafada (%.1f dB)" % meat_fridge._target_hum_vol)
	print("  [PASS] Geladeira de carnes: abertura, fechamento e refrigeração aprovados.")

	print("\n--- 7. GELADEIRA DE HORTIFRÚTI & BATATAS ---")
	var ing_fridge = IngredientRefrigerator.new()
	world.add_child(ing_fridge)
	ing_fridge._ready()
	assert(ing_fridge.hum_audio != null and ing_fridge.hum_audio.stream == SoundSynthesizer.get_stream("fridge_hum_loop"), "Hum da geladeira ativo com stream correto")

	ing_fridge.open_door()
	assert(ing_fridge.door_audio.stream == SoundSynthesizer.get_stream("fridge_door_open"), "Som de porta de geladeira abrindo")
	assert(ing_fridge._target_hum_vol >= -18.0, "Geladeira aberta: compressor audível")

	ing_fridge.is_animating = false
	ing_fridge.is_open = true
	ing_fridge.close_door()
	assert(ing_fridge.door_audio.stream == SoundSynthesizer.get_stream("fridge_door_close"), "Som de porta de geladeira fechando")
	assert(ing_fridge._target_hum_vol <= -25.0, "Geladeira fechada: compressor abafado")
	print("  [PASS] Geladeira de hortifrúti: abertura, fechamento e refrigeração aprovados.")

	print("\n============================================================")
	print("TODOS OS TESTES DE PASSOS, EXTERIOR E GELADEIRAS/FREEZERS APROVADOS!")
	print("============================================================")

	quit()
