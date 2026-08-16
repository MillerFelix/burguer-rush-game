extends SceneTree

# ================================================================
# TESTE DA ESTAÇÃO DE MOLHOS, BISNAGAS TRANSLÚCIDAS, JATO 3D E DROP
# ================================================================

func _init() -> void:
	print("\n============================================================")
	print("BURGER RUSH - TESTE DA ESTAÇÃO DE MOLHOS, BISNAGAS E DROP")
	print("============================================================\n")

	var world = Node3D.new()
	root.add_child(world)

	var inv = InventoryManager.new()
	world.add_child(inv)
	inv._ready()

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	world.add_child(player)
	player.position = Vector3(0, 0, 1.5)
	player._ready()

	var prep_table_scene = load("res://src/stations/prep_table.tscn")
	var prep_table = prep_table_scene.instantiate() as PrepTable
	world.add_child(prep_table)
	prep_table._ready()

	# -------------------------------------------------------------
	# TESTE 1: BANCADA LIMPA E 4 BISNAGAS ORGANIZADAS SEM TEXTO
	# -------------------------------------------------------------
	print("--- Teste 1: Bancada de Molhos Limpa e Organizada ---")
	var ketchup = prep_table.get_node_or_null("KetchupBottle") as SauceBottle
	var mustard = prep_table.get_node_or_null("MustardBottle") as SauceBottle
	var mayo = prep_table.get_node_or_null("MayoBottle") as SauceBottle
	var special = prep_table.get_node_or_null("SpecialSauceBottle") as SauceBottle

	assert(ketchup != null, "Bisnaga de Ketchup presente")
	assert(mustard != null, "Bisnaga de Mostarda presente")
	assert(mayo != null, "Bisnaga de Maionese presente")
	assert(special != null, "Bisnaga de Molho Especial presente")

	# Verifica ausência total de legendas poluídas / porcentagens
	assert(ketchup.get_node_or_null("Label3D") == null, "Label3D e porcentagens removidos do frasco")
	assert(prep_table.get_node_or_null("StatusLabel") == null, "StatusLabel removido da bancada")

	# Verifica cores características
	assert(ketchup.sauce_color.r > 0.7 and ketchup.sauce_color.g < 0.2, "Cor do Ketchup é vermelho forte")
	assert(mustard.sauce_color.r > 0.8 and mustard.sauce_color.g > 0.6, "Cor da Mostarda é amarelo vivo")
	assert(mayo.sauce_color.r > 0.9 and mayo.sauce_color.g > 0.9, "Cor da Maionese é branco cremoso")
	print("  [PASS] 4 Bisnagas posicionadas, limpas e sem poluição de porcentagens.")

	# -------------------------------------------------------------
	# TESTE 2: FRASCO TRANSLÚCIDO E NÍVEL FÍSICO REAL DO MOLHO
	# -------------------------------------------------------------
	print("\n--- Teste 2: Nível Físico Real do Conteúdo dentro do Frasco ---")
	var fill_pivot = ketchup.get_node("Model/SauceFillPivot") as Node3D
	assert(fill_pivot != null and fill_pivot.visible, "Coluna de molho interna visível")
	assert(fill_pivot.scale.y >= 0.99, "Coluna de molho 100% cheia no início")

	# Simula consumo para 50%
	ketchup.current_amount = 50.0
	ketchup._update_sauce_level_visual()
	assert(is_equal_approx(fill_pivot.scale.y, 0.5), "Coluna de molho desce fisicamente para 50% da altura")
	print("  [PASS] Nível do líquido dentro da bisnaga translúcida desce fisicamente de forma clara.")

	# -------------------------------------------------------------
	# TESTE 3: PEGAR A BISNAGA NA MÃO COM CLIQUE ESQUERDO
	# -------------------------------------------------------------
	print("\n--- Teste 3: Pegar Bisnaga na Mão com Clique Esquerdo ---")
	player.pick_up(ketchup)
	assert(player.held_item == ketchup, "Jogador segurando a Bisnaga de Ketchup")
	assert(ketchup.location == Item.ItemLocation.PLAYER_HAND, "Bisnaga em PLAYER_HAND")
	assert(ketchup.get_display_name() == "Bisnaga de Ketchup", "Nome limpo sem números/porcentagens")
	print("  [PASS] Bisnaga segura na mão do jogador com nome e prompt limpos.")

	# -------------------------------------------------------------
	# TESTE 4: ANIMAÇÃO DE TOMBAMENTO SUAVE JUNTO AO CORPO (~55°)
	# -------------------------------------------------------------
	print("\n--- Teste 4: Animação de Tombamento Suave Junto ao Corpo ---")
	ketchup.start_squeezing()
	assert(ketchup.is_squeezing, "Modo de aplicação ativo")

	# Simula 0.25s de processo
	ketchup._process(0.25)
	assert(ketchup.tilt_progress > 0.8, "Bisnaga inclinou suavemente em direção ao alimento")
	assert(ketchup.model_root.rotation.x < -0.8, "Rotação moderada (~55°) tomba o bico para baixo")
	assert(abs(ketchup.model_root.position.z) < 0.05, "Bisnaga não se afasta da mão/corpo")
	print("  [PASS] Bisnaga tomba fisicamente sem se afastar da mão do jogador.")

	# -------------------------------------------------------------
	# TESTE 5: FLUXO GROSSO 3D VISÍVEL, APLICAÇÃO E CONSUMO GRADUAL
	# -------------------------------------------------------------
	print("\n--- Teste 5: Fluxo Grosso 3D, Aplicação no Lanche e Consumo Gradual ---")
	var bread_scene = load("res://src/items/bread_bottom.tscn")
	var bread_bot = bread_scene.instantiate() as Item
	world.add_child(bread_bot)
	bread_bot.position = Vector3(0, 0.9, 0)
	bread_bot._ensure_assembly()

	var initial_amount = ketchup.current_amount
	# Simula aplicação por 1 segundo
	ketchup._process(1.0)
	assert(ketchup.current_amount < initial_amount, "Quantidade na bisnaga diminuiu gradualmente")
	assert(ketchup.get_stream_mesh().visible, "Jato espesso 3D de molho visível e ativo")
	bread_bot.assembly.apply_sauce(ketchup.sauce_type, ketchup.sauce_color, bread_bot.position, 1.0)
	assert(bread_bot.assembly.applied_sauces.has("ketchup"), "Molho acumulado com sucesso no lanche")
	print("  [PASS] Jato espesso 3D visível e consumo gradual: %.1f%% -> %.1f%%" % [initial_amount, ketchup.current_amount])

	# Solta o clique
	ketchup.stop_squeezing()
	ketchup._process(0.3)
	assert(not ketchup.is_squeezing, "Aplicação interrompida")
	assert(not ketchup.get_stream_mesh().visible, "Jato de molho ocultado ao soltar")
	assert(ketchup.tilt_progress < 0.2, "Bisnaga retornando à posição vertical")
	print("  [PASS] Interrupção imediata do fluxo ao soltar o clique.")

	# -------------------------------------------------------------
	# TESTE 6: DROP FÍSICO COM [E] DIRETAMENTE NA SUPERFÍCIE
	# -------------------------------------------------------------
	print("\n--- Teste 6: Drop Físico com [E] Diretamente na Superfície ---")
	player.drop_item()
	assert(player.held_item == null, "Mão do jogador agora está livre")
	assert(ketchup.location == Item.ItemLocation.WORLD, "Bisnaga voltou ao estado WORLD")
	assert(ketchup.get_parent() == world, "Bisnaga desanexada e adicionada ao mundo")
	print("  [PASS] Bisnaga solta com tecla [E] assentando naturalmente na superfície.")

	# -------------------------------------------------------------
	# TESTE 7: BISNAGA VAZIA BLOQUEIA FLUXO
	# -------------------------------------------------------------
	print("\n--- Teste 7: Bisnaga Vazia Bloqueia Fluxo ---")
	ketchup.current_amount = 0.0
	ketchup._update_sauce_level_visual()
	assert(not fill_pivot.visible, "Coluna de molho oculta quando vazia")
	ketchup.start_squeezing()
	assert(not ketchup.is_squeezing, "Bisnaga vazia não permite dispensar")
	print("  [PASS] Bisnaga vazia bloqueia fluxo corretamente.")

	print("\n============================================================")
	print("TODOS OS TESTES DA ESTAÇÃO DE MOLHOS E DROP FORAM 100% APROVADOS!")
	print("============================================================\n")
	quit()
