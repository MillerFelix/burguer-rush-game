extends SceneTree

# =============================================================================
# BURGER RUSH - TESTE DE VALIDAÇÃO: BUCHA NA MÃO, ESPÁTULA E NOME PLACEHOLDER
# =============================================================================

var pass_count = 0
var fail_count = 0

func _init() -> void:
	print("\n=================================================================")
	print("=== TESTE DE GAMEPLAY: BUCHA NA MÃO + ESPÁTULA + PLACEHOLDER ===")
	print("=================================================================\n")
	
	_test_placeholder_name()
	_test_sponge_visual_and_cleaning()
	_test_spatula_and_grill_mechanics()
	_test_multiple_patties_aim_precision()
	
	print("\n=================================================================")
	print("RESULTADO DO TESTE: %d PASSOU / %d FALHOU" % [pass_count, fail_count])
	print("=================================================================\n")
	
	if fail_count == 0:
		print(">>> SUCESSO TOTAL: TODOS OS AJUSTES DE GAMEPLAY VALIDADOS! <<<\n")
		quit(0)
	else:
		printerr(">>> ERRO: FALHAS DETECTADAS NOS AJUSTES! <<<\n")
		quit(1)

func assert_true(condition: bool, message: String) -> void:
	if condition:
		pass_count += 1
		print("  [PASS] %s" % message)
	else:
		fail_count += 1
		printerr("  [FAIL] %s" % message)

func _test_placeholder_name() -> void:
	print("--- TESTE 1: Placeholder do Nome do Chefe ---")
	var intro_scene = load("res://src/ui/intro_story.tscn")
	assert_true(intro_scene != null, "Cena intro_story.tscn carregada com sucesso")
	if intro_scene:
		var intro_inst = intro_scene.instantiate()
		var name_input = intro_inst.find_child("NameInput", true, false) as LineEdit
		assert_true(name_input != null, "Campo NameInput presente na cena de história")
		if name_input:
			assert_true(not name_input.placeholder_text.to_lower().contains("miller"), "Placeholder não contém 'Miller'")
			assert_true(name_input.placeholder_text.contains("Carlos"), "Placeholder atualizado para exemplo neutro ('Carlos')")
		intro_inst.queue_free()

func _test_sponge_visual_and_cleaning() -> void:
	print("\n--- TESTE 2: Bucha na Mão e Funcionalidade de Limpeza ---")
	var player_scene = load("res://src/player/player.tscn")
	assert_true(player_scene != null, "Cena player.tscn carregada com sucesso")
	if not player_scene:
		return
	
	var player = player_scene.instantiate()
	root.add_child(player)
	
	# Seleciona a bucha (Slot 2)
	player.select_tool_slot(player.ToolSlot.SPONGE, false)
	assert_true(player.active_tool_slot == player.ToolSlot.SPONGE, "Slot da Bucha selecionado")
	
	var tool_holder = player.get_node_or_null("Head/Camera3D/ToolHolder")
	assert_true(tool_holder != null and tool_holder.get_child_count() > 0, "ToolHolder possui nó filho instanciado")
	
	var sponge = tool_holder.get_child(0) as Sponge if tool_holder and tool_holder.get_child_count() > 0 else null
	assert_true(sponge != null, "Objeto instanciado no ToolHolder é do tipo Sponge")
	if sponge:
		var model = sponge.get_node_or_null("Model")
		assert_true(model != null, "Modelo 3D da bucha presente")
		assert_true(sponge.is_clean(), "Bucha inicia limpa")
		
		# Testa simulação de sujeira na bucha
		sponge.set_dirty()
		assert_true(sponge.is_dirty, "Bucha fica suja após set_dirty()")
		assert_true(player.sponge_is_dirty, "Flag sponge_is_dirty no player sincronizada")
		
		# Lava a bucha
		sponge.set_clean()
		assert_true(sponge.is_clean(), "Bucha fica limpa após set_clean()")
		assert_true(not player.sponge_is_dirty, "Flag sponge_is_dirty no player desmarcada após lavagem")
	
	player.queue_free()

