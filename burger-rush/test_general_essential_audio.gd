extends SceneTree

# ================================================================
# TESTE COMPLETO: ÁUDIO GERAL E ESSENCIAL DO BURGER RUSH
# Valida passos, manipulação de itens, troca de ferramentas,
# clientes (salão/balcão), delivery (carros/buzinas) e ambientação 3D
# ================================================================

const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")
const AmbientAudioManager = preload("res://src/audio/ambient_audio_manager.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DO SISTEMA DE ÁUDIO GERAL E ESSENCIAL")
	print("============================================================")

	var world = Node3D.new()
	world.name = "TestWorld"
	root.add_child(world)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	world.add_child(player)
	player._ready()

	print("\n--- 1. Movimentação do Jogador & Passos Sincronizados ---")
	assert(player.footstep_audio != null, "FootstepAudioPlayer configurado no Player")
	assert(player.tool_audio != null, "ToolAudioPlayer configurado no Player")
	assert(player.item_audio != null, "ItemAudioPlayer configurado no Player")

	# Parado: nenhum passo
	player.velocity = Vector3.ZERO
	player._physics_process(0.5)
	assert(not player.footstep_audio.playing, "Parado: sem tocar passos")

	# Andando: ritmo regular
	player.velocity = Vector3(3.0, 0.0, 0.0)
	player._physics_process(0.4)
	assert(player.footstep_audio.stream == SoundSynthesizer.get_stream("player_footstep"), "Passos sincronizados com o movimento")
	print("  [PASS] Passos sincronizados com movimento físico validados.")

	print("\n--- 2. Pegar e Soltar Itens ---")
	var item_scene = load("res://src/items/item.tscn")
	var test_item = item_scene.instantiate() as Item
	world.add_child(test_item)

	# Pegar
	player.pick_up(test_item)
	assert(player.held_item == test_item, "Item na mão do jogador")
	assert(player.item_audio.stream == SoundSynthesizer.get_stream("item_pickup"), "Som de pegar item")

	# Soltar
	player.drop_item()
	assert(player.held_item == null, "Item solto")
	assert(player.item_audio.stream == SoundSynthesizer.get_stream("item_drop"), "Som de soltar item na bancada/chão")
	print("  [PASS] Feedback sonoro de pegar e soltar itens validado.")

	print("\n--- 3. Troca de Ferramentas (Teclas 1, 2, 3) ---")
	player.select_tool_slot(Player.ToolSlot.SPATULA, true)
	assert(player.tool_audio.stream == SoundSynthesizer.get_stream("tool_spatula_equip"), "Som ao equipar Espátula [1]")

	player.select_tool_slot(Player.ToolSlot.SPONGE, true)
	assert(player.tool_audio.stream == SoundSynthesizer.get_stream("tool_sponge_equip"), "Som ao equipar Bucha [2]")

	player.select_tool_slot(Player.ToolSlot.HANDS, true)
	assert(player.tool_audio.stream == SoundSynthesizer.get_stream("tool_hands_equip"), "Som ao retornar para Mãos [3]")
	print("  [PASS] Troca e seleção física de ferramentas com áudio validada.")

	print("\n--- 4. Clientes: Chegada, Chamado, Atendimento, Comida e Saída ---")
	var customer_scene = load("res://src/customers/customer.tscn")
	var customer = customer_scene.instantiate() as Customer
	world.add_child(customer)
	customer._ready()

	# Chegada
	customer.position = Vector3(0.0, 0.0, 8.4)
	customer.state = Customer.State.ENTERING_RESTAURANT
	customer._physics_process(0.1)
	assert(customer.customer_audio.stream == SoundSynthesizer.get_stream("customer_arrive"), "Som de presença/chegada de cliente")

	# Chamado de atenção na mesa com variação de arquétipos
	customer.state = Customer.State.SEATED_WAITING_TO_ORDER
	customer.archetype = Customer.Archetype.REGULAR
	customer._call_attention_timer = 0.0
	customer._physics_process(0.1)
	assert(customer.customer_audio.stream != null and customer.customer_audio.stream in [
		SoundSynthesizer.get_stream("customer_call_hey"),
		SoundSynthesizer.get_stream("customer_call_hello"),
		SoundSynthesizer.get_stream("customer_call_whistle"),
		SoundSynthesizer.get_stream("customer_call_excuse"),
		SoundSynthesizer.get_stream("customer_call_regular")
	], "Vocalização sutil de cliente regular")

	customer.archetype = Customer.Archetype.CHILD
	customer._call_attention_timer = 0.0
	customer._physics_process(0.1)
	assert(customer.customer_audio.stream == SoundSynthesizer.get_stream("customer_call_hello") or customer.customer_audio.stream == SoundSynthesizer.get_stream("customer_call_child"), "Vocalização sutil de criança")

	# Atendimento / pedido anotado
	customer.place_order(player)
	assert(customer.customer_audio.stream == SoundSynthesizer.get_stream("customer_attend"), "Som de confirmação de atendimento")

	# Receber comida / agradecimento
	customer.receive_food()
	assert(customer.customer_audio.stream == SoundSynthesizer.get_stream("customer_thank"), "Vocalização de agradecimento/satisfação")

	# Saída
	customer.on_payment_completed()
	assert(customer.customer_audio.stream == SoundSynthesizer.get_stream("customer_leave"), "Som de passos/saída do cliente")
	print("  [PASS] Ciclo de áudio e vocalizações dos clientes validado com sucesso.")

	print("\n--- 5. Delivery & Carros: Motor, Marcha Lenta, Buzina e Saída ---")
	var car_scene = load("res://src/environment/delivery_car.tscn")
	var car = car_scene.instantiate() as DeliveryCar
	world.add_child(car)
	car._ready()

	# Aproximação
	car.current_state = DeliveryCar.CarState.MOVING_TO_QUEUE
	car._physics_process(0.1)
	assert(car.engine_audio.stream == SoundSynthesizer.get_stream("car_engine_approach"), "Som de aproximação de motor")

	# Marcha lenta
	car.current_state = DeliveryCar.CarState.WAITING_IN_LINE
	car._physics_process(0.1)
	assert(car.engine_audio.stream == SoundSynthesizer.get_stream("car_engine_idle"), "Som de motor em marcha lenta")

	# Buzina 3D
	car._play_horn()
	assert(car.horn_audio.stream == SoundSynthesizer.get_stream("car_horn_beep"), "Buzina 3D do veículo")

	# Saída
	car.current_state = DeliveryCar.CarState.LEAVING
	car._physics_process(0.1)
	assert(car.engine_audio.stream == SoundSynthesizer.get_stream("car_engine_leave"), "Som de motor acelerando na saída")
	print("  [PASS] Sons de motores, marcha lenta, saída e buzina do delivery aprovados.")

	print("\n--- 6. Ambiente 3D: Coifa da Cozinha e Trânsito Externo ---")
	var ambient_mgr = AmbientAudioManager.new()
	world.add_child(ambient_mgr)
	ambient_mgr._ready()
	assert(ambient_mgr.kitchen_audio != null and ambient_mgr.kitchen_audio.stream == SoundSynthesizer.get_stream("kitchen_hood_ambience"), "Coifa da cozinha ativa")
	assert(ambient_mgr.outside_traffic_audio != null and ambient_mgr.outside_traffic_audio.stream == SoundSynthesizer.get_stream("outside_traffic_ambience"), "Trânsito externo 3D ativo")
	print("  [PASS] Camadas ambientais 3D da cozinha e do exterior aprovadas.")

	print("\n============================================================")
	print("TODOS OS TESTES DE ÁUDIO GERAL ESSENCIAL FORAM APROVADOS!")
	print("============================================================")

	quit()
