extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE REFINAMENTO DOS SLOTS DE ARMAZENAMENTO")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()
	inv.items["bread_bottom"]["quantity"] = 25
	inv.items["bread_top"]["quantity"] = 25
	inv.items["cheese"]["quantity"] = 30
	inv.items["potato_raw"]["quantity"] = 40
	inv.items["tomato"]["quantity"] = 20
	inv.items["lettuce"]["quantity"] = 20

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	# ---------------------------------------------------------
	# TESTE 1: CAIXAS DE PAPELÃO COM ALTA DENSIDADE E ETIQUETAS
	# ---------------------------------------------------------
	print("\n--- Teste 1: Validação de Caixas de Papelão e Etiquetas Visuais ---")
	var rack_scene = load("res://src/stations/storage_rack.tscn")
	var rack = rack_scene.instantiate() as StorageRack
	root.add_child(rack)
	rack._ready()

	# Confirma que caixas de papelão existem com suas etiquetas
	assert(rack.has_node("Model/BoxBreadBottom/Label"), "Caixa da base do pão deve ter etiqueta")
	assert(rack.has_node("Model/BoxBreadTop/Label"), "Caixa da tampa do pão deve ter etiqueta")
	assert(rack.has_node("Model/BoxCheese/Label"), "Caixa do queijo deve ter etiqueta")
	assert(rack.has_node("Model/BoxPotato/Label"), "Caixa de batata deve ter etiqueta")
	assert(rack.has_node("Model/BoxTomato/Label"), "Caixa de tomate deve ter etiqueta")
	assert(rack.has_node("Model/BoxLettuce/Label"), "Caixa de alface deve ter etiqueta")

	# Confirma caixas de expansão futura
	assert(rack.has_node("Model/BoxOnion"), "Caixa de cebola (expansão) deve existir")
	assert(rack.has_node("Model/BoxBacon"), "Caixa de bacon (expansão) deve existir")
	assert(rack.has_node("Model/BoxPickle"), "Caixa de picles (expansão) deve existir")

	# Validação de espaçamento / densidade (não estão afastadas 1.2m, mas sim ~0.55m)
	var box_bread_bot = rack.get_node("Model/BoxBreadBottom") as Node3D
	var box_bread_top = rack.get_node("Model/BoxBreadTop") as Node3D
	var box_cheese = rack.get_node("Model/BoxCheese") as Node3D

	var dist_1 = abs(box_bread_top.position.x - box_bread_bot.position.x)
	var dist_2 = abs(box_cheese.position.x - box_bread_top.position.x)

	assert(dist_1 <= 0.65 and dist_1 >= 0.45, "Distância entre caixas deve ser compacta (~0.55m): dist_1 = %.2fm" % dist_1)
	assert(dist_2 <= 0.65 and dist_2 >= 0.45, "Distância entre caixas deve ser compacta (~0.55m): dist_2 = %.2fm" % dist_2)

	print("  [PASS] Caixas de papelão compactas e organizadas lado a lado com espaçamento de %.2fm!" % dist_1)

	# ---------------------------------------------------------
	# TESTE 2: ATUALIZAÇÃO DAS ETIQUETAS E RETIRADA DE INGREDIENTES
	# ---------------------------------------------------------
	print("\n--- Teste 2: Retirada de Itens e Atualização de Estoque ---")
	var label_cheese = rack.get_node("Model/BoxCheese/Label") as Label3D
	assert(label_cheese.text.contains("30"), "Etiqueta deve exibir x30 inicialmente")

	# Pega 1 queijo
	rack.active_item_index = 2 # Queijo
	rack.interact(player)
	assert(player.held_item != null and player.held_item.item_id == "cheese", "Jogador pegou queijo cheddar")
	assert(inv.get_stock("cheese") == 29, "Estoque deve ter reduzido para 29")
	assert(label_cheese.text.contains("29"), "Etiqueta deve ter atualizado para x29 (atual: %s)" % label_cheese.text)
	player.take_held_item().queue_free()

	print("  [PASS] Queijo retirado e etiqueta atualizada para x29 com sucesso!")

	# Pega 1 base de pão
	var label_bread = rack.get_node("Model/BoxBreadBottom/Label") as Label3D
	rack.active_item_index = 0 # Base Pão
	rack.interact(player)
	assert(player.held_item != null and player.held_item.item_id == "bread_bottom", "Jogador pegou base do pão")
	assert(inv.get_stock("bread_bottom") == 24, "Estoque de pão deve ter reduzido para 24")
	assert(label_bread.text.contains("24"), "Etiqueta de pão deve ter atualizado para x24 (atual: %s)" % label_bread.text)
	player.take_held_item().queue_free()

	print("  [PASS] Base de pão retirada e etiqueta atualizada para x24 com sucesso!")

	# Pega 1 tomate
	var label_tomato = rack.get_node("Model/BoxTomato/Label") as Label3D
	rack.active_item_index = 7 # Tomate
	rack.interact(player)
	assert(player.held_item != null and player.held_item.item_id == "tomato", "Jogador pegou tomate")
	assert(inv.get_stock("tomato") == 19, "Estoque de tomate deve ter reduzido para 19")
	assert(label_tomato.text.contains("19"), "Etiqueta de tomate deve ter atualizado para x19")
	player.take_held_item().queue_free()

	print("  [PASS] Tomate retirado e etiqueta atualizada para x19 com sucesso!")

	# Limpeza
	player.queue_free()
	rack.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE REFINAMENTO DOS SLOTS FORAM APROVADOS!")
	print("============================================================")
	quit(0)
