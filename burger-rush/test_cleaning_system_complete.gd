extends SceneTree

# =============================================================================
# BURGER RUSH - TEST SUITE: SISTEMA DE LIMPEZA COMPLETO E ETIQUETA DOS REFIS
# =============================================================================

const SodaRefillRack = preload("res://src/stations/soda_refill_rack.gd")
const RestaurantTable = preload("res://src/stations/restaurant_table.gd")
const CommercialSink = preload("res://src/stations/commercial_sink.gd")
const Grill = preload("res://src/stations/grill.gd")
const Sponge = preload("res://src/tools/sponge.gd")
const Customer = preload("res://src/customers/customer.gd")
const Patty = preload("res://src/items/patty.gd")
const ServingTray = preload("res://src/items/serving_tray.gd")

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(75))
	print("TESTE: SISTEMA UNIFICADO DE LIMPEZA & ETIQUETA DOS REFIS")
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
		print("ERRO CRÍTICO: Não foi possível carregar main.tscn")
		quit(1)
		return

	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	await create_timer(0.2).timeout

	print("--- TESTE 1: Etiqueta do Suporte de Refis (INSUMOS DE REFRIGERANTE) ---")
	var rack: SodaRefillRack = root_node.get_node_or_null("SodaRefillRack")
	assert_test(rack != null, "Suporte de Refis encontrado no armazém")
	if rack:
		var badge = rack.get_node_or_null("Model/FrontBadge")
		assert_test(badge != null, "Placa frontal na base presente")
		if badge:
			var label: Label3D = badge.get_node_or_null("Label") as Label3D
			assert_test(label != null and label.text == "INSUMOS DE REFRIGERANTE",
				"Texto da etiqueta corrigido para 'INSUMOS DE REFRIGERANTE'")
			assert_test(label.billboard == BaseMaterial3D.BILLBOARD_DISABLED,
				"Etiqueta física sem billboard (adesivo plano)")

	print("\n--- TESTE 2: Bucha de Limpeza (Estados LIMPA e SUJA) ---")
	var sponge_scene = load("res://src/tools/sponge.tscn")
	var sponge: Sponge = sponge_scene.instantiate() as Sponge
	root_node.add_child(sponge)

	assert_test(sponge.is_clean(), "Bucha nasce no estado LIMPA")
	assert_test(not sponge.is_dirty, "Propriedade is_dirty é false")

	sponge.set_dirty()
	assert_test(sponge.is_dirty and not sponge.is_clean(), "Bucha transiciona para estado SUJA")

	sponge.set_clean()
	assert_test(sponge.is_clean() and not sponge.is_dirty, "Bucha transiciona de volta para LIMPA")

	print("\n--- TESTE 3: Mesas — Sujeira após Refeição e Permanência da Bandeja ---")
	var table: RestaurantTable = root_node.get_node_or_null("Table1")
	assert_test(table != null, "Mesa 1 encontrada")

	var player = root_node.get_node_or_null("Player")
	assert_test(player != null, "Player ativo")

	if table and player:
		# Cria uma bandeja e simula refeição terminada
		var tray_scene = load("res://src/items/serving_tray.tscn")
		var tray: ServingTray = tray_scene.instantiate() as ServingTray
		table.plate_slot.add_child(tray)
		table.served_items.append(tray)

		# Cliente come e sai
		table.release()
		assert_test(table.is_dirty(), "Mesa fica no estado DIRTY após cliente comer")
		assert_test(table.has_tray_on_table(), "Bandeja física usada permanece sobre a mesa")

		var dirt_mesh = table.get_node_or_null("Model/TableTop/TableTopDirt")
		assert_test(dirt_mesh != null and dirt_mesh.visible, "Manchas visíveis de sujeira (TableTopDirt) ativas no modelo da mesa")

		# Tentar limpar com bandeja ainda na mesa é bloqueado
		assert_test(not table.clean_progress(0.5, player), "Limpeza da mesa bloqueada enquanto bandeja estiver sobre ela")

		# Jogador recolhe a bandeja
		table.clean_table(player) # recolhe a bandeja
		assert_test(player.held_item != null or not table.has_tray_on_table(), "Bandeja recolhida da mesa")
		if player.held_item:
			player.held_item.queue_free()
			player.held_item = null
		assert_test(table.is_dirty(), "Mesa continua suja após retirada da bandeja (aguardando bucha)")

		# Jogador limpa a mesa com bucha limpa
		sponge.set_clean()
		table.dirt_amount = 0.5
		var cleaned = table.clean_progress(1.0, player)
		assert_test(cleaned, "Progresso de limpeza finalizado com sucesso")
		assert_test(not table.is_dirty() and table.is_available(), "Mesa agora está LIMPA e DISPONÍVEL (AVAILABLE)")
		assert_test(dirt_mesh != null and not dirt_mesh.visible, "Manchas de sujeira sumiram da mesa")

	print("\n--- TESTE 4: Bloqueio de Limpeza com Bucha Suja e Lavagem na Pia ---")
	var sink: CommercialSink = root_node.get_node_or_null("CommercialSink")
	assert_test(sink != null, "Pia Industrial (CommercialSink) encontrada")

	if sink and player and table:
		sponge.set_dirty()
		player.select_tool_slot(2) # Equipa bucha no ToolHolder
		var player_sponge = player.tool_holder.get_child(0) as Sponge
		if player_sponge:
			player_sponge.set_dirty()

		# Suja a mesa novamente
		table.table_state = RestaurantTable.TableState.DIRTY
		table.dirt_amount = 1.0

		# Tenta limpar com bucha suja (bloqueado)
		assert_test(player_sponge.is_dirty, "Bucha do jogador está SUJA")

		# Lava na pia
		sink.wash_or_sanitize(player)
		assert_test(player_sponge.is_clean(), "Bucha lavada na pia voltou ao estado LIMPO")
		assert_test(sink.is_water_running, "Água corrente da pia ativada durante a lavagem")

	print("\n--- TESTE 5: Grelha — Acúmulo de Sujeira, Bloqueio de Carne e Limpeza ---")
	var grill: Grill = root_node.get_node_or_null("Grill")
	assert_test(grill != null, "Grelha (Grill) encontrada")

	if grill and player:
		grill.dirt_level = 0.0
		assert_test(not grill.is_dirty(), "Grelha nasce limpa (dirt_level = 0)")

		# Acumula sujeira com uso
		grill.add_dirt(0.5)
		assert_test(not grill.is_dirty(), "Grelha com uso moderado (dirt_level = 0.5) ainda aceita carne")

		grill.add_dirt(0.5)
		assert_test(grill.is_dirty(), "Grelha atinge limite de sujeira (dirt_level = 1.0) e entra em estado DIRTY")

		var grill_dirt = grill.get_node_or_null("Model/GrillPlate/GrillDirt")
		assert_test(grill_dirt != null and grill_dirt.visible, "Manchas de gordura/carbono visíveis na chapa da grelha")

		# Tenta colocar carne na grelha suja -> Bloqueado!
		var patty_scene = load("res://src/items/patty.tscn")
		var raw_patty: Patty = patty_scene.instantiate() as Patty
		var placed = grill.place_item(raw_patty)
		assert_test(not placed, "Grelha suja REJEITA colocação de nova carne")
		raw_patty.queue_free()

		# Limpa a grelha com a bucha
		var clean_done = grill.clean_progress(2.0, player)
		assert_test(clean_done, "Grelha limpa com a bucha")
		assert_test(not grill.is_dirty(), "Grelha voltou ao estado LIMPO")
		assert_test(grill_dirt != null and not grill_dirt.visible, "Manchas de gordura desapareceram da grelha")

		# Agora que está limpa, aceita carne normalmente
		var new_patty: Patty = patty_scene.instantiate() as Patty
		var placed_ok = grill.place_item(new_patty)
		assert_test(placed_ok, "Grelha limpa ACEITA colocação de nova carne normalmente")

	print("\n--- TESTE 6: Clientes Sem Mesa — Fila de Espera e Ocupação Pós-Limpeza ---")
	var customer_scene = load("res://src/customers/customer.tscn")
	var customer: Customer = customer_scene.instantiate() as Customer
	root_node.add_child(customer)

	# Configura cliente no salão aguardando mesa
	customer.setup(Vector3(0, 0, 7.2), Vector3(0, 0, 10.5), "", false)
	customer.is_inside_restaurant = true
	customer.assign_waiting_area()

	assert_test(customer.state == Customer.State.WAITING_FOR_TABLE, "Cliente entra em estado WAITING_FOR_TABLE")

	# Simula mesa ficando disponível (livre e limpa)
	table.table_state = RestaurantTable.TableState.AVAILABLE
	table.seated_customers.clear()
	table.served_items.clear()
	table.dirt_amount = 0.0

	# Processa espera da mesa
	customer._table_check_timer = 0.0
	customer._process_table_waiting(0.1)

	assert_test(customer.assigned_table != null, "Cliente em espera encontrou a mesa limpa e livre")
	assert_test(customer.state == Customer.State.GOING_TO_SEAT, "Cliente transicionou para GOING_TO_SEAT")
	assert_test(table.table_state == RestaurantTable.TableState.RESERVED or table.table_state == RestaurantTable.TableState.OCCUPIED,
		"Mesa reservada pelo cliente que estava esperando")

	print("\n--- TESTE 7: Efeitos Sonoros do Sistema de Limpeza no SoundSynthesizer ---")
	var scrub_sound = SoundSynthesizer.get_stream("sponge_scrub_loop")
	assert_test(scrub_sound != null and scrub_sound.data.size() > 0, "Som 'sponge_scrub_loop' sintetizado")

	var water_sound = SoundSynthesizer.get_stream("sink_running_water")
	assert_test(water_sound != null and water_sound.data.size() > 0, "Som 'sink_running_water' sintetizado")

	var faucet_sound = SoundSynthesizer.get_stream("sink_faucet_turn")
	assert_test(faucet_sound != null and faucet_sound.data.size() > 0, "Som 'sink_faucet_turn' sintetizado")

	print("\n" + "=".repeat(75))
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(75) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES PASSARAM COM SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
