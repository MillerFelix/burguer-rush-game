extends SceneTree

# Script de validação das 3 correções pontuais do Tutorial

func _init() -> void:
	print("--- TESTANDO AS 3 CORREÇÕES PONTUAIS DO TUTORIAL ---")
	call_deferred("run")

func run() -> void:
	# Teste 1: Sponge / Bucha
	print("\n[TESTE 1] Bucha na mão do jogador...")
	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	await process_frame
	
	player.select_tool_slot(Player.ToolSlot.SPONGE, false)
	await process_frame
	
	assert(player.active_tool_slot == Player.ToolSlot.SPONGE, "Slot 2 ativo")
	assert(player.tool_holder.get_child_count() > 0, "ToolHolder tem a Bucha")
	var sponge = player.tool_holder.get_child(0) as Sponge
	assert(sponge != null, "Filho é Sponge")
	assert(sponge.visible, "Sponge visível")
	assert(sponge.get_node_or_null("Model/YellowBody") != null, "YellowBody existe")
	assert(sponge.get_node_or_null("Model/GreenScourPad") != null, "GreenScourPad existe")
	
	# Teste sujeira e pia
	sponge.set_dirty()
	assert(sponge.is_dirty, "Bucha ficou suja")
	assert(player.sponge_is_dirty, "Player sponge_is_dirty sincronizado")
	sponge.set_clean()
	assert(not sponge.is_dirty, "Bucha ficou limpa")
	print("  -> Bucha na mão validada com sucesso!")

	# Teste 2: PC Administrativo
	print("\n[TESTE 2] Label do PC Administrativo no tutorial...")
	var tut_scene = load("res://src/ui/tutorial.tscn")
	var tut = tut_scene.instantiate() as TutorialController
	var main_scene = Node3D.new()
	main_scene.name = "Main"
	root.add_child(main_scene)
	current_scene = main_scene
	
	var pc_scene = load("res://src/stations/computer_station.tscn")
	var pc = pc_scene.instantiate() as ComputerStation
	main_scene.add_child(pc)
	pc.name = "ComputerStation"
	main_scene.add_child(tut)
	await process_frame
	
	# Avança para etapa 1 (PC)
	tut._show_step(1)
	assert(tut.current_highlight_marker != null, "Marker 3D do PC criado")
	assert(tut.current_highlight_marker.no_depth_test == true, "no_depth_test ativado para não atravessar geometria")
	assert(tut.current_highlight_marker.text.contains("PC Administrativo"), "Texto contém PC Administrativo")
	print("  -> Marker do PC validado com sucesso!")

	# Teste 3: Colocar Base do Pão na Bancada
	print("\n[TESTE 3] Reconhecimento da BreadBottom na bancada...")
	var island_scene = load("res://src/stations/prep_island.tscn")
	var island = island_scene.instantiate() as PrepIsland
	main_scene.add_child(island)
	island.name = "PrepIsland"
	await process_frame
	
	tut._show_step(6) # Etapa 6: Colocar BreadBottom
	assert(tut.current_step_index == 6, "Tutorial na etapa 6")
	
	# Simula BreadBottom colocada no mundo sobre a ilha
	var bread_bottom = load("res://src/items/bread_bottom.tscn").instantiate() as BreadBottom
	main_scene.add_child(bread_bottom)
	bread_bottom.global_position = island.global_position + Vector3(0, 0.9, 0)
	bread_bottom.location = Item.ItemLocation.WORLD
	await process_frame
	
	# Atualiza cleanup da ilha
	island._cleanup_placed_items()
	tut._check_step_conditions()
	assert(tut.current_step_index == 7, "Tutorial avançou para etapa 7!")
	print("  -> Reconhecimento da BreadBottom na bancada validado com sucesso!")

	print("\n>>> TODOS OS TESTES PRELIMINARES PASSARAM COM SUCESSO! <<<\n")
	quit(0)
