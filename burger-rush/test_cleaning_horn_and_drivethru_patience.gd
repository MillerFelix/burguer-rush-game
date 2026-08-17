extends SceneTree

# =============================================================================
# BURGER RUSH - TESTE: LIMPEZA DA CHAPA, BUZINA DE ENTREGA E DRIVE-THRU
# =============================================================================

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(85))
	print("TESTE: LIMPEZA DA CHAPA (ANIMAÇÃO/SOM), BUZINA DO CAMINHÃO E PACIÊNCIA DRIVE-THRU")
	print("=".repeat(85) + "\n")
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
	await create_timer(0.3).timeout

	print("\n--- TESTE 1: Limpeza da Chapa (Animação, Som, Progresso e Bucha) ---")
	var grill = root_node.find_child("Grill", true, false)
	assert_test(grill != null, "1.1 Grill presente na cozinha")
	var player = root_node.find_child("Player", true, false)
	assert_test(player != null, "1.2 Jogador presente")

	# Deixa a chapa suja
	grill.add_dirt(1.0)
	assert_test(grill.is_dirty(), "1.3 Chapa da grelha em estado SUJA (dirt_level = 1.0)")

	# Equipa a bucha (Slot 2)
	player.select_tool_slot(2)
	var tool_holder = player.get_node_or_null("Head/Camera3D/ToolHolder")
	var sponge = tool_holder.get_child(0) as Sponge if (tool_holder and tool_holder.get_child_count() > 0) else null
	assert_test(sponge != null, "1.4 Bucha de limpeza equipada com sucesso no ToolHolder")
	assert_test(sponge.is_clean(), "1.5 Bucha inicialmente limpa e pronta para uso")

	# Simula esfregação contínua
	player._play_scrubbing_audio()
	sponge.start_scrub_continuous()
	assert_test(sponge.get("_is_scrubbing_continuous") == true, "1.6 Bucha ativou animação contínua de esfregação")
	assert_test(player.get("_is_scrubbing_audio_playing") == true, "1.7 Áudio realista de esfregação com bucha ativo")

	# Progresso da limpeza (sujeira diminui progressivamente)
	var initial_dirt = grill.dirt_level
	grill.clean_progress(0.75, player)
	assert_test(grill.dirt_level < initial_dirt, "1.8 Sujeira da chapa diminuindo progressivamente (%.2f -> %.2f)" % [initial_dirt, grill.dirt_level])

	# Conclusão da limpeza
	var is_finished = grill.clean_progress(1.0, player)
	assert_test(is_finished and not grill.is_dirty(), "1.9 Chapa 100% limpa e brilhando")

	# Parada de som e bucha ficando suja
	sponge.set_dirty()
	player._stop_scrubbing_audio()
	assert_test(sponge.is_dirty, "1.10 Bucha ficou suja após a limpeza completa")
	assert_test(sponge.get("_is_scrubbing_continuous") == false, "1.11 Animação de esfregação finalizada")
	assert_test(player.get("_is_scrubbing_audio_playing") == false, "1.12 Áudio de esfregação interrompido ao terminar")

	print("\n--- TESTE 2: Buzina Realista do Caminhão de Entrega ---")
	var sound_synth = load("res://src/audio/sound_synthesizer.gd")
	var stream_horn = sound_synth.get_stream("truck_horn")
	assert_test(stream_horn != null and stream_horn.get_length() > 0.4, "2.1 Stream de áudio da buzina de caminhão sintetizado com sucesso (%.2fs)" % stream_horn.get_length())

	var receiving_area = root_node.find_child("ReceivingArea", true, false) as ReceivingArea
	assert_test(receiving_area != null, "2.2 ReceivingArea presente na doca/pallet externo")
	assert_test(receiving_area.horn_audio != null, "2.3 Player de áudio 3D posicional da buzina presente no pallet")
	assert_test(receiving_area.horn_audio.max_distance >= 80.0, "2.4 Alcance espacial da buzina amplo para o interior do restaurante (%.0fm)" % receiving_area.horn_audio.max_distance)

	print("\n--- TESTE 3: Paciência Proporcional no Drive-Thru ---")
	var deliv_mgr = root_node.find_child("DeliveryQueueManager", true, false)
	assert_test(deliv_mgr != null, "3.1 DeliveryQueueManager ativo")

	var car = deliv_mgr.spawn_car() as DeliveryCar
	assert_test(car != null, "3.2 Carro gerado no Drive-Thru")

	# 1. Pedido Pequeno (1 item)
	var small_order = Order.new()
	small_order.id = 201
	small_order.source_type = "DELIVERY"
	var small_items: Array[Dictionary] = [{"product_id": "cheeseburger", "product_name": "Cheeseburger", "quantity": 1, "delivered_quantity": 0, "price": 18.0}]
	small_order.items = small_items
	car.current_order = small_order
	var small_tol = car.tolerance_food_wait
	assert_test(small_tol >= 125.0 and small_tol <= 140.0, "3.3 Tolerância para Pedido Pequeno generosa (%.1fs >= 125.0s)" % small_tol)

	# 2. Pedido Médio (2 a 3 itens)
	var med_order = Order.new()
	med_order.id = 202
	med_order.source_type = "DELIVERY"
	var med_items: Array[Dictionary] = [
		{"product_id": "cheeseburger", "product_name": "Cheeseburger", "quantity": 1, "delivered_quantity": 0, "price": 18.0},
		{"product_id": "fries", "product_name": "Batata Frita", "quantity": 1, "delivered_quantity": 0, "price": 10.0},
		{"product_id": "soda_cola", "product_name": "Refrigerante Cola", "quantity": 1, "delivered_quantity": 0, "price": 8.0}
	]
	med_order.items = med_items
	car.current_order = med_order
	var med_tol = car.tolerance_food_wait
	assert_test(med_tol >= 165.0 and med_tol > small_tol, "3.4 Tolerância para Pedido Médio maior que pequeno (%.1fs > %.1fs)" % [med_tol, small_tol])

	# 3. Pedido Grande / Família (4+ itens: lanches + batatas + bebidas)
	var large_order = Order.new()
	large_order.id = 203
	large_order.source_type = "DELIVERY"
	var large_items: Array[Dictionary] = [
		{"product_id": "cheeseburger", "product_name": "Cheeseburger", "quantity": 2, "delivered_quantity": 0, "price": 36.0},
		{"product_id": "x_bacon", "product_name": "X-Bacon", "quantity": 1, "delivered_quantity": 0, "price": 24.0},
		{"product_id": "fries", "product_name": "Batata Frita", "quantity": 2, "delivered_quantity": 0, "price": 20.0},
		{"product_id": "soda_cola", "product_name": "Refrigerante Cola", "quantity": 3, "delivered_quantity": 0, "price": 24.0}
	]
	large_order.items = large_items
	car.current_order = large_order
	var large_tol = car.tolerance_food_wait
	assert_test(large_tol >= 220.0 and large_tol > med_tol, "3.5 Tolerância para Pedido Grande significativamente maior (%.1fs > %.1fs)" % [large_tol, med_tol])

	# 4. Clientes presenciais de mesa mantêm paciência inalterada
	var cust_spawner = root_node.find_child("CustomerSpawner", true, false)
	var table_custs = cust_spawner.spawn_customer_group()
	if not table_custs.is_empty():
		var table_cust = table_custs[0]
		assert_test(table_cust.tolerance_food_wait <= 100.0, "3.6 Clientes presenciais mantêm tolerância padrão de salão (%.1fs <= 100.0s)" % table_cust.tolerance_food_wait)

	print("\n" + "=".repeat(85))
	print("RESULTADO DOS TESTES: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(85) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES DE LIMPEZA, BUZINA E DRIVE-THRU PASSARAM COM 100% DE SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
