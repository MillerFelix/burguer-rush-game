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
	print("=== TESTE DE PRECISÃO DE INTERAÇÃO INDIVIDUAL NA CHAPA ===")
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
	grill.current_temperature = 180.0 # Temperatura ideal de grelha

	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D") as RayCast3D

	# =========================================================================
	# TESTE 1: 4 HAMBÚRGUERES NA CHAPA — IDENTIFICAÇÃO INDIVIDUAL PELA MIRA
	# =========================================================================
	print("\n--- TESTE 1: 4 Hambúrgueres na Chapa ---")
	var patty_scene = load("res://src/items/patty.tscn")
	var p1: Patty = patty_scene.instantiate() as Patty
	var p2: Patty = patty_scene.instantiate() as Patty
	var p3: Patty = patty_scene.instantiate() as Patty
	var p4: Patty = patty_scene.instantiate() as Patty

	grill.place_item(p1)
	grill.place_item(p2)
	grill.place_item(p3)
	grill.place_item(p4)

	assert_test(grill.active_items.size() == 4, "4 Hambúrgueres colocados na chapa")

	player.active_tool_slot = Player.ToolSlot.SPATULA

	# Simula RayCast apontando para a posição exata de cada hambúrguer
	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[0])
	var target1 = grill._get_aimed_item(player)
	assert_test(target1.get("item") == p1, "Mira no Hambúrguer 1 seleciona exclusivamente o Hambúrguer 1")

	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[1])
	var target2 = grill._get_aimed_item(player)
	assert_test(target2.get("item") == p2, "Mira no Hambúrguer 2 seleciona exclusivamente o Hambúrguer 2")

	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[2])
	var target3 = grill._get_aimed_item(player)
	assert_test(target3.get("item") == p3, "Mira no Hambúrguer 3 seleciona exclusivamente o Hambúrguer 3")

	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[3])
	var target4 = grill._get_aimed_item(player)
	assert_test(target4.get("item") == p4, "Mira no Hambúrguer 4 seleciona exclusivamente o Hambúrguer 4")

	# =========================================================================
	# TESTE 2: ESTADOS DIFERENTES E INTERAÇÃO EXCLUSIVA COM O ALVO
	# =========================================================================
	print("\n--- TESTE 2: Estados Diferentes (Pronto, Virar, Grelhando, Queimado) ---")
	p1.state = Patty.State.READY_SIDE_1 # Precisa virar
	p2.state = Patty.State.COOKING_SIDE_1 # Grelhando lado 1
	p2.side_a_cooked = 40.0
	p3.state = Patty.State.COOKED # Pronto para retirar
	p4.state = Patty.State.BURNT # Queimado

	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[0])
	var prompt1 = grill.get_interaction_prompt(player)
	assert_test(prompt1.contains("VIRAR"), "Prompt do Hambúrguer 1 exibe 'VIRAR' (atual: '%s')" % prompt1)

	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[1])
	var prompt2 = grill.get_interaction_prompt(player)
	assert_test(prompt2.contains("Virar/Retirar") or prompt2.contains("Grelhando"), "Prompt do Hambúrguer 2 reflete estado de cozimento (atual: '%s')" % prompt2)

	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[2])
	var prompt3 = grill.get_interaction_prompt(player)
	assert_test(prompt3.contains("RETIRAR") and prompt3.contains("Pronto"), "Prompt do Hambúrguer 3 exibe 'RETIRAR Pronto' (atual: '%s')" % prompt3)

	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[3])
	var prompt4 = grill.get_interaction_prompt(player)
	assert_test(prompt4.contains("Queimado"), "Prompt do Hambúrguer 4 exibe 'Queimado' (atual: '%s')" % prompt4)

	# Interage exclusivamente com o Hambúrguer 1 (vira)
	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[0])
	grill.interact_item(player)

	assert_test(p1.is_flipped == true, "Apenas o Hambúrguer 1 foi virado")
	assert_test(p2.is_flipped == false and p2.state == Patty.State.COOKING_SIDE_1, "Hambúrguer 2 permaneceu inalterado")
	assert_test(p3.state == Patty.State.COOKED, "Hambúrguer 3 permaneceu inalterado")
	assert_test(p4.state == Patty.State.BURNT, "Hambúrguer 4 permaneceu inalterado")

	# =========================================================================
	# TESTE 3: INGREDIENTES DIFERENTES (Carne, Queijo, Bacon, Ovo)
	# =========================================================================
	print("\n--- TESTE 3: Ingredientes Diferentes na Chapa ---")
	_clear_grill(grill)

	var p_meat: Patty = patty_scene.instantiate() as Patty
	var cheese_scene = load("res://src/items/cheese.tscn")
	var p_cheese: Cheese = cheese_scene.instantiate() as Cheese
	var bacon_scene = load("res://src/items/bacon.tscn")
	var p_bacon: Bacon = bacon_scene.instantiate() as Bacon
	var egg_scene = load("res://src/items/egg.tscn")
	var p_egg: Egg = egg_scene.instantiate() as Egg

	grill.place_item(p_meat)
	grill.place_item(p_cheese)
	grill.place_item(p_bacon)
	grill.place_item(p_egg)

	p_bacon.state = Bacon.State.COOKED
	p_egg.state = Egg.State.COOKED
	p_cheese.state = Cheese.State.READY
	p_cheese.cook_progress = 100.0

	assert_test(grill.active_items.size() == 4, "Carne, Queijo, Bacon e Ovo na mesma chapa")

	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[0])
	assert_test(grill._get_aimed_item(player).get("item") == p_meat, "Mira na Carne seleciona exclusivamente a Carne")

	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[1])
	assert_test(grill._get_aimed_item(player).get("item") == p_cheese, "Mira no Queijo seleciona exclusivamente o Queijo")
	var prompt_c = grill.get_interaction_prompt(player)
	assert_test(prompt_c.contains("Queijo"), "Prompt do Queijo exibe 'Queijo' (atual: '%s')" % prompt_c)

	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[2])
	assert_test(grill._get_aimed_item(player).get("item") == p_bacon, "Mira no Bacon seleciona exclusivamente o Bacon")
	var prompt_b = grill.get_interaction_prompt(player)
	assert_test(prompt_b.contains("Bacon"), "Prompt do Bacon exibe 'Bacon' (atual: '%s')" % prompt_b)

	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[3])
	assert_test(grill._get_aimed_item(player).get("item") == p_egg, "Mira no Ovo seleciona exclusivamente o Ovo")
	var prompt_e = grill.get_interaction_prompt(player)
	assert_test(prompt_e.contains("Ovo"), "Prompt do Ovo exibe 'Ovo' (atual: '%s')" % prompt_e)

	# =========================================================================
	# TESTE 4 & 5: MOVER A MIRA E RETIRADA INDIVIDUAL
	# =========================================================================
	print("\n--- TESTE 4 & 5: Mover a Mira e Retirada Individual ---")
	_clear_player(player)

	# Retira apenas o Bacon com a espátula
	_set_ray_aim(ray, grill, grill.SLOT_OFFSETS[2])
	grill.interact_item(player)

	assert_test(player.held_item == p_bacon, "Bacon retirado individualmente para a mão do jogador")
	assert_test(grill.active_items.size() == 3, "Chapa mantém exatamente os outros 3 ingredientes (Carne, Queijo, Ovo)")

	var remaining_items = grill.active_items.map(func(it): return it["item"])
	assert_test(remaining_items.has(p_meat), "Carne permanece na chapa")
	assert_test(remaining_items.has(p_cheese), "Queijo permanece na chapa")
	assert_test(remaining_items.has(p_egg), "Ovo permanece na chapa")
	assert_test(not remaining_items.has(p_bacon), "Bacon removido da lista da chapa")

	print("\n=================================================================")
	print("RESULTADO FINAL: %d/%d APROVADOS" % [passed_tests, total_tests])
	print("=================================================================\n")

	if passed_tests == total_tests:
		print(">>> SUCESSO TOTAL: PRECISÃO INDIVIDUAL NA CHAPA 100% VALIDADA! <<<\n")
		quit(0)
	else:
		print(">>> FALHA NOS TESTES! <<<\n")
		quit(1)

func _set_ray_aim(ray: RayCast3D, grill: Grill, target_pos: Vector3) -> void:
	if ray:
		# Define colisor como a chapa e ponto de impacto exatamente na posição do item
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
	player.active_tool_slot = Player.ToolSlot.SPATULA
	if player.held_item != null:
		if is_instance_valid(player.held_item) and player.held_item.get_parent():
			player.held_item.get_parent().remove_child(player.held_item)
		player.held_item = null
