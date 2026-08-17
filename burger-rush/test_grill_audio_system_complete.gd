extends SceneTree

const Grill = preload("res://src/stations/grill.gd")
const Patty = preload("res://src/items/patty.gd")
const Bacon = preload("res://src/items/bacon.gd")
const Egg = preload("res://src/items/egg.gd")
const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE: SISTEMA DE ÁUDIO 3D DA CHAPA / GRELHA")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var world = Node3D.new()
	root.add_child(world)

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	world.add_child(player)
	player._ready()

	var grill_scene = load("res://src/stations/grill.tscn")
	var grill = grill_scene.instantiate() as Grill
	world.add_child(grill)
	grill._ready()

	# -------------------------------------------------------------
	# 1. TESTE: CHAPA DESLIGADA -> SEM SOM DE FUNCIONAMENTO
	# -------------------------------------------------------------
	print("\n--- 1. Chapa Desligada ---")
	assert(not grill.is_on, "Grelha inicia desligada")
	grill._process(0.1)
	assert(grill.hum_audio.volume_db <= -60.0 or not grill.hum_audio.playing, "Sem som de funcionamento com chapa desligada")
	assert(grill.sizzle_audio.volume_db <= -60.0 or not grill.sizzle_audio.playing, "Sem som de fritura")
	print("  [PASS] Chapa desligada permanece silenciosa.")

	# -------------------------------------------------------------
	# 2. TESTE: LIGAR CHAPA -> SOM DE ACIONAMENTO + HUM AMBIENTE
	# -------------------------------------------------------------
	print("\n--- 2. Ligar Chapa ---")
	grill.toggle_power(player)
	assert(grill.is_on, "Grelha ligada")
	assert(grill.oneshot_audio.stream == SoundSynthesizer.get_stream("grill_switch_on"), "Som de interruptor carregado")
	assert(grill.oneshot_audio.volume_db == -6.0, "Volume de acionamento configurado (-6 dB)")

	# Passa tempo de aquecimento
	grill._process(0.5)
	assert(grill.hum_audio.stream == SoundSynthesizer.get_stream("grill_hum_loop"), "Hum térmico ambiente ativo com stream loop")
	assert(grill.hum_audio.volume_db > -35.0, "Volume do hum ambiente perceptível e sutil (%.1f dB)" % grill.hum_audio.volume_db)
	print("  [PASS] Ligar chapa: clique de acionamento + hum térmico contínuo.")

	# -------------------------------------------------------------
	# 3. TESTE: AQUECER E CHEGAR À TEMPERATURA IDEAL -> READY CHIME
	# -------------------------------------------------------------
	print("\n--- 3. Aquecimento e Feedback de Temperatura Ideal ---")
	assert(not grill.is_ideal_temp(), "Chapa ainda aquecendo (< 160°C)")

	# Acelera simulação de aquecimento até atingir 165°C
	grill.current_temperature = 159.0
	grill._process(0.2) # cruza 160°C
	assert(grill.is_ideal_temp(), "Chapa atingiu temperatura ideal (> 160°C)")
	assert(grill._has_played_ready_chime, "Flag de feedback sonoro acionada")
	assert(grill.oneshot_audio.stream == SoundSynthesizer.get_stream("grill_ready_chime"), "Chime discreto de prontidão reproduzido")
	print("  [PASS] Feedback acústico discreto disparado ao atingir 160°C.")

	# -------------------------------------------------------------
	# 4. TESTE: COLOCAR HAMBÚRGUER -> SOM DE CONTATO + INÍCIO DE FRITURA
	# -------------------------------------------------------------
	print("\n--- 4. Colocar Hambúrguer e Iniciar Fritura ---")
	var patty_scene = load("res://src/items/patty.tscn")
	var patty1 = patty_scene.instantiate() as Patty
	world.add_child(patty1)
	grill.place_item(patty1)

	assert(grill.oneshot_audio.stream == SoundSynthesizer.get_stream("grill_place_patty"), "Som de impacto/contato com a chapa tocado")
	grill._process(0.6)
	assert(grill.sizzle_audio.stream == SoundSynthesizer.get_stream("grill_sizzle_loop"), "Som contínuo de fritura (sizzle loop) carregado")
	var vol_1_item = grill.sizzle_audio.volume_db
	assert(vol_1_item > -18.0, "Volume de fritura ativo e claro (%.1f dB)" % vol_1_item)
	assert(vol_1_item <= -12.0, "Volume de fritura moderado e equilibrado (%.1f dB)" % vol_1_item)
	print("  [PASS] Hambúrguer colocado: som de contato + chiado de fritura sincronizado.")

	# -------------------------------------------------------------
	# 5. TESTE: MÚLTIPLOS ALIMENTOS (BACON E OVO) -> ESCALA DINÂMICA
	# -------------------------------------------------------------
	print("\n--- 5. Múltiplos Alimentos (Bacon e Ovo) e Escalação de Volume ---")
	var bacon_scene = load("res://src/items/bacon.tscn")
	var bacon = bacon_scene.instantiate() as Bacon
	world.add_child(bacon)
	grill.place_item(bacon)
	assert(grill.oneshot_audio.stream == SoundSynthesizer.get_stream("grill_place_bacon"), "Som de contato do bacon tocado")

	var egg_scene = load("res://src/items/egg.tscn")
	var egg = egg_scene.instantiate() as Egg
	world.add_child(egg)
	grill.place_item(egg)
	assert(grill.oneshot_audio.stream == SoundSynthesizer.get_stream("grill_place_egg"), "Som de contato do ovo tocado")

	grill._process(0.5)
	var vol_3_items = grill.sizzle_audio.volume_db
	assert(vol_3_items > vol_1_item, "Volume aumentou naturalmente com 3 alimentos na chapa (%.1f > %.1f)" % [vol_3_items, vol_1_item])
	assert(grill.sizzle_audio.volume_db <= -4.0, "Volume não ultrapassa teto de equilíbrio seguro (-4 dB)")
	print("  [PASS] Bacon e Ovo: sons de contato específicos e aumento dinâmico do chiado.")

	# -------------------------------------------------------------
	# 6. TESTE: VIRAR HAMBÚRGUER COM A ESPÁTULA
	# -------------------------------------------------------------
	print("\n--- 6. Virar Hambúrguer com Espátula ---")
	player.active_tool_slot = 1 # Espátula
	patty1.state = Patty.State.READY_SIDE_1
	grill.interact_item(player)

	assert(patty1.is_flipped, "Hambúrguer virado")
	assert(grill.spatula_audio.stream == SoundSynthesizer.get_stream("grill_flip_spatula"), "Som característico de raspagem e tombo da carne reproduzido")
	assert(grill.spatula_audio.volume_db == -5.0, "Volume da espátula equilibrado (-5 dB)")

	# Fritura continua normalmente do outro lado
	grill._process(0.5)
	assert(grill.sizzle_audio.stream == SoundSynthesizer.get_stream("grill_sizzle_loop"), "Chiado de fritura continua ativo no lado 2")
	print("  [PASS] Virada com espátula: som metálico + tombo, fritura contínua.")

	# -------------------------------------------------------------
	# 7. TESTE: RETIRAR ALIMENTOS -> SOM DE RETIRADA + PARADA SUAVE DO CHIADO
	# -------------------------------------------------------------
	print("\n--- 7. Retirar Alimentos da Chapa ---")
	patty1.state = Patty.State.COOKED
	grill.interact_item(player) # Retira patty1
	assert(grill.spatula_audio.stream == SoundSynthesizer.get_stream("grill_remove_item"), "Som de deslize/retirada de hambúrguer tocado")

	player.take_held_item() # libera mão
	grill.interact_item(player) # Retira bacon
	player.take_held_item()
	grill.interact_item(player) # Retira ovo
	player.take_held_item()

	assert(grill.active_items.is_empty(), "Chapa totalmente vazia")
	grill._process(3.0) # tempo de fade-out do chiado
	assert(grill.sizzle_audio.volume_db <= -60.0 or not grill.sizzle_audio.playing, "Chiado de fritura cessou após retirar todos os alimentos")
	print("  [PASS] Retirada com espátula: som de deslize e encerramento do chiado.")

	# -------------------------------------------------------------
	# 8. TESTE: DESLIGAR CHAPA -> SOM DE DESLIGAMENTO E SILÊNCIO
	# -------------------------------------------------------------
	print("\n--- 8. Desligamento ---")
	grill.toggle_power(player)
	assert(not grill.is_on, "Grelha desligada")
	assert(grill.oneshot_audio.stream == SoundSynthesizer.get_stream("grill_switch_off"), "Som de clique de desligamento tocado")

	grill._process(3.0) # tempo de fade-out do hum
	assert(grill.hum_audio.volume_db <= -60.0 or not grill.hum_audio.playing, "Hum desligado completamente")
	print("  [PASS] Desligamento: clique sonoro e desligamento suave de todos os áudios.")

	# -------------------------------------------------------------
	# 9. TESTE: PROPRIEDADES ESPACIAIS 3D
	# -------------------------------------------------------------
	print("\n--- 9. Verificação dos Parâmetros Espaciais 3D ---")
	assert(grill.hum_audio.unit_size > 2.0, "Unit size espacial 3D configurado")
	assert(grill.hum_audio.max_distance >= 15.0, "Max distance espacial 3D configurado")
	assert(grill.sizzle_audio.unit_size > 2.0, "Sizzle player 3D configurado")
	print("  [PASS] Áudio 3D posicional com atenuação de distância validado.")

	# Limpeza
	patty1.queue_free()
	bacon.queue_free()
	egg.queue_free()
	grill.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DO SISTEMA DE ÁUDIO DA CHAPA FORAM APROVADOS!")
	print("============================================================\n")
	quit(0)
