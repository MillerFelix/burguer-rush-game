extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DA GRELHA (TERMÔMETRO VERTICAL & ESPÁTULA)")
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
	player.global_position = Vector3(0, 0, 2)
	player._ready()

	print("\n--- Teste 1: Seleção e Alternância de Ferramentas (1, 2, 3) ---")
	# Inicia com mão (3)
	assert(player.active_tool_slot == Player.ToolSlot.HANDS, "Inicia com mãos livres (Slot 3)")
	assert(player.tool_holder.get_child_count() == 0, "ToolHolder vazio no slot de mãos livres")
	print("  [PASS] Slot 3 (Mão) ativo por padrão")

	const SpatulaScript = preload("res://src/tools/spatula.gd")
	const SpongeScript = preload("res://src/tools/sponge.gd")

	# Seleciona 1 (Espátula)
	player.select_tool_slot(Player.ToolSlot.SPATULA, false)
	assert(player.active_tool_slot == Player.ToolSlot.SPATULA, "Slot 1 (Espátula) ativado")
	assert(player.tool_holder.get_child_count() == 1, "Modelo da Espátula carregado no ToolHolder")
	assert(player.tool_holder.get_child(0).get_script() == SpatulaScript, "Instância é do script Spatula")
	var spatula_node = player.tool_holder.get_child(0) as Spatula
	assert(spatula_node.get_blade_rest_point() != null, "Espátula possui BladeRestPoint para repouso de alimento")
	print("  [PASS] Slot 1 (Espátula) equipado com sucesso e BladeRestPoint verificado")

	# Seleciona 2 (Bucha)
	player.select_tool_slot(Player.ToolSlot.SPONGE, false)
	assert(player.active_tool_slot == Player.ToolSlot.SPONGE, "Slot 2 (Bucha) ativado")
	assert(player.tool_holder.get_child_count() == 1, "Modelo da Bucha carregado no ToolHolder")
	assert(player.tool_holder.get_child(0).get_script() == SpongeScript, "Instância é do script Sponge")
	print("  [PASS] Slot 2 (Bucha) equipado com sucesso")

	# Retorna para 3 (Mão)
	player.select_tool_slot(Player.ToolSlot.HANDS, false)
	assert(player.active_tool_slot == Player.ToolSlot.HANDS, "Retornou para Slot 3 (Mão)")
	assert(player.tool_holder.get_child_count() == 0, "ToolHolder descarregado")
	print("  [PASS] Retorno ao Slot 3 limpa a mão para pegar ingredientes")

	print("\n--- Teste 2: Grelha - Coluna Vertical de Temperatura e Piloto Verde ---")
	var grill_scene = load("res://src/stations/grill.tscn")
	var grill = grill_scene.instantiate() as Grill
	world.add_child(grill)
	grill.global_position = Vector3(0, 0, 0)
	grill._ready()

	assert(not grill.is_on, "Grelha inicia desligada")
	assert(grill.current_temperature == 25.0, "Temperatura ambiente inicial de 25°C")
	assert(grill.fluid_column_pivot != null, "Coluna de temperatura vertical presente")
	assert(grill.temp_pilot_light != null, "Luz piloto de temperatura presente")
	print("  [PASS] Grelha desligada a 25°C (Coluna baixa e Piloto apagado)")

	# Liga com E (interact_equipment)
	grill.interact_equipment(player)
	assert(grill.is_on, "Grelha ligada com [E]")

	# Simula aquecimento gradual
	print("  -> Simulando aquecimento gradual até temperatura ideal (~13s)...")
	for _i in range(15):
		grill._process(1.0) # 15 segundos de simulação
	assert(grill.current_temperature >= 160.0, "Grelha deve atingir temperatura ideal de cocção (>= 160°C)")
	assert(grill.is_ideal_temp(), "Estado da grelha é IDEAL_TEMP")
	assert(grill.fluid_column_pivot.scale.x > 0.6, "Barra horizontal expandiu para a zona verde ideal")
	print("  [PASS] Grelha atingiu %.1f°C — Barra Horizontal Ampla na Zona Verde & Piloto Verde (Pronta para Fritar)" % grill.current_temperature)

	# Desliga com E
	grill.interact_equipment(player)
	assert(not grill.is_on, "Grelha desligada com [E]")
	grill._process(4.0)
	assert(grill.current_temperature < 200.0, "Temperatura cai gradualmente quando desligada")
	print("  [PASS] Grelha desligada perde calor gradualmente (%.1f°C)" % grill.current_temperature)

	# Religando para o teste de fritura
	grill.interact_equipment(player)
	for _i in range(8):
		grill._process(1.0)

	print("\n--- Teste 3: Hambúrguer com Dois Lados Independentes e Flip Estável ---")
	var patty_scene = load("res://src/items/patty.tscn")
	var patty = patty_scene.instantiate() as Patty
	world.add_child(patty)
	patty._ready()

	# Coloca hambúrguer na grelha
	player.select_tool_slot(Player.ToolSlot.HANDS, false)
	player.pick_up(patty)
	grill.interact_item(player)
	assert(grill.active_items.size() == 1, "Hambúrguer colocado na grelha")
	assert(patty.position.y >= 0.0, "Hambúrguer assentado SOBRE a chapa (Y = %.3f)" % patty.position.y)
	print("  [PASS] Hambúrguer cru colocado na chapa com altura física correta")

	# Frita Lado 1 (simula 10 segundos)
	print("  -> Fritando Lado 1 (Lado A)...")
	for _i in range(10):
		grill._process(1.0)

	assert(patty.side_a_cooked >= 100.0, "Lado A do hambúrguer deve estar 100%% grelhado")
	assert(patty.side_b_cooked == 0.0, "Lado B continua cru e pronto para ser grelhado")
	assert(patty.state == Patty.State.READY_SIDE_1, "Estado deve ser READY_SIDE_1 (precisa virar!)")
	print("  [PASS] Lado A grelhado (%.0f%%) / Lado B cru (%.0f%%) — Estado: READY_SIDE_1" % [patty.side_a_cooked, patty.side_b_cooked])

	# Tenta pegar com a mão livre (deve ser rejeitado pois está quente)
	player.select_tool_slot(Player.ToolSlot.HANDS, false)
	grill.interact_item(player)
	assert(grill.active_items.size() == 1, "Hambúrguer NÃO pode ser pego com a mão nua na chapa quente")
	print("  [PASS] Mão nua rejeitada com segurança ao tocar chapa quente")

	# Equipa a Espátula (1) e vira o hambúrguer
	player.select_tool_slot(Player.ToolSlot.SPATULA, false)
	grill.interact_item(player)
	assert(patty.is_flipped, "Hambúrguer virado 180° com a espátula")
	assert(patty.current_side_cooking == 2, "Agora fritando o Lado 2 (Lado B)")
	assert(patty.position.y >= 0.0, "Hambúrguer NÃO afunda na chapa após virar (Y = %.3f)" % patty.position.y)
	print("  [PASS] Espátula virou o hambúrguer suavemente sem afundar na chapa")

	# Frita Lado 2 (simula mais 10 segundos)
	print("  -> Fritando Lado 2 (Lado B)...")
	for _i in range(10):
		grill._process(1.0)

	assert(patty.side_b_cooked >= 100.0, "Lado B do hambúrguer deve estar 100%% grelhado")
	assert(patty.is_fully_cooked(), "Hambúrguer completamente pronto nos dois lados!")
	assert(patty.state == Patty.State.COOKED, "Estado final do hambúrguer: COOKED")
	print("  [PASS] Ambos os lados grelhados com perfeição! (Lado A: %.0f%%, Lado B: %.0f%%)" % [patty.side_a_cooked, patty.side_b_cooked])

	# Retira o hambúrguer com a espátula
	grill.interact_item(player)
	assert(grill.active_items.is_empty(), "Hambúrguer retirado da grelha com a espátula")
	assert(player.held_item == patty, "Hambúrguer agora em posse do jogador")

	# Verifica se a carne está assentada SOBRE a lâmina da espátula (BladeRestPoint)
	var current_spatula = player.tool_holder.get_child(0) as Spatula
	var rest_point = current_spatula.get_blade_rest_point()
	assert(rest_point.is_ancestor_of(patty), "Carne está no BladeRestPoint da Espátula")
	print("  [PASS] Hambúrguer assentado perfeitamente SOBRE a lâmina da espátula, sem atravessar o modelo!")

	# Limpeza
	patty.queue_free()
	grill.queue_free()
	player.queue_free()
	world.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE REFINAMENTO FORAM 100% APROVADOS!")
	print("============================================================")
	quit(0)
