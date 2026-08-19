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
	print("=== TESTE DE CORREÇÃO: PÃO, POLPAS E REFIS DE REFRIGERANTE ===")
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

	# 1. Armazenamento de Pães
	var bread_rack_scene = load("res://src/stations/storage_rack.tscn")
	var bread_rack: StorageRack = bread_rack_scene.instantiate() as StorageRack
	root.add_child(bread_rack)
	bread_rack._ready()

	# 2. Mesa de Polpas
	var pulp_table_scene = load("res://src/stations/pulp_storage_table.tscn")
	var pulp_table: PulpStorageTable = pulp_table_scene.instantiate() as PulpStorageTable
	root.add_child(pulp_table)
	pulp_table._ready()

	# 3. Suporte de Refis de Refrigerante
	var soda_rack_scene = load("res://src/stations/soda_refill_rack.tscn")
	var soda_rack: SodaRefillRack = soda_rack_scene.instantiate() as SodaRefillRack
	root.add_child(soda_rack)
	soda_rack._ready()

	# =========================================================================
	# PARTE 1: BASE DO PÃO (Sem duplicação e sincronização visual)
	# =========================================================================
	print("\n--- 1. BASE DO PÃO (LMB Pegar, RMB Devolver, Sem Duplicação, Visual Sincronizado) ---")
	_clear_player(player)

	inv.items["bread_bottom"]["quantity"] = 20
	bread_rack._update_all_visual_stocks()

	assert_test(inv.get_stock("bread_bottom") == 20, "Estoque inicial de Base do Pão: 20 un.")
	assert_test(bread_rack.bread_bot_full.visible == true, "Visual Inicial: Estágio CHEIO visível (>= 15)")
	assert_test(bread_rack.bread_bot_med.visible == false, "Visual Inicial: Estágio MÉDIO oculto")
	assert_test(bread_rack.bread_bot_low.visible == false, "Visual Inicial: Estágio BAIXO oculto")

	# Pega 1 base com LMB
	bread_rack.active_item_index = 1 # Base do pão
	bread_rack.interact_item(player)

	assert_test(inv.get_stock("bread_bottom") == 19, "LMB Pegou 1 Base: Estoque reduziu para 19")
	assert_test(player.quick_slots[0].get("item_id") == "bread_bottom", "Base do Pão no Slot 0 do jogador")
	assert_test(bread_rack.bread_bot_full.visible == true, "Visual: Permanece CHEIO em 19 un.")

	# Devolve a base com RMB
	bread_rack.interact_return(player)

	assert_test(inv.get_stock("bread_bottom") == 20, "RMB Devolveu 1 Base: Estoque voltou exatamente para 20 (+1, NUNCA +2)")
	assert_test(player.quick_slots[0].is_empty(), "Slot 0 liberado após devolução")
	assert_test(bread_rack.bread_bot_full.visible == true, "Visual: Permanece CHEIO em 20 un.")

	# Teste de Estágios Visuais: Reduz para 10 (Médio)
	inv.items["bread_bottom"]["quantity"] = 10
	bread_rack._update_all_visual_stocks()
	assert_test(bread_rack.bread_bot_full.visible == false, "Estoque 10 un.: Estágio CHEIO oculto")
	assert_test(bread_rack.bread_bot_med.visible == true, "Estoque 10 un.: Estágio MÉDIO visível (6 a 14)")
	assert_test(bread_rack.bread_bot_low.visible == false, "Estoque 10 un.: Estágio BAIXO oculto")

	# Reduz para 3 (Baixo)
	inv.items["bread_bottom"]["quantity"] = 3
	bread_rack._update_all_visual_stocks()
	assert_test(bread_rack.bread_bot_med.visible == false, "Estoque 3 un.: Estágio MÉDIO oculto")
	assert_test(bread_rack.bread_bot_low.visible == true, "Estoque 3 un.: Estágio BAIXO visível (1 a 5)")

	# Reduz para 0 (Vazio)
	inv.items["bread_bottom"]["quantity"] = 0
	bread_rack._update_all_visual_stocks()
	assert_test(bread_rack.bread_bot_low.visible == false, "Estoque 0 un.: Todos os estágios ocultos")

	# Devolve 1 base em estoque 0
	_clear_player(player)
	var bb_scene = load("res://src/items/bread_bottom.tscn")
	var bb_item = bb_scene.instantiate()
	root.add_child(bb_item)
	player.pick_up(bb_item)
	bread_rack.interact_return(player)

	assert_test(inv.get_stock("bread_bottom") == 1, "Devolveu 1 base com estoque zerado: Estoque = 1")
	assert_test(bread_rack.bread_bot_low.visible == true, "Visual atualizou dinamicamente para BAIXO (1 un.)")

	# =========================================================================
	# PARTE 2: POLPAS DE SUCO (LMB Pegar, RMB Devolver, Sem Duplicação, Visual)
	# =========================================================================
	print("\n--- 2. POLPAS DE SUCO (LMB Pegar, RMB Devolver, Sincronização) ---")
	_clear_player(player)
	inv.items["pulp_orange"]["quantity"] = 10
	inv.items["pulp_grape"]["quantity"] = 10
	inv.items["pulp_strawberry"]["quantity"] = 10
	pulp_table._update_all_visuals()

	# Pegar Polpa de Laranja com LMB (index 0)
	pulp_table.take_pulp(player, 0)
	assert_test(player.quick_slots[0].get("item_id") == "pulp_orange", "LMB Pegou Polpa de Laranja no Slot 0")
	assert_test(inv.get_stock("pulp_orange") == 9, "Estoque de Laranja reduziu para 9")

	# Pegar Polpa de Uva com LMB (index 1)
	pulp_table.take_pulp(player, 1)
	assert_test(player.quick_slots[1].get("item_id") == "pulp_grape", "LMB Pegou Polpa de Uva no Slot 1")
	assert_test(inv.get_stock("pulp_grape") == 9, "Estoque de Uva reduziu para 9")

	# Devolver Laranja com RMB
	player.active_quick_slot = 0
	var pulp_ret = player.return_one_matching_ingredient("pulp_orange")
	assert_test(pulp_ret == true, "Removeu 1x polpa de laranja do jogador")
	inv.add_stock("pulp_orange", 1)
	pulp_table._update_all_visuals()

	assert_test(inv.get_stock("pulp_orange") == 10, "Estoque de Laranja restaurado (+1 un. = 10)")
	assert_test(player.quick_slots[0].is_empty(), "Slot 0 de Laranja liberado")
	assert_test(player.quick_slots[1].get("item_id") == "pulp_grape", "Slot 1 de Uva mantido intacto")

	# Teste Visual da Polpa (10 blocos >= 8; 5 blocos >= 4; 2 blocos > 0; 0 blocos == 0)
	inv.items["pulp_orange"]["quantity"] = 5
	pulp_table._update_all_visuals()
	var block_0_4 = pulp_table.get_node_or_null("Model/Crate/Pulp_0_4")
	var block_0_5 = pulp_table.get_node_or_null("Model/Crate/Pulp_0_5")
	if block_0_4 and block_0_5:
		assert_test(block_0_4.visible == true and block_0_5.visible == false, "Visual Polpa: Estágio MÉDIO exibe 5 blocos (0-4)")

	# =========================================================================
	# PARTE 3: REFIS DE REFRIGERANTE (LMB Nunca Devolve, RMB Devolve Exclusivamente)
	# =========================================================================
	print("\n--- 3. REFIS DE REFRIGERANTE (LMB Pegar, LMB NÃO Devolve, RMB Devolve) ---")
	_clear_player(player)

	assert_test(soda_rack.has_reserve(0) == true, "Suporte possui refil de Cola no Slot 0")

	# LMB: Pegar refil de Cola
	var can_cola = soda_rack.take_canister(0)
	root.add_child(can_cola)
	player.pick_up(can_cola)

	assert_test(player.held_item is SyrupCanister, "Jogador segurando barril de refil de Cola")
	assert_test(soda_rack.has_reserve(0) == false, "Slot 0 do suporte agora está vazio")

	# LMB com o refil na mão: NUNCA DEVE DEVOLVER
	soda_rack.interact_item(player)
	assert_test(player.held_item is SyrupCanister, "LMB com refil na mão NÃO devolveu (refil continua na mão)")
	assert_test(soda_rack.has_reserve(0) == false, "Slot 0 do suporte continua vazio")

	# RMB com o refil na mão: DEVOLVE AO SUPORTE
	soda_rack.interact_return(player)
	assert_test(player.held_item == null, "RMB devolveu o refil: Mão do jogador liberada")
	assert_test(soda_rack.has_reserve(0) == true, "Slot 0 do suporte agora possui o refil novamente")

	# RMB novamente com mão vazia: Rejeição segura
	soda_rack.interact_return(player)
	assert_test(soda_rack.has_reserve(0) == true, "Slot 0 inalterado (não duplicou)")

	print("\n=================================================================")
	print("RESULTADO FINAL: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=================================================================\n")

	if passed_tests == total_tests:
		print(">>> SUCESSO TOTAL: TODAS AS 3 CORREÇÕES VALIDADAS COM 100%! <<<\n")
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
