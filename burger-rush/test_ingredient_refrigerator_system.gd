extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DA NOVA GELADEIRA DE HORTIFRÚTI & BATATAS")
	print("4 ANDARES: BATATA CONGELADA | ALFACE & TOMATE | CEBOLAS | PICLES")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()
	inv.items["potato_raw"]["quantity"] = 25
	inv.items["lettuce"]["quantity"] = 15
	inv.items["tomato"]["quantity"] = 15
	inv.items["red_onion"]["quantity"] = 15
	inv.items["onion"]["quantity"] = 15
	inv.items["pickle"]["quantity"] = 15

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	print("\n--- Carregando ingredient_refrigerator.tscn ---")
	var fridge_scene = load("res://src/stations/ingredient_refrigerator.tscn")
	assert(fridge_scene != null, "Cena ingredient_refrigerator.tscn deve carregar com sucesso")

	var fridge = fridge_scene.instantiate() as IngredientRefrigerator
	root.add_child(fridge)
	fridge._ready()

	# -----------------------------------------------------------------
	# TESTE 1: PORTA DA GELADEIRA (TECLA E)
	# -----------------------------------------------------------------
	print("\n--- Teste 1: Funcionamento da Porta via Tecla E ---")
	assert(not fridge.is_door_open(), "Geladeira deve iniciar fechada")
	var door_body = fridge.get_node("DoorPivot/DoorBody")

	var prompt_door = door_body.get_interaction_prompt(player)
	assert(prompt_door.contains("Abrir Geladeira"), "Prompt da porta fechada deve ser [Abrir]")

	# Abrir
	fridge._apply_state_instant(true)
	assert(fridge.is_door_open(), "Geladeira aberta com sucesso")
	var prompt_door_open = door_body.get_interaction_prompt(player)
	assert(prompt_door_open.contains("Fechar Geladeira"), "Prompt da porta aberta deve ser [Fechar]")

	# -----------------------------------------------------------------
	# TESTE 2: ANDAR 1 (INFERIOR) — SACOS DE BATATA CONGELADA
	# -----------------------------------------------------------------
	print("\n--- Teste 2: Andar 1 — Saco Grande de Batata Frita Congelada ---")
	var pot_slot = fridge.get_node("PotatoSlot")
	var prompt_pot = pot_slot.get_interaction_prompt(player)
	assert(prompt_pot.contains("Batata") and prompt_pot.contains("Clique"), "Prompt de batata deve indicar [Clique]")
	pot_slot.interact_item(player)
	assert(player.held_item != null and player.held_item is Potato, "Jogador deve segurar Potato")
	var held_pot = player.held_item as Potato
	assert(held_pot.state == Potato.State.RAW, "Estado da batata deve ser RAW (Saco Congelado)")
	assert(inv.get_stock("potato_raw") == 24, "Estoque de batata raw decrementou 25 -> 24")

	# Devolver saco
	pot_slot.interact_item(player)
	assert(player.held_item == null, "Saco de batata devolvido à geladeira")
	assert(inv.get_stock("potato_raw") == 25, "Estoque restaurado 24 -> 25")
	print("  [PASS] Andar 1 (Batatas Congeladas) 100% validado.")

	# -----------------------------------------------------------------
	# TESTE 3: ANDAR 2 — ALFACE E TOMATE
	# -----------------------------------------------------------------
	print("\n--- Teste 3: Andar 2 — Alface e Tomate ---")
	var let_slot = fridge.get_node("LettuceSlot")
	let_slot.interact_item(player)
	assert(player.held_item != null and player.held_item is Lettuce, "Jogador pegou Alface")
	assert(inv.get_stock("lettuce") == 14, "Estoque de alface 15 -> 14")
	let_slot.interact_item(player)
	assert(player.held_item == null, "Alface devolvida")
	assert(inv.get_stock("lettuce") == 15, "Estoque de alface 14 -> 15")

	var tom_slot = fridge.get_node("TomatoSlot")
	tom_slot.interact_item(player)
	assert(player.held_item != null and player.held_item is Tomato, "Jogador pegou Tomate")
	assert(inv.get_stock("tomato") == 14, "Estoque de tomate 15 -> 14")
	tom_slot.interact_item(player)
	assert(player.held_item == null, "Tomate devolvido")
	assert(inv.get_stock("tomato") == 15, "Estoque de tomate 14 -> 15")
	print("  [PASS] Andar 2 (Alface & Tomate) 100% validado.")

	# -----------------------------------------------------------------
	# TESTE 4: ANDAR 3 — CEBOLA ROXA E CEBOLA NORMAL
	# -----------------------------------------------------------------
	print("\n--- Teste 4: Andar 3 — Cebola Roxa e Cebola Normal Fatiadas ---")
	var red_oni_slot = fridge.get_node("RedOnionSlot")
	red_oni_slot.interact_item(player)
	assert(player.held_item != null and player.held_item is Onion, "Jogador pegou Cebola")
	var red_onion_item = player.held_item as Onion
	assert(red_onion_item.onion_type == Onion.OnionType.RED, "Tipo de cebola é RED ONION")
	assert(inv.get_stock("red_onion") == 14, "Estoque cebola roxa 15 -> 14")
	red_oni_slot.interact_item(player)
	assert(player.held_item == null, "Cebola roxa devolvida")
	assert(inv.get_stock("red_onion") == 15, "Estoque cebola roxa 14 -> 15")

	var white_oni_slot = fridge.get_node("WhiteOnionSlot")
	white_oni_slot.interact_item(player)
	assert(player.held_item != null and player.held_item is Onion, "Jogador pegou Cebola")
	var white_onion_item = player.held_item as Onion
	assert(white_onion_item.onion_type == Onion.OnionType.NORMAL, "Tipo de cebola é NORMAL ONION")
	assert(inv.get_stock("onion") == 14, "Estoque cebola normal 15 -> 14")
	white_oni_slot.interact_item(player)
	assert(player.held_item == null, "Cebola normal devolvida")
	assert(inv.get_stock("onion") == 15, "Estoque cebola normal 14 -> 15")
	print("  [PASS] Andar 3 (Cebola Roxa & Cebola Normal) 100% validado.")

	# -----------------------------------------------------------------
	# TESTE 5: ANDAR 4 (SUPERIOR) — PICLES
	# -----------------------------------------------------------------
	print("\n--- Teste 5: Andar 4 (Superior) — Picles em Fatias Pequenas ---")
	var pic_slot = fridge.get_node("PickleSlot")
	pic_slot.interact_item(player)
	assert(player.held_item != null and player.held_item is Pickle, "Jogador pegou Picles")
	assert(inv.get_stock("pickle") == 14, "Estoque de picles 15 -> 14")
	pic_slot.interact_item(player)
	assert(player.held_item == null, "Picles devolvido")
	assert(inv.get_stock("pickle") == 15, "Estoque de picles 14 -> 15")
	print("  [PASS] Andar 4 (Picles) 100% validado.")

	# -----------------------------------------------------------------
	# TESTE 6: PROTEÇÃO DE MÃOS OCUPADAS E NÃO MISTURA DE ITENS
	# -----------------------------------------------------------------
	print("\n--- Teste 6: Proteção de Mãos Ocupadas ---")
	red_oni_slot.interact_item(player)
	assert(player.held_item != null and (player.held_item as Onion).onion_type == Onion.OnionType.RED)

	# Tentar clicar no slot de batatas
	pot_slot.interact_item(player)
	assert(player.held_item != null and (player.held_item as Onion).onion_type == Onion.OnionType.RED, "Mão continua intacta com a cebola roxa")
	assert(inv.get_stock("potato_raw") == 25, "Estoque de batata permaneceu inalterado")

	# Devolver cebola roxa
	red_oni_slot.interact_item(player)
	assert(player.held_item == null)
	print("  [PASS] Proteção contra mistura acidental e duplicação aprovada.")

	# -----------------------------------------------------------------
	# TESTE 7: PORTA FECHADA BLOQUEIA ACESSO AOS SLOTS
	# -----------------------------------------------------------------
	print("\n--- Teste 7: Fechar Porta e Validar Bloqueio ---")
	fridge._apply_state_instant(false)
	assert(not fridge.is_door_open())
	var prompt_closed_slot = pot_slot.get_interaction_prompt(player)
	assert(prompt_closed_slot == "", "Com a porta fechada, slots de itens não geram prompt")
	print("  [PASS] Bloqueio físico e lógico da porta fechada aprovado.")

	# -----------------------------------------------------------------
	# TESTE 8: INTEGRAÇÃO NA CENA PRINCIPAL MAIN.TSCN
	# -----------------------------------------------------------------
	print("\n--- Teste 8: Verificação de main.tscn ---")
	var main_scene = load("res://src/main.tscn")
	var main_instance = main_scene.instantiate()
	root.add_child(main_instance)

	assert(main_instance.has_node("IngredientRefrigerator"), "main.tscn deve possuir IngredientRefrigerator")
	assert(not main_instance.has_node("VegetableStation"), "main.tscn NÃO deve possuir VegetableStation antiga")

	var ing_fridge_node = main_instance.get_node("IngredientRefrigerator") as Node3D
	assert(ing_fridge_node.position.x < -8.0, "Geladeira encostada na parede oeste")
	print("  [PASS] Integração e posicionamento da nova geladeira no armazém validados.")

	main_instance.queue_free()
	fridge.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DA NOVA GELADEIRA DE HORTIFRÚTI PASSARAM!")
	print("============================================================")
	quit(0)
