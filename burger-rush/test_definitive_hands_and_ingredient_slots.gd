extends SceneTree

# ================================================================
# TESTE AUTOMATIZADO DEFINITIVO: SISTEMA DE MÃOS E SLOTS RÁPIDOS (4, 5, 6)
# ================================================================

var total_tests: int = 0
var passed_tests: int = 0

func assert_test(condition: bool, description: String) -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % description)
	else:
		printerr("  [FAIL] %s" % description)

func _init() -> void:
	print("\n=======================================================")
	print("=== INICIANDO TESTE DO SISTEMA DE MÃOS E SLOTS RÁPIDOS ===")
	print("=======================================================\n")

	var player_scene = load("res://src/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root.add_child(player)

	# --- CENÁRIO A ---
	print("--- CENÁRIO A: 3 Ingredientes nos Slots + Pegar Bandeja ---")
	player.quick_slots = [{}, {}, {}]
	player.active_quick_slot = -1
	player.held_item = null

	var patty = load("res://src/items/patty.tscn").instantiate()
	var cheese = load("res://src/items/cheese.tscn").instantiate()
	var tomato = load("res://src/items/tomato.tscn").instantiate()

	player.pick_up(patty)
	player.pick_up(cheese)
	player.pick_up(tomato)

	assert_test(player.quick_slots[0].get("item_id") == "patty_beef", "Slot 4 contém Carne")
	assert_test(player.quick_slots[1].get("item_id") == "cheese", "Slot 5 contém Queijo")
	assert_test(player.quick_slots[2].get("item_id") == "tomato", "Slot 6 contém Tomate")
	assert_test(player.held_item == null, "Mão principal continua LIVRE com os 3 slots ocupados")
	assert_test(player.is_hand_free() == true, "is_hand_free() retorna true")

	var tray = load("res://src/items/serving_tray.tscn").instantiate()
	root.add_child(tray)
	player.pick_up(tray)

	assert_test(player.held_item == tray, "Mão principal agora segura a Bandeja")
	assert_test(player.is_holding_large_item() == true, "is_holding_large_item() retorna true")
	assert_test(player.quick_slots[0].get("item_id") == "patty_beef", "Slot 4 continua intacto com Carne")
	assert_test(player.quick_slots[1].get("item_id") == "cheese", "Slot 5 continua intacto com Queijo")
	assert_test(player.quick_slots[2].get("item_id") == "tomato", "Slot 6 continua intacto com Tomate")

	# --- CENÁRIO B ---
	print("\n--- CENÁRIO B: 1 Ingrediente no Slot + Pegar Saco ---")
	player.held_item = null
	if is_instance_valid(tray): tray.queue_free()
	player.quick_slots = [{}, {}, {}]
	player.active_quick_slot = -1

	var tom_b = load("res://src/items/tomato.tscn").instantiate()
	player.pick_up(tom_b)

	assert_test(player.quick_slots[0].get("item_id") == "tomato", "Slot 4 contém Tomate")
	assert_test(player.quick_slots[1].is_empty(), "Slot 5 está vazio")
	assert_test(player.quick_slots[2].is_empty(), "Slot 6 está vazio")
	assert_test(player.held_item == null, "Mão principal está LIVRE")

	var bag = load("res://src/items/delivery_bag.tscn").instantiate()
	root.add_child(bag)
	player.pick_up(bag)

	assert_test(player.held_item == bag, "Mão principal segura o Saco de Delivery")
	assert_test(player.quick_slots[0].get("item_id") == "tomato", "Slot 4 permanece com Tomate")

	# --- CENÁRIO C ---
	print("\n--- CENÁRIO C: Mão Ocupada Bloqueia Manipulação de Ingredientes ---")
	assert_test(player.can_take_ingredient() == false, "can_take_ingredient() retorna false enquanto segura o saco")
	assert_test(player.can_manipulate_ingredients() == false, "can_manipulate_ingredients() retorna false")

	var lettuce_extra = load("res://src/items/lettuce.tscn").instantiate()
	player.pick_up(lettuce_extra)

	assert_test(player.quick_slots[1].is_empty(), "Tentativa de pegar alface com mão ocupada foi bloqueada (Slot 5 permanece vazio)")
	assert_test(player.held_item == bag, "Saco continua na mão")
	if is_instance_valid(lettuce_extra): lettuce_extra.queue_free()

	# --- CENÁRIO D ---
	print("\n--- CENÁRIO D: Soltar Objeto Grande e Usar Ingredientes ---")
	player.drop_item()

	assert_test(player.held_item == null, "Mão principal agora está LIVRE após soltar o saco")
	assert_test(player.is_hand_free() == true, "is_hand_free() é true")
	assert_test(player.quick_slots[0].get("item_id") == "tomato", "Slot 4 permaneceu 100% intacto com Tomate")
	assert_test(player.can_manipulate_ingredients() == true, "can_manipulate_ingredients() agora é true")

	# Agora pode pegar novo ingrediente normalmente
	var lettuce_now = load("res://src/items/lettuce.tscn").instantiate()
	player.pick_up(lettuce_now)
	assert_test(player.quick_slots[1].get("item_id") == "lettuce", "Alface foi pega com sucesso no Slot 5 após liberar a mão")

	# --- CENÁRIO E: Seleção e Consumo nos Equipamentos ---
	print("\n--- CENÁRIO E: Seleção e Consumo de Ingredientes Ativos ---")
	player.select_quick_slot(0)
	assert_test(player.active_quick_slot == 0, "Slot 4 (Tomate) selecionado")
	assert_test(player.held_item == null, "Seleção do slot 4 NÃO ocupa a mão principal")

	player.select_quick_slot(1)
	assert_test(player.active_quick_slot == 1, "Slot 5 (Alface) selecionado")
	assert_test(player.held_item == null, "Seleção do slot 5 NÃO ocupa a mão principal")

	# Consome o ingrediente ativo
	var consumed_node = player.consume_active_ingredient()
	assert_test(consumed_node != null and consumed_node is Lettuce, "consume_active_ingredient() instanciou a Alface")
	assert_test(player.quick_slots[1].is_empty(), "Slot 5 esvaziado após consumo")
	assert_test(player.active_quick_slot == 0, "active_quick_slot transicionou automaticamente para o Slot 4 (Tomate)")
	if is_instance_valid(consumed_node): consumed_node.queue_free()

	print("\n=======================================================")
	print("RESULTADO DOS TESTES: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=======================================================\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS TESTES PASSARAM COM SUCESSO! <<<\n")
	else:
		printerr(">>> ALGUNS TESTES FALHARAM! <<<\n")

	quit(0 if passed_tests == total_tests else 1)
