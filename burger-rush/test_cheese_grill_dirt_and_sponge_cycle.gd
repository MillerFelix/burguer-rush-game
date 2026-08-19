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
	print("=== TESTE: QUEIJO NA GRELHA + SUJEIRA + CICLO COMPLETO DA BUCHA ===")
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

	var grill_scene = load("res://src/stations/grill.tscn")
	var grill: Grill = grill_scene.instantiate() as Grill
	root.add_child(grill)
	grill.position = Vector3(0, 0, 0)
	grill.is_on = true
	grill.current_temperature = 180.0

	var sink_scene = load("res://src/stations/commercial_sink.tscn")
	var sink = sink_scene.instantiate()
	root.add_child(sink)
	sink.position = Vector3(3, 0, 0)

	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D") as RayCast3D

	# =========================================================================
	# TESTE A: QUEIJO NA GRELHA (SEM CRASH, COCÇÃO E RETIRADA)
	# =========================================================================
	print("\n--- TESTE A: Queijo na Grelha ---")
	var cheese_scene = load("res://src/items/cheese.tscn")
	var cheese: Cheese = cheese_scene.instantiate() as Cheese
	cheese.cheese_type = Cheese.CheeseType.CHEDDAR
	root.add_child(cheese)

	# 1. Coloca o queijo na grelha
	var placed = grill.place_item(cheese)
	assert_test(placed, "Queijo Cheddar colocado na grelha com sucesso")
	assert_test(grill.active_items.size() == 1, "Chapa contém 1 item (Queijo)")

	# 2. Simula cocção/derretimento na chapa quente
	grill._process(2.0)
	assert_test(cheese.cook_progress > 0.0, "Queijo cozinhando normalmente (cook_progress = %.1f%%)" % cheese.cook_progress)

	# 3. Verifica prompts sem nenhum erro de melt_progress
	player.active_tool_slot = Player.ToolSlot.HANDS
	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[0])
	var prompt_hands = grill.get_interaction_prompt(player)
	assert_test(prompt_hands.contains("Queijo"), "Prompt da Mão Livre exibe estado do Queijo sem erros: '%s'" % prompt_hands)

	player.active_tool_slot = Player.ToolSlot.SPATULA
	var prompt_spatula = grill.get_interaction_prompt(player)
	assert_test(prompt_spatula.contains("Queijo"), "Prompt da Espátula exibe estado do Queijo sem erros: '%s'" % prompt_spatula)

	# 4. Retira o queijo com a espátula
	grill.interact_item(player)
	assert_test(player.held_item == cheese, "Queijo retirado com sucesso para a mão do jogador")
	assert_test(grill.active_items.is_empty(), "Chapa liberada após retirada do queijo")

	# =========================================================================
	# TESTE B: OUTROS INGREDIENTES (Carne Bovina, Frango, Bacon, Ovo)
	# =========================================================================
	print("\n--- TESTE B: Outros Ingredientes na Grelha ---")
	_clear_player(player)
	_clear_grill(grill)

	var patty_scene = load("res://src/items/patty.tscn")
	var p_beef: Patty = patty_scene.instantiate() as Patty
	p_beef.meat_type = Patty.MeatType.BEEF

	var p_chick: Patty = patty_scene.instantiate() as Patty
	p_chick.meat_type = Patty.MeatType.CHICKEN

	var bacon_scene = load("res://src/items/bacon.tscn")
	var bacon: Bacon = bacon_scene.instantiate() as Bacon

	var egg_scene = load("res://src/items/egg.tscn")
	var egg: Egg = egg_scene.instantiate() as Egg

	grill.place_item(p_beef)
	grill.place_item(p_chick)
	grill.place_item(bacon)
	grill.place_item(egg)

	assert_test(grill.active_items.size() == 4, "4 Ingredientes diferentes na chapa ao mesmo tempo")

	grill._process(3.0)

	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[0])
	assert_test(grill._get_aimed_item(player).get("item") == p_beef, "Carne Bovina identificada")

	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[1])
	assert_test(grill._get_aimed_item(player).get("item") == p_chick, "Frango identificado")

	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[2])
	assert_test(grill._get_aimed_item(player).get("item") == bacon, "Bacon identificado")

	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[3])
	assert_test(grill._get_aimed_item(player).get("item") == egg, "Ovo identificado")

	# =========================================================================
	# TESTE C: FREQUÊNCIA BALANCEADA DE SUJEIRA
	# =========================================================================
	print("\n--- TESTE C: Frequência Balanceada de Sujeira ---")
	grill.dirt_level = 0.0 # Reseta sujeira para teste

	# Cozinha e retira 5 itens
	for i in range(5):
		grill.add_dirt(0.04)

	assert_test(grill.dirt_level <= 0.25, "Após 5 preparos, nível de sujeira é suave (%.2f <= 0.25)" % grill.dirt_level)
	assert_test(grill.is_dirty() == false, "Grelha NÃO fica suja prematuramente com poucos preparos")

	# Cozinha até atingir o limite natural
	for i in range(20):
		grill.add_dirt(0.04)

	assert_test(grill.is_dirty() == true, "Após ~25 preparos acumulados, a grelha atinge estado sujo (dirt_level = %.2f)" % grill.dirt_level)

	# =========================================================================
	# TESTE D: CICLO COMPLETO DA BUCHA E HIGIENIZAÇÃO NA PIA
	# =========================================================================
	print("\n--- TESTE D: Ciclo da Bucha (Limpa -> Suja -> Pia -> Limpa) ---")
	_clear_player(player)

	# 1. Equipa bucha inicialmente limpa
	player.sponge_is_dirty = false
	player.select_tool_slot(Player.ToolSlot.SPONGE, false)

	var tool_holder = player.get_node_or_null("Head/Camera3D/ToolHolder")
	var sponge: Sponge = tool_holder.get_node_or_null("Sponge") as Sponge
	assert_test(sponge != null, "Bucha instanciada no ToolHolder")
	assert_test(sponge.is_dirty == false, "Bucha inicia no estado LIMPA")
	assert_test(player.sponge_is_dirty == false, "Player registra bucha limpa")

	# 2. Executa a limpeza completa da grelha
	assert_test(grill.is_dirty() == true, "Grelha está suja antes da limpeza")

	var finished = grill.clean_progress(10.0, player) # 10s completa a limpeza
	assert_test(finished == true, "Limpeza da grelha concluída com sucesso")
	assert_test(grill.is_dirty() == false, "Grelha agora está limpa (dirt_level = 0.0)")

	# Marca a bucha como suja ao terminar a limpeza
	sponge.set_dirty()
	assert_test(sponge.is_dirty == true, "Bucha fica SUJA após concluir a limpeza da grelha")
	assert_test(player.sponge_is_dirty == true, "Player persiste estado da bucha como SUJA")

	# Troca de ferramenta e volta para a bucha: confirma que continua suja
	player.select_tool_slot(Player.ToolSlot.HANDS, false)
	player.select_tool_slot(Player.ToolSlot.SPONGE, false)
	sponge = tool_holder.get_node_or_null("Sponge") as Sponge
	assert_test(sponge.is_dirty == true, "Bucha permanece SUJA mesmo após reequipar a ferramenta")

	# 3. Leva a bucha à pia e executa lavagem
	sink.wash_or_sanitize(player)

	assert_test(sponge.is_dirty == false, "Bucha volta a ficar LIMPA após ser lavada na pia")
	assert_test(player.sponge_is_dirty == false, "Player registra estado LIMPA após lavagem na pia")

	# 4. Repete o ciclo para garantir que a bucha pode ser suja e lavada novamente
	grill.dirt_level = 1.0 # Suja a grelha novamente
	grill.clean_progress(10.0, player)
	sponge.set_dirty()
	assert_test(sponge.is_dirty == true, "Segundo Ciclo: Bucha fica suja após nova limpeza")

	sink.wash_or_sanitize(player)
	assert_test(sponge.is_dirty == false, "Segundo Ciclo: Bucha lavada na pia fica 100% limpa novamente")

	print("\n=================================================================")
	print("RESULTADO FINAL: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=================================================================\n")

	if passed_tests == total_tests:
		print(">>> SUCESSO TOTAL: QUEIJO NA GRELHA, FREQUÊNCIA DE SUJEIRA E CICLO DA BUCHA 100% VALIDADOS! <<<\n")
		quit(0)
	else:
		print(">>> FALHA NOS TESTES! <<<\n")
		quit(1)

func _set_ray_aim(ray: RayCast3D, grill: Grill, target_pos: Vector3) -> void:
	if ray:
		ray.set_meta("test_collider", grill)
		ray.set_meta("test_collision_point", target_pos)

func _clear_grill(grill: Grill) -> void:
	for item_data in grill.active_items.duplicate():
		var itm = item_data["item"]
		if is_instance_valid(itm):
			itm.queue_free()
	grill.active_items.clear()

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
