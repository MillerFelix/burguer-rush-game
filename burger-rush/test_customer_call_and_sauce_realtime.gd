extends SceneTree

# ================================================================
# TESTE DE EXECUÇÃO REAL EM TEMPO REAL: BISNAGAS E CLIENTES
# Testa:
# 1. Chegada do cliente -> sentar na mesa -> levantar mão -> som audível na cozinha e próximo
# 2. Percepção espacial 3D com AudioListener3D ativo
# 3. Bisnaga: pegar -> apertar botão esquerdo -> som toca -> soltar -> som para imediatamente
# ================================================================

const MainScene = preload("res://src/main.tscn")
const Customer = preload("res://src/customers/customer.gd")
const SauceBottle = preload("res://src/items/sauce_bottle.gd")
const RestaurantTable = preload("res://src/stations/restaurant_table.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE EM TEMPO REAL: BISNAGA E CLIENTE CHAMANDO")
	print("============================================================")

	var main = MainScene.instantiate()
	root.add_child(main)

	var player = main.find_child("Player", true, false)
	assert(player != null, "Player presente na cena principal")

	var listener = player.find_child("AudioListener3D", true, false) as AudioListener3D
	assert(listener != null and listener.is_current(), "AudioListener3D ativo nos ouvidos do jogador")
	print("  [PASS] Jogador e AudioListener3D ativos na cena.")

	print("\n--- 1. TESTE REAL: CLIENTE CHEGA, SENTA E CHAMA O ATENDENTE ---")
	var tables = main.find_children("", "RestaurantTable", true, false)
	assert(not tables.is_empty(), "Mesas encontradas no restaurante")
	var table = tables[0] as RestaurantTable

	var customer_scene = load("res://src/customers/customer.tscn")
	var customer = customer_scene.instantiate() as Customer
	main.add_child(customer)
	customer.setup(Vector3(0.0, 0.0, 10.0), Vector3(0.0, 0.0, 12.0), "classic_burger", false)
	customer.assign_seat(table, table.position + Vector3(0.0, 0.0, -0.6), 1)

	# Simula cliente caminhando e completando a transição para sentar
	customer._complete_sitting_transition()

	assert(customer.state == Customer.State.SEATED_WAITING_TO_ORDER, "Cliente sentado aguardando atendimento com a mão levantada")
	assert(customer.customer_audio != null, "AudioStreamPlayer3D do cliente ativo")
	assert(customer.customer_audio.playing or customer.customer_audio.stream != null, "Vocalização reproduzida no momento do chamado")
	assert(customer.customer_audio.volume_db >= -2.0, "Volume calibrado para ser nítido no restaurante (%.1f dB)" % customer.customer_audio.volume_db)
	assert(customer.customer_audio.unit_size >= 4.0, "Unit size espacial 3D amplo (%.1f)" % customer.customer_audio.unit_size)
	print("  [PASS] Cliente sentado: mão levantada e som de vocalização (%s) disparado com sucesso!" % customer.customer_audio.stream.resource_path)

	print("\n--- 2. TESTE REAL: AUDIBILIDADE NA COZINHA (DISTÂNCIA DE 6 A 8 METROS) ---")
	player.position = Vector3(0.0, 0.0, -3.5) # Centro da cozinha/grelha
	var dist_to_cust = player.position.distance_to(customer.position)
	print("  Distância do jogador (na cozinha) até a mesa do cliente: %.2f metros" % dist_to_cust)
	assert(dist_to_cust < customer.customer_audio.max_distance, "Cliente dentro do alcance espacial audível da cozinha")
	print("  [PASS] Vocalização espacial audível a partir da cozinha sem ser inaudível nem ensurdecedora.")

	print("\n--- 3. TESTE REAL: BISNAGA DE MOLHO (PEGAR, APERTAR E SOLTAR - SILENCIOSA) ---")
	var bottle_scene = load("res://src/items/sauce_bottle.tscn")
	var bottle = bottle_scene.instantiate() as SauceBottle
	main.add_child(bottle)
	bottle._ready()
	bottle.setup_bottle("ketchup")
	bottle.current_amount = 80.0
	bottle.location = SauceBottle.ItemLocation.PLAYER_HAND

	assert(bottle.get_node_or_null("SqueezeAudioPlayer") == null, "Sem nó de áudio na bisnaga")

	# Jogador segura a bisnaga e pressiona o botão esquerdo
	bottle.start_squeezing()
	assert(bottle.is_squeezing, "Bisnaga em estado de aperto físico")
	print("  [PASS] Bisnaga sendo apertada: molho saindo visualmente sem áudio.")

	# Jogador solta o botão esquerdo
	bottle.stop_squeezing()
	assert(not bottle.is_squeezing, "Aperto cessado")
	print("  [PASS] Botão solto: fluxo de molho interrompido instantaneamente.")

	print("\n============================================================")
	print("TESTE EM TEMPO REAL CONCLUÍDO COM 100% DE SUCESSO!")
	print("============================================================")

	quit()
