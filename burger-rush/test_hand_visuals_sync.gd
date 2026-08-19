extends SceneTree

# ================================================================
# TESTE DOS CENÁRIOS DE VISUAL DA MÃO E SLOTS RÁPIDOS
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
	print("=== INICIANDO TESTE DE SINCRONIZAÇÃO VISUAL DA MÃO ===")
	print("=======================================================\n")

	var player_scene = load("res://src/player/player.tscn")
	var player: Player = player_scene.instantiate() as Player
	root.add_child(player)

	# Setup dos slots rápidos
	var tomato = load("res://src/items/tomato.tscn").instantiate()
	var lettuce = load("res://src/items/lettuce.tscn").instantiate()
	var onion = load("res://src/items/onion.tscn").instantiate()

	player.pick_up(tomato)
	player.pick_up(lettuce)
	player.pick_up(onion)

	# --- TESTE 1 ---
	print("--- TESTE 1: Tomate -> Pegar Bandeja -> Soltar Bandeja -> Tomate Volta ---")
	player.select_quick_slot(0, false)

	assert_test(player.active_quick_slot == 0, "Slot 4 (Tomate) ativo")
	assert_test(is_instance_valid(player.quick_slot_visual) and player.quick_slot_visual.name.to_lower().contains("tomato"), "Visual do Tomate aparece na mão")

	# Pegar bandeja
	var tray = load("res://src/items/serving_tray.tscn").instantiate()
	root.add_child(tray)
	player.pick_up(tray)

	assert_test(player.held_item == tray, "Segurando a Bandeja na mão")
	assert_test(player.quick_slot_visual == null, "Visual do Tomate sumiu (mão ocupada)")

	# Soltar bandeja
	player.drop_item()
	assert_test(player.held_item == null, "Mão livre após soltar bandeja")
	assert_test(is_instance_valid(player.quick_slot_visual) and player.quick_slot_visual.name.to_lower().contains("tomato"), "Visual do Tomate voltou automaticamente para a mão")

	# --- TESTE 2 ---
	print("\n--- TESTE 2: Tomate -> Pegar Bandeja -> Selecionar Alface (Slot 5) -> Soltar Bandeja -> Alface aparece ---")
	player.select_quick_slot(0, false)
	player.pick_up(tray)

	assert_test(player.held_item == tray, "Segurando a Bandeja na mão")
	assert_test(player.quick_slot_visual == null, "Visual do Tomate ocultado")

	# Seleciona alface (Slot 5 / Índice 1) com a mão ocupada
	player.select_quick_slot(1, false)
	assert_test(player.active_quick_slot == 1, "Slot 5 (Alface) selecionado com a mão ocupada")
	assert_test(player.quick_slot_visual == null, "Visual continua ocultado enquanto segura a bandeja")

	# Soltar bandeja
	player.drop_item()
	assert_test(player.held_item == null, "Mão livre")
	assert_test(is_instance_valid(player.quick_slot_visual) and player.quick_slot_visual.name.to_lower().contains("lettuce"), "Visual da Alface apareceu automaticamente na mão")

	# --- TESTE 3 ---
	print("\n--- TESTE 3: Alface na mão -> Selecionar Cebola por Scroll/Seleção Direta ---")
	assert_test(player.active_quick_slot == 1, "Alface ativa")
	assert_test(player.quick_slot_visual.name.to_lower().contains("lettuce"), "Alface na mão")

	# Seleciona cebola (Slot 6 / Índice 2)
	player.select_quick_slot(2, false)
	assert_test(player.active_quick_slot == 2, "Cebola ativa")
	assert_test(is_instance_valid(player.quick_slot_visual) and player.quick_slot_visual.name.to_lower().contains("onion"), "Visual da Cebola apareceu imediatamente na mão")

	# --- TESTE 4 ---
	print("\n--- TESTE 4: Múltiplas unidades do mesmo ingrediente (3 tomates nos slots 4, 5, 6) ---")
	player.quick_slots[0] = {}
	player.quick_slots[1] = {}
	player.quick_slots[2] = {}
	player.active_quick_slot = -1
	player._update_quick_slot_visual()

	var t1 = load("res://src/items/tomato.tscn").instantiate()
	var t2 = load("res://src/items/tomato.tscn").instantiate()
	var t3 = load("res://src/items/tomato.tscn").instantiate()
	root.add_child(t1)
	root.add_child(t2)
	root.add_child(t3)

	player.pick_up(t1)
	assert_test(player.quick_slots[0].get("item_id") == "tomato", "Slot 4 contém Tomate 1")
	player.pick_up(t2)
	assert_test(player.quick_slots[1].get("item_id") == "tomato", "Slot 5 contém Tomate 2")
	player.pick_up(t3)
	assert_test(player.quick_slots[2].get("item_id") == "tomato", "Slot 6 contém Tomate 3")
	assert_test(player.active_quick_slot == 2, "Slot 6 (último pego) ativo logicamente")

	# --- TESTE 5 ---
	print("\n--- TESTE 5: Troca explícita para Mão Principal (Tecla 3) limpa visual mas preserva slots ---")
	player.select_quick_slot(0, false) # Seleciona Tomate no slot 4
	assert_test(is_instance_valid(player.quick_slot_visual) and player.quick_slot_visual.name.to_lower().contains("tomato"), "Visual do Tomate na mão antes da troca")

	player.select_tool_slot(Player.ToolSlot.HANDS, false) # Seleciona Mão Principal
	assert_test(player.active_quick_slot == -1, "active_quick_slot resetado para -1")
	assert_test(player.quick_slot_visual == null, "Mão física vazia (sem visual de ingrediente)")
	player.select_quick_slot(0, false) # Seleciona Tomate no slot 4
	assert_test(player.quick_slots[0].get("item_id") == "tomato", "Tomate continua armazenado no Slot 4")
	assert_test(player.quick_slots[1].get("item_id") == "tomato", "Tomate continua armazenado no Slot 5")
	assert_test(player.quick_slots[2].get("item_id") == "tomato", "Tomate continua armazenado no Slot 6")

	# --- TESTE 6 ---
	print("\n--- TESTE 6: Soltar ingrediente ativo (Tomate) no mundo ---")
	player.select_tool_slot(Player.ToolSlot.HANDS, false) # Seleciona HANDS
	player.select_quick_slot(0, false) # Seleciona Tomate do slot 4
	assert_test(is_instance_valid(player.quick_slot_visual) and player.quick_slot_visual.name.to_lower().contains("tomato"), "Visual do Tomate na mão antes do drop")

	player.drop_item() # Solta o ingrediente
	assert_test(player.quick_slots[0].is_empty(), "Slot 4 esvaziado após soltar o tomate")
	assert_test(player.active_quick_slot == 1, "active_quick_slot auto-avançou para o Slot 5")
	assert_test(is_instance_valid(player.quick_slot_visual) and player.quick_slot_visual.name.to_lower().contains("tomato"), "Próximo tomate do Slot 5 aparece automaticamente na mão")

	# --- TESTE 7 ---
	print("\n--- TESTE 7: E não solta ingrediente, mas clique esquerdo solta ---")
	player.select_quick_slot(1, false) # Seleciona Tomate no slot 5
	assert_test(player.active_quick_slot == 1, "Slot 5 ativo")

	# Simula apertar E (interact)
	player._try_interact_equipment()
	assert_test(player.active_quick_slot == 1, "Tomate continua selecionado e não foi solto com E")

	# Simula clique esquerdo (_try_interact_item) mirando em uma mesa
	var table = StaticBody3D.new()
	var col = CollisionShape3D.new()
	col.shape = BoxShape3D.new()
	col.shape.size = Vector3(2.0, 0.1, 2.0)
	table.add_child(col)
	root.add_child(table)
	table.global_position = player.global_position + Vector3(0, 0, -1)
	
	# Força a colisão do raycast
	player.raycast.global_position = player.global_position
	player.raycast.target_position = Vector3(0, 0, -2)
	player.raycast.force_raycast_update()
	
	player._try_interact_item() # Clique esquerdo solta
	assert_test(player.quick_slots[1].is_empty(), "Slot 5 esvaziado após clique esquerdo no suporte/mesa")
	assert_test(player.active_quick_slot == 2, "active_quick_slot auto-avançou para o Slot 6")
	
	# Limpeza
	table.queue_free()

	print("\n=======================================================")
	print("RESULTADO DO TESTE VISUAL: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=======================================================\n")

	if passed_tests == total_tests:
		print(">>> TODOS OS TESTES DE VISUAL PASSARAM COM SUCESSO! <<<\n")
	else:
		printerr(">>> ALGUNS TESTES DE VISUAL FALHARAM! <<<\n")

	quit(0 if passed_tests == total_tests else 1)
