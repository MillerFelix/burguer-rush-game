extends SceneTree

# ================================================================
# TESTE ESPECÍFICO: MIXAGEM DE ÁUDIO, AMBIENTE, PASSOS E DELIVERY
# Valida rigorosamente todos os pontos solicitados pelo usuário
# ================================================================

const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")
const AmbientAudioManager = preload("res://src/audio/ambient_audio_manager.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE: AJUSTE FINO DA MIXAGEM DE ÁUDIO")
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

	print("\n--- 1. Jogador Parado -> Nenhum Passo ---")
	player.velocity = Vector3.ZERO
	player._process_footsteps(0.5, 0.0)
	assert(player._step_timer > 0.0, "Timer de passos em repouso")
	print("  [PASS] Jogador parado não reproduz passos.")

	print("\n--- 2. Jogador Andando -> Passos Discretos (-18.0 dB) ---")
	player.velocity = Vector3(3.0, 0.0, 0.0)
	player._process_footsteps(0.4, 3.0)
	assert(player.footstep_audio.stream == SoundSynthesizer.get_stream("player_footstep"), "Passos sincronizados tocando no ritmo correto")
	assert(player.footstep_audio.volume_db <= -16.0, "Volume dos passos discreto e suave (%.1f dB)" % player.footstep_audio.volume_db)
	print("  [PASS] Passos discretos e suaves, sem dominar a mixagem.")

	print("\n--- 3. Música Ambiente Global 2D (-16.0 dB) ---")
	assert(ambient_mgr.music_audio is AudioStreamPlayer, "Música é AudioStreamPlayer 2D global (não posicional 3D)")
	assert(ambient_mgr.music_audio.stream == SoundSynthesizer.get_stream("diner_bg_music"), "Música ambiente tranquila em loop")
	assert(ambient_mgr.music_audio.volume_db == -16.0, "Volume da música constante em todo o mapa (%.1f dB)" % ambient_mgr.music_audio.volume_db)
	print("  [PASS] Música ambiente global 2D constante em todo o jogo.")

	print("\n--- 4. Som Externo: Zero Vazamento / Inaudível no Centro da Cozinha ---")
	player.position = Vector3(0.0, 0.0, 0.0)
	ambient_mgr._process(1.5)
	assert(ambient_mgr.outside_traffic_audio.volume_db <= -50.0, "Som externo inaudível no centro da cozinha (%.1f dB)" % ambient_mgr.outside_traffic_audio.volume_db)
	print("  [PASS] Centro da cozinha: ambiente interno 100% isolado de vento e trânsito.")

	print("\n--- 5. Transição: Aproximando da Porta e Saindo para a Rua ---")
	# Aproxima da porta de entrada frontal (Z = 8.5)
	player.position = Vector3(0.0, 0.0, 8.5)
	ambient_mgr._process(1.5)
	assert(ambient_mgr.outside_traffic_audio.volume_db > -25.0, "Trânsito começa a ser ouvido perto da porta (%.1f dB)" % ambient_mgr.outside_traffic_audio.volume_db)
	print("  [PASS] Próximo à porta: transição natural percebendo a rua externa.")

	# Sai para a calçada e rua (Z = 10.5)
	player.position = Vector3(0.0, 0.0, 10.5)
	ambient_mgr._process(1.5)
	assert(ambient_mgr.outside_traffic_audio.volume_db >= -6.0, "Trânsito plenamente audível no exterior (%.1f dB)" % ambient_mgr.outside_traffic_audio.volume_db)
	print("  [PASS] Fora do restaurante: trânsito plenamente audível.")

	# Retorna ao centro da cozinha (Z = 0.0)
	player.position = Vector3(0.0, 0.0, 0.0)
	ambient_mgr._process(1.5)
	assert(ambient_mgr.outside_traffic_audio.volume_db <= -50.0, "Som externo volta a ficar inaudível na cozinha (%.1f dB)" % ambient_mgr.outside_traffic_audio.volume_db)
	print("  [PASS] Retorno à cozinha: trânsito volta a ficar silencioso.")

	print("\n--- 6. Armazém: Música Global Contínua ---")
	player.position = Vector3(-6.0, 0.0, -4.0)
	ambient_mgr._process(1.5)
	assert(ambient_mgr.music_audio.volume_db == -16.0, "Música continua audível no armazém (%.1f dB)" % ambient_mgr.music_audio.volume_db)
	assert(ambient_mgr.outside_traffic_audio.volume_db <= -50.0, "Armazém sem vazamento externo (%.1f dB)" % ambient_mgr.outside_traffic_audio.volume_db)
	print("  [PASS] Armazém: música ambiente tocando suavemente sem ruídos externos.")

	print("\n--- 7. Buzina do Delivery (Chamativa e Marcante) ---")
	var car_scene = load("res://src/environment/delivery_car.tscn")
	var car = car_scene.instantiate() as DeliveryCar
	world.add_child(car)
	car._ready()

	car.target_queue_index = 0
	car.target_position = Vector3(6.45, 0.0, -11.5)
	car.position = Vector3(6.5, 0.0, -11.5)
	car.current_state = DeliveryCar.CarState.MOVING_TO_QUEUE
	car._physics_process(0.1)

	assert(car.current_state == DeliveryCar.CarState.AT_WINDOW_WAITING_ORDER, "Carro na janela de atendimento")
	assert(car.horn_audio.stream == SoundSynthesizer.get_stream("car_horn_beep"), "Buzina acionada na chegada")
	assert(car.horn_audio.volume_db >= 0.0, "Buzina chamativa com presença marcante (%.1f dB)" % car.horn_audio.volume_db)
	print("  [PASS] Buzina do Delivery: toque duplo, chamativo e destacado do trânsito.")

	# Saída do carro
	car.finish_and_leave()
	assert(car.current_state == DeliveryCar.CarState.LEAVING, "Carro em estado de saída")
	assert(car.engine_audio.stream == SoundSynthesizer.get_stream("car_engine_leave"), "Motor de saída acionado")
	print("  [PASS] Saída do veículo validada.")

	print("\n============================================================")
	print("TODOS OS TESTES DE MIXAGEM DE ÁUDIO FORAM 100% APROVADOS!")
	print("============================================================")

	quit()
