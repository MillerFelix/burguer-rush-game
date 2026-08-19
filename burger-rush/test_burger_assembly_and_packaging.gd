extends SceneTree

var passed_tests: int = 0
var total_tests: int = 0

func assert_test(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		print("  [FAIL] %s" % test_name)

func _init() -> void:
	print("\n=================================================================")
	print("=== TESTE DE MONTAGEM, COLETA (TECLA E) E EMBALAGEM DE BURGERS ===")
	print("=================================================================\n")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	# 1. Base do Pão no balcão
	var bb_scene = load("res://src/items/bread_bottom.tscn")
	var bread_bottom: BreadBottom = bb_scene.instantiate() as BreadBottom
	root.add_child(bread_bottom)
	bread_bottom._ready()
	bread_bottom.location = Item.ItemLocation.WORLD

	var assembly = bread_bottom.assembly
	assert_test(assembly != null, "BurgerAssembly inicializado na Base do Pão")
	assert_test(assembly.ingredients.size() == 0, "Burger inicialmente vazio (0 ingredientes)")

	# =========================================================================
	# TESTE 1: CARNE NA MÃO + LMB NO PÃO -> CARNE ADICIONADA
	# =========================================================================
	print("\n--- TESTE 1: Carne na mão + LMB no pão ---")
	_clear_player(player)

	var patty_scene = load("res://src/items/patty.tscn")
	var patty: Patty = patty_scene.instantiate() as Patty
	patty.state = 2 # Grelhado
	root.add_child(patty)
	player.pick_up(patty)

	# Simula clique LMB mirando no pão
	bread_bottom.interact_item(player)

	assert_test(assembly.ingredients.size() == 1, "LMB colocou a Carne sobre o pão (1 ingrediente)")
	assert_test(assembly.ingredients[0] == patty, "Carne é filha do BurgerAssembly")
	assert_test(player.quick_slots[0].is_empty() and player.held_item == null, "Slot/Mão do jogador liberada após colocar a carne")

	# =========================================================================
	# TESTE 2: QUEIJO NA MÃO + LMB NO LANCHE -> QUEIJO ADICIONADO
	# =========================================================================
	print("\n--- TESTE 2: Queijo na mão + LMB no lanche ---")
	_clear_player(player)

	var cheese_scene = load("res://src/items/cheese.tscn")
	var cheese: Cheese = cheese_scene.instantiate() as Cheese
	cheese.cheese_type = Cheese.CheeseType.CHEDDAR
	root.add_child(cheese)
	player.pick_up(cheese)

	# Simula clique LMB no lanche
	bread_bottom.interact_item(player)

	assert_test(assembly.ingredients.size() == 2, "LMB colocou o Queijo sobre a carne (2 ingredientes)")
	assert_test(assembly.ingredients[1] == cheese, "Queijo é o segundo ingrediente na montagem")
	assert_test(player.quick_slots[0].is_empty() and player.held_item == null, "Mão liberada após colocar o queijo")

	# =========================================================================
	# TESTE 3: ADICIONAR MÚLTIPLOS INGREDIENTES CONSECUTIVOS COM LMB
	# =========================================================================
	print("\n--- TESTE 3: Múltiplos ingredientes com LMB (Alface, Tomate, Cebola) ---")
	var lettuce_scene = load("res://src/items/lettuce.tscn")
	var lettuce = lettuce_scene.instantiate()
	root.add_child(lettuce)
	player.pick_up(lettuce)
	bread_bottom.interact_item(player)

	var tomato_scene = load("res://src/items/tomato.tscn")
	var tomato = tomato_scene.instantiate()
	root.add_child(tomato)
	player.pick_up(tomato)
	bread_bottom.interact_item(player)

	var onion_scene = load("res://src/items/onion.tscn")
	var onion = onion_scene.instantiate()
	root.add_child(onion)
	player.pick_up(onion)
	bread_bottom.interact_item(player)

	assert_test(assembly.ingredients.size() == 5, "Montagem contém 5 ingredientes (Carne, Queijo, Alface, Tomate, Cebola)")
	assert_test(assembly.state == BurgerAssembly.State.ASSEMBLING, "Estado da montagem é ASSEMBLING")

	# =========================================================================
	# TESTE 4: LANCHE INCOMPLETO + PRESSIONAR TECLA E -> PEGA O LANCHE INTEIRO
	# =========================================================================
	print("\n--- TESTE 4: Lanche incompleto + Tecla E -> Pega o lanche inteiro ---")
	_clear_player(player)

	# Jogador pressiona E olhando para o lanche
	bread_bottom.interact(player)

	assert_test(player.held_item == bread_bottom, "Tecla E pegou o lanche incompleto inteiro para a mão")
	assert_test(assembly.ingredients.size() == 5, "Todos os 5 ingredientes continuam perfeitamente preservados na mão")
	assert_test(bread_bottom.is_held == true, "Base do pão em estado is_held")

	# Solta de volta no balcão
	player.drop_item()
	assert_test(player.held_item == null, "Lanche solto de volta no balcão")
	assert_test(bread_bottom.location == Item.ItemLocation.WORLD, "Lanche voltou ao estado WORLD")
	assert_test(assembly.ingredients.size() == 5, "Todos os 5 ingredientes permanecem juntos na bancada")

	# =========================================================================
	# TESTE 5: FECHAR LANCHE (BREAD_TOP COM LMB) + LANCHE COMPLETO + TECLA E
	# =========================================================================
	print("\n--- TESTE 5: Fechar lanche com LMB + Tecla E pega lanche completo ---")
	_clear_player(player)

	var bt_scene = load("res://src/items/bread_top.tscn")
	var bread_top = bt_scene.instantiate()
	root.add_child(bread_top)
	player.pick_up(bread_top)

	# LMB fecha o lanche com a tampa do pão
	bread_bottom.interact_item(player)

	assert_test(assembly.state == BurgerAssembly.State.CLOSED, "LMB fechou o lanche com o pão superior (Estado CLOSED)")
	assert_test(assembly.top_bun == bread_top, "Pão superior associado ao lanche")
	assert_test(assembly.can_package() == true, "Lanche pronto para ser embalado (can_package = true)")

	# Tecla E pega o lanche completo
	bread_bottom.interact(player)
	assert_test(player.held_item == bread_bottom, "Tecla E pegou o lanche completo inteiro para a mão")
	assert_test(assembly.ingredients.size() == 5 and assembly.top_bun == bread_top, "Composição completa preservada na mão")

	# Solta no balcão
	player.drop_item()

	# =========================================================================
	# TESTE 6: EMBALAGEM NA MÃO + MIRAR NO LANCHE + LMB -> LANCHE EMBALADO
	# =========================================================================
	print("\n--- TESTE 6: Caixinha na mão + Mirar no lanche + LMB -> Embala o lanche ---")
	_clear_player(player)

	var box_scene = load("res://src/items/burger_box.tscn")
	var box: BurgerBox = box_scene.instantiate() as BurgerBox
	root.add_child(box)
	player.pick_up(box)

	assert_test(player.held_item == box, "Jogador segurando Caixinha de Hambúrguer na mão")

	# LMB na montagem fechada
	bread_bottom.interact_item(player)

	assert_test(player.held_item == null, "Caixinha consumida da mão do jogador")
	assert_test(assembly.state == BurgerAssembly.State.PACKAGED, "Montagem convertida para PACKAGED")

	print("\n=================================================================")
	print("RESULTADO FINAL: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=================================================================\n")

	if passed_tests == total_tests:
		print(">>> SUCESSO TOTAL: MONTAGEM (LMB), COLETA (TECLA E) E EMBALAGEM 100% VALIDADAS! <<<\n")
		quit(0)
	else:
		print(">>> FALHA NOS TESTES! <<<\n")
		quit(1)

func _clear_player(player: Player) -> void:
	player.quick_slots.clear()
	player.quick_slots.append({})
	player.quick_slots.append({})
	player.quick_slots.append({})
	player.active_quick_slot = -1
	player.active_tool_slot = Player.ToolSlot.HANDS
	if player.held_item != null:
		if is_instance_valid(player.held_item) and player.held_item.get_parent():
			player.held_item.get_parent().remove_child(player.held_item)
		player.held_item = null
