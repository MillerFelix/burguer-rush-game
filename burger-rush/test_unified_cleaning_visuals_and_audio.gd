@tool
extends SceneTree

func _init() -> void:
	print("================================================================")
	print("TESTE COMPLETO DO SISTEMA DE LIMPEZA PADRONIZADO E VISUAIS ORGÂNICOS")
	print("================================================================")

	var errors: Array[String] = []

	# 1. Validação das Texturas Orgânicas
	var texture_paths = [
		"res://assets/textures/dirt_stain_grill.png",
		"res://assets/textures/dirt_stain_table.png",
		"res://assets/textures/dirt_stain_counter.png",
		"res://assets/textures/dirt_stain_floor.png",
		"res://assets/textures/dirt_stain_fryer.png"
	]

	for path in texture_paths:
		if not ResourceLoader.exists(path):
			errors.append("Textura não encontrada: " + path)
		else:
			var tex = load(path)
			if not tex or not (tex is Texture2D):
				errors.append("Falha ao carregar textura: " + path)
			else:
				print("✔ Textura carregada com sucesso: %s (%dx%d)" % [path, tex.get_width(), tex.get_height()])

	# 2. Validação do Áudio de Esfregação
	var scrub_stream = SoundSynthesizer.get_stream("sponge_scrub_loop")
	if not scrub_stream or not (scrub_stream is AudioStreamWAV):
		errors.append("Falha ao sintetizar áudio 'sponge_scrub_loop'")
	else:
		var wav = scrub_stream as AudioStreamWAV
		if wav.data.is_empty():
			errors.append("Áudio 'sponge_scrub_loop' possui dados PCM vazios")
		elif wav.loop_mode != AudioStreamWAV.LOOP_FORWARD:
			errors.append("Áudio 'sponge_scrub_loop' não está em modo de loop contínuo")
		else:
			print("✔ Áudio 'sponge_scrub_loop' sintetizado com sucesso: %d bytes PCM, taxa %d Hz, loop: %d-%d" % [
				wav.data.size(), wav.mix_rate, wav.loop_begin, wav.loop_end
			])

	# 3. Validação da Bucha (Sponge)
	var sponge_scene = load("res://src/tools/sponge.tscn")
	if not sponge_scene:
		errors.append("Falha ao carregar sponge.tscn")
	else:
		var sponge = sponge_scene.instantiate() as Sponge
		root.add_child(sponge)
		if sponge.is_dirty:
			errors.append("Bucha nova deve iniciar limpa")
		sponge.start_scrub_continuous()
		sponge._process(0.016)
		sponge.stop_scrub_continuous()
		sponge.set_dirty()
		if not sponge.is_dirty:
			errors.append("Bucha não atualizou para dirty")
		sponge.set_clean()
		if sponge.is_dirty:
			errors.append("Bucha não limpou com set_clean")
		sponge.queue_free()
		print("✔ Bucha (Sponge) testada com sucesso (animação, estados e materiais)")

	# 4. Validação da Grelha (Grill)
	var grill_scene = load("res://src/stations/grill.tscn")
	if not grill_scene:
		errors.append("Falha ao carregar grill.tscn")
	else:
		var grill = grill_scene.instantiate() as Grill
		root.add_child(grill)
		grill.dirt_level = 0.0
		grill._update_dirt_visuals()
		var g_dirt = grill.get_node_or_null("Model/GrillPlate/GrillDirt")
		if not g_dirt:
			errors.append("GrillDirt não encontrado em grill.tscn")
		else:
			if g_dirt.visible:
				errors.append("GrillDirt deve estar invisível quando limpo")

		grill.add_dirt(1.0)
		if not grill.is_dirty() or not g_dirt.visible:
			errors.append("GrillDirt deve estar visível após add_dirt")

		var fin1 = grill.clean_progress(0.7)
		if fin1:
			errors.append("clean_progress parcial não deve retornar true")
		if grill.dirt_level >= 1.0 or grill.dirt_level <= 0.0:
			errors.append("dirt_level da grelha deve diminuir progressivamente (atual: %f)" % grill.dirt_level)

		var fin2 = grill.clean_progress(1.5)
		if not fin2 or grill.dirt_level > 0.0 or g_dirt.visible:
			errors.append("Grelha deve estar 100% limpa após término de clean_progress")

		grill.queue_free()
		print("✔ Grelha (Grill) testada com sucesso (limpeza progressiva, visuais orgânicos)")

	# 5. Validação da Mesa do Restaurante (RestaurantTable)
	var table_scene = load("res://src/stations/restaurant_table.tscn")
	if not table_scene:
		errors.append("Falha ao carregar restaurant_table.tscn")
	else:
		var table = table_scene.instantiate() as RestaurantTable
		root.add_child(table)
		table.table_state = RestaurantTable.TableState.AVAILABLE
		table._update_visual_status()
		var t_dirt = table.get_node_or_null("Model/TableTop/TableTopDirt")
		if not t_dirt:
			errors.append("TableTopDirt não encontrado em restaurant_table.tscn")
		else:
			if t_dirt.visible:
				errors.append("TableTopDirt deve estar invisível quando livre")

		table.table_state = RestaurantTable.TableState.DIRTY
		table.dirt_amount = 1.0
		table._update_visual_status()
		if not table.is_dirty() or not t_dirt.visible:
			errors.append("TableTopDirt deve estar visível quando mesa estiver DIRTY")

		var t_fin1 = table.clean_progress(0.6)
		if t_fin1:
			errors.append("clean_progress parcial da mesa não deve retornar true")
		if table.dirt_amount >= 1.0 or table.dirt_amount <= 0.0:
			errors.append("dirt_amount da mesa deve diminuir progressivamente (atual: %f)" % table.dirt_amount)

		var t_fin2 = table.clean_progress(1.5)
		if not t_fin2 or table.table_state != RestaurantTable.TableState.AVAILABLE or t_dirt.visible:
			errors.append("Mesa deve ficar AVAILABLE e limpa após término de clean_progress")

		table.queue_free()
		print("✔ Mesa (RestaurantTable) testada com sucesso (limpeza progressiva e estados)")

	# 6. Validação da Ilha de Preparo (PrepIsland)
	var island_scene = load("res://src/stations/prep_island.tscn")
	if not island_scene:
		errors.append("Falha ao carregar prep_island.tscn")
	else:
		var island = island_scene.instantiate() as PrepIsland
		root.add_child(island)
		island.dirt_level = 0.0
		island._update_dirt_visuals()
		var i_dirt = island.get_node_or_null("Model/IslandDirt")
		if not i_dirt:
			errors.append("IslandDirt não encontrado em prep_island.tscn")
		else:
			if i_dirt.visible:
				errors.append("IslandDirt deve estar invisível quando limpo")

		island.add_dirt(0.8)
		if not island.is_dirty() or not i_dirt.visible:
			errors.append("IslandDirt deve estar visível após add_dirt")

		var i_fin = island.clean_progress(1.5)
		if not i_fin or island.dirt_level > 0.0 or i_dirt.visible:
			errors.append("PrepIsland deve estar limpa após término de clean_progress")

		island.queue_free()
		print("✔ Ilha de Preparo (PrepIsland) testada com sucesso")

	# 7. Validação da Mancha no Chão (FloorDirtSpot)
	var spot_scene = load("res://src/stations/floor_dirt_spot.tscn")
	if not spot_scene:
		errors.append("Falha ao carregar floor_dirt_spot.tscn")
	else:
		var spot = spot_scene.instantiate() as FloorDirtSpot
		root.add_child(spot)
		spot.dirt_amount = 1.0
		spot._update_visuals()
		if not spot.is_dirty():
			errors.append("FloorDirtSpot deve iniciar sujo com dirt_amount 1.0")

		spot.clean_progress(0.4)
		if spot.dirt_amount >= 1.0 or spot.dirt_amount <= 0.0:
			errors.append("FloorDirtSpot deve diminuir progressivamente (atual: %f)" % spot.dirt_amount)

		spot.queue_free()
		print("✔ Mancha no Chão (FloorDirtSpot) testada com sucesso")

	# 8. Validação da Fritadeira (Fryer)
	var fryer_scene = load("res://src/stations/fryer.tscn")
	if not fryer_scene:
		errors.append("Falha ao carregar fryer.tscn")
	else:
		var fryer = fryer_scene.instantiate() as Fryer
		root.add_child(fryer)
		fryer.dirt_level = 0.0
		fryer._update_dirt_visuals()
		var fry_dirt = fryer.get_node_or_null("Model/FryerDirt")
		if not fry_dirt:
			errors.append("FryerDirt não encontrado em fryer.tscn")

		fryer.add_dirt(0.8)
		if not fryer.is_dirty() or not fry_dirt.visible:
			errors.append("FryerDirt deve estar visível após add_dirt")

		var fry_fin = fryer.clean_progress(1.8)
		if not fry_fin or fryer.dirt_level > 0.0 or fry_dirt.visible:
			errors.append("Fritadeira deve estar limpa após término de clean_progress")

		fryer.queue_free()
		print("✔ Fritadeira (Fryer) testada com sucesso")

	print("================================================================")
	if errors.is_empty():
		print("🎉 TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! 🎉")
		print("================================================================")
		quit(0)
	else:
		print("❌ ERROS ENCONTRADOS (%d):" % errors.size())
		for e in errors:
			print(" - " + e)
		print("================================================================")
		quit(1)
