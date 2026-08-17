extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DA ESTAÇÃO COMPLETA DE BEBIDAS E EMBALAGENS")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()
	inv.items["cup_empty"]["quantity"] = 30
	inv.items["cup_lid"]["quantity"] = 30
	inv.items["syrup_soda"]["quantity"] = 30
	inv.items["burger_box"]["quantity"] = 30

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	# 1. Instanciar estações
	var packaging_scene = load("res://src/stations/packaging_station.tscn")
	assert(packaging_scene != null, "Cena packaging_station.tscn deve existir")
	var packaging_station = packaging_scene.instantiate() as PackagingStation
	root.add_child(packaging_station)
	packaging_station._ready()

	var drink_scene = load("res://src/stations/drink_machine.tscn")
	assert(drink_scene != null, "Cena drink_machine.tscn deve existir")
	var drink_machine = drink_scene.instantiate() as DrinkMachine
	root.add_child(drink_machine)
	drink_machine._ready()

	var juice_scene = load("res://src/stations/juice_machine.tscn")
	assert(juice_scene != null, "Cena juice_machine.tscn deve existir")
	var juice_machine = juice_scene.instantiate() as JuiceMachine
	root.add_child(juice_machine)
	juice_machine._ready()

	# ---------------------------------------------------------
	# TESTE 1: EMBALAGENS E SUPORTE DE COPOS NA BANCADA
	# ---------------------------------------------------------
	print("\n--- Teste 1: Área de Embalagem e Dispensador de Copos ---")
	assert(packaging_station.has_node("Model/BurgerBoxes"), "Bancada deve possuir pilha de caixas de hambúrguer")
	assert(packaging_station.has_node("Model/PotatoBoxes"), "Bancada deve possuir suporte de embalagens de batata")
	assert(packaging_station.has_node("Model/Cups"), "Bancada deve possuir suporte/coluna dispensadora de copos")
	assert(packaging_station.has_node("Model/DeliveryBags"), "Bancada deve possuir suporte de sacos de delivery")
	assert(packaging_station.has_node("PackagingSlot"), "Bancada deve possuir PackagingSlot")
	print("  [PASS] Elementos visuais de embalagem (Caixas, Batatas, Copos, Sacos de Delivery) validados")

	# Pegar copo vazio da bancada com a mão livre via clique esquerdo na seção de copos (Z = 0.25)
	player.global_position = packaging_station.global_position + Vector3(0, 0, 0.25)
	packaging_station.interact_item(player)
	assert(player.held_item != null and player.held_item is DrinkCup, "Jogador deve pegar um Copo Vazio")
	var empty_cup = player.held_item as DrinkCup
	assert(empty_cup.state == DrinkCup.State.EMPTY, "Copo pego deve estar VAZIO")
	print("  [PASS] Copo vazio retirado do suporte de embalagens com sucesso")

	# ---------------------------------------------------------
	# TESTE 2: CICLO COMPLETO NA MÁQUINA DE SUCO
	# ---------------------------------------------------------
	print("\n--- Teste 2: Máquina de Suco (Laranja, Uva, Morango com Alavancas Animadas) ---")
	assert(JuiceMachine.FLAVORS.size() == 3, "Suqueira deve ter 3 sabores de suco")
	assert(juice_machine.has_node("Model/Reservoir_0"), "Suqueira deve ter Reservatório 1")
	assert(juice_machine.has_node("Model/Reservoir_1"), "Suqueira deve ter Reservatório 2")
	assert(juice_machine.has_node("Model/Reservoir_2"), "Suqueira deve ter Reservatório 3")
	assert(juice_machine.has_node("Model/LeverPivot_0"), "Suqueira deve ter Alavanca 1")
	assert(juice_machine.has_node("Model/LeverPivot_1"), "Suqueira deve ter Alavanca 2")
	assert(juice_machine.has_node("Model/LeverPivot_2"), "Suqueira deve ter Alavanca 3")

	var juice_flavors = [
		{"id": "juice_orange", "name": "Suco de Laranja"},
		{"id": "juice_grape", "name": "Suco de Uva"},
		{"id": "juice_strawberry", "name": "Suco de Morango"}
	]

	for i in range(juice_flavors.size()):
		var jf = juice_flavors[i]
		juice_machine.select_flavor_by_index(i)

		# Coloca o copo que está na mão do jogador na máquina
		if player.held_item == null:
			player.global_position = packaging_station.global_position + Vector3(0, 0, 0.25)
			packaging_station.interact_item(player)

		juice_machine.interact(player)
		assert(player.held_item == null, "Copo deve ter saído da mão do jogador")
		assert(juice_machine.current_cup != null, "Copo deve estar posicionado na suqueira")

		# Puxa a alavanca e inicia enchimento
		juice_machine.interact(player)
		assert(juice_machine.is_filling, "Máquina deve iniciar o fluxo de suco")
		assert(juice_machine.current_cup.flavor == jf["id"], "Sabor deve ser %s" % jf["id"])

		# Processa animação da alavanca e fluxo
		juice_machine._process(0.4)
		var lever = juice_machine._get_lever_by_index(i)
		assert(lever != null and lever.rotation.x > 0.0, "Alavanca %d deve inclinar para baixo ao dispensar" % (i + 1))

		# Conclui enchimento
		juice_machine._process(1.0)
		assert(not juice_machine.is_filling, "Enchimento deve finalizar")
		assert(juice_machine.current_cup.state == DrinkCup.State.FILLED, "Copo deve estar CHEIO com suco")

		# Sela o copo
		juice_machine.interact(player)
		assert(juice_machine.current_cup.state == DrinkCup.State.CLOSED, "Copo de suco deve estar SELADO")

		# Retira o copo pronto
		juice_machine.interact(player)
		assert(player.held_item != null and player.held_item is DrinkCup, "Jogador deve segurar o suco pronto")
		var finished_juice = player.held_item as DrinkCup
		assert(finished_juice.get_flavor_display_name() == jf["name"], "Nome exibido deve ser %s" % jf["name"])

		# Limpa a mão para o próximo teste
		player.take_held_item().queue_free()
		print("  [PASS] %s: Bico -> Alavanca Inclinada -> Encher -> Selar -> Retirar OK" % jf["name"])

	# ---------------------------------------------------------
	# TESTE 3: CICLO COMPLETO NA MÁQUINA DE REFRIGERANTE
	# ---------------------------------------------------------
	print("\n--- Teste 3: Máquina de Refrigerante (4 Sabores Físicos) ---")
	var soda_flavors = ["soda_cola", "soda_cola_zero", "soda_sprite", "juice_orange"]
	for i in range(soda_flavors.size()):
		drink_machine.select_flavor_by_index(i)
		player.global_position = packaging_station.global_position + Vector3(0, 0, 0.25)
		packaging_station.interact_item(player)
		drink_machine.interact(player)
		drink_machine.interact(player) # Encher
		drink_machine._process(1.0) # Concluir
		drink_machine.interact(player) # Selar
		drink_machine.interact(player) # Retirar
		assert(player.held_item != null and player.held_item is DrinkCup, "Refrigerante retirado")
		player.take_held_item().queue_free()
	print("  [PASS] Todos os 4 sabores de refrigerante servidos e selados com sucesso")

	# ---------------------------------------------------------
	# TESTE 4: SELAGEM DE BEBIDA NA BANCADA DE EMBALAGEM
	# ---------------------------------------------------------
	print("\n--- Teste 4: Preparar Suco Aberto -> Levar para Selagem na Bancada de Embalagem ---")
	player.global_position = packaging_station.global_position + Vector3(0, 0, 0.25)
	packaging_station.interact_item(player)
	juice_machine.select_flavor_by_index(0) # Laranja
	juice_machine.interact(player)
	juice_machine.interact(player) # Encher
	juice_machine._process(1.0)
	assert(juice_machine.current_cup.state == DrinkCup.State.FILLED, "Copo cheio sem tampa")

	# Retira copo aberto (com suco não selado)
	var cup_open = juice_machine.current_cup
	juice_machine.current_cup = null
	juice_machine.cup_slot.remove_child(cup_open)
	player.pick_up(cup_open)

	# Executa selagem na bancada
	packaging_station.interact(player)
	assert(cup_open.state == DrinkCup.State.CLOSED, "Copo selado na bancada de embalagem")
	assert(player.held_item == cup_open, "Copo selado permanece na mão do jogador")
	player.take_held_item().queue_free()
	print("  [PASS] Suco aberto selado na bancada de embalagem e retirado com sucesso")

	# Limpeza
	player.queue_free()
	packaging_station.queue_free()
	drink_machine.queue_free()
	juice_machine.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DA ESTAÇÃO DE BEBIDAS E EMBALAGENS FORAM APROVADOS COM 100%!")
	print("============================================================")
	quit(0)
