extends SceneTree

# ================================================================
# TESTE COMPLETO E2E — REVISÃO DE MOLHOS, MONTAGEM E INTERAÇÃO
# ================================================================

func _init() -> void:
	print("\n============================================================")
	print("BURGER RUSH - TESTE E2E: MONTAGEM, MOLHO E INTERAÇÃO DE ITENS")
	print("============================================================\n")

	var world = Node3D.new()
	root.add_child(world)

	var inv = InventoryManager.new()
	world.add_child(inv)
	inv._initialize_default_inventory()

	var prog = ProgressionManager.new()
	world.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	world.add_child(player)
	player.position = Vector3(0, 0, 1.5)
	player._ready()

	# -------------------------------------------------------------
	# PASSO 1: COLOCAR PÃO NA BANCADA / ILHA
	# -------------------------------------------------------------
	print("--- Passo 1: Colocar Base do Pão no Mundo ---")
	var bread_scene = load("res://src/items/bread_bottom.tscn")
	var bread_bot = bread_scene.instantiate() as BreadBottom
	world.add_child(bread_bot)
	bread_bot.position = Vector3(0.0, 0.90, 0.0)
	bread_bot.location = Item.ItemLocation.WORLD
	bread_bot._ensure_assembly()
	assert(bread_bot.assembly != null, "Montagem inicializada")
	print("  [PASS] Base do pão posicionada no mundo.")

	# -------------------------------------------------------------
	# PASSO 2: COLOCAR CARNE SOBRE O PÃO
	# -------------------------------------------------------------
	print("\n--- Passo 2: Colocar Carne Grelhada sobre o Pão ---")
	var patty_scene = load("res://src/items/patty.tscn")
	var patty = patty_scene.instantiate() as Patty
	patty.state = Patty.State.COOKED
	world.add_child(patty)
	player.pick_up(patty)

	var hit_pos = bread_bot.global_position if bread_bot.is_inside_tree() else bread_bot.position
	bread_bot.assembly.add_ingredient(player.take_held_item(), hit_pos, 0.0)
	assert(patty.get_parent() == bread_bot.assembly, "Carne adicionada como filha de BurgerAssembly")
	assert(bread_bot.assembly.ingredients.has(patty), "Carne registrada na lista de ingredientes")
	print("  [PASS] Carne adicionada como filha direta da montagem.")

	# -------------------------------------------------------------
	# PASSO 3 & 4: CLICAR NA CARNE COM MÃOS LIVRES PEGA O LANCHE INTEIRO
	# -------------------------------------------------------------
	print("\n--- Passos 3 & 4: Clicar na Carne Seleciona e Pega o Lanche Inteiro ---")
	var target = player._get_target_interactable(patty)
	assert(target == bread_bot, "Mirar na carne resolve para a base do pão inteira")

	player.pick_up(target as Item)
	assert(player.held_item == bread_bot, "Jogador está segurando o lanche completo")
	assert(patty.get_parent() == bread_bot.assembly, "Carne não desapareceu e continua dentro da montagem")
	print("  [PASS] Carne NÃO desapareceu. Lanche inteiro pego com sucesso!")

	# -------------------------------------------------------------
	# PASSO 5: SOLTAR COM [E] EM OUTRO LOCAL
	# -------------------------------------------------------------
	print("\n--- Passo 5: Soltar o Lanche com [E] em Outro Local ---")
	player.position = Vector3(2.0, 0.0, 3.0)
	player.drop_item()
	assert(player.held_item == null, "Mão do jogador liberada")
	assert(bread_bot.location == Item.ItemLocation.WORLD, "Lanche em estado WORLD")
	assert(patty.get_parent() == bread_bot.assembly, "Carne continua presa ao lanche")
	print("  [PASS] Conjunto solto com sucesso com ingredientes intactos.")

	# -------------------------------------------------------------
	# PASSO 6, 7 & 8: PEGAR BISNAGA E APLICAR MOLHO DIRETAMENTE NO LANCHE
	# -------------------------------------------------------------
	print("\n--- Passos 6, 7 & 8: Pegar Bisnaga e Aplicar Molho na Carne ---")
	var sauce_scene = load("res://src/items/sauce_bottle.tscn")
	var ketchup_bottle = sauce_scene.instantiate() as SauceBottle
	ketchup_bottle.setup_bottle("ketchup", Color(0.85, 0.08, 0.08), "Ketchup")
	world.add_child(ketchup_bottle)
	player.pick_up(ketchup_bottle)
	assert(player.held_item == ketchup_bottle, "Jogador segurando a bisnaga de ketchup")

	ketchup_bottle.start_squeezing()
	assert(ketchup_bottle.is_squeezing, "Bisnaga espremendo")

	# Simula aplicação por 0.8s
	var burger_target_pos = bread_bot.global_position if bread_bot.is_inside_tree() else bread_bot.position
	bread_bot.assembly.apply_sauce(ketchup_bottle.sauce_type, ketchup_bottle.sauce_color, burger_target_pos, 0.8)

	assert(bread_bot.assembly.applied_sauces.has("ketchup"), "Molho registrado na montagem")
	assert(bread_bot.assembly.sauce_visuals.size() > 0, "Camada de molho visual criada")
	assert(bread_bot.assembly.sauce_visuals[0].get_parent() == bread_bot.assembly, "Molho é filho de BurgerAssembly (não pertence ao World solto)")
	print("  [PASS] Molho aplicado diretamente na carne e integrado à hierarquia do lanche.")

	# Solta a bisnaga com [E]
	player.drop_item()
	assert(player.held_item == null, "Bisnaga solta com tecla [E]")

	# -------------------------------------------------------------
	# PASSOS 9, 10 & 11: PEGAR O LANCHE COM MOLHO E MOVER
	# -------------------------------------------------------------
	print("\n--- Passos 9, 10 & 11: Mover o Lanche e Verificar que Molho Acompanha ---")
	player.pick_up(bread_bot)
	assert(player.held_item == bread_bot, "Jogador segurando o lanche")
	assert(bread_bot.assembly.sauce_visuals[0].get_parent() == bread_bot.assembly, "Molho continua no lanche quando segurado")

	player.position = Vector3(-1.0, 0.0, 4.0)
	player.drop_item()
	assert(bread_bot.assembly.sauce_visuals[0].get_parent() == bread_bot.assembly, "Molho continua no lanche após ser solto")
	print("  [PASS] Molho acompanha o lanche perfeitamente em todas as movimentações.")

	# -------------------------------------------------------------
	# PASSO 12: FECHAR E EMBALAR
	# -------------------------------------------------------------
	print("\n--- Passo 12: Fechar com Tampa e Embalar na Caixa ---")
	var top_scene = load("res://src/items/bread_top.tscn")
	var bread_top = top_scene.instantiate() as Item
	world.add_child(bread_top)
	player.pick_up(bread_top)
	bread_bot.assembly.close_burger(player.take_held_item(), burger_target_pos, 0.0)
	assert(bread_bot.assembly.state == BurgerAssembly.State.CLOSED, "Lanche fechado")

	var box_scene = load("res://src/items/burger_box.tscn")
	var box = box_scene.instantiate() as Item
	world.add_child(box)
	box._ready()
	player.pick_up(box)

	var packaged = bread_bot.assembly.package_burger(player.take_held_item(), player)
	assert(packaged != null and packaged is PackagedBurger, "Lanche embalado")
	assert(packaged.burger_name != "", "Nome do burger registrado na embalagem")
	print("  [PASS] Lanche fechado e embalado com sucesso na caixa!")

	# Limpeza
	packaged.queue_free()
	ketchup_bottle.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()
	world.queue_free()

	print("\n============================================================")
	print("TODOS OS PASSOS DO TESTE E2E FORAM 100% CONCLUÍDOS COM SUCESSO!")
	print("============================================================\n")
	quit(0)
