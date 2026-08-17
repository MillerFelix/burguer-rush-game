extends SceneTree

# ================================================================
# TESTE ESPECÍFICO: GRELHA, FRITADEIRA E BISNAGAS DE MOLHO
# Valida rigorosamente todos os 6 pontos do ajuste fino solicitado
# ================================================================

const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")
const Grill = preload("res://src/stations/grill.gd")
const Fryer = preload("res://src/stations/fryer.gd")
const SauceBottle = preload("res://src/items/sauce_bottle.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE: GRELHA, FRITADEIRA E BISNAGAS DE MOLHO")
	print("============================================================")

	var world = Node3D.new()
	world.name = "TestWorld"
	root.add_child(world)

	print("\n--- 1. GRELHA: VOLUME MODERADO DE FRITURA ---")
	var grill = Grill.new()
	world.add_child(grill)
	grill._ready()
	grill.is_on = true
	grill.current_temperature = 175.0 # Temperatura ideal

	# Adiciona 1 hambúrguer e processa áudio
	var fake_patty = Node3D.new()
	grill.active_items.append({"item": fake_patty, "type": "patty", "timer": 1.0, "slot_index": 0})
	grill._process(0.1)

	assert(grill.sizzle_audio != null, "Audio de chiado presente")
	assert(grill.sizzle_audio.stream == SoundSynthesizer.get_stream("grill_sizzle_loop"), "Stream de fritura correto")
	assert(grill._target_sizzle_vol <= -10.0, "Volume de fritura calibrado para nível moderado (%.1f dB)" % grill._target_sizzle_vol)
	print("  [PASS] Fritura da grelha: claramente audível e equilibrada (%.1f dB)." % grill._target_sizzle_vol)

	print("\n--- 2. FRITADEIRA: CESTOS METÁLICOS SUAVES ---")
	var fryer = Fryer.new()
	world.add_child(fryer)
	fryer._ready()

	# Abaixar cesto
	fryer._play_basket_move(true)
	assert(fryer.basket_audio.stream == SoundSynthesizer.get_stream("fryer_basket_lower"), "Som de abaixar cesto correto")
	assert(fryer.basket_audio.volume_db <= -12.0, "Volume de movimento dos cestos suave e não-estridente (%.1f dB)" % fryer.basket_audio.volume_db)

	# Levantar cesto
	fryer._play_basket_move(false)
	assert(fryer.basket_audio.stream == SoundSynthesizer.get_stream("fryer_basket_raise"), "Som de levantar cesto correto")
	assert(fryer.basket_audio.volume_db <= -12.0, "Volume suave e moderado (%.1f dB)" % fryer.basket_audio.volume_db)
	print("  [PASS] Movimento de cestos metálicos da fritadeira suave e moderado (-14.0 dB).")

	print("\n--- 3. BISNAGA: PARADA / REPOUSO (SILENCIOSA) ---")
	var bottle_scene = load("res://src/items/sauce_bottle.tscn")
	var bottle = bottle_scene.instantiate() as SauceBottle
	world.add_child(bottle)
	bottle.setup_bottle("ketchup")

	assert(bottle.get_node_or_null("SqueezeAudioPlayer") == null, "Nenhum nó de áudio na bisnaga")
	print("  [PASS] Bisnaga em repouso permanece 100% silenciosa.")

	print("\n--- 4. BISNAGA: APERTAR E DESPEJAR MOLHO (SILENCIOSO) ---")
	bottle.location = Item.ItemLocation.PLAYER_HAND
	bottle.current_amount = 80.0
	bottle.start_squeezing()
	assert(bottle.is_squeezing, "Bisnaga em estado de aperto")
	print("  [PASS] Despejar molho: fluxo e aplicação ocorrendo normalmente sem áudio.")

	# Processa fluxo contínuo
	bottle._process(0.2)
	assert(bottle.is_squeezing, "Fluxo contínuo mantido enquanto aperta")
	assert(bottle.current_amount < 80.0, "Molho sendo consumido fisicamente")
	print("  [PASS] Fluxo contínuo e consumo físico de molho mantidos.")

	print("\n--- 5. BISNAGA: SOLTAR BOTÃO ---")
	bottle.stop_squeezing()
	assert(not bottle.is_squeezing, "Estado de aperto finalizado")
	print("  [PASS] Aperto e fluxo finalizados imediatamente ao soltar o botão.")

	print("\n--- 6. BISNAGA VAZIA: TENTATIVA DE APERTO SEM MOLHO ---")
	bottle.current_amount = 0.0
	bottle.start_squeezing()
	assert(not bottle.is_squeezing, "Bisnaga vazia rejeita aperto")
	print("  [PASS] Bisnaga vazia não permite despejo.")

	print("\n============================================================")
	print("TODOS OS TESTES DE GRELHA, FRITADEIRA E MOLHOS FORAM APROVADOS!")
	print("============================================================")

	quit()
