extends SceneTree

const SyrupCanister = preload("res://src/items/syrup_canister.gd")
const DrinkCup = preload("res://src/items/drink_cup.gd")
const DrinkMachine = preload("res://src/stations/drink_machine.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE: NOMES DEFINITIVOS (COLA, ZERO, SODA, CITRUS)")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()
	inv.items["cup_empty"]["quantity"] = 50

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
	# 1. TESTE DE AÇÃO DA TECLA E NAS PORTAS DA MÁQUINA
	# -------------------------------------------------------------
	print("\n--- 1. Teste de Ação da Tecla E nas Portas ---")
	assert(not machine.is_left_door_open and not machine.is_right_door_open, "Portas iniciam fechadas")

	machine.toggle_left_door(player)
	assert(machine.is_left_door_open, "Porta esquerda ABRIU com a tecla E")
	machine._process(0.5)
	assert(machine.left_door_hinge.rotation.y < -0.5, "Porta rotacionou 95° para fora")

	machine.toggle_left_door(player)
	assert(not machine.is_left_door_open, "Porta esquerda FECHOU com a tecla E")
	machine._process(0.5)
	assert(absf(machine.left_door_hinge.rotation.y) < 0.1, "Porta esquerda retornou ao centro")

	machine.toggle_right_door(player)
	assert(machine.is_right_door_open, "Porta direita ABRIU com a tecla E")
	machine._process(0.5)
	assert(machine.right_door_hinge.rotation.y > 0.5, "Porta direita rotacionou para fora")
	machine.toggle_right_door(player)
	assert(not machine.is_right_door_open, "Porta direita FECHOU com a tecla E")
	machine._process(0.5)
	assert(absf(machine.right_door_hinge.rotation.y) < 0.1, "Porta direita retornou ao centro")
	print("  [PASS] Portas abrem e fecham perfeitamente.")

	# -------------------------------------------------------------
	# 2. TESTE DOS BARRIS (COLA, ZERO, SODA, CITRUS)
	# -------------------------------------------------------------
	print("\n--- 2. Teste dos Barris de Insumo (COLA, ZERO, SODA, CITRUS) ---")
	machine.toggle_left_door(player)

	var can_cola = machine.remove_canister(0, player)
	assert(can_cola != null and player.held_item == can_cola, "Barril de Cola retirado para a mão com clique")
	assert(machine.canisters[0] == null and machine.syrup_levels[0] == 0.0, "Encaixe 0 ficou vazio na máquina")

	player.take_held_item()
	var ok_insert = machine.insert_canister(0, can_cola, player)
	assert(ok_insert, "Barril reinstalado no encaixe correspondente")
	assert(machine.canisters[0] == can_cola, "Máquina reconheceu o barril")

	machine.toggle_left_door(player)
	print("  [PASS] Barris manipuláveis com clique esquerdo de forma independente.")

	# -------------------------------------------------------------
	# 3. TESTE DOS 4 SABORES (COLA, ZERO, SODA, CITRUS)
	# -------------------------------------------------------------
	print("\n--- 3. Teste das 4 Estações: COLA, ZERO, SODA, CITRUS ---")
	var flavor_data = [
		{"idx": 0, "name": "Copo de Cola", "id": "soda_cola", "label": "COLA"},
		{"idx": 1, "name": "Copo de Zero", "id": "soda_cola_zero", "label": "ZERO"},
		{"idx": 2, "name": "Copo de Soda", "id": "soda_lime", "label": "SODA"},
		{"idx": 3, "name": "Copo de Citrus", "id": "soda_citrus", "label": "CITRUS"}
	]

	for f in flavor_data:
		var i = f["idx"]

		# 1. Copo vazio na mão
		var cup = cup_scene.instantiate() as DrinkCup
		world.add_child(cup)
		cup._ready()
		cup.set_state(DrinkCup.State.EMPTY)
		player.pick_up(cup)
		assert(player.held_item == cup, "Copo pego com clique esquerdo")

		# 2. Posiciona copo no berço sob a torneira
		var cup_held = player.take_held_item() as DrinkCup
		var ok_place = machine.place_cup_in_slot(i, cup_held, player)
		assert(ok_place, "Copo apoiado no berço sob a torneira de %s" % f["label"])
		assert(machine.current_cups[i] == cup, "Copo registrado no slot da estação")

		# 3. Aciona alavanca com [E] -> inicia fluxo
		machine.toggle_lever(i, player)
		assert(machine.is_lever_down[i], "Alavanca acionada e abaixada")
		var stream = machine.get_node_or_null("Model/Stream_%d" % i)
		assert(stream != null and stream.visible, "Jato descendo da torneira de %s" % f["label"])

		# 4. Enchimento progressivo
		machine._process(1.5)
		assert(cup.state == DrinkCup.State.FILLED, "Copo totalmente cheio de %s" % str(f["label"]))

		# 5. Para fluxo
		machine.toggle_lever(i, player)
		assert(not machine.is_lever_down[i], "Alavanca retornou para cima")

		# 6. Retira copo cheio com clique
		var taken_cup = machine.take_cup_from_slot(i, player)
		assert(taken_cup == cup and player.held_item == cup, "Copo de %s retirado da maquina com clique" % str(f["label"]))

		# 7. Validação da geometria do líquido: rente às paredes internas do copo
		var cyl_mesh = cup.liquid_mesh.mesh as CylinderMesh
		assert(cyl_mesh != null, "Malha do líquido presente")
		assert(cyl_mesh.bottom_radius >= 0.046 and cyl_mesh.top_radius >= 0.062, "Líquido toca nas paredes internas")
		assert(cup.liquid_mesh.position.y > 0.0, "Líquido começa rente ao fundo interno do copo")

		print("  [PASS] Estação %d: %s (%s) servida e validada." % [i + 1, f["label"], f["name"]])
		player.take_held_item().queue_free()

	# Limpeza
	machine.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE NOMES DEFINITIVOS FORAM APROVADOS!")
	print("============================================================\n")
	quit(0)
