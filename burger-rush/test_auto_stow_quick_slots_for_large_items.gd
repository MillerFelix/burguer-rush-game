extends SceneTree

# ================================================================
# TESTE: LIBERAÇÃO AUTOMÁTICA DA MÃO E PRESERVAÇÃO DOS SLOTS RÁPIDOS
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
	print("\n=== INICIANDO TESTES DE LIBERAÇÃO AUTOMÁTICA DA MÃO PARA OBJETOS GRANDES ===")
	call_deferred("_run_tests")

func _run_tests() -> void:
	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	# ── TESTE 1: INGREDIENTE ATIVO + PEGAR BANDEJA (AUTO-STOW) ──
	print("\n--- 1. Testando Troca Natural: Ingrediente Ativo -> Bandeja ---")
	var tomato = load("res://src/items/tomato.tscn").instantiate()
	var lettuce = load("res://src/items/lettuce.tscn").instantiate()
	root.add_child(tomato)
	root.add_child(lettuce)

	player.pick_up(tomato)
	player.pick_up(lettuce)
	player.select_quick_slot(0, false) # Seleciona Tomate na mão

	assert_test(player.held_item is Tomato, "Tomate está inicialmente ativo na mão")
	assert_test(player.active_quick_slot == 0, "Slot ativo é o Slot 4 (Tomate)")
	assert_test(player.quick_slots[0].get("count") == 1, "Slot 4 contém 1x Tomate")
	assert_test(player.quick_slots[1].get("count") == 1, "Slot 5 contém 1x Alface")

	# Jogador pega uma Bandeja sem soltar manualmente o tomate
	var tray = load("res://src/items/serving_tray.tscn").instantiate()
	root.add_child(tray)
	player.pick_up(tray)

	assert_test(player.held_item is ServingTray, "Mão segura a Bandeja imediatamente")
	assert_test(player.is_holding_large_item() == true, "is_holding_large_item() retorna true")
	assert_test(player.active_quick_slot == -1, "Slot ativo na mão foi liberado (-1)")
	assert_test(player.quick_slots[0].get("count") == 1, "Tomate retornou em segurança ao Slot 4 (count=1)")
	assert_test(player.quick_slots[1].get("count") == 1, "Alface permaneceu intacta no Slot 5 (count=1)")

	# ── TESTE 2: ENTREGAR BANDEJA E REATIVAR SLOTS RÁPIDOS ──
	print("\n--- 2. Testando Reativação dos Slots Rápidos após Entregar Bandeja ---")
	var delivered_tray = player.take_held_item()
	if delivered_tray: delivered_tray.queue_free()

	assert_test(player.held_item == null, "Mãos livres após entregar a bandeja")
	assert_test(player.is_holding_large_item() == false, "Não está segurando objeto grande")

	# Seleciona o Tomate novamente
	player.select_quick_slot(0, false)
	assert_test(player.held_item is Tomato, "Tomate do Slot 4 pode ser selecionado e volta para a mão")
	assert_test(player.active_quick_slot == 0, "Slot 4 ativo na mão novamente")

	# ── TESTE 3: TROCA NATURAL COM OUTROS OBJETOS GRANDES (COPO, CAIXA, SACOLA) ──
	print("\n--- 3. Testando Troca Natural com Outros Objetos Grandes ---")
	# 3.1 Copo de Bebida
	var cup = load("res://src/items/drink_cup.tscn").instantiate()
	root.add_child(cup)
	player.pick_up(cup)
	assert_test(player.held_item is DrinkCup, "Tomate guardado e Copo colocado na mão")
	assert_test(player.quick_slots[0].get("count") == 1, "Tomate preservado no Slot 4")
	var dropped_cup = player.take_held_item()
	if dropped_cup: dropped_cup.queue_free()

	# 3.2 Caixa de Hambúrguer
	player.select_quick_slot(1, false) # Seleciona Alface
	assert_test(player.held_item is Lettuce, "Alface ativa na mão")
	var burger_box = load("res://src/items/burger_box.tscn").instantiate()
	root.add_child(burger_box)
	player.pick_up(burger_box)
	assert_test(player.held_item is BurgerBox, "Alface guardada e Caixa de Hambúrguer colocada na mão")
	assert_test(player.quick_slots[1].get("count") == 1, "Alface preservada no Slot 5")
	var dropped_box = player.take_held_item()
	if dropped_box: dropped_box.queue_free()

	# 3.3 Sacola de Delivery
	player.select_quick_slot(0, false) # Seleciona Tomate
	var delivery_bag = load("res://src/items/delivery_bag.tscn").instantiate()
	root.add_child(delivery_bag)
	player.pick_up(delivery_bag)
	assert_test(player.held_item is DeliveryBag, "Tomate guardado e Sacola de Delivery colocada na mão")
	assert_test(player.quick_slots[0].get("count") == 1, "Tomate preservado no Slot 4")
	var dropped_bag = player.take_held_item()
	if dropped_bag: dropped_bag.queue_free()

	# ── RELATÓRIO FINAL ──
	print("\n=======================================================")
	print("RESULTADO DOS TESTES: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=======================================================\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS TESTES DE TROCA NATURAL PASSARAM COM SUCESSO! <<<\n")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<\n")
		quit(1)
