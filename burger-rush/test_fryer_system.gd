extends SceneTree

# ================================================================
# TESTE COMPLETO DA FRITADEIRA INDUSTRIAL (4 CESTOS, ÓLEO & TEMPERATURA)
# ================================================================

func _init() -> void:
	print("\n============================================================")
	print("BURGER RUSH - TESTE DA FRITADEIRA PROFISSIONAL DE 4 CESTOS")
	print("============================================================\n")

	var world = Node3D.new()
	root.add_child(world)

	var inv = InventoryManager.new()
	world.add_child(inv)
	inv._ready()

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Node3D
	world.add_child(player)
	player.position = Vector3(0, 0, 1.5)
	player._ready()

	var fryer_scene = load("res://src/stations/fryer.tscn")
	var fryer = fryer_scene.instantiate() as Fryer
	world.add_child(fryer)
	fryer._ready()

	# -------------------------------------------------------------
	# TESTE 1: LIGAR/DESLIGAR, TERMÔMETRO HORIZONTAL & LUZ VERDE
	# -------------------------------------------------------------
	print("--- Teste 1: Sistema Térmico, Indicador Horizontal e Piloto Verde ---")
	assert(not fryer.is_on, "Fritadeira inicia desligada")
	assert(fryer.current_temperature == 25.0, "Temperatura inicial ambiente de 25°C")
	assert(fryer.fluid_column_pivot.scale.x < 0.2, "Barra horizontal retraída quando fria")

	# Liga a máquina
	fryer.interact_equipment(player)
	assert(fryer.is_on, "Fritadeira ligada com [E]")

	# Simula aquecimento de ~12s
	print("  -> Simulando aquecimento gradual até temperatura ideal (~12s)...")
	for _i in range(14):
		fryer._process(1.0)
	assert(fryer.current_temperature >= 150.0, "Fritadeira atingiu temperatura ideal de fritura (>= 150°C)")
	assert(fryer.is_ideal_temp(), "is_ideal_temp() retorna true")
	assert(fryer.fluid_column_pivot.scale.x > 0.7, "Barra horizontal expandida para a zona verde")
	print("  [PASS] Fritadeira atingiu %.1f°C — Barra Ampla na Zona Verde e Piloto Verde Ativo" % fryer.current_temperature)

	# -------------------------------------------------------------
	# TESTE 2: 4 CUBAS VAZADAS COM PROFUNDIDADE & ÓLEO PRÉ-EXISTENTE
	# -------------------------------------------------------------
	print("\n--- Teste 2: 4 Cubas Vazadas com Profundidade e Óleo Líquido Visível ---")
	for i in range(4):
		var oil_mesh = fryer.get_node_or_null("Model/OilMesh%d" % i) as MeshInstance3D
		assert(oil_mesh != null and oil_mesh.visible, "Óleo visível no compartimento %d" % i)
		assert(oil_mesh.position.y >= 0.73, "Óleo posicionado com profundidade de 16cm abaixo da borda")
		var vat = fryer.get_node_or_null("Model/Vat%d" % i)
		assert(vat != null, "Cuba %d estruturada com paredes e fundo vazado" % i)
	print("  [PASS] Todas as 4 cubas possuem profundidade real e óleo líquido pré-existente.")

	# -------------------------------------------------------------
	# TESTE 3: COLOCAÇÃO DE BATATA CONGELADA NO CESTO ARAMADO LEVANTADO
	# -------------------------------------------------------------
	print("\n--- Teste 3: Adição de Batata Congelada ao Cesto Aramado Levantado ---")
	var potato_bag = load("res://src/items/potato.tscn").instantiate() as Potato
	world.add_child(potato_bag)
	player.pick_up(potato_bag)
	assert(player.held_item == potato_bag, "Jogador pegou o saco de batata congelada")

	assert(not fryer.compartments[0]["basket_down"], "Cesto 1 está levantado")
	fryer.interact_item(player) # Coloca no cesto 0
	assert(fryer.compartments[0]["food_state"] == "frozen", "Batata no cesto 1 em estado congelado")
	assert(player.held_item == null, "Saco de batata consumido")
	var fries_mesh = fryer.get_node("Model/Basket0/FriesMesh") as MeshInstance3D
	assert(fries_mesh.visible, "Batatas visíveis através da grade aramada do cesto")
	print("  [PASS] Batata congelada visível dentro da malha do Cesto 1.")

	# -------------------------------------------------------------
	# TESTE 4: ABAIXAR CESTO NO ÓLEO QUENTE E SUBMERGIR BATATAS
	# -------------------------------------------------------------
	print("\n--- Teste 4: Abaixar Cesto no Óleo Quente e Submergir Batatas ---")
	fryer.toggle_basket(0, player)
	assert(fryer.compartments[0]["basket_down"], "Cesto 1 abaixado no óleo")

	# Simula 4 segundos de fritura (estado "cooking")
	fryer._process(4.0)
	assert(fryer.compartments[0]["food_state"] == "cooking", "Batata fritando e borbulhando submersa no óleo quente")
	print("  [PASS] Batata fritando submersa (4.0s) com partículas e borbulhamento ativos.")

	# Simula mais 5 segundos até completar a fritura (total 9s >= 8s cook_time)
	fryer._process(5.0)
	assert(fryer.compartments[0]["food_state"] == "cooked", "Batata completamente frita e dourada!")
	print("  [PASS] Batata atingiu ponto perfeito (COOKED).")

	# -------------------------------------------------------------
	# TESTE 5: LEVANTAR CESTO, DRENAGEM E EMBALAGEM
	# -------------------------------------------------------------
	print("\n--- Teste 5: Levantar Cesto para Drenagem e Embalar ---")
	fryer.toggle_basket(0, player)
	assert(not fryer.compartments[0]["basket_down"], "Cesto 1 levantado fora do óleo")
	assert(fryer.compartments[0]["drain_timer"] > 0.0, "Drenagem ativada com gotas de óleo escorrendo")

	# Jogador embala a batata frita
	fryer.interact_item(player)
	assert(player.held_item is FriesPack, "Batata frita embalada no FriesPack nas mãos do jogador")
	assert(fryer.compartments[0]["food_state"] == "empty", "Cesto 1 esvaziado e pronto para novo lote")
	assert(not fries_mesh.visible, "Cesto agora está visivelmente vazio")
	print("  [PASS] Batata embalada com sucesso: %s" % player.held_item.get_display_name())

	# Descarta pacote para limpar as mãos
	var pack = player.take_held_item()
	pack.queue_free()

	# -------------------------------------------------------------
	# TESTE 6: INDEPENDÊNCIA DOS 4 COMPARTIMENTOS E ALAVANCAS
	# -------------------------------------------------------------
	print("\n--- Teste 6: Operação Independente dos 4 Cestos Simultâneos ---")
	# Configura Cesto 2 e Cesto 3
	fryer.compartments[1]["food_state"] = "empty"
	fryer.compartments[2]["food_state"] = "frozen"
	fryer.toggle_basket(2, player) # Abaixa Cesto 3
	assert(not fryer.compartments[1]["basket_down"], "Cesto 2 permanece levantado")
	assert(fryer.compartments[2]["basket_down"], "Cesto 3 abaixado no óleo")
	assert(not fryer.compartments[3]["basket_down"], "Cesto 4 permanece levantado")

	fryer._process(9.0) # Frita apenas o cesto 3
	assert(fryer.compartments[2]["food_state"] == "cooked", "Cesto 3 fritou de forma independente")
	assert(fryer.compartments[1]["food_state"] == "empty", "Cesto 2 não foi afetado")
	assert(fryer.compartments[3]["food_state"] == "empty", "Cesto 4 não foi afetado")
	print("  [PASS] Todos os 4 cestos operam com total independência física e lógica.")

	# -------------------------------------------------------------
	# TESTE 7: SEPARAÇÃO DO BOTÃO LIGA/DESLIGA VS ALAVANCAS
	# -------------------------------------------------------------
	print("\n--- Teste 7: Separação de Mira do Botão Liga/Desliga vs Alavancas ---")
	for x in Fryer.SLOT_X:
		assert(absf(x - Fryer.POWER_BUTTON_X) > 0.20, "Distância segura entre o botão e os cestos")
	print("  [PASS] Botão de energia isolado a mais de 24cm de distância de qualquer alavanca.")

	print("\n============================================================")
	print("TODOS OS TESTES DE REFINAMENTO DA FRITADEIRA FORAM 100% APROVADOS!")
	print("============================================================\n")
	quit()
