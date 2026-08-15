extends SceneTree

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE VISUAIS DO HAMBÚRGUER NA MÃO E ESTADOS")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	var patty_scene = load("res://src/items/patty.tscn")
	assert(patty_scene != null, "Cena patty.tscn deve existir")

	# 1. Teste de Hambúrguer Bovino Cru (RAW)
	print("\n--- Teste 1: Hambúrguer Bovino Cru ---")
	var beef_patty = patty_scene.instantiate() as Patty
	beef_patty.meat_type = Patty.MeatType.BEEF
	root.add_child(beef_patty)
	beef_patty._ready()

	assert(beef_patty.state == Patty.State.RAW, "Estado deve ser RAW")
	assert(beef_patty.get_display_name() == "Carne Bovina (Cru)", "Nome deve ser 'Carne Bovina (Cru)'")
	var mesh = beef_patty.get_node("MeshInstance3D") as MeshInstance3D
	var mat = mesh.material_override as StandardMaterial3D
	assert(mat != null, "Material deve estar atribuído")
	assert(mat.albedo_texture != null, "Texture RAW deve estar carregada")
	assert(mat.albedo_texture.resource_path.contains("meat_patty_beef_raw.png"), "Texture deve ser meat_patty_beef_raw")
	assert(mat.normal_texture != null and mat.normal_texture.resource_path.contains("meat_patty_normal.png"), "Normal map RAW ativo")
	print("  [PASS] Carne bovina crua com textura e normal map de carne moída crua.")

	# 2. Teste de Transição para COZIDO (COOKED com Marcas de Grelha)
	print("\n--- Teste 2: Transição para Cozido com Marcas de Grelha ---")
	beef_patty.set_state(Patty.State.COOKED)
	assert(beef_patty.state == Patty.State.COOKED, "Estado deve ser COOKED")
	assert(beef_patty.get_display_name() == "Carne Bovina (Pronto)", "Nome deve ser 'Carne Bovina (Pronto)'")
	mat = mesh.material_override as StandardMaterial3D
	assert(mat.albedo_texture.resource_path.contains("meat_patty_beef_cooked.png"), "Texture deve ser meat_patty_beef_cooked (com marcas de grelha)")
	assert(mat.normal_texture.resource_path.contains("meat_patty_cooked_normal.png"), "Normal map com marcas de grelha ativo")
	assert(is_equal_approx(mat.roughness, 0.45), "Roughness de carne grelhada suculenta (0.45)")
	print("  [PASS] Carne bovina cozida com marcas de grelha e textura tostada.")

	# 3. Teste de Transição para QUEIMADO (BURNT)
	print("\n--- Teste 3: Transição para Queimado ---")
	beef_patty.set_state(Patty.State.BURNT)
	assert(beef_patty.state == Patty.State.BURNT, "Estado deve ser BURNT")
	mat = mesh.material_override as StandardMaterial3D
	assert(mat.albedo_texture.resource_path.contains("meat_patty_burnt.png"), "Texture deve ser meat_patty_burnt")
	assert(is_equal_approx(mat.roughness, 0.95), "Roughness de carvão/cinza (0.95)")
	print("  [PASS] Carne queimada com textura carbonizada fosca.")
	beef_patty.queue_free()

	# 4. Teste de Hambúrguer de Frango (Cru e Cozido)
	print("\n--- Teste 4: Hambúrguer de Frango (Cru e Cozido) ---")
	var chick_patty = patty_scene.instantiate() as Patty
	chick_patty.meat_type = Patty.MeatType.CHICKEN
	root.add_child(chick_patty)
	chick_patty._ready()

	assert(chick_patty.get_display_name() == "Hambúrguer de Frango (Cru)", "Nome deve ser 'Hambúrguer de Frango (Cru)'")
	var chick_mesh = chick_patty.get_node("MeshInstance3D") as MeshInstance3D
	var chick_mat = chick_mesh.material_override as StandardMaterial3D
	assert(chick_mat.albedo_texture.resource_path.contains("meat_patty_chicken_raw.png"), "Texture deve ser frango cru")

	chick_patty.set_state(Patty.State.COOKED)
	chick_mat = chick_mesh.material_override as StandardMaterial3D
	assert(chick_mat.albedo_texture.resource_path.contains("meat_patty_chicken_cooked.png"), "Texture deve ser frango grelhado")
	print("  [PASS] Hambúrguer de frango com texturas dedicadas cru e grelhado.")
	chick_patty.queue_free()

	# 5. Teste de Interação na Mão (Pick Up / Hold / Drop)
	print("\n--- Teste 5: Interação com a Mão do Jogador ---")
	var hand_patty = patty_scene.instantiate() as Patty
	root.add_child(hand_patty)
	player.pick_up(hand_patty)

	assert(player.held_item == hand_patty, "Jogador deve estar segurando o patty")
	assert(hand_patty.get_parent() == player.hold_position, "Patty deve estar atachado ao HoldPosition")

	player.drop_item()
	assert(player.held_item == null, "Mão do jogador deve estar vazia")

	player.pick_up(hand_patty)
	assert(player.held_item == hand_patty, "Jogador deve conseguir pegar o patty novamente")
	player.take_held_item().queue_free()
	print("  [PASS] Fluxo de pegar, segurar na mão, soltar e pegar novamente testado com sucesso.")

	# Limpeza
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DE VISUAIS DO HAMBÚRGUER FORAM APROVADOS!")
	print("============================================================")
	quit(0)
