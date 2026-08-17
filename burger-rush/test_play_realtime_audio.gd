extends SceneTree

# ================================================================
# TESTE DE EXECUÇÃO EM TEMPO REAL DE ÁUDIO NO MAIN.TSCN
# Carrega a cena principal completa do jogo e valida áudio em execução
# ================================================================

const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - EXECUÇÃO EM TEMPO REAL: ÁUDIO NO MAIN.TSCN")
	print("============================================================")

	var main_scene = load("res://src/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)

	# 1. Verifica AudioListener3D ativo no Player
	var player = main.find_child("Player", true, false) as Player
	assert(player != null, "Player presente na cena principal")

	var listener = player.find_child("AudioListener3D", true, false) as AudioListener3D
	assert(listener != null, "AudioListener3D presente no Head/Camera3D do Player")
	assert(listener.is_current(), "AudioListener3D está ativo e recebendo áudio espacial")
	print("  [PASS] AudioListener3D 100% ativo e posicionado nos ouvidos do jogador.")

	# 2. Verifica AmbientAudioManager ativo
	var ambient_mgr = main.find_child("AmbientAudioManager", true, false)
	print("  AmbientAudioManager node: ", ambient_mgr)
	if ambient_mgr:
		ambient_mgr._ready()
		print("  ambient_mgr.kitchen_audio: ", ambient_mgr.get("kitchen_audio"))
	assert(ambient_mgr != null, "AmbientAudioManager presente na cena")
	assert(ambient_mgr.kitchen_audio != null and ambient_mgr.kitchen_audio.stream != null, "Coifa da cozinha com stream ativo")
	assert(ambient_mgr.music_audio != null and ambient_mgr.music_audio.stream != null, "Música diner com stream ativo")
	assert(ambient_mgr.outside_traffic_audio != null and ambient_mgr.outside_traffic_audio.stream != null, "Trânsito externo com stream ativo")
	print("  [PASS] AmbientAudioManager ativo com fluxos de cozinha, música e exterior.")

	# 3. Simula passos ao andar
	player._ready()
	player.velocity = Vector3(3.5, 0.0, 0.0)
	player._process_footsteps(0.4, 3.5)
	assert(player.footstep_audio != null and player.footstep_audio.stream == SoundSynthesizer.get_stream("player_footstep"), "Passos reproduzidos com o movimento")
	print("  [PASS] Passos do jogador acionados com volume calibrado (%.1f dB)." % player.footstep_audio.volume_db)

	# 4. Spawna carro no delivery e valida buzina ao parar na janela
	var queue_mgr = main.find_child("DeliveryQueueManager", true, false) as DeliveryQueueManager
	assert(queue_mgr != null, "DeliveryQueueManager presente")

	var car = queue_mgr.car_scene.instantiate() as DeliveryCar
	main.add_child(car)
	car._ready()

	car.target_queue_index = 0
	car.target_position = Vector3(6.45, 0.0, -11.5)
	car.position = Vector3(6.48, 0.0, -11.5)
	car.current_state = DeliveryCar.CarState.MOVING_TO_QUEUE
	car._physics_process(0.1)

	assert(car.current_state == DeliveryCar.CarState.AT_WINDOW_WAITING_ORDER, "Carro chegou na janela")
	assert(car.horn_audio.stream == SoundSynthesizer.get_stream("car_horn_beep"), "Buzina acionada no ponto de atendimento")
	print("  [PASS] Buzina do Delivery confirmada (Volume %.1f dB, UnitSize %.1f, MaxDist %.1f)." % [
		car.horn_audio.volume_db,
		car.horn_audio.unit_size,
		car.horn_audio.max_distance
	])

	# 5. Saída do carro
	car.finish_and_leave()
	assert(car.engine_audio.stream == SoundSynthesizer.get_stream("car_engine_leave"), "Motor de saída acionado")
	print("  [PASS] Som de saída do delivery confirmado.")

	print("\n============================================================")
	print("VALIDAÇÃO EM TEMPO REAL DA CENA PRINCIPAL 100% APROVADA!")
	print("============================================================")

	quit()
