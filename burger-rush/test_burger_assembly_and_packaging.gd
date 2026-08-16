extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE MONTAGEM TOTALMENTE LIVRE E EMBALAGEM")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var world = Node3D.new()
	root.add_child(world)

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	world.add_child(player)
	player._ready()

	# =========================================================================
	# TESTE 1: BASE DO PÃO COLOCADA EM QUALQUER SUPERFÍCIE (NÃO DESAPARECE)
	# =========================================================================
	print("\n--- Teste 1: Base do Pão Física no Mundo (Permanece Visível) ---")
	var bread_bot_scene = load("res://src/items/bread_bottom.tscn")
	var bread_bot = bread_bot_scene.instantiate() as BreadBottom
	world.add_child(bread_bot)
	bread_bot._ready()
	var free_table_pos = Vector3(4.5, 0.90, 2.0)
	bread_bot.position = free_table_pos
	bread_bot.location = Item.ItemLocation.WORLD

	assert(bread_bot.get_parent() == world, "Pão base deve estar presente e visível na árvore de nós")
	assert(bread_bot.assembly != null, "Pão base deve inicializar seu componente de montagem interno")
	assert(bread_bot.assembly.state == BurgerAssembly.State.EMPTY, "Montagem inicializada no estado EMPTY")
	print("  [PASS] Base do pão permanece visível e funcional em qualquer superfície do mundo.")

	# =========================================================================
	# TESTE 2: ADIÇÃO FÍSICA COMO FILHO DA MONTAGEM (HIERARQUIA UNIFICADA)
	# =========================================================================
	print("\n--- Teste 2: Adição Sequencial de Ingredientes como Filhos da Montagem ---")
	var ingredients_to_add = [
		{"id": "patty", "scene": "res://src/items/patty.tscn", "state": Patty.State.COOKED, "name": "Carne Grelhada"},
		{"id": "cheese", "scene": "res://src/items/cheese.tscn", "state": 0, "name": "Queijo Cheddar"},
		{"id": "lettuce", "scene": "res://src/items/lettuce.tscn", "state": 0, "name": "Alface"},
		{"id": "tomato", "scene": "res://src/items/tomato.tscn", "state": 0, "name": "Tomate"},
		{"id": "onion", "scene": "res://src/items/onion.tscn", "state": 0, "name": "Cebola"}
	]

	var prev_height = bread_bot.assembly.current_stack_height

	for ing_info in ingredients_to_add:
		var ing_item = load(ing_info["scene"]).instantiate() as Item
		if "state" in ing_item and ing_info.has("state"):
			ing_item.set("state", ing_info["state"])
		world.add_child(ing_item)
		player.pick_up(ing_item)

		var hit_coord = (bread_bot.global_position if bread_bot.is_inside_tree() else bread_bot.position) + Vector3(0.01, 0.0, -0.01)
		var ok = bread_bot.assembly.add_ingredient(player.take_held_item(), hit_coord, 0.0)
		assert(ok, "Ingrediente %s adicionado" % ing_info["name"])
		assert(ing_item.get_parent() == bread_bot.assembly, "Ingrediente deve ser filho de BurgerAssembly")
		assert(bread_bot.assembly.current_stack_height > prev_height, "Altura da pilha avançou")
		prev_height = bread_bot.assembly.current_stack_height
		print("  [PASS] %s empilhado na hierarquia da montagem. Altura: %.3fm." % [ing_info["name"], prev_height])

	# Aplica molhos físicos que passam a ser filhos da montagem
	var bot_pos = bread_bot.global_position if bread_bot.is_inside_tree() else bread_bot.position
	bread_bot.assembly.apply_sauce("ketchup", Color(0.85, 0.1, 0.1), bot_pos, 2.0)
	bread_bot.assembly.apply_sauce("mustard", Color(0.9, 0.7, 0.1), bot_pos, 2.0)
	assert(bread_bot.assembly.applied_sauces.has("ketchup") and bread_bot.assembly.applied_sauces.has("mustard"), "Ketchup e Mostarda aplicados")
	assert(bread_bot.assembly.sauce_visuals.size() > 0, "Visual de molho instanciado")
	assert(bread_bot.assembly.sauce_visuals[0].get_parent() == bread_bot.assembly, "Molho deve ser filho de BurgerAssembly")
	print("  [PASS] Molhos aplicados e vinculados à montagem do lanche.")

	# =========================================================================
	# TESTE 3: INTERAÇÃO NO INGREDIENTE PEGA O LANCHE INTEIRO
	# =========================================================================
	print("\n--- Teste 3: Clicar no Ingrediente Seleciona e Pega o Lanche Inteiro ---")
	var target_patty = bread_bot.assembly.ingredients[0]
	var target_burger = player._get_target_interactable(target_patty)
	assert(target_burger == bread_bot, "Mirar na carne resolve para a base do pão inteira")

	player.pick_up(target_burger as Item)
	assert(player.held_item == bread_bot, "Jogador segurando o lanche completo")
	assert(target_patty.get_parent() == bread_bot.assembly, "Carne continua filha da montagem nas mãos do jogador")
	print("  [PASS] Lanche completo pego na mão do jogador (nenhum ingrediente se perdeu).")

	# Solta o lanche em outra posição com drop_item (tecla E)
	player.drop_item()
	assert(player.held_item == null, "Jogador soltou o lanche")
	assert(bread_bot.location == Item.ItemLocation.WORLD, "Lanche voltou ao estado WORLD")
	assert(target_patty.get_parent() == bread_bot.assembly, "Carne continua presa ao lanche após drop")
	print("  [PASS] Lanche solto com sucesso com todos os ingredientes e molhos acompanhando.")

	# =========================================================================
	# TESTE 4: FECHAMENTO COM TAMPA DO PÃO E RECONHECIMENTO DE RECEITA
	# =========================================================================
	print("\n--- Teste 4: Fechamento com Tampa do Pão e Validação da Receita ---")
	var bread_top_scene = load("res://src/items/bread_top.tscn")
	var bread_top = bread_top_scene.instantiate() as Item
	world.add_child(bread_top)
	player.pick_up(bread_top)

	bread_bot.assembly.close_burger(player.take_held_item(), bot_pos, 0.0)
	assert(bread_bot.assembly.state == BurgerAssembly.State.CLOSED, "Lanche fechado com sucesso")
	assert(bread_bot.assembly.matched_recipe != null, "Receita reconhecida com sucesso")
	print("  [PASS] Lanche fechado! Receita identificada: '%s'." % bread_bot.assembly.matched_recipe.display_name)

	# =========================================================================
	# TESTE 5: EMBALAGEM DIRETA COM CAIXA FECHADA
	# =========================================================================
	print("\n--- Teste 5: Embalagem Direta do Burger Montado ---")
	var box_scene = load("res://src/items/burger_box.tscn")
	var box = box_scene.instantiate() as Item
	world.add_child(box)
	box._ready()
	player.pick_up(box)

	var packaged_burger = bread_bot.assembly.package_burger(player.take_held_item(), player)
	assert(packaged_burger != null and packaged_burger is PackagedBurger, "PackagedBurger criado com sucesso")
	print("  [PASS] Lanche embalado com sucesso contendo receita e ingredientes.")

	# =========================================================================
	# TESTE 6: RETIRADA COM CLIQUE ESQUERDO
	# =========================================================================
	print("\n--- Teste 6: Retirada do Lanche Embalado com Clique Esquerdo ---")
	player.pick_up(packaged_burger)
	assert(player.held_item == packaged_burger, "Jogador segurando o Burger Clássico Embalado")
	player.take_held_item().queue_free()
	print("  [PASS] Produto final pego pelo jogador com sucesso.")

	# Limpeza
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE MONTAGEM LIVRE FORAM CONCLUÍDOS COM SUCESSO!")
	print("============================================================")
	quit(0)
