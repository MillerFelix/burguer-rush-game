extends SceneTree

# ==============================================================================
# BURGER RUSH - TESTE DE VALIDAÇÃO DE BUGS E RESTAURAÇÃO VISUAL (v0.1.6)
# ==============================================================================

func _init() -> void:
	print("\n==================================================")
	print("🧪 INICIANDO TESTES: BUGFIXES E RESTAURAÇÃO VISUAL")
	print("==================================================")
	
	var passed = 0
	var failed = 0
	
	# --------------------------------------------------------------------------
	# TESTE 1: PÃO FANTASMA NA MÃO DO JOGADOR (PICK MÚLTIPLOS E DROP TOTAL)
	# --------------------------------------------------------------------------
	print("\n[TESTE 1] Sistema de Mãos / Quick Slots / Drop sem Pão Fantasma...")
	var player_scene = load("res://src/player/player.tscn")
	if not player_scene:
		print("❌ Falha ao carregar player.tscn")
		failed += 1
	else:
		var player = player_scene.instantiate()
		root.add_child(player)
		
		# Simula pegar 3 pães/ingredientes reais em slots rápidos
		var bread1 = load("res://src/items/bread_bottom.tscn").instantiate()
		var bread2 = load("res://src/items/bread_top.tscn").instantiate()
		var patty = load("res://src/items/patty.tscn").instantiate()
		
		player.pick_up(bread1)
		player.pick_up(bread2)
		player.pick_up(patty)
		
		var hold_pos = player.get_node_or_null("Head/Camera3D/HoldPosition")
		if not hold_pos:
			print("❌ HoldPosition não encontrado no player")
			failed += 1
		else:
			print("  - 3 itens coletados. Filhos em HoldPosition: %d (esperado 1 visual ativo)" % hold_pos.get_child_count())
			if hold_pos.get_child_count() == 1:
				passed += 1
			else:
				failed += 1
				
			# Dropar item 1
			player.drop_item()
			print("  - Dropped 1 item. Filhos em HoldPosition: %d" % hold_pos.get_child_count())
			if hold_pos.get_child_count() == 1:
				passed += 1
			else:
				failed += 1
				
			# Dropar item 2
			player.drop_item()
			print("  - Dropped 2o item. Filhos em HoldPosition: %d" % hold_pos.get_child_count())
			if hold_pos.get_child_count() == 1:
				passed += 1
			else:
				failed += 1
				
			# Dropar item 3 (todos os slots ficam vazios)
			player.drop_item()
			print("  - Dropped todos os itens. Filhos em HoldPosition: %d, held_item: %s, quick_slot_visual: %s" % [
				hold_pos.get_child_count(),
				str(player.held_item),
				str(player.quick_slot_visual)
			])
			
			if hold_pos.get_child_count() == 0 and player.held_item == null and player.quick_slot_visual == null:
				print("  ✅ SUCESSO: Nenhum pão fantasma ou nó órfão permaneceu preso à mão!")
				passed += 1
			else:
				print("  ❌ FALHA: Restou nó fantasma ou held_item inválido na mão")
				failed += 1
				
		player.queue_free()

	# --------------------------------------------------------------------------
	# TESTE 2: GRELHA E CICLO DETERMINÍSTICO (DIRTY -> CLEANING -> CLEAN)
	# --------------------------------------------------------------------------
	print("\n[TESTE 2] Ciclo de Limpeza da Grelha e Liberação de Uso...")
	var grill_scene = load("res://src/stations/grill.tscn")
	if not grill_scene:
		print("❌ Falha ao carregar grill.tscn")
		failed += 1
	else:
		var grill = grill_scene.instantiate()
		root.add_child(grill)
		
		# 1. Estado inicial limpo
		if not grill.is_dirty() and grill.dirt_level == 0.0:
			print("  ✅ Grelha inicia limpa")
			passed += 1
		else:
			print("  ❌ Grelha não iniciou limpa")
			failed += 1
			
		# 2. Sujar a grelha
		grill.add_dirt(0.60)
		if grill.is_dirty() and grill.cleanliness_state == Grill.CleanlinessState.DIRTY:
			print("  ✅ Grelha detecta sujeira (dirt_level: %.2f)" % grill.dirt_level)
			passed += 1
		else:
			print("  ❌ Grelha não transitou para DIRTY")
			failed += 1
			
		# 3. Tentar colocar ingrediente enquanto suja deve ser bloqueado
		var test_patty = load("res://src/items/patty.tscn").instantiate()
		var placed_dirty = grill.place_item(test_patty)
		if not placed_dirty:
			print("  ✅ Bloqueio de ingrediente em chapa suja funcionando")
			passed += 1
		else:
			print("  ❌ Grelha permitiu ingrediente em chapa suja")
			failed += 1
			
		# 4. Limpeza parcial
		var finished_partial = grill.clean_progress(0.3)
		if not finished_partial and grill.cleanliness_state == Grill.CleanlinessState.CLEANING and grill.is_dirty():
			print("  ✅ Estado CLEANING durante limpeza contínua")
			passed += 1
		else:
			print("  ❌ Transição para CLEANING falhou")
			failed += 1
			
		# 5. Limpeza completa
		var finished_full = grill.clean_progress(2.0)
		var dirt_mesh = grill.get_node_or_null("Model/GrillPlate/GrillDirt")
		var is_dirt_hidden = dirt_mesh and not dirt_mesh.visible
		if finished_full and not grill.is_dirty() and grill.dirt_level == 0.0 and grill.cleanliness_state == Grill.CleanlinessState.CLEAN and is_dirt_hidden:
			print("  ✅ Grelha 100% CLEAN: dirt_level == 0, sujeira visual oculta")
			passed += 1
		else:
			print("  ❌ Falha na finalização da limpeza da grelha")
			failed += 1
			
		# 6. Colocar ingrediente imediatamente após limpeza deve ter sucesso
		var placed_clean = grill.place_item(test_patty)
		if placed_clean:
			print("  ✅ Ingrediente colocado com sucesso na chapa limpa!")
			passed += 1
		else:
			print("  ❌ Falha ao colocar ingrediente após limpeza")
			failed += 1
			
		grill.queue_free()

	# --------------------------------------------------------------------------
	# TESTE 3: MATERIAIS E TEXTURAS RESTAURADAS
	# --------------------------------------------------------------------------
	print("\n[TESTE 3] Validação de Texturas Restauradas (Piso, Paredes e Madeira)...")
	var main_scene = load("res://src/main.tscn")
	if not main_scene:
		print("❌ Falha ao carregar main.tscn")
		failed += 1
	else:
		var main_inst = main_scene.instantiate()
		root.add_child(main_inst)
		
		var floor_kitchen = main_inst.get_node_or_null("Room/FloorKitchen")
		if floor_kitchen and floor_kitchen.material:
			var mat = floor_kitchen.material as StandardMaterial3D
			if mat and mat.albedo_texture != null and mat.uv1_scale.x <= 4.0:
				print("  ✅ Piso da Cozinha com grandes azulejos brancos e escala adequada (uv1_scale: %s)" % str(mat.uv1_scale))
				passed += 1
			else:
				print("  ❌ Piso da cozinha com textura ou escala incorreta")
				failed += 1
		else:
			print("  ❌ FloorKitchen não encontrado")
			failed += 1
			
		var wall_north = main_inst.get_node_or_null("Room/WallNorth")
		if wall_north and wall_north.material:
			var mat = wall_north.material as StandardMaterial3D
			if mat and mat.albedo_texture != null:
				print("  ✅ Parede da Cozinha com azulejos brancos detalhados restaurados")
				passed += 1
			else:
				print("  ❌ Parede da cozinha sem textura de azulejos")
				failed += 1
		else:
			print("  ❌ WallNorth não encontrado")
			failed += 1
			
		var counter_base = main_inst.get_node_or_null("Room/MainCounterBase")
		if counter_base and counter_base.material:
			var mat = counter_base.material as StandardMaterial3D
			if mat and mat.albedo_texture != null:
				print("  ✅ Bancada principal com textura visível de madeira natural restaurada")
				passed += 1
			else:
				print("  ❌ Bancada principal sem textura de madeira")
				failed += 1
		else:
			print("  ❌ MainCounterBase não encontrado")
			failed += 1
			
		main_inst.queue_free()

	print("\n==================================================")
	print("📊 RESULTADO FINAL: %d PASSOU | %d FALHOU" % [passed, failed])
	print("==================================================")
	
	if failed == 0:
		print("🎉 TODOS OS TESTES PASSARAM COM SUCESSO!")
	else:
		print("⚠️ ALGUNS TESTES FALHARAM!")
		
	quit(0 if failed == 0 else 1)
