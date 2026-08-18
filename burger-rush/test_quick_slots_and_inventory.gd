extends SceneTree

# ================================================================
# TESTE COMPLETO: SISTEMA DE SLOTS RÁPIDOS (4, 5, 6), FERRAMENTAS E MÃO
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
	print("\n=== INICIANDO TESTES DO SISTEMA DE SLOTS RÁPIDOS, FERRAMENTAS E MÃO ===")
	call_deferred("_run_tests")

func _run_tests() -> void:
	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	# ── TESTE 1: FERRAMENTAS INDIVIDUAIS (1, 2, 3) ──
	print("\n--- 1. Testando Ferramentas [1], [2], [3] ---")
	player.select_tool_slot(Player.ToolSlot.SPATULA, false)
	assert_test(player.active_tool_slot == Player.ToolSlot.SPATULA, "Tecla 1 equipa Espátula")

	player.select_tool_slot(Player.ToolSlot.SPONGE, false)
	assert_test(player.active_tool_slot == Player.ToolSlot.SPONGE, "Tecla 2 equipa Bucha de Limpeza")

	player.select_tool_slot(Player.ToolSlot.HANDS, false)
	assert_test(player.active_tool_slot == Player.ToolSlot.HANDS, "Tecla 3 equipa Mão Livre")

	# ── TESTE 2: COLETA DE INGREDIENTES EM SLOTS RÁPIDOS (1 UNIDADE FÍSICA POR COLETA) ──
	print("\n--- 2. Testando Coleta e Unidades Físicas nos Slots 4, 5, 6 ---")
	var tomato = load("res://src/items/tomato.tscn").instantiate()
	var lettuce = load("res://src/items/lettuce.tscn").instantiate()
	var onion = load("res://src/items/onion.tscn").instantiate()

	root.add_child(tomato)
	root.add_child(lettuce)
	root.add_child(onion)

	player.pick_up(tomato)
	assert_test(player.quick_slots[0].get("count") == 1, "Primeiro ingrediente (Tomate) ocupa Slot 4 (count=1)")
	assert_test(player.active_quick_slot == 0, "Slot 4 fica ativo na mão")
	assert_test(player.held_item is Tomato, "Item ativo na mão é exatamente o Tomate")

	player.pick_up(lettuce)
	assert_test(player.quick_slots[1].get("count") == 1, "Alface ocupa o Slot 5 (count=1)")
	assert_test(player.active_quick_slot == 1, "Alface (Slot 5) se torna o ingrediente ativo mais recente")
	assert_test(player.held_item is Lettuce, "Item ativo na mão é exatamente a Alface")

	player.pick_up(onion)
	assert_test(player.quick_slots[2].get("count") == 1, "Cebola ocupa o Slot 6 (count=1)")
	assert_test(player.active_quick_slot == 2, "Cebola (Slot 6) se torna o ingrediente ativo mais recente")
	assert_test(player.held_item is Onion, "Item ativo na mão é exatamente a Cebola")

	# ── TESTE 3: LIMITE DE 3 SLOTS RÁPIDOS ──
	print("\n--- 3. Testando Capacidade Máxima dos Slots Rápidos (3 Itens) ---")
	var cheese = load("res://src/items/cheese.tscn").instantiate()
	root.add_child(cheese)
	assert_test(player.can_take_ingredient("cheese") == false, "can_take_ingredient('cheese') retorna false quando os 3 slots estão cheios")

	# ── TESTE 4: SELEÇÃO POR TECLAS 4, 5, 6 ──
	print("\n--- 4. Testando Seleção por Teclas 4, 5, 6 ---")
	player.select_quick_slot(0, false)
	assert_test(player.active_quick_slot == 0, "Tecla 4 seleciona Tomate (Slot 0)")
	assert_test(player.held_item is Tomato, "Item instanciado na mão é Tomato")

	player.select_quick_slot(1, false)
	assert_test(player.active_quick_slot == 1, "Tecla 5 seleciona Alface (Slot 1)")
	assert_test(player.held_item is Lettuce, "Item instanciado na mão é Lettuce")

	player.select_quick_slot(2, false)
	assert_test(player.active_quick_slot == 2, "Tecla 6 seleciona Cebola (Slot 2)")
	assert_test(player.held_item is Onion, "Item instanciado na mão é Onion")

	# ── TESTE 5: SCROLL DO MOUSE ──
	print("\n--- 5. Testando Troca por Scroll do Mouse ---")
	player.cycle_quick_slot(-1) # Scroll up: de slot 2 para slot 1
	assert_test(player.active_quick_slot == 1, "Scroll Up alterna para o slot anterior (Alface)")

	player.cycle_quick_slot(-1) # Scroll up: de slot 1 para slot 0
	assert_test(player.active_quick_slot == 0, "Scroll Up alterna para o primeiro slot (Tomate)")

	player.cycle_quick_slot(1) # Scroll down: de slot 0 para slot 1
	assert_test(player.active_quick_slot == 1, "Scroll Down alterna para o próximo slot (Alface)")

	# ── TESTE 6: CONSUMO / USO DOS INGREDIENTES E LIMPEZA DO SLOT ──
	print("\n--- 6. Testando Consumo do Slot Ativo (take_held_item) ---")
	player.select_quick_slot(0, false) # Tomate
	var used_tomato = player.take_held_item()
	assert_test(used_tomato is Tomato, "take_held_item() entrega o Tomate")
	assert_test(player.quick_slots[0].is_empty(), "Slot 4 é imediatamente esvaziado após uso")
	assert_test(player.active_quick_slot == 1, "Transição automática para o próximo slot ocupado (Slot 5 - Alface)")
	assert_test(player.held_item is Lettuce, "Próximo item físico ativo na mão é a Alface")

	# ── TESTE 7: DEVOLUÇÃO DO INGREDIENTE ──
	print("\n--- 7. Testando Devolução do Ingrediente ---")
	var returned_lettuce = player.take_held_item()
	assert_test(returned_lettuce is Lettuce, "take_held_item() retira a Alface para devolução")
	assert_test(player.quick_slots[1].is_empty(), "Slot 5 é esvaziado após devolução")
	returned_lettuce.queue_free()

	# ── TESTE 8: OBJETOS GRANDES E ÚNICOS NA MÃO ──
	print("\n--- 8. Testando Objetos Grandes (Mão Principal Isolada) ---")
	var tray = load("res://src/items/serving_tray.tscn").instantiate()
	root.add_child(tray)
	player.pick_up(tray)
	assert_test(player.held_item is ServingTray, "Bandeja segurada na Mão Principal")
	assert_test(player.is_holding_large_item() == true, "is_holding_large_item() retorna true")
	assert_test(player.active_quick_slot == -1, "Bandeja NÃO ocupa slots rápidos (active_quick_slot = -1)")
	assert_test(player.quick_slots[2].get("count") == 1, "Ingrediente Cebola permanece seguro no Slot 6")

	var taken_tray = player.take_held_item()
	assert_test(taken_tray is ServingTray, "take_held_item() retira a bandeja normalmente")
	assert_test(player.held_item == null, "Mãos livres após entregar a bandeja")

	# ── RELATÓRIO FINAL ──
	print("\n=======================================================")
	print("RESULTADO DOS TESTES: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=======================================================\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS TESTES PASSARAM COM SUCESSO! <<<\n")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<\n")
		quit(1)