func _test_spatula_and_grill_mechanics() -> void:
	print("\n--- TESTE 3: Espátula, Chapa e Impossibilidade de Pegar Hambúrguer com a Mão ---")
	var player_scene = load("res://src/player/player.tscn")
	var grill_scene = load("res://src/stations/grill.tscn")
	var patty_scene = load("res://src/items/patty.tscn")
	
	var player = player_scene.instantiate()
	var grill = grill_scene.instantiate() as Grill
	root.add_child(player)
	root.add_child(grill)
	
	# Coloca um hambúrguer na grelha
	var patty1 = patty_scene.instantiate() as Patty
	patty1.meat_type = Patty.MeatType.BEEF
	grill.place_item(patty1)
	assert_true(grill.active_items.size() == 1, "Hambúrguer colocado na chapa")
	
	# Simula cozimento do hambúrguer até ficar pronto
	patty1.side_a_cooked = 100.0
	patty1.state = Patty.State.READY_SIDE_1
	
	# Configura raycast do player mirando no hambúrguer da grelha
	var ray = player.get_node("Head/Camera3D/RayCast3D")
	ray.set_meta("test_collider", patty1)
	ray.set_meta("test_collision_point", patty1.global_position)
	
	# 1. TESTE COM MÃOS LIVRES (SLOT 3): NÃO PODE PEGAR O HAMBÚRGUER DA CHAPA!
	player.select_tool_slot(player.ToolSlot.HANDS, false)
	grill.interact_item(player)
	assert_true(grill.active_items.size() == 1, "Hambúrguer NÃO foi retirado com a mão livre")
	assert_true(player.held_item == null, "Mão do jogador permanece livre (sem queimaduras de chapa)")
	assert_true(player.quick_slots[0].is_empty(), "Hambúrguer não entrou nos slots rápidos da mão")
	
	# 2. TESTE COM ESPÁTULA (SLOT 1): VIRA E DEPOIS RETIRA PARA A ESPÁTULA
	player.select_tool_slot(player.ToolSlot.SPATULA, false)
	assert_true(player.active_tool_slot == player.ToolSlot.SPATULA, "Espátula equipada no Slot 1")
	
	# Vira o hambúrguer
	grill.interact_item(player)
	assert_true(patty1.is_flipped, "Hambúrguer virado com a espátula")
	assert_true(grill.active_items.size() == 1, "Hambúrguer continua na chapa grelhando lado 2")
	
	# Conclui cozimento do lado 2
	patty1.side_b_cooked = 100.0
	patty1.state = Patty.State.COOKED
	
	# Retira o hambúrguer com a espátula
	grill.interact_item(player)
	assert_true(grill.active_items.size() == 0, "Hambúrguer retirado da chapa pela espátula")
	
	var spatula = player.get_spatula() as Spatula
	assert_true(spatula != null, "Instância da Espátula obtida no player")
	assert_true(spatula.has_patty(), "Hambúrguer está PRESO NA ESPÁTULA")
	assert_true(spatula.get_held_patty() == patty1, "Hambúrguer correto está na espátula")
	assert_true(player.held_item == null, "Slot de mão principal continua livre (item está na lâmina)")
	assert_true(player.quick_slots[0].is_empty(), "Slots rápidos de ingredientes vazios")
	
	# 3. TESTE DE BLOQUEIO DE TROCA DE FERRAMENTA ENQUANTO A ESPÁTULA ESTÁ OCUPADA
	player.select_tool_slot(player.ToolSlot.HANDS, false)
	assert_true(player.active_tool_slot == player.ToolSlot.SPATULA, "Troca de ferramenta BLOQUEADA enquanto a espátula tem hambúrguer")
	
	# 4. TESTE DE DEPOSITAR O HAMBÚRGUER NA MONTAGEM DO LANCHE (BreadBottom)
	var bread_bottom_scene = load("res://src/items/bread_bottom.tscn")
	var bread_bottom = bread_bottom_scene.instantiate() as BreadBottom
	root.add_child(bread_bottom)
	bread_bottom.global_position = Vector3(1, 0, 0)
	
	ray.set_meta("test_collider", bread_bottom)
	ray.set_meta("test_collision_point", bread_bottom.global_position)
	
	bread_bottom.interact_item(player)
	assert_true(not spatula.has_patty(), "Espátula ficou LIVRE após depositar hambúrguer no pão")
	assert_true(bread_bottom.has_ingredients(), "Pão recebeu o hambúrguer da espátula")
	
	# 5. AGORA A ESPÁTULA ESTÁ LIVRE E O JOGADOR PODE TROCAR DE FERRAMENTA
	player.select_tool_slot(player.ToolSlot.HANDS, false)
	assert_true(player.active_tool_slot == player.ToolSlot.HANDS, "Troca de ferramenta permitida após espátula ser liberada")
	
	player.queue_free()
	grill.queue_free()
	bread_bottom.queue_free()

func _test_multiple_patties_aim_precision() -> void:
	print("\n--- TESTE 4: Precisão de Mira com Múltiplos Hambúrgueres na Chapa ---")
	var player_scene = load("res://src/player/player.tscn")
	var grill_scene = load("res://src/stations/grill.tscn")
	var patty_scene = load("res://src/items/patty.tscn")
	
	var player = player_scene.instantiate()
	var grill = grill_scene.instantiate() as Grill
	root.add_child(player)
	root.add_child(grill)
	
	var pA = patty_scene.instantiate() as Patty
	pA.meat_type = Patty.MeatType.BEEF
	grill.place_item(pA)
	
	var pB = patty_scene.instantiate() as Patty
	pB.meat_type = Patty.MeatType.CHICKEN
	grill.place_item(pB)
	
	assert_true(grill.active_items.size() == 2, "Dois hambúrgueres colocados na chapa")
	
	pA.side_a_cooked = 100.0
	pA.side_b_cooked = 100.0
	pA.state = Patty.State.COOKED
	
	pB.side_a_cooked = 20.0
	pB.state = Patty.State.COOKING_SIDE_1
	
	# Mira especificamente no pA
	var ray = player.get_node("Head/Camera3D/RayCast3D")
	ray.set_meta("test_collider", pA)
	ray.set_meta("test_collision_point", pA.global_position)
	
	player.select_tool_slot(player.ToolSlot.SPATULA, false)
	grill.interact_item(player)
	
	var spatula = player.get_spatula() as Spatula
	assert_true(spatula != null and spatula.get_held_patty() == pA, "Apenas o hambúrguer pA mirado foi retirado para a espátula")
	assert_true(grill.active_items.size() == 1, "Hambúrguer pB permaneceu intacto na chapa")
	assert_true(grill.active_items[0]["item"] == pB, "Item restante na chapa é exatamente o pB")
	
	player.queue_free()
	grill.queue_free()
