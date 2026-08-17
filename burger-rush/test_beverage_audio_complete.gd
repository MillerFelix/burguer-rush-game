extends SceneTree

const DrinkMachine = preload("res://src/stations/drink_machine.gd")
const JuiceMachine = preload("res://src/stations/juice_machine.gd")
const DrinkCup = preload("res://src/items/drink_cup.gd")
const JuicePulp = preload("res://src/items/juice_pulp.gd")
const SyrupCanister = preload("res://src/items/syrup_canister.gd")
const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE COMPLETO: ÁUDIO DAS MÁQUINAS DE BEBIDAS")
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

	var soda_scene = load("res://src/stations/drink_machine.tscn")
	var soda = soda_scene.instantiate() as DrinkMachine
	world.add_child(soda)
	soda._ready()

	var juice_scene = load("res://src/stations/juice_machine.tscn")
	var juice = juice_scene.instantiate() as JuiceMachine
	world.add_child(juice)
	juice._ready()

	# =============================================================
	# PARTE 1: MÁQUINA DE REFRIGERANTES (4 SABORES)
	# =============================================================
	print("\n--- 1. Soda: Ligar/Desligar e Refrigeração ---")
	assert(soda.is_powered, "Máquina inicia ligada")
	soda._process(0.6)
	assert(soda.hum_audio.stream == SoundSynthesizer.get_stream("soda_fridge_loop"), "Compressor/refrigeração em loop carregado")
	assert(soda.hum_audio.volume_db > -35.0, "Volume de refrigeração perceptível (%.1f dB)" % soda.hum_audio.volume_db)

	# Desliga
	soda.toggle_power(player)
	assert(not soda.is_powered, "Máquina desligada")
	assert(soda.oneshot_audio.stream == SoundSynthesizer.get_stream("soda_switch_off"), "Som de desligamento tocado")
	soda._process(2.0)
	assert(soda.hum_audio.volume_db <= -60.0 or not soda.hum_audio.playing, "Compressor desligado")

	# Religa
	soda.toggle_power(player)
	assert(soda.is_powered, "Máquina religada")
	assert(soda.oneshot_audio.stream == SoundSynthesizer.get_stream("soda_switch_on"), "Som de acionamento tocado")
	print("  [PASS] Ligar, desligar e som sutil de refrigeração validados.")

	print("\n--- 2. Soda: Portas e Dobradiças ---")
	# Porta esquerda
	soda.toggle_left_door(player)
	assert(soda.is_left_door_open, "Porta esquerda aberta")
	assert(soda.oneshot_audio.stream == SoundSynthesizer.get_stream("soda_door_open"), "Som de dobradiça abrindo")
	soda.toggle_left_door(player)
	assert(not soda.is_left_door_open, "Porta esquerda fechada")
	assert(soda.oneshot_audio.stream == SoundSynthesizer.get_stream("soda_door_close"), "Som de porta metálica fechando com trava")

	# Porta direita
	soda.toggle_right_door(player)
	assert(soda.is_right_door_open, "Porta direita aberta")
	assert(soda.oneshot_audio.stream == SoundSynthesizer.get_stream("soda_door_open"), "Som de dobradiça direita")
	soda.toggle_right_door(player)
	assert(not soda.is_right_door_open, "Porta direita fechada")
	assert(soda.oneshot_audio.stream == SoundSynthesizer.get_stream("soda_door_close"), "Som de fechamento porta direita")
	print("  [PASS] Sons de abrir e fechar portas metálicas independentes.")

	print("\n--- 3. Soda: Manuseio de Barris/Galões de Xarope ---")
	var removed_can = soda.remove_canister(0, player)
	assert(removed_can != null, "Canister de Cola retirado")
	assert(soda.oneshot_audio.stream == SoundSynthesizer.get_stream("soda_canister_remove"), "Som de desengate/remoção do galão")

	var reinserted = soda.insert_canister(0, removed_can, player)
	assert(reinserted, "Canister de Cola reconectado")
	assert(soda.oneshot_audio.stream == SoundSynthesizer.get_stream("soda_canister_insert"), "Som de encaixe e conexão do galão")
	print("  [PASS] Sons de remoção e encaixe de galões validados.")

	print("\n--- 4. Soda: Colocar Copo, Alavanca e Fluxo da Bebida ---")
	var cup_scene = load("res://src/items/drink_cup.tscn")
	var cup0 = cup_scene.instantiate() as DrinkCup
	world.add_child(cup0)
	soda.place_cup_in_slot(0, cup0, player)
	assert(soda.oneshot_audio.stream == SoundSynthesizer.get_stream("soda_cup_place"), "Som de copo plástico colocado na bandeja")

	# Aciona alavanca
	soda.toggle_lever(0, player)
	assert(soda.is_lever_down[0], "Alavanca de Cola abaixada")
	assert(soda.oneshot_audio.stream == SoundSynthesizer.get_stream("soda_lever_pull"), "Som de clique mecânico da alavanca ao puxar")

	soda._process(0.4)
	assert(soda.dispense_audio.stream == SoundSynthesizer.get_stream("soda_dispense_loop"), "Fluxo contínuo de refrigerante e gás em loop")
	assert(soda.dispense_audio.volume_db > -22.0, "Volume de fluxo ativo e suave (%.1f dB)" % soda.dispense_audio.volume_db)

	# Completa o enchimento do copo
	soda._process(1.0)
	assert(cup0.state == DrinkCup.State.FILLED, "Copo de refrigerante 100% cheio")
	assert(not soda.is_lever_down[0], "Alavanca retornou automaticamente após encher")
	assert(soda.oneshot_audio.stream == SoundSynthesizer.get_stream("soda_lever_release"), "Som mecânico de retorno da alavanca")

	# Retira o copo cheio
	var taken_cup = soda.take_cup_from_slot(0, player)
	assert(taken_cup == cup0, "Copo cheio retirado")
	assert(soda.oneshot_audio.stream == SoundSynthesizer.get_stream("soda_cup_remove"), "Som de copo retirado")
	player.take_held_item().queue_free()
	print("  [PASS] Ciclo completo de áudio do refrigerante: copo, alavanca, fluxo e retirada.")

	# =============================================================
	# PARTE 2: MÁQUINA DE SUCOS (3 SABORES)
	# =============================================================
	print("\n--- 5. Sucos: Ligar/Desligar e Funcionamento ---")
	assert(juice.is_powered, "Máquina de sucos inicia ligada")
	juice._process(0.6)
	assert(juice.hum_audio.stream == SoundSynthesizer.get_stream("juice_hum_loop"), "Hum ambiente de funcionamento carregado")
	assert(juice.hum_audio.volume_db > -35.0, "Volume de funcionamento perceptível (%.1f dB)" % juice.hum_audio.volume_db)

	# Desliga
	juice.toggle_power(player)
	assert(not juice.is_powered, "Máquina de sucos desligada")
	assert(juice.oneshot_audio.stream == SoundSynthesizer.get_stream("juice_switch_off"), "Som de desligamento tocado")

	# Religa
	juice.toggle_power(player)
	assert(juice.is_powered, "Máquina de sucos religada")
	assert(juice.oneshot_audio.stream == SoundSynthesizer.get_stream("juice_switch_on"), "Som de acionamento tocado")
	print("  [PASS] Liga/desliga e zumbido suave da máquina de sucos validados.")

	print("\n--- 6. Sucos: Gavetas e Rejeição/Inserção de Polpas ---")
	# Abrir gaveta 0 (Laranja)
	juice.toggle_drawer(0, player)
	assert(juice.is_drawer_open[0], "Gaveta de laranja aberta")
	assert(juice.oneshot_audio.stream == SoundSynthesizer.get_stream("juice_drawer_open"), "Som de gaveta acrílica abrindo")

	# Tentar colocar polpa errada (Uva na gaveta de Laranja) -> Rejeição
	var pulp_grape = load("res://src/items/juice_pulp.tscn").instantiate() as JuicePulp
	pulp_grape.fruit_type = "uva"
	pulp_grape.item_id = "pulp_grape"
	world.add_child(pulp_grape)
	var inserted_wrong = juice.insert_pulp_in_drawer(0, pulp_grape, player)
	assert(not inserted_wrong, "Polpa incompatível rejeitada")
	assert(juice.oneshot_audio.stream == SoundSynthesizer.get_stream("juice_pulp_reject"), "Som/bipe de rejeição reproduzido")
	pulp_grape.queue_free()

	# Colocar polpa correta (Laranja)
	var pulp_orange = load("res://src/items/juice_pulp.tscn").instantiate() as JuicePulp
	pulp_orange.fruit_type = "laranja"
	pulp_orange.item_id = "pulp_orange"
	world.add_child(pulp_orange)
	var inserted_ok = juice.insert_pulp_in_drawer(0, pulp_orange, player)
	assert(inserted_ok, "Polpa correta de laranja aceita")
	assert(juice.oneshot_audio.stream == SoundSynthesizer.get_stream("juice_pulp_place"), "Som de colocação da pedra de polpa")

	# Fechar gaveta -> Inicia processamento
	juice.toggle_drawer(0, player)
	assert(not juice.is_drawer_open[0], "Gaveta de laranja fechada")
	assert(juice.oneshot_audio.stream == SoundSynthesizer.get_stream("juice_drawer_close"), "Som de fechamento da gaveta")
	assert(juice.is_processing[0], "Iniciou moagem e extração da polpa")

	# Processa
	juice._process(0.5)
	assert(juice.process_audio.stream == SoundSynthesizer.get_stream("juice_process_loop"), "Motor de moagem/extração da polpa ativo")
	assert(juice.process_audio.volume_db > -22.0, "Volume de moagem suave ativo (%.1f dB)" % juice.process_audio.volume_db)

	# Conclui moagem e inicia subida do líquido
	juice._process(2.0)
	assert(not juice.is_processing[0], "Processamento de polpa finalizado")
	assert(juice.target_juice_doses[0] == 5.0, "Reservatório abastecido com 5 doses")
	assert(juice.oneshot_audio.stream == SoundSynthesizer.get_stream("juice_fill_reservoir"), "Som de abastecimento do reservatório acrílico")
	print("  [PASS] Gavetas, validação estrita, moagem de polpa e abastecimento com áudio perfeito.")

	print("\n--- 7. Sucos: Servir Suco no Copo ---")
	var cup_juice = cup_scene.instantiate() as DrinkCup
	world.add_child(cup_juice)
	juice.place_cup_in_slot(0, cup_juice, player)
	assert(juice.oneshot_audio.stream == SoundSynthesizer.get_stream("soda_cup_place"), "Som de copo posicionado sob a torneira")

	# Aciona torneira
	juice.toggle_lever(0, player)
	assert(juice.is_lever_down[0], "Torneira de suco de laranja acionada")
	assert(juice.oneshot_audio.stream == SoundSynthesizer.get_stream("soda_lever_pull"), "Som mecânico da torneira")

	juice._process(0.4)
	assert(juice.dispense_audio.stream == SoundSynthesizer.get_stream("juice_dispense_loop"), "Fluxo contínuo de suco em loop")
	assert(juice.dispense_audio.volume_db > -22.0, "Volume de fluxo de suco suave audível (%.1f dB)" % juice.dispense_audio.volume_db)

	# Completa o enchimento
	juice._process(1.0)
	assert(cup_juice.state == DrinkCup.State.FILLED, "Copo de suco 100% cheio")
	assert(not juice.is_lever_down[0], "Torneira fechou após completar copo")

	# Retira o copo de suco
	var taken_juice = juice.take_cup_from_slot(0, player)
	assert(taken_juice == cup_juice, "Copo de suco retirado")
	assert(juice.oneshot_audio.stream == SoundSynthesizer.get_stream("soda_cup_remove"), "Som de retirada do copo")
	player.take_held_item().queue_free()
	print("  [PASS] Servir suco: torneira, cascata de suco e retirada com sons calibrados.")

	# =============================================================
	# PARTE 3: PROPRIEDADES 3D ESPACIAIS
	# =============================================================
	print("\n--- 8. Verificação Espacial 3D ---")
	assert(soda.hum_audio.unit_size >= 2.5 and soda.hum_audio.max_distance >= 15.0, "Soda 3D validado")
	assert(juice.hum_audio.unit_size >= 2.5 and juice.hum_audio.max_distance >= 15.0, "Juice 3D validado")
	print("  [PASS] Áudio 3D posicional com atenuação de distância aprovado em ambas as máquinas.")

	# Limpeza
	juice.queue_free()
	soda.queue_free()
	player.queue_free()
	world.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE ÁUDIO DAS BEBIDAS E SUCOS FORAM APROVADOS!")
	print("============================================================\n")
	quit(0)
