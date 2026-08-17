extends SceneTree

# =============================================================================
# BURGER RUSH - TEST SUITE: ESTOQUE VISUAL DO OUTRO LADO DO ARMAZÉM
# + IDENTIFICAÇÃO VISUAL FÍSICA DISCRETA DAS BANCADAS
# (Bancada dos Pães, Bancada de Ovos & Bacon, Bancada das Polpas)
# =============================================================================

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(75))
	print("TESTE: ESTOQUE VISUAL E ETIQUETAS FÍSICAS DO ARMAZÉM SUL")
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

	print("--- TESTE 1: Presença e Posicionamento das Bancadas do Armazém Sul ---")
	var bread_rack: StorageRack = root_node.get_node_or_null("StorageRack")
	var bacon_egg_station: BaconEggStation = root_node.get_node_or_null("BaconEggStation")
	var pulp_table: PulpStorageTable = root_node.get_node_or_null("PulpStorageTable")

	assert_test(bread_rack != null, "Bancada dos Pães (StorageRack) encontrada na cena")
	assert_test(bacon_egg_station != null, "Bancada de Bacon & Ovos (BaconEggStation) encontrada na cena")
	assert_test(pulp_table != null, "Bancada das Polpas (PulpStorageTable) encontrada na cena")

	if bread_rack and bacon_egg_station and pulp_table:
		assert_test(is_equal_approx(bread_rack.position.z, -0.55), "Bancada dos Pães alinhada na parede Sul (Z = %.2f)" % bread_rack.position.z)
		assert_test(is_equal_approx(bacon_egg_station.position.z, -0.55), "Bancada de Bacon & Ovos alinhada na parede Sul (Z = %.2f)" % bacon_egg_station.position.z)
		assert_test(is_equal_approx(pulp_table.position.z, -0.55), "Bancada das Polpas alinhada na parede Sul (Z = %.2f)" % pulp_table.position.z)

	print("\n--- TESTE 2: Identificação Física Integrada (Sem Textos Flutuantes) ---")
	if bread_rack:
		var lbl_bread_main: Label3D = bread_rack.get_node_or_null("Model/TableFrontBadge/Label")
		var lbl_bread_top: Label3D = bread_rack.get_node_or_null("Model/BoxBreadTop/Badge/Label")
		var lbl_bread_bot: Label3D = bread_rack.get_node_or_null("Model/BoxBreadBottom/Badge/Label")

		assert_test(lbl_bread_main != null and lbl_bread_main.text == "PÃES", "Etiqueta física frontal 'PÃES' fixada na bancada")
		assert_test(lbl_bread_top != null and lbl_bread_top.text == "TAMPA", "Etiqueta física 'TAMPA' fixada na caixa esquerda")
		assert_test(lbl_bread_bot != null and lbl_bread_bot.text == "BASE", "Etiqueta física 'BASE' fixada na caixa direita")
		if lbl_bread_main:
			assert_test(lbl_bread_main.billboard == BaseMaterial3D.BILLBOARD_DISABLED, "Etiqueta 'PÃES' sem billboard flutuante (placa física)")

	if bacon_egg_station:
		var lbl_be_main: Label3D = bacon_egg_station.get_node_or_null("Model/TableFrontBadge/Label")
		var lbl_bacon: Label3D = bacon_egg_station.get_node_or_null("Model/BaconArea/Badge/Label")
		var lbl_egg: Label3D = bacon_egg_station.get_node_or_null("Model/EggArea/Badge/Label")

		assert_test(lbl_be_main != null and lbl_be_main.text == "BACON & OVOS", "Etiqueta física frontal 'BACON & OVOS' fixada na bancada")
		assert_test(lbl_bacon != null and lbl_bacon.text == "BACON", "Etiqueta física 'BACON' fixada próxima ao estoque de bacon")
		assert_test(lbl_egg != null and lbl_egg.text == "OVOS", "Etiqueta física 'OVOS' fixada próxima ao cesto de ovos")
		if lbl_bacon:
			assert_test(lbl_bacon.billboard == BaseMaterial3D.BILLBOARD_DISABLED, "Etiqueta 'BACON' sem billboard flutuante (adesivo físico)")

	if pulp_table:
		var lbl_pulp: Label3D = pulp_table.get_node_or_null("Model/Crate/CrateBadge/Label")
		assert_test(lbl_pulp != null and lbl_pulp.text == "POLPA DE FRUTA", "Etiqueta física discreta 'POLPA DE FRUTA' fixada no cesto")
		if lbl_pulp:
			assert_test(lbl_pulp.billboard == BaseMaterial3D.BILLBOARD_DISABLED, "Etiqueta 'POLPA DE FRUTA' sem billboard flutuante (placa física)")

	# Garante que nenhum StatusLabel flutuante em billboard existe
	var floating_status_rack = bread_rack.get_node_or_null("StatusLabel")
	var floating_status_be = bacon_egg_station.get_node_or_null("StatusLabel")
	var floating_status_pulp = pulp_table.get_node_or_null("StatusLabel")
	assert_test(floating_status_rack == null, "Bancada dos Pães sem StatusLabel flutuante no ar")
	assert_test(floating_status_be == null, "Bancada de Bacon & Ovos sem StatusLabel flutuante no ar")
	assert_test(floating_status_pulp == null, "Bancada de Polpas sem StatusLabel flutuante no ar")

	var inv = InventoryManager.get_instance()
	assert_test(inv != null, "InventoryManager ativo")

	var player = root_node.get_node_or_null("Player")
	assert_test(player != null, "Player presente na cena")

	print("\n--- TESTE 3: Bancada dos Pães — Estoque Visual Dinâmico (3 Estágios) ---")
	if inv and bread_rack:
		# 3.1 Tampas de Pão (bread_top)
		inv.items["bread_top"]["quantity"] = 30 # CHEIO
		bread_rack._update_all_visual_stocks()
		assert_test(bread_rack.bread_top_full.visible == true and bread_rack.bread_top_med.visible == false and bread_rack.bread_top_low.visible == false,
			"Tampas de Pão CHEIO (qtd 30) -> Full visível, Med/Low ocultos")

		inv.items["bread_top"]["quantity"] = 12 # MÉDIO
		bread_rack._update_all_visual_stocks()
		assert_test(bread_rack.bread_top_full.visible == false and bread_rack.bread_top_med.visible == true and bread_rack.bread_top_low.visible == false,
			"Tampas de Pão MÉDIO (qtd 12) -> Med visível, Full/Low ocultos")

		inv.items["bread_top"]["quantity"] = 3 # BAIXO
		bread_rack._update_all_visual_stocks()
		assert_test(bread_rack.bread_top_full.visible == false and bread_rack.bread_top_med.visible == false and bread_rack.bread_top_low.visible == true,
			"Tampas de Pão BAIXO (qtd 3) -> Low visível, Full/Med ocultos")

		inv.items["bread_top"]["quantity"] = 0 # ZERO
		bread_rack._update_all_visual_stocks()
		assert_test(bread_rack.bread_top_full.visible == false and bread_rack.bread_top_med.visible == false and bread_rack.bread_top_low.visible == false,
			"Tampas de Pão ZERO (qtd 0) -> Caixa vazia, nenhum produto falso visível")

		# 3.2 Bases de Pão (bread_bottom)
		inv.items["bread_bottom"]["quantity"] = 25 # CHEIO
		bread_rack._update_all_visual_stocks()
		assert_test(bread_rack.bread_bot_full.visible == true and bread_rack.bread_bot_med.visible == false and bread_rack.bread_bot_low.visible == false,
			"Bases de Pão CHEIO (qtd 25) -> Full visível, Med/Low ocultos")

		inv.items["bread_bottom"]["quantity"] = 10 # MÉDIO
		bread_rack._update_all_visual_stocks()
		assert_test(bread_rack.bread_bot_full.visible == false and bread_rack.bread_bot_med.visible == true and bread_rack.bread_bot_low.visible == false,
			"Bases de Pão MÉDIO (qtd 10) -> Med visível, Full/Low ocultos")

		inv.items["bread_bottom"]["quantity"] = 2 # BAIXO
		bread_rack._update_all_visual_stocks()
		assert_test(bread_rack.bread_bot_full.visible == false and bread_rack.bread_bot_med.visible == false and bread_rack.bread_bot_low.visible == true,
			"Bases de Pão BAIXO (qtd 2) -> Low visível, Full/Med ocultos")

		inv.items["bread_bottom"]["quantity"] = 0 # ZERO
		bread_rack._update_all_visual_stocks()
		assert_test(bread_rack.bread_bot_full.visible == false and bread_rack.bread_bot_med.visible == false and bread_rack.bread_bot_low.visible == false,
			"Bases de Pão ZERO (qtd 0) -> Caixa vazia, nenhum produto falso visível")

	print("\n--- TESTE 4: Bancada de Bacon & Ovos — Independência de Estoque e 3 Estágios ---")
	if inv and bacon_egg_station:
		# 4.1 Bacon
		inv.items["bacon"]["quantity"] = 20 # CHEIO
		inv.items["egg"]["quantity"] = 20   # CHEIO
		bacon_egg_station._update_all_visual_stocks()
		assert_test(bacon_egg_station.bacon_full.visible == true and bacon_egg_station.bacon_med.visible == false and bacon_egg_station.bacon_low.visible == false,
			"Bacon CHEIO (qtd 20) -> Full visível, Med/Low ocultos")
		assert_test(bacon_egg_station.egg_full.visible == true, "Ovos permanecem CHEIO ao abastecer Bacon")

		inv.items["bacon"]["quantity"] = 8 # MÉDIO
		bacon_egg_station._update_all_visual_stocks()
		assert_test(bacon_egg_station.bacon_full.visible == false and bacon_egg_station.bacon_med.visible == true and bacon_egg_station.bacon_low.visible == false,
			"Bacon MÉDIO (qtd 8) -> Med visível, Full/Low ocultos")
		assert_test(bacon_egg_station.egg_full.visible == true, "Ovos permanecem CHEIO após consumo de Bacon (Independência validada)")

		inv.items["bacon"]["quantity"] = 2 # BAIXO
		bacon_egg_station._update_all_visual_stocks()
		assert_test(bacon_egg_station.bacon_full.visible == false and bacon_egg_station.bacon_med.visible == false and bacon_egg_station.bacon_low.visible == true,
			"Bacon BAIXO (qtd 2) -> Low visível, Full/Med ocultos")

		inv.items["bacon"]["quantity"] = 0 # ZERO
		bacon_egg_station._update_all_visual_stocks()
		assert_test(bacon_egg_station.bacon_full.visible == false and bacon_egg_station.bacon_med.visible == false and bacon_egg_station.bacon_low.visible == false,
			"Bacon ZERO (qtd 0) -> Área vazia, nenhum pacote falso visível")
		assert_test(bacon_egg_station.egg_full.visible == true, "Ovos continuam CHEIO mesmo com Bacon zerado")

		# 4.2 Ovos
		inv.items["egg"]["quantity"] = 8 # MÉDIO
		bacon_egg_station._update_all_visual_stocks()
		assert_test(bacon_egg_station.egg_full.visible == false and bacon_egg_station.egg_med.visible == true and bacon_egg_station.egg_low.visible == false,
			"Ovos MÉDIO (qtd 8) -> Med visível, Full/Low ocultos")

		inv.items["egg"]["quantity"] = 2 # BAIXO
		bacon_egg_station._update_all_visual_stocks()
		assert_test(bacon_egg_station.egg_full.visible == false and bacon_egg_station.egg_med.visible == false and bacon_egg_station.egg_low.visible == true,
			"Ovos BAIXO (qtd 2) -> Low visível, Full/Med ocultos")

		inv.items["egg"]["quantity"] = 0 # ZERO
		bacon_egg_station._update_all_visual_stocks()
		assert_test(bacon_egg_station.egg_full.visible == false and bacon_egg_station.egg_med.visible == false and bacon_egg_station.egg_low.visible == false,
			"Ovos ZERO (qtd 0) -> Cesto vazio, nenhum ovo falso visível")

	print("\n--- TESTE 5: Bancada das Polpas — 3 Sabores Independentes e 3 Estágios ---")
	if inv and pulp_table:
		# Laranja CHEIO, Uva MÉDIO, Morango ZERO
		inv.items["pulp_orange"]["quantity"] = 10
		inv.items["pulp_grape"]["quantity"] = 5
		inv.items["pulp_strawberry"]["quantity"] = 0
		pulp_table._sync_from_inventory()
		pulp_table._update_all_visuals()

		# Laranja (CHEIO: 10 visíveis)
		var visible_orange = 0
		for slot in range(10):
			var node = pulp_table.get_node_or_null("Model/Crate/Pulp_0_%d" % slot)
			if node and node.visible: visible_orange += 1
		assert_test(visible_orange == 10, "Polpa de Laranja CHEIO -> 10 pedras visíveis (encontradas: %d)" % visible_orange)

		# Uva (MÉDIO: 5 visíveis)
		var visible_grape = 0
		for slot in range(10):
			var node = pulp_table.get_node_or_null("Model/Crate/Pulp_1_%d" % slot)
			if node and node.visible: visible_grape += 1
		assert_test(visible_grape == 5, "Polpa de Uva MÉDIO -> 5 pedras visíveis (encontradas: %d)" % visible_grape)

		# Morango (ZERO: 0 visíveis)
		var visible_strawberry = 0
		for slot in range(10):
			var node = pulp_table.get_node_or_null("Model/Crate/Pulp_2_%d" % slot)
			if node and node.visible: visible_strawberry += 1
		assert_test(visible_strawberry == 0, "Polpa de Morango ZERO -> 0 pedras visíveis no cesto (encontradas: %d)" % visible_strawberry)

		# Morango BAIXO (qtd 2 -> 2 visíveis)
		inv.items["pulp_strawberry"]["quantity"] = 2
		pulp_table._sync_from_inventory()
		pulp_table._update_all_visuals()
		visible_strawberry = 0
		for slot in range(10):
			var node = pulp_table.get_node_or_null("Model/Crate/Pulp_2_%d" % slot)
			if node and node.visible: visible_strawberry += 1
		assert_test(visible_strawberry == 2, "Polpa de Morango BAIXO (qtd 2) -> 2 pedras visíveis (encontradas: %d)" % visible_strawberry)

	print("\n--- TESTE 6: Regras de Interação (Clique = Pega/Devolve, E = Não Pega) ---")
	if inv and player and bread_rack and bacon_egg_station and pulp_table:
		# Restaura estoques
		inv.items["bread_top"]["quantity"] = 10
		inv.items["bread_bottom"]["quantity"] = 10
		inv.items["bacon"]["quantity"] = 10
		inv.items["egg"]["quantity"] = 10
		inv.items["pulp_orange"]["quantity"] = 10
		bread_rack._update_all_visual_stocks()
		bacon_egg_station._update_all_visual_stocks()
		pulp_table._sync_from_inventory()
		pulp_table._update_all_visuals()

		# Prompts limpos
		bread_rack.active_item_index = 0
		var p_bread = bread_rack.get_interaction_prompt(player)
		assert_test(not ("(" in p_bread or "%" in p_bread or "10" in p_bread), "Prompt de Tampa do Pão sem contadores/porcentagens: '%s'" % p_bread)

		bacon_egg_station.active_item_index = 0
		var p_bacon = bacon_egg_station.get_interaction_prompt(player)
		assert_test(not ("(" in p_bacon or "%" in p_bacon or "10" in p_bacon), "Prompt de Bacon sem contadores/porcentagens: '%s'" % p_bacon)

		var p_pulp = pulp_table.get_interaction_prompt(player)
		assert_test(not ("(" in p_pulp or "%" in p_pulp or "10" in p_pulp), "Prompt de Polpa sem contadores/porcentagens: '%s'" % p_pulp)

		# Pressionar E NÃO pega item
		bread_rack.interact(player)
		assert_test(player.held_item == null, "Pressionar E na Bancada de Pães NÃO pega item")
		assert_test(inv.get_stock("bread_top") == 10, "Estoque de Pão permanece inalterado ao pressionar E")

		bacon_egg_station.interact(player)
		assert_test(player.held_item == null, "Pressionar E na Bancada de Bacon/Ovos NÃO pega item")
		assert_test(inv.get_stock("bacon") == 10, "Estoque de Bacon permanece inalterado ao pressionar E")

		pulp_table.interact(player)
		assert_test(player.held_item == null, "Pressionar E na Bancada de Polpas NÃO pega item")
		assert_test(inv.get_stock("pulp_orange") == 10, "Estoque de Polpa permanece inalterado ao pressionar E")

		# Clique Esquerdo PEGA item
		# 1. Pão
		bread_rack.interact_item(player)
		assert_test(player.held_item != null and str(player.held_item.get("item_id")) == "bread_top", "Jogador pegou BreadTop via clique esquerdo")
		assert_test(inv.get_stock("bread_top") == 9, "Estoque de bread_top decrementado para 9")

		# Devolução de Pão
		bread_rack.interact_item(player)
		assert_test(player.held_item == null, "Jogador devolveu BreadTop via clique esquerdo")
		assert_test(inv.get_stock("bread_top") == 10, "Estoque de bread_top incrementado de volta para 10")

		# 2. Bacon
		bacon_egg_station.interact_item(player)
		assert_test(player.held_item != null and player.held_item is Bacon, "Jogador pegou Bacon via clique esquerdo")
		assert_test(inv.get_stock("bacon") == 9, "Estoque de bacon decrementado para 9")

		# Devolução de Bacon
		bacon_egg_station.interact_item(player)
		assert_test(player.held_item == null, "Jogador devolveu Bacon via clique esquerdo")
		assert_test(inv.get_stock("bacon") == 10, "Estoque de bacon incrementado de volta para 10")

		# 3. Polpa de Fruta
		pulp_table.interact_item(player)
		assert_test(player.held_item != null and player.held_item is JuicePulp, "Jogador pegou JuicePulp via clique esquerdo")
		assert_test(inv.get_stock("pulp_orange") == 9, "Estoque de pulp_orange decrementado para 9")

		# Devolução de Polpa
		pulp_table.interact_item(player)
		assert_test(player.held_item == null, "Jogador devolveu JuicePulp via clique esquerdo")
		assert_test(inv.get_stock("pulp_orange") == 10, "Estoque de pulp_orange incrementado de volta para 10")

	print("\n" + "=".repeat(75))
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(75) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES PASSARAM COM SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
