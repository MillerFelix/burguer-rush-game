extends SceneTree

# =============================================================================
# BURGER RUSH - TEST SUITE: EXPANSÃO DO SISTEMA DE LIMPEZA
# Freezers, Geladeiras, Poças, Chão, Bancadas e Fritadeira
# =============================================================================

const IngredientRefrigerator = preload("res://src/stations/ingredient_refrigerator.gd")
const CommercialRefrigerator = preload("res://src/stations/commercial_refrigerator.gd")
const CommercialChestFreezer = preload("res://src/stations/commercial_chest_freezer.gd")
const FloorPuddle = preload("res://src/stations/floor_puddle.gd")
const FloorDirtSpot = preload("res://src/stations/floor_dirt_spot.gd")
const PrepIsland = preload("res://src/stations/prep_island.gd")
const Fryer = preload("res://src/stations/fryer.gd")
const CommercialSink = preload("res://src/stations/commercial_sink.gd")
const Sponge = preload("res://src/tools/sponge.gd")

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(75))
	print("TESTE: EXPANSÃO DO SISTEMA DE LIMPEZA (FREEZERS, GELADEIRAS, POÇAS, CHÃO E BANCADAS)")
	print("=".repeat(75) + "\n")
	call_deferred("_run_tests")

func assert_test(condition: bool, test_name: String) -> void:
	if condition:
		pass_count += 1
		print("  [PASS] %s" % test_name)
	else:
		fail_count += 1
		print("  [FAIL] %s" % test_name)

