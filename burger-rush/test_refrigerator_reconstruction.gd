extends SceneTree

func _init() -> void:
	_run_tests()

func _run_tests() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE DE RECONSTRUÇÃO COMPLETA DA GELADEIRA")
	print("============================================================")

	# 1. Configurar gerenciadores do jogo
	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()
	inv.items["patty_beef"]["quantity"] = 25
	inv.items["patty_chicken"]["quantity"] = 18

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	root.add_child(player)
	player._ready()

	# 2. Carregar e instanciar cena da Geladeira Reconstruída
	print("\n--- Carregando commercial_refrigerator.tscn ---")
	var fridge_scene = load("res://src/stations/commercial_refrigerator.tscn")
	assert(fridge_scene != null, "Cena commercial_refrigerator.tscn deve carregar com sucesso")
	var fridge = fridge_scene.instantiate() as MeatRefrigerator
	root.add_child(fridge)
	fridge._ready()

	# ─────────────────────────────────────────────────────────────
	# TESTE 1: ESTRUTURA E CAVIDADE INTERNA REAL
	# ─────────────────────────────────────────────────────────────
	print("\n--- Teste 1: Estrutura Física e Cavidade Interna ---")
	assert(fridge.has_node("FridgeBody"), "Deve ter FridgeBody")
	assert(fridge.has_node("FridgeBody/ColLeft") and fridge.has_node("FridgeBody/ColRight"), "Deve ter colisões laterais periféricas")
	assert(fridge.has_node("FridgeBody/ColBack") and fridge.has_node("FridgeBody/ColTop"), "Deve ter colisões de fundo e teto")
	assert(fridge.has_node("FridgeBody/InnerBack"), "Deve ter revestimento de fundo interno (profundidade real)")
	assert(fridge.has_node("FridgeBody/InnerLeft") and fridge.has_node("FridgeBody/InnerRight"), "Deve ter laterais internas")
	assert(fridge.has_node("FridgeBody/InnerCeiling") and fridge.has_node("FridgeBody/InnerFloor"), "Deve ter teto e piso internos")
	assert(fridge.has_node("FridgeBody/Divider"), "Deve ter divisória central separando bovina de frango")
	assert(fridge.has_node("FridgeBody/LEDStrip"), "Deve ter fita LED no teto interno")
	assert(fridge.has_node("InteriorLight"), "Deve ter OmniLight3D para iluminação interna")
	print("  [PASS] Cavidade interna, paredes, teto, piso, divisória e luz verificados.")

	# ─────────────────────────────────────────────────────────────
	# TESTE 2: CESTOS E SEPARAÇÃO DE CARNE BOVINA E FRANGO
	# ─────────────────────────────────────────────────────────────
	print("\n--- Teste 2: Cestos de Armazenamento e Separação ---")
	assert(fridge.has_node("FridgeBody/BasketBeefMid"), "Deve ter cesto de carne bovina no nível médio")
	assert(fridge.has_node("FridgeBody/BasketBeefTop"), "Deve ter cesto de carne bovina no nível superior")
	assert(fridge.has_node("FridgeBody/BasketChickenMid"), "Deve ter cesto de frango no nível médio")
	assert(fridge.has_node("FridgeBody/BasketChickenTop"), "Deve ter cesto de frango no nível superior")
	assert(fridge.has_node("FridgeBody/BeefFoodGroup"), "Deve ter grupo de hambúrgueres bovinos visíveis")
	assert(fridge.has_node("FridgeBody/ChickenFoodGroup"), "Deve ter grupo de hambúrgueres de frango visíveis")
	print("  [PASS] Cestos e modelos visíveis de carne bovina e frango configurados separadamente.")

	# ─────────────────────────────────────────────────────────────
	# TESTE 3: ESTADO INICIAL FECHADO E BLOQUEIO DE ACESSO
	# ─────────────────────────────────────────────────────────────
	print("\n--- Teste 3: Estado Fechado e Bloqueio de Acesso aos Produtos ---")
	assert(not fridge.is_open, "Geladeira deve iniciar fechada (is_open == false)")
	assert(not fridge.is_door_open(), "is_door_open() deve retornar false")
	assert(fridge.beef_slot_col.disabled, "Slot de carne bovina deve estar desabilitado com porta fechada")
	assert(fridge.chicken_slot_col.disabled, "Slot de frango deve estar desabilitado com porta fechada")

	var door = fridge.get_node("DoorPivot/FridgeDoor") as StaticBody3D
	var beef_slot = fridge.get_node("BeefSlot") as StaticBody3D
	var chicken_slot = fridge.get_node("ChickenSlot") as StaticBody3D

	var door_prompt_closed = door.get_interaction_prompt(player)
	assert(door_prompt_closed == "E — Abrir Geladeira de Carnes", "Prompt da porta fechada deve ser 'E — Abrir Geladeira de Carnes'")
	assert(beef_slot.get_interaction_prompt(player) == "", "Slot de carne deve retornar prompt vazio quando fechada")
	assert(chicken_slot.get_interaction_prompt(player) == "", "Slot de frango deve retornar prompt vazio quando fechada")
	print("  [PASS] Porta fechada bloqueia acesso aos produtos e exibe prompt correto para abrir.")

	# ─────────────────────────────────────────────────────────────
	# TESTE 4: ABERTURA DA PORTA E ANIMAÇÃO
	# ─────────────────────────────────────────────────────────────
	print("\n--- Teste 4: Abertura da Porta ---")
	door.interact(player)
	await create_timer(0.6).timeout

	assert(fridge.is_open, "is_open deve ser true após abrir")
	assert(fridge.is_door_open(), "is_door_open() deve retornar true")
	assert(not fridge.beef_slot_col.disabled, "Slot de carne bovina deve estar habilitado com porta aberta")
	assert(not fridge.chicken_slot_col.disabled, "Slot de frango deve estar habilitado com porta aberta")

	var door_prompt_open = door.get_interaction_prompt(player)
	assert(door_prompt_open == "E — Fechar Geladeira", "Prompt da porta aberta deve ser 'E — Fechar Geladeira'")
	print("  [PASS] Porta abre suavemente, slots são ativados e estado is_open = true.")

	# ─────────────────────────────────────────────────────────────
	# TESTE 5: INTERAÇÃO E RETIRADA DE CARNE BOVINA
	# ─────────────────────────────────────────────────────────────
	print("\n--- Teste 5: Retirada de Carne Bovina ---")
	var beef_prompt = beef_slot.get_interaction_prompt(player)
	assert(beef_prompt.begins_with("🥩 E — Pegar Carne Bovina"), "Prompt do slot de carne deve ser informativo")

	var initial_beef_stock = inv.get_stock("patty_beef")
	beef_slot.interact(player)

	assert(player.held_item != null, "Jogador deve estar segurando o item pego")
	assert(player.held_item is Patty, "Item pego deve ser uma instância de Patty")
	var held_patty = player.held_item as Patty
	assert(held_patty.meat_type == Patty.MeatType.BEEF, "Patty deve ser do tipo BEEF")
	assert(inv.get_stock("patty_beef") == initial_beef_stock - 1, "Estoque de carne bovina deve ser decrementado em 1")
	player.take_held_item().queue_free()
	print("  [PASS] Carne bovina retirada com sucesso, Patty gerada com meat_type BEEF e estoque atualizado.")

	# ─────────────────────────────────────────────────────────────
	# TESTE 6: INTERAÇÃO E RETIRADA DE HAMBÚRGUER DE FRANGO
	# ─────────────────────────────────────────────────────────────
	print("\n--- Teste 6: Retirada de Hambúrguer de Frango ---")
	var chicken_prompt = chicken_slot.get_interaction_prompt(player)
	assert(chicken_prompt.begins_with("🍗 E — Pegar Hambúrguer de Frango"), "Prompt do slot de frango deve ser informativo")

	var initial_chick_stock = inv.get_stock("patty_chicken")
	chicken_slot.interact(player)

	assert(player.held_item != null, "Jogador deve estar segurando o frango")
	assert(player.held_item is Patty, "Item pego deve ser uma instância de Patty")
	var held_chicken = player.held_item as Patty
	assert(held_chicken.meat_type == Patty.MeatType.CHICKEN, "Patty deve ser do tipo CHICKEN")
	assert(inv.get_stock("patty_chicken") == initial_chick_stock - 1, "Estoque de frango deve ser decrementado em 1")
	player.take_held_item().queue_free()
	print("  [PASS] Hambúrguer de frango retirado com sucesso, Patty gerada com meat_type CHICKEN e estoque atualizado.")

	# ─────────────────────────────────────────────────────────────
	# TESTE 7: FECHAMENTO DA PORTA E BLOQUEIO NOVAMENTE
	# ─────────────────────────────────────────────────────────────
	print("\n--- Teste 7: Fechamento da Porta ---")
	door.interact(player)
	await create_timer(0.6).timeout

	assert(not fridge.is_open, "is_open deve voltar para false após fechar")
	assert(fridge.beef_slot_col.disabled, "Slot de carne bovina deve ser desabilitado novamente")
	assert(fridge.chicken_slot_col.disabled, "Slot de frango deve ser desabilitado novamente")
	assert(door.get_interaction_prompt(player) == "E — Abrir Geladeira de Carnes", "Prompt deve voltar para 'Abrir'")
	print("  [PASS] Porta fecha completamente e slots são desabilitados com segurança.")

	# Limpeza
	fridge.queue_free()
	player.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DA GELADEIRA FORAM APROVADOS COM SUCESSO!")
	print("============================================================")
	quit(0)
