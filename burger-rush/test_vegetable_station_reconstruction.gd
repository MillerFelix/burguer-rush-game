extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DA MESA DE ARMAZENAMENTO DE VERDURAS")
	print("ALFACE | TOMATE | CEBOLA ROXA | CEBOLA NORMAL | PICLES")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()
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

	print("\n--- Carregando vegetable_station.tscn ---")
	var veg_station_scene = load("res://src/stations/vegetable_station.tscn")
	assert(veg_station_scene != null, "Cena vegetable_station.tscn deve carregar")

	var veg_station = veg_station_scene.instantiate() as VegetableStation
	root.add_child(veg_station)
	veg_station._ready()

	# -----------------------------------------------------------------
	# TESTE 1: ALFACE (LETTUCE)
	# -----------------------------------------------------------------
	print("\n--- Teste 1: Pegar e Devolver Alface via Clique do Mouse ---")
	var let_slot = veg_station.get_node("LettuceSlot")
	var prompt_let = let_slot.get_interaction_prompt(player)
	assert(prompt_let.contains("Clique para Pegar") and prompt_let.contains("Alface"), "Prompt deve exibir [Clique] e Alface")
	let_slot.interact_item(player)
	assert(player.held_item != null and player.held_item is Lettuce, "Jogador pegou Alface")
	assert(inv.get_stock("lettuce") == 14, "Estoque de alface decrementou 15 -> 14")

	# Devolver Alface
	var prompt_let_ret = let_slot.get_interaction_prompt(player)
	assert(prompt_let_ret.contains("Clique para Devolver"), "Prompt deve exibir [Clique para Devolver]")
	let_slot.interact_item(player)
	assert(player.held_item == null, "Alface devolvida")
	assert(inv.get_stock("lettuce") == 15, "Estoque de alface restaurado 14 -> 15")
	print("  [PASS] Ciclo de Alface concluído com sucesso.")

	# -----------------------------------------------------------------
	# TESTE 2: TOMATE (TOMATO)
	# -----------------------------------------------------------------
	print("\n--- Teste 2: Pegar e Devolver Tomate via Clique do Mouse ---")
	var tom_slot = veg_station.get_node("TomatoSlot")
	var prompt_tom = tom_slot.get_interaction_prompt(player)
	assert(prompt_tom.contains("Clique para Pegar") and prompt_tom.contains("Tomate"), "Prompt Tomate")
	tom_slot.interact_item(player)
	assert(player.held_item != null and player.held_item is Tomato, "Jogador pegou Tomate")
	assert(inv.get_stock("tomato") == 14, "Estoque de tomate decrementou 15 -> 14")

	tom_slot.interact_item(player)
	assert(player.held_item == null, "Tomate devolvido")
	assert(inv.get_stock("tomato") == 15, "Estoque de tomate restaurado 14 -> 15")
	print("  [PASS] Ciclo de Tomate concluído com sucesso.")

	# -----------------------------------------------------------------
	# TESTE 3: CEBOLA ROXA (RED ONION)
	# -----------------------------------------------------------------
	print("\n--- Teste 3: Pegar e Devolver Cebola Roxa via Clique do Mouse ---")
	var red_oni_slot = veg_station.get_node("RedOnionSlot")
	red_oni_slot.interact_item(player)
	assert(player.held_item != null and player.held_item is Onion, "Jogador pegou Cebola")
	var red_onion_item = player.held_item as Onion
	assert(red_onion_item.onion_type == Onion.OnionType.RED, "Tipo do item é RED ONION")
	assert(inv.get_stock("red_onion") == 14, "Estoque de cebola roxa decrementou 15 -> 14")

	red_oni_slot.interact_item(player)
	assert(player.held_item == null, "Cebola roxa devolvida")
	assert(inv.get_stock("red_onion") == 15, "Estoque de cebola roxa restaurado 14 -> 15")
	print("  [PASS] Ciclo de Cebola Roxa concluído com sucesso.")

	# -----------------------------------------------------------------
	# TESTE 4: CEBOLA NORMAL (WHITE ONION)
	# -----------------------------------------------------------------
	print("\n--- Teste 4: Pegar e Devolver Cebola Normal via Clique do Mouse ---")
	var oni_slot = veg_station.get_node("WhiteOnionSlot")
	oni_slot.interact_item(player)
	assert(player.held_item != null and player.held_item is Onion, "Jogador pegou Cebola")
	var white_onion_item = player.held_item as Onion
	assert(white_onion_item.onion_type == Onion.OnionType.NORMAL, "Tipo do item é NORMAL ONION")
	assert(inv.get_stock("onion") == 14, "Estoque de cebola normal decrementou 15 -> 14")

	oni_slot.interact_item(player)
	assert(player.held_item == null, "Cebola normal devolvida")
	assert(inv.get_stock("onion") == 15, "Estoque de cebola normal restaurado 14 -> 15")
	print("  [PASS] Ciclo de Cebola Normal concluído com sucesso.")

	# -----------------------------------------------------------------
	# TESTE 5: PICLES (PICKLE)
	# -----------------------------------------------------------------
	print("\n--- Teste 5: Pegar e Devolver Picles via Clique do Mouse ---")
	var pic_slot = veg_station.get_node("PickleSlot")
	pic_slot.interact_item(player)
	assert(player.held_item != null and player.held_item is Pickle, "Jogador pegou Picles")
	assert(inv.get_stock("pickle") == 14, "Estoque de picles decrementou 15 -> 14")

	pic_slot.interact_item(player)
	assert(player.held_item == null, "Picles devolvido")
	assert(inv.get_stock("pickle") == 15, "Estoque de picles restaurado 14 -> 15")
	print("  [PASS] Ciclo de Picles concluído com sucesso.")

	# -----------------------------------------------------------------
	# TESTE 6: NÃO CONFUNDIR CEBOLAS & PROTEÇÃO DE MÃOS OCUPADAS
	# -----------------------------------------------------------------
	print("\n--- Teste 6: Distinção Rigorosa de Cebolas e Proteção de Mãos Ocupadas ---")
	# Pega cebola roxa
	red_oni_slot.interact_item(player)
	assert(player.held_item != null and (player.held_item as Onion).onion_type == Onion.OnionType.RED)

	# Tenta clicar no slot de cebola normal
	oni_slot.interact_item(player)
	assert(player.held_item != null and (player.held_item as Onion).onion_type == Onion.OnionType.RED, "Mão continua com cebola roxa intacta")
	assert(inv.get_stock("onion") == 15, "Estoque de cebola normal permanece inalterado")

	# Devolve cebola roxa no slot correto
	red_oni_slot.interact_item(player)
	assert(player.held_item == null, "Cebola roxa devolvida")
	assert(inv.get_stock("red_onion") == 15, "Estoque de cebola roxa restaurado")
	print("  [PASS] Cebola roxa e normal mantêm separação completa sem contaminação cruzada.")

	# -----------------------------------------------------------------
	# TESTE 7: INTEGRAÇÃO NA CENA MAIN.TSCN
	# -----------------------------------------------------------------
	print("\n--- Teste 7: Verificação da Mesa de Verduras em main.tscn ---")
	var main_scene = load("res://src/main.tscn")
	var main_instance = main_scene.instantiate()
	root.add_child(main_instance)

	assert(main_instance.has_node("VegetableStation"), "main.tscn deve possuir o nó VegetableStation")
	var veg_node = main_instance.get_node("VegetableStation") as Node3D
	var chest_node = main_instance.get_node("CommercialChestFreezer") as Node3D

	assert(veg_node.position.x < -8.0, "Mesa de verduras encostada na parede oeste (X = -8.6)")
	assert(veg_node.position.z > chest_node.position.z, "Mesa posicionada na parede lateral próxima aos freezers")
	print("  [PASS] VegetableStation perfeitamente posicionada e integrada ao cenário.")

	main_instance.queue_free()
	veg_station.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DA MESA DE VERDURAS FORAM APROVADOS!")
	print("============================================================")
	quit(0)