func _run_tests() -> void:
	var main_scene = load("res://src/main.tscn")
	if not main_scene:
		print("ERRO: main.tscn não encontrado")
		quit(1)
		return

	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	await create_timer(0.2).timeout

	var player = root_node.get_node_or_null("Player")
	assert_test(player != null, "Player ativo no mundo")

	var sink: CommercialSink = root_node.get_node_or_null("CommercialSink")
	assert_test(sink != null, "Pia Industrial encontrada para lavagem")

	var sponge_scene = load("res://src/tools/sponge.tscn")
	var sponge: Sponge = sponge_scene.instantiate() as Sponge
	root_node.add_child(sponge)

	print("\n--- TESTE 1: Freezer de Queijos — Efeito de Ar Frio & Formação de Poça ---")
	var freezer: CommercialChestFreezer = root_node.get_node_or_null("CommercialChestFreezer")
	assert_test(freezer != null, "Freezer de Queijos (CommercialChestFreezer) encontrado")

	if freezer:
		var cold_mist: CPUParticles3D = freezer.get_node_or_null("ColdMistParticles")
		assert_test(cold_mist != null, "Emissor de partículas de ar frio/névoa presente no freezer")

		# 1. Abre o freezer
		freezer.open_freezer(player)
		await create_timer(0.5).timeout
		assert_test(freezer.is_door_open(), "Freezer aberto")
		assert_test(cold_mist != null and cold_mist.emitting, "Efeito de ar frio/névoa ATIVO enquanto o freezer está aberto")

		# 2. Deixa aberto por tempo suficiente -> forma poça
		freezer._open_duration = 6.0
		freezer._process_condensation_puddle(1.0)
		var puddle: FloorPuddle = freezer._puddle_instance as FloorPuddle
		assert_test(puddle != null and is_instance_valid(puddle), "Poça d'água (FloorPuddle) formada no chão em frente ao freezer")
		assert_test(puddle != null and puddle.is_dirty(), "Poça d'água reconhecida como objeto de limpeza (is_dirty = true)")

		# 3. Fecha o freezer -> ar frio para, mas poça permanece
		freezer.close_freezer(player)
		await create_timer(0.5).timeout
		assert_test(not freezer.is_door_open(), "Freezer fechado")
		assert_test(cold_mist != null and not cold_mist.emitting, "Efeito de ar frio DESATIVADO após fechar o freezer")
		assert_test(puddle != null and is_instance_valid(puddle), "Poça d'água permanece no chão após fechar o freezer")

		# 4. Limpeza da poça com a bucha
		sponge.set_clean()
		assert_test(sponge.is_clean(), "Bucha está limpa antes de secar a poça")
		var dried = puddle.clean_progress(1.5, player)
		assert_test(dried, "Poça d'água seca e removida do chão com a bucha")
		sponge.set_dirty()
		assert_test(sponge.is_dirty, "Bucha torna-se SUJA após secar a poça")

	print("\n--- TESTE 2: Geladeira de Hortifrúti — Efeito de Ar Frio & Condensação ---")
	var ing_fridge: IngredientRefrigerator = root_node.get_node_or_null("IngredientRefrigerator")
	assert_test(ing_fridge != null, "Geladeira de Hortifrúti (IngredientRefrigerator) encontrada")

	if ing_fridge:
		var fridge_mist: CPUParticles3D = ing_fridge.get_node_or_null("ColdMistParticles")
		assert_test(fridge_mist != null, "Emissor de ar frio presente na geladeira de hortifrúti")

		ing_fridge.open_door(player)
		await create_timer(0.5).timeout
		assert_test(ing_fridge.is_door_open(), "Geladeira de hortifrúti aberta")
		assert_test(fridge_mist != null and fridge_mist.emitting, "Névoa fria ativa com a porta aberta")

		ing_fridge._open_duration = 6.0
		ing_fridge._process_condensation_puddle(1.0)
		var fridge_puddle: FloorPuddle = ing_fridge._puddle_instance as FloorPuddle
		assert_test(fridge_puddle != null and is_instance_valid(fridge_puddle), "Poça d'água formada em frente à geladeira")

		ing_fridge.close_door(player)
		await create_timer(0.5).timeout
		assert_test(not ing_fridge.is_door_open(), "Geladeira de hortifrúti fechada")
		assert_test(fridge_mist != null and not fridge_mist.emitting, "Névoa fria desativada ao fechar porta")

		# Limpa poça da geladeira
		if fridge_puddle and is_instance_valid(fridge_puddle):
			fridge_puddle.clean_progress(1.5, player)
			assert_test(not is_instance_valid(fridge_puddle) or not fridge_puddle.is_dirty(), "Poça da geladeira limpa")

	print("\n--- TESTE 3: Manchas no Chão (FloorDirtSpot) ---")
	var spot_scene = load("res://src/stations/floor_dirt_spot.tscn")
	var floor_spot: FloorDirtSpot = spot_scene.instantiate() as FloorDirtSpot
	root_node.add_child(floor_spot)
	floor_spot.global_position = Vector3(1.0, 0.004, 2.0)
	floor_spot.dirt_amount = 1.0

	assert_test(floor_spot.is_dirty(), "Mancha no chão criada e marcada como sujeira")
	sponge.set_clean()
	var spot_cleaned = floor_spot.clean_progress(1.0, player)
	assert_test(spot_cleaned, "Mancha no chão limpa e removida com a bucha")
	sponge.set_dirty()
	assert_test(sponge.is_dirty, "Bucha torna-se SUJA após limpar mancha no chão")

	print("\n--- TESTE 4: Bancada / Ilha de Preparo (PrepIsland) ---")
	var prep_island: PrepIsland = root_node.get_node_or_null("PrepIsland")
	assert_test(prep_island != null, "Ilha de Preparo (PrepIsland) encontrada")

	if prep_island:
		prep_island.dirt_level = 0.0
		assert_test(not prep_island.is_dirty(), "Bancada inicialmente limpa")

		# Acúmulo de sujeira com o uso
		prep_island.add_dirt(0.40)
		prep_island.add_dirt(0.40)
		assert_test(prep_island.is_dirty(), "Bancada acumula sujeira e entra em estado DIRTY")

		var island_dirt = prep_island.get_node_or_null("Model/IslandDirt")
		assert_test(island_dirt != null and island_dirt.visible, "Manchas visíveis na bancada da ilha de preparo")

		sponge.set_clean()
		var island_cleaned = prep_island.clean_progress(1.5, player)
		assert_test(island_cleaned, "Bancada limpa com sucesso utilizando a bucha")
		assert_test(not prep_island.is_dirty(), "Bancada voltou ao estado LIMPO")
		assert_test(island_dirt != null and not island_dirt.visible, "Manchas visuais da bancada desapareceram")
		sponge.set_dirty()
		assert_test(sponge.is_dirty, "Bucha torna-se SUJA após limpar a bancada")

	print("\n--- TESTE 5: Fritadeira Industrial (Fryer) ---")
	var fryer: Fryer = root_node.get_node_or_null("Fryer")
	assert_test(fryer != null, "Fritadeira Industrial (Fryer) encontrada")

	if fryer:
		fryer.dirt_level = 0.0
		assert_test(not fryer.is_dirty(), "Fritadeira inicialmente limpa")

		fryer.add_dirt(0.40)
		fryer.add_dirt(0.40)
		assert_test(fryer.is_dirty(), "Fritadeira acumula respingos de óleo e entra em estado DIRTY")

		var fryer_dirt = fryer.get_node_or_null("Model/FryerDirt")
		assert_test(fryer_dirt != null and fryer_dirt.visible, "Manchas visíveis de respingos de óleo na fritadeira")

		sponge.set_clean()
		var fryer_cleaned = fryer.clean_progress(1.5, player)
		assert_test(fryer_cleaned, "Fritadeira limpa com sucesso utilizando a bucha")
		assert_test(not fryer.is_dirty(), "Fritadeira voltou ao estado LIMPO")
		assert_test(fryer_dirt != null and not fryer_dirt.visible, "Manchas de óleo desapareceram da fritadeira")

	print("\n--- TESTE 6: Ciclo de Reutilização da Bucha na Pia ---")
	if sink and player:
		sponge.set_dirty()
		player.select_tool_slot(2)
		var player_sponge = player.tool_holder.get_child(0) as Sponge
		if player_sponge:
			player_sponge.set_dirty()
			assert_test(player_sponge.is_dirty, "Bucha do jogador está SUJA")

			sink.wash_or_sanitize(player)
			assert_test(player_sponge.is_clean(), "Bucha lavada na pia retornou ao estado LIMPA e pronta para reuso")

	print("\n" + "=".repeat(75))
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(75) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES DA EXPANSÃO DE LIMPEZA PASSARAM COM SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
