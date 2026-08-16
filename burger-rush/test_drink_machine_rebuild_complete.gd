extends SceneTree

const SyrupCanister = preload("res://src/items/syrup_canister.gd")
const DrinkCup = preload("res://src/items/drink_cup.gd")
const DrinkMachine = preload("res://src/stations/drink_machine.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DA REFORMA COMPLETA DA MÁQUINA DE BEBIDAS")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()
	inv.items["cup_empty"]["quantity"] = 50
	inv.items["cup_lid"]["quantity"] = 50

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var world = Node3D.new()
	root.add_child(world)

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	world.add_child(player)
	player.global_position = Vector3(0.0, 0.0, 1.5)
	player._ready()

	var machine_scene = load("res://src/stations/drink_machine.tscn")
	assert(machine_scene != null, "Cena drink_machine.tscn deve existir")
	var machine = machine_scene.instantiate() as DrinkMachine
	world.add_child(machine)
	machine.global_position = Vector3(0.0, 0.0, 0.0)
	machine._ready()

	var cup_scene = load("res://src/items/drink_cup.tscn")

	# -------------------------------------------------------------
	# TESTE 1: MÁQUINA DESLIGADA -> TENTAR SERVIR -> NÃO FUNCIONA
	# -------------------------------------------------------------
	print("\n--- Teste 1: Máquina Desligada Bloqueia Operação ---")
	machine.is_powered = false
	machine._update_all_visuals()
	assert(not machine.is_powered, "Máquina deve estar desligada")

	var cup_test = cup_scene.instantiate() as DrinkCup
	world.add_child(cup_test)
	machine.place_cup_in_slot(0, cup_test, player)
	machine.toggle_lever(0, player)
	assert(not machine.is_lever_down[0], "Alavanca não deve acionar quando desligada")
	assert(cup_test.fill_amount == 0.0, "Copo não deve encher com máquina desligada")
	machine.take_cup_from_slot(0, player)
	player.take_held_item().queue_free()
	print("  [PASS] Máquina desligada bloqueia alavanca e fluxo com sucesso.")

	# -------------------------------------------------------------
	# TESTE 2: LIGAR MÁQUINA -> INDICADOR LED POWER MUDA
	# -------------------------------------------------------------
	print("\n--- Teste 2: Ligar Máquina e Indicador Power ---")
	machine.toggle_power(player)
	assert(machine.is_powered, "Máquina deve ligar com sucesso")
	assert(machine.power_led != null, "LED de Power presente na máquina")
	print("  [PASS] Botão Power ligou o sistema e ativou os circuitos eletrônicos.")

	# -------------------------------------------------------------
	# TESTE 3: ABRIR COMPARTIMENTO INFERIOR
	# -------------------------------------------------------------
	print("\n--- Teste 3: Abertura Articulada da Porta Inferior ---")
	assert(not machine.is_door_open, "Porta inicialmente fechada")
	machine.toggle_door(player)
	assert(machine.is_door_open, "Porta do compartimento aberta com sucesso")
	machine._process(0.5)
	assert(absf(machine.door_hinge.rotation.y) > 0.5, "Dobradiça da porta girou fisicamente para revelar interior")
	print("  [PASS] Porta articulada abriu suavemente revelando o interior mecânico.")

	# -------------------------------------------------------------
	# TESTE 4: VERIFICAR OS 4 RECIPIENTES DE INSUMO INSTALADOS
	# -------------------------------------------------------------
	print("\n--- Teste 4: Verificação dos 4 Recipientes/Galões nos Encaixes ---")
	for i in range(4):
		var can = machine.canisters[i]
		assert(can != null, "Recipiente %d presente no compartimento" % i)
		assert(can is SyrupCanister, "Recipiente deve ser do tipo SyrupCanister")
		assert(machine.syrup_levels[i] == 25.0, "Nível inicial de insumo deve ser 25 doses")
		print("  [PASS] Encaixe %d: %s (25 doses)" % [i + 1, can.display_name])

	# -------------------------------------------------------------
	# TESTE 5: RETIRAR UM RECIPIENTE -> RECONHECIMENTO DE AUSÊNCIA
	# -------------------------------------------------------------
	print("\n--- Teste 5: Retirada de um Galão de Insumo ---")
	var removed_can = machine.remove_canister(0, player)
	assert(removed_can != null, "Galão de Cola retirado com sucesso")
	assert(machine.canisters[0] == null, "Encaixe 0 agora está vazio")
	assert(machine.syrup_levels[0] == 0.0, "Nível de insumo da Cola zerado pela ausência do galão")
	assert(player.held_item == removed_can, "Jogador segurando o galão de insumo na mão")
	print("  [PASS] Galão de Cola retirado e nível da estação zerado automaticamente.")

	# -------------------------------------------------------------
	# TESTE 6: COLOCAR RECIPIENTE CHEIO -> NÍVEL RESTAURADO A 25
	# -------------------------------------------------------------
	print("\n--- Teste 6: Instalação e Reconhecimento de Novo Galão de Insumo ---")
	var held_can = player.take_held_item() as SyrupCanister
	held_can.refill()
	var ok_insert = machine.insert_canister(0, held_can, player)
	assert(ok_insert, "Galão reconectado com sucesso no encaixe de Cola")
	assert(machine.canisters[0] == held_can, "Galão instalado no slot 0")
	assert(machine.syrup_levels[0] == 25.0, "Nível de Cola restaurado para 25 doses")
	print("  [PASS] Galão reconhecido e nível do insumo restaurado para 25 doses.")

	# Teste de bloqueio de sabor incorreto
	var orange_can = SyrupCanister.new()
	orange_can.flavor_type = "juice_orange"
	machine.remove_canister(0, player)
	player.take_held_item() # libera mão
	var wrong_insert = machine.insert_canister(0, orange_can, player)
	assert(not wrong_insert, "Sistema deve rejeitar galão de Laranja no bocal de Cola")
	orange_can.queue_free()
	machine.insert_canister(0, held_can, player)
	print("  [PASS] Encaixe com trava anti-erro rejeitou galão de sabor incorreto.")

	# -------------------------------------------------------------
	# TESTE 7: FECHAR PORTA -> INTERIOR PROTEGIDO
	# -------------------------------------------------------------
	print("\n--- Teste 7: Fechamento da Porta Inferior ---")
	machine.toggle_door(player)
	assert(not machine.is_door_open, "Porta fechada com sucesso")
	machine._process(0.5)
	assert(machine.door_hinge.rotation.y < 0.1, "Dobradiça retornou à posição fechada")
	print("  [PASS] Porta fechada com o interior mecânico protegido.")

	# -------------------------------------------------------------
	# TESTES 8 A 12: PREPARO FÍSICO DOS 4 SABORES INDEPENDENTES
	# -------------------------------------------------------------
	print("\n--- Testes 8 a 12: Ciclo Físico de Enchimento dos 4 Sabores ---")
	var flavor_tests = [
		{"idx": 0, "name": "Cola", "id": "soda_cola"},
		{"idx": 1, "name": "Cola Zero", "id": "soda_cola_zero"},
		{"idx": 2, "name": "Soda", "id": "soda_lime"},
		{"idx": 3, "name": "Citrus", "id": "soda_citrus"}
	]

	for f in flavor_tests:
		var i = f["idx"]
		var c = cup_scene.instantiate() as DrinkCup
		world.add_child(c)
		c.set_state(DrinkCup.State.EMPTY)

		# 8. Colocar copo no slot do sabor
		var ok_place = machine.place_cup_in_slot(i, c, player)
		assert(ok_place, "Copo colocado no slot %d (%s)" % [i, f["name"]])
		assert(machine.current_cups[i] == c, "Copo registrado na estação %d" % i)

		# 9. Acionar alavanca
		machine.toggle_lever(i, player)
		assert(machine.is_lever_down[i], "Alavanca %s abaixada" % f["name"])
		var stream = machine.get_node_or_null("Model/Stream_%d" % i)
		assert(stream != null and stream.visible, "Jato líquido de %s visível" % f["name"])

		# 10. Copo começa a encher progressivamente
		machine._process(0.4)
		assert(c.fill_amount > 0.2 and c.fill_amount < 0.9, "Copo enchendo progressivamente")
		assert(machine.syrup_levels[i] < 25.0, "Insumo consumido durante o fluxo")

		# 11. Processa até atingir 100% -> fluxo interrompido automaticamente
		machine._process(1.2)
		assert(not machine.is_lever_down[i], "Alavanca sobe automaticamente ao atingir 100%")
		assert(not stream.visible, "Jato ocultado após copo cheio")
		assert(c.state == DrinkCup.State.FILLED, "Copo no estado FILLED")
		assert(c.flavor == f["id"], "Bebida identificada como %s" % f["id"])

		# Selar e retirar
		c.set_state(DrinkCup.State.CLOSED)
		var taken = machine.take_cup_from_slot(i, player)
		assert(taken == c, "Bebida pronta retirada com sucesso")
		player.take_held_item().queue_free()
		print("  [PASS] Estação %d (%s): Enchimento físico e selagem 100%% concluídos." % [i + 1, f["name"]])

	# -------------------------------------------------------------
	# TESTE 13: TESTAR MÁQUINA SEM COPO (NÃO DESPERDIÇAR BEBIDA)
	# -------------------------------------------------------------
	print("\n--- Teste 13: Proteção Contra Acionamento Sem Copo ---")
	var cola_prev_level = machine.syrup_levels[0]
	machine.toggle_lever(0, player) # tenta acionar alavanca sem copo
	assert(not machine.is_lever_down[0], "Alavanca não deve travar abaixada sem copo")
	assert(machine.syrup_levels[0] == cola_prev_level, "Nenhum insumo desperdiçado")
	print("  [PASS] Alavanca protegida contra acionamento acidental sem copo.")

	# -------------------------------------------------------------
	# TESTE 14: TESTAR SABOR SEM INSUMO (0%)
	# -------------------------------------------------------------
	print("\n--- Teste 14: Bloqueio de Estação Esgotada ---")
	machine.syrup_levels[2] = 0.0 # Zera Limão
	var c_lemon = cup_scene.instantiate() as DrinkCup
	world.add_child(c_lemon)
	c_lemon.set_state(DrinkCup.State.EMPTY)
	machine.place_cup_in_slot(2, c_lemon, player)
	machine.toggle_lever(2, player)
	assert(not machine.is_lever_down[2], "Alavanca de sabor esgotado bloqueada")
	assert(c_lemon.fill_amount == 0.0, "Nenhum líquido dispensado sem insumo")
	machine.take_cup_from_slot(2, player)
	player.take_held_item().queue_free()
	print("  [PASS] Estação com 0% de insumo bloqueada com sucesso.")

	# -------------------------------------------------------------
	# TESTE 15: TESTAR MÁQUINA DESLIGADA
	# -------------------------------------------------------------
	print("\n--- Teste 15: Máquina Desligada Impede Qualquer Fluxo ---")
	machine.toggle_power(player)
	assert(not machine.is_powered, "Máquina desligada")
	for i in range(4):
		assert(not machine.is_lever_down[i], "Todas as alavancas desligadas")
	print("  [PASS] Desligamento desativou completamente todas as estações.")

	# Limpeza
	machine.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS 15 TESTES OBRIGATÓRIOS DA MÁQUINA FORAM APROVADOS!")
	print("============================================================\n")
	quit(0)
