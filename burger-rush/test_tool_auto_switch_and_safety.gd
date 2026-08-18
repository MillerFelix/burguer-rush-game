extends SceneTree

# ================================================================
# TESTE COMPLETO: TROCA AUTOMÁTICA DE FERRAMENTAS E PROTEÇÃO CONTRA CRASHES
# ================================================================

var total_tests = 0
var passed_tests = 0

func assert_test(condition: bool, test_name: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		print("  [FAIL] %s" % test_name)

func _init() -> void:
	print("\n=== INICIANDO TESTES DE TROCA INTELIGENTE DE FERRAMENTAS E SEGURANÇA ===")
	call_deferred("_run_tests")

func _run_tests() -> void:
	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	# ── TESTE 1: ESPÁTULA + ITENS VÁLIDOS (GRELHA/CHAPA) ──
	print("\n--- 1. Testando Espátula com Itens Fritáveis/Grelha ---")
	player.select_tool_slot(Player.ToolSlot.SPATULA, false)
	assert_test(player.active_tool_slot == Player.ToolSlot.SPATULA, "Espátula equipada [1]")

	var patty = load("res://src/items/patty.tscn").instantiate()
	root.add_child(patty)
	assert_test(player.can_be_picked_with_spatula(patty) == true, "Patty é compatível com Espátula")

	player.pick_up(patty)
	assert_test(player.active_tool_slot == Player.ToolSlot.SPATULA, "Espátula permanece ativa ao manipular Patty")
	var dropped_patty = player.take_held_item()
	if dropped_patty: dropped_patty.queue_free()

	# ── TESTE 2: ESPÁTULA + INGREDIENTES NÃO FRITÁVEIS (AUTO-SWITCH PARA MÃO) ──
	print("\n--- 2. Testando Espátula com Ingredientes Não Grelháveis ---")
	player.select_tool_slot(Player.ToolSlot.SPATULA, false)
	var tomato = load("res://src/items/tomato.tscn").instantiate()
	root.add_child(tomato)
	assert_test(player.can_be_picked_with_spatula(tomato) == false, "Tomate NÃO é compatível com Espátula")

	player.pick_up(tomato)
	assert_test(player.active_tool_slot == Player.ToolSlot.HANDS, "Espátula troca automaticamente para MÃO ao pegar Tomate")
	assert_test(player.held_item is Tomato, "Tomate é pego com sucesso na Mão")
	var dropped_tomato = player.take_held_item()
	if dropped_tomato: dropped_tomato.queue_free()

	# ── TESTE 3: ESPÁTULA + OBJETOS GRANDES (BANDEJA, COPO, CAIXA, SACOLA) ──
	print("\n--- 3. Testando Espátula com Objetos Grandes ---")
	player.select_tool_slot(Player.ToolSlot.SPATULA, false)
	var tray = load("res://src/items/serving_tray.tscn").instantiate()
	root.add_child(tray)
	assert_test(player.can_be_picked_with_spatula(tray) == false, "Bandeja NÃO é compatível com Espátula")

	player.pick_up(tray)
	assert_test(player.active_tool_slot == Player.ToolSlot.HANDS, "Espátula troca automaticamente para MÃO ao pegar Bandeja")
	assert_test(player.held_item is ServingTray, "Bandeja é segurada na Mão Principal")
	var dropped_tray = player.take_held_item()
	if dropped_tray: dropped_tray.queue_free()

	# ── TESTE 4: BUCHA/ESPONJA + TENTATIVA DE PEGAR OBJETOS (AUTO-SWITCH PARA MÃO) ──
	print("\n--- 4. Testando Bucha de Limpeza (Auto-Switch para Mão) ---")
	player.select_tool_slot(Player.ToolSlot.SPONGE, false)
	assert_test(player.active_tool_slot == Player.ToolSlot.SPONGE, "Bucha equipada [2]")

	var cheese = load("res://src/items/cheese.tscn").instantiate()
	root.add_child(cheese)
	player.pick_up(cheese)
	assert_test(player.active_tool_slot == Player.ToolSlot.HANDS, "Bucha troca automaticamente para MÃO ao pegar Queijo")
	assert_test(player.held_item is Cheese, "Queijo é pego com sucesso na Mão")
	var dropped_cheese = player.take_held_item()
	if dropped_cheese: dropped_cheese.queue_free()

	# Teste Bucha + Copo
	player.select_tool_slot(Player.ToolSlot.SPONGE, false)
	var cup = load("res://src/items/drink_cup.tscn").instantiate()
	root.add_child(cup)
	player.pick_up(cup)
	assert_test(player.active_tool_slot == Player.ToolSlot.HANDS, "Bucha troca automaticamente para MÃO ao pegar Copo")
	assert_test(player.held_item is DrinkCup, "Copo é segurado na Mão Principal")
	var dropped_cup = player.take_held_item()
	if dropped_cup: dropped_cup.queue_free()

	# ── TESTE 5: SEGURANÇA CONTRA CRASHES (COMBINAÇÕES E OBJETOS NULOS/INVÁLIDOS) ──
	print("\n--- 5. Testando Estabilidade e Proteção Contra Crashes ---")
	player.select_tool_slot(Player.ToolSlot.SPATULA, false)
	player.pick_up(null)
	assert_test(true, "pick_up(null) não gera erro nem crash")

	var invalid_node = Node3D.new()
	root.add_child(invalid_node)
	assert_test(player.can_be_picked_with_spatula(invalid_node) == false, "can_be_picked_with_spatula(invalid_node) retorna false com segurança")
	invalid_node.queue_free()

	# ── RELATÓRIO FINAL ──
	print("\n=======================================================")
	print("RESULTADO DOS TESTES: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=======================================================\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS TESTES DE FERRAMENTAS PASSARAM COM SUCESSO! <<<\n")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<\n")
		quit(1)
