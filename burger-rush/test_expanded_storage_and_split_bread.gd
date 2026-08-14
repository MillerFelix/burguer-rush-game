extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE EXPANSÃO DA ESTANTE E PÃO DIVIDIDO (BASE E TAMPA)")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()
	inv.items["bread_bottom"]["quantity"] = 30
	inv.items["bread_top"]["quantity"] = 30
	inv.items["patty"]["quantity"] = 30
	inv.items["cheese"]["quantity"] = 30
	inv.items["tomato"]["quantity"] = 30
	inv.items["lettuce"]["quantity"] = 30

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	# ---------------------------------------------------------
	# TESTE 1: BASE E TAMPA DE PÃO INDEPENDENTES
	# ---------------------------------------------------------
	print("\n--- Teste 1: Base e Tampa de Pão Brioche Independentes ---")
	var bot_scene = load("res://src/items/bread_bottom.tscn")
	assert(bot_scene != null, "Cena bread_bottom.tscn deve existir")
	var bread_bot = bot_scene.instantiate()
	root.add_child(bread_bot)
	assert(bread_bot.item_id == "bread_bottom", "item_id deve ser bread_bottom")
	assert(bread_bot.has_node("MeshInstance3D/BottomBun"), "Base deve ter malha de pão inferior")
	assert(bread_bot.has_node("MeshInstance3D/Crumb"), "Base deve ter camada de miolo")

	var top_scene = load("res://src/items/bread_top.tscn")
	assert(top_scene != null, "Cena bread_top.tscn deve existir")
	var bread_top = top_scene.instantiate()
	root.add_child(bread_top)
	assert(bread_top.item_id == "bread_top", "item_id deve ser bread_top")
	assert(bread_top.has_node("MeshInstance3D/TopBun"), "Tampa deve ter topo abaulado brioche")
	assert(bread_top.has_node("MeshInstance3D/Sesame1"), "Tampa deve ter gergelim")

	print("  [PASS] Base e Tampa instanciadas como objetos físicos independentes com sucesso")

	# ---------------------------------------------------------
	# TESTE 2: FLUXO DE MONTAGEM (BASE -> CARNE -> QUEIJO -> VEGETAIS -> TAMPA -> PRONTO)
	# ---------------------------------------------------------
	print("\n--- Teste 2: Fluxo Real de Montagem Completa com Base e Tampa ---")
	var prep_scene = load("res://src/stations/prep_table.tscn")
	var prep_table = prep_scene.instantiate() as PrepTable
	root.add_child(prep_table)
	prep_table._ready()

	# 1. Coloca a BASE DO PÃO
	player.pick_up(bread_bot)
	assert(prep_table.get_interaction_prompt(player).contains("Base do Pão"), "Prompt deve indicar colocação da base")
	prep_table.interact(player)
	assert(prep_table.placed_items.size() == 1, "Base do pão deve estar na mesa")

	# 2. Coloca CARNE COZIDA
	var patty = load("res://src/items/patty.tscn").instantiate() as Patty
	patty.state = Patty.State.COOKED
	root.add_child(patty)
	player.pick_up(patty)
	prep_table.interact(player)
	assert(prep_table.placed_items.size() == 2, "Carne deve estar sobre a base")

	# 3. Coloca QUEIJO CHEDDAR
	var cheese = load("res://src/items/cheese.tscn").instantiate()
	root.add_child(cheese)
	player.pick_up(cheese)
	prep_table.interact(player)
	assert(prep_table.placed_items.size() == 3, "Queijo deve estar sobre a carne")

	# 4. Coloca TOMATE
	var tomato = load("res://src/items/tomato.tscn").instantiate()
	root.add_child(tomato)
	player.pick_up(tomato)
	prep_table.interact(player)

	# 5. Coloca ALFACE
	var lettuce = load("res://src/items/lettuce.tscn").instantiate()
	root.add_child(lettuce)
	player.pick_up(lettuce)
	prep_table.interact(player)

	# 6. Coloca a TAMPA DO PÃO para finalizar
	player.pick_up(bread_top)
	assert(prep_table.get_interaction_prompt(player).contains("Tampa do Pão"), "Prompt deve indicar fechamento com a tampa")
	prep_table.interact(player)

	# O hambúrguer deve ter sido finalizado como X-Salada imediatamente ao receber a tampa!
	assert(prep_table.placed_items.size() == 1, "Mesa deve conter o lanche montado finalizado")
	var finished_burger = prep_table.placed_items[0]
	assert(finished_burger.item_id == "x_salada", "Lanche finalizado com tampa deve ser um X-Salada")
	print("  [PASS] Montagem real [Base -> Carne -> Queijo -> Tomate -> Alface -> Tampa] finalizada com sucesso!")

	# ---------------------------------------------------------
	# TESTE 3: ESTANTE EXPANDIDA NO MAIN.TSCN
	# ---------------------------------------------------------
	print("\n--- Teste 3: Estante Expandida com Asa de Canto e Vãos de Expansão ---")
	var main_scene = load("res://src/main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)

	var rack = main.get_node_or_null("StorageRack") as StorageRack
	assert(rack != null, "StorageRack deve existir em main.tscn")
	assert(rack.has_node("Model/ShelfWingTop"), "Estante deve ter Prateleira de Canto Superior")
	assert(rack.has_node("Model/ShelfWingMid"), "Estante deve ter Prateleira de Canto Média")
	assert(rack.has_node("Model/ShelfWingBot"), "Estante deve ter Prateleira de Canto Inferior")
	assert(rack.has_node("Model/CrateBreadBottom"), "Estante deve ter Caixa da Base do Pão")
	assert(rack.has_node("Model/CrateBreadTop"), "Estante deve ter Caixa da Tampa do Pão")
	assert(rack.has_node("Model/CrateFreeTop"), "Estante deve ter Vão Livre para Expansão Futura")

	# Teste de pegar base e tampa diretamente da estante
	rack.active_item_index = 0 # Base
	rack.interact(player)
	assert(player.held_item != null and player.held_item.item_id == "bread_bottom", "Jogador deve pegar Base do Pão da estante")
	player.take_held_item().queue_free()

	rack.active_item_index = 1 # Tampa
	rack.interact(player)
	assert(player.held_item != null and player.held_item.item_id == "bread_top", "Jogador deve pegar Tampa do Pão da estante")
	player.take_held_item().queue_free()

	print("  [PASS] Estante expandida com asa de canto, vãos livres e suporte completo a base/tampa validada!")

	# Limpeza
	player.queue_free()
	prep_table.queue_free()
	main.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DA ESTANTE EXPANDIDA E PÃO DIVIDIDO APROVADOS!")
	print("============================================================")
	quit(0)
