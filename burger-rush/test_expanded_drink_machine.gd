extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DA MÁQUINA DE REFRIGERANTES EXPANDIDA (5 SABORES)")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()
	inv.items["cup_empty"]["quantity"] = 20
	inv.items["cup_lid"]["quantity"] = 20
	inv.items["syrup_soda"]["quantity"] = 20

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	var machine_scene = load("res://src/stations/drink_machine.tscn")
	assert(machine_scene != null, "Cena drink_machine.tscn deve existir")
	var machine = machine_scene.instantiate() as DrinkMachine
	root.add_child(machine)
	machine._ready()

	assert(machine.available_flavors.size() == 4, "Máquina deve suportar 4 sabores de refrigerante")
	assert(machine.syrup_current == 25, "Capacidade inicial deve ser 25 doses de xarope")

	# Teste dos 4 Sabores Individuais
	print("\n--- Teste 1: Validação dos 4 Sabores de Bebida ---")
	var flavors_expected = [
		{"id": "soda_cola", "name": "COLA"},
		{"id": "soda_cola_zero", "name": "ZERO"},
		{"id": "soda_lime", "name": "SODA"},
		{"id": "soda_citrus", "name": "CITRUS"}
	]

	for i in range(flavors_expected.size()):
		var f = flavors_expected[i]
		machine.select_flavor_by_index(i)
		assert(machine.get_current_flavor_id() == f["id"], "ID de sabor incorreto: %s" % f["id"])
		assert(machine.get_current_flavor_name() == f["name"], "Nome de sabor incorreto: %s" % f["name"])
		print("  [PASS] Bico %d: %s (%s)" % [i + 1, f["name"], f["id"]])

	# Teste de Ciclo Físico de Preparo: Copo -> Bico -> Encher -> Selar
	print("\n--- Teste 2: Ciclo Físico com Copo (Copo -> Bico -> Encher -> Selar) ---")
	var cup_scene = load("res://src/items/drink_cup.tscn")
	for i in range(flavors_expected.size()):
		var f = flavors_expected[i]
		machine.select_flavor_by_index(i)

		# 1. Instancia copo vazio e coloca na máquina
		var cup = cup_scene.instantiate() as DrinkCup
		machine.cup_slot.add_child(cup)
		cup.set_state(DrinkCup.State.EMPTY)
		machine.current_cup = cup

		# 2. Inicia enchimento
		machine.interact(player)
		assert(machine.is_filling, "Máquina deve estar no estado de enchimento")
		assert(machine.current_cup.flavor == f["id"], "Sabor deve ser %s" % f["id"])

		# 3. Processa enchimento até 100%
		machine._process(1.0)
		assert(not machine.is_filling, "Enchimento deve finalizar em 100%")
		assert(machine.current_cup.state == DrinkCup.State.FILLED, "Copo deve estar CHEIO")

		# 4. Retira da máquina para a mão do jogador
		machine.interact(player)
		assert(player.held_item == cup, "Copo deve estar na mão do jogador")
		assert(cup.state == DrinkCup.State.FILLED or cup.state == DrinkCup.State.CLOSED, "Copo deve estar CHEIO e PRONTO")
		assert(cup.get_flavor_display_name().to_lower().contains(f["name"].to_lower()), "Nome da bebida deve conter o sabor")

		player.take_held_item()
		cup.queue_free()
		print("  [PASS] Bebida %s servida e pronta com sucesso!" % f["name"])

	# Teste de Bloqueio quando sem xarope
	print("\n--- Teste 3: Bloqueio quando Reservatório Esgota ---")
	machine.syrup_current = 0
	var empty_cup = cup_scene.instantiate() as DrinkCup
	machine.cup_slot.add_child(empty_cup)
	empty_cup.set_state(DrinkCup.State.EMPTY)
	machine.current_cup = empty_cup

	machine.interact(player)
	assert(not machine.is_filling, "Não deve encher quando sem xarope")
	assert(empty_cup.state == DrinkCup.State.EMPTY, "Copo deve permanecer vazio")
	print("  [PASS] Enchimento impedido corretamente quando sem xarope")

	# Recarga
	machine.refill_syrup(50)
	assert(machine.syrup_current == 50, "Xarope recarregado com sucesso")
	print("  [PASS] Reservatório recarregado para 50 doses")

	empty_cup.queue_free()
	machine.queue_free()
	player.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DA MÁQUINA DE BEBIDAS FORAM APROVADOS COM 100%!")
	print("============================================================")
	quit(0)
