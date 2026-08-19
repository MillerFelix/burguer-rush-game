extends SceneTree

# =============================================================================
# BURGER RUSH - TESTE AUTOMATIZADO DO SISTEMA UNIFICADO DE LIMPEZA E BUCHA SUJA
#
# Valida a regra universal:
# Terminou qualquer limpeza com a bucha -> a bucha fica SUJA imediatamente.
#
# Superfícies testadas individualmente e em ciclo contínuo:
# 1. Água do chão (FloorPuddle)
# 2. Grelha (Grill)
# 3. Mesa (RestaurantTable)
# 4. Balcão / Ilha de Preparo (PrepIsland)
# 5. Fritadeira (Fryer) & Mancha no chão (FloorDirtSpot)
# 6. Ciclo de lavagem na pia e reutilização contínua
# =============================================================================

const Player = preload("res://src/player/player.gd")
const Sponge = preload("res://src/tools/sponge.gd")
const CommercialSink = preload("res://src/stations/commercial_sink.gd")
const FloorPuddle = preload("res://src/stations/floor_puddle.gd")
const Grill = preload("res://src/stations/grill.gd")
const RestaurantTable = preload("res://src/stations/restaurant_table.gd")
const PrepIsland = preload("res://src/stations/prep_island.gd")
const Fryer = preload("res://src/stations/fryer.gd")
const FloorDirtSpot = preload("res://src/stations/floor_dirt_spot.gd")

var pass_count: int = 0
var total_count: int = 0

func assert_test(condition: bool, description: String) -> void:
	total_count += 1
	if condition:
		pass_count += 1
		print("  [PASS] %s" % description)
	else:
		printerr("  [FAIL] %s" % description)

func _init() -> void:
	print("\n=================================================================")
	print("=== TESTE: BUCHA FICA SUJA APÓS QUALQUER AÇÃO DE LIMPEZA ===")
	print("=================================================================\n")

	test_all_cleaning_surfaces()

	print("\n=================================================================")
	print("RESULTADO FINAL: %d/%d APROVADOS" % [pass_count, total_count])
	print("=================================================================\n")

	if pass_count == total_count:
		print(">>> SUCESSO TOTAL: REGRA UNIVERSAL DA BUCHA SUJA 100% VALIDADA! <<<\n")
		quit(0)
	else:
		printerr(">>> ERRO: ALGUNS TESTES FALHARAM! <<<\n")
		quit(1)

func test_all_cleaning_surfaces() -> void:
	# 1. Setup do Jogador e da Pia
	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)

	var sink_scene = load("res://src/stations/commercial_sink.tscn")
	var sink = sink_scene.instantiate() as CommercialSink
	root.add_child(sink)

	player.select_tool_slot(Player.ToolSlot.SPONGE, false)
	var sponge = player.tool_holder.get_node_or_null("Sponge") as Sponge
	assert_test(sponge != null, "Bucha equipada no ToolHolder do jogador")

	# --- SUPERFÍCIE 1: ÁGUA DO CHÃO (FloorPuddle) ---
	print("\n--- TESTE 1: Água do Chão ---")
	sink.wash_or_sanitize(player)
	assert_test(sponge.is_clean() and not player.sponge_is_dirty, "1.1 Bucha inicia LIMPA")

	var puddle = FloorPuddle.new()
	puddle.puddle_size = 1.0
	root.add_child(puddle)
	assert_test(puddle.is_dirty(), "1.2 Poça d'água está suja")

	var puddle_done = puddle.clean_progress(1.5, player)
	assert_test(puddle_done, "1.3 Limpeza da poça d'água concluída")
	assert_test(sponge.is_dirty and player.sponge_is_dirty, "1.4 Bucha tornou-se SUJA imediatamente após secar a poça")

	# --- SUPERFÍCIE 2: GRELHA (Grill) ---
	print("\n--- TESTE 2: Grelha ---")
	sink.wash_or_sanitize(player)
	assert_test(sponge.is_clean() and not player.sponge_is_dirty, "2.1 Bucha lavada na pia voltou ao estado LIMPA")

	var grill = Grill.new()
	grill.dirt_level = 1.0
	root.add_child(grill)
	assert_test(grill.is_dirty(), "2.2 Grelha está suja")

	var grill_done = grill.clean_progress(2.0, player)
	assert_test(grill_done, "2.3 Limpeza da grelha concluída")
	assert_test(not grill.is_dirty() and grill.dirt_level == 0.0, "2.4 Grelha está 100% LIMPA")
	assert_test(sponge.is_dirty and player.sponge_is_dirty, "2.5 Bucha tornou-se SUJA imediatamente após limpar a grelha")

	# --- SUPERFÍCIE 3: MESA (RestaurantTable) ---
	print("\n--- TESTE 3: Mesa ---")
	sink.wash_or_sanitize(player)
	assert_test(sponge.is_clean() and not player.sponge_is_dirty, "3.1 Bucha lavada na pia voltou ao estado LIMPA")

	var table_scene = load("res://src/stations/restaurant_table.tscn")
	var table = table_scene.instantiate() as RestaurantTable
	root.add_child(table)
	table.table_state = RestaurantTable.TableState.DIRTY
	table.dirt_amount = 1.0
	table._update_visual_status()
	assert_test(table.is_dirty(), "3.2 Mesa está suja")

	var table_done = table.clean_progress(2.0, player)
	assert_test(table_done, "3.3 Limpeza da mesa concluída")
	assert_test(not table.is_dirty() and table.table_state == RestaurantTable.TableState.AVAILABLE, "3.4 Mesa está 100% LIMPA")
	assert_test(sponge.is_dirty and player.sponge_is_dirty, "3.5 Bucha tornou-se SUJA imediatamente após limpar a mesa")

	# --- SUPERFÍCIE 4: BALCÃO / ILHA DE PREPARO (PrepIsland) ---
	print("\n--- TESTE 4: Balcão / Ilha de Preparo ---")
	sink.wash_or_sanitize(player)
	assert_test(sponge.is_clean() and not player.sponge_is_dirty, "4.1 Bucha lavada na pia voltou ao estado LIMPA")

	var island = PrepIsland.new()
	island.dirt_level = 1.0
	root.add_child(island)
	assert_test(island.is_dirty(), "4.2 Balcão da ilha está sujo")

	var island_done = island.clean_progress(2.0, player)
	assert_test(island_done, "4.3 Limpeza do balcão concluída")
	assert_test(not island.is_dirty() and island.dirt_level == 0.0, "4.4 Balcão está 100% LIMPO")
	assert_test(sponge.is_dirty and player.sponge_is_dirty, "4.5 Bucha tornou-se SUJA imediatamente após limpar o balcão")

	# --- SUPERFÍCIE 5: FRITADEIRA & MANCHA NO CHÃO ---
	print("\n--- TESTE 5: Fritadeira & Mancha no Chão ---")
	sink.wash_or_sanitize(player)
	assert_test(sponge.is_clean() and not player.sponge_is_dirty, "5.1 Bucha lavada na pia voltou ao estado LIMPA")

	var fryer = Fryer.new()
	fryer.dirt_level = 1.0
	root.add_child(fryer)
	var fryer_done = fryer.clean_progress(2.0, player)
	assert_test(fryer_done and not fryer.is_dirty(), "5.2 Fritadeira limpa com sucesso")
	assert_test(sponge.is_dirty and player.sponge_is_dirty, "5.3 Bucha tornou-se SUJA imediatamente após limpar a fritadeira")

	sink.wash_or_sanitize(player)
	var spot = FloorDirtSpot.new()
	spot.dirt_amount = 1.0
	root.add_child(spot)
	var spot_done = spot.clean_progress(1.5, player)
	assert_test(spot_done, "5.4 Mancha no chão limpa com sucesso")
	assert_test(sponge.is_dirty and player.sponge_is_dirty, "5.5 Bucha tornou-se SUJA imediatamente após limpar o chão")

	# --- TESTE 6: CICLO REPETIDO CONTÍNUO (Reutilização) ---
	print("\n--- TESTE 6: Ciclo Repetido de Limpeza e Lavagem ---")
	for i in range(3):
		sink.wash_or_sanitize(player)
		assert_test(sponge.is_clean() and not player.sponge_is_dirty, "Ciclo %d: Bucha LIMPA após lavar na pia" % (i + 1))
		table.table_state = RestaurantTable.TableState.DIRTY
		table.dirt_amount = 1.0
		table.clean_progress(2.0, player)
		assert_test(sponge.is_dirty and player.sponge_is_dirty, "Ciclo %d: Bucha SUJA imediatamente após a limpeza" % (i + 1))

	player.queue_free()
	sink.queue_free()
	grill.queue_free()
	table.queue_free()
	island.queue_free()
	fryer.queue_free()
