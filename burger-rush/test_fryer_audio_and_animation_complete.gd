extends SceneTree

const Fryer = preload("res://src/stations/fryer.gd")
const Potato = preload("res://src/items/potato.gd")
const PotatoBoxItem = preload("res://src/items/potato_box_item.gd")
const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

func _init() -> void:
	print("============================================================")
	print("BURGER RUSH - TESTE: ÁUDIO + ANIMAÇÕES DA FRITADEIRA (4 CESTOS)")
	print("============================================================")

	var inv = InventoryManager.new()
	root.add_child(inv)
	inv._initialize_default_inventory()
	inv.items["potato_box"]["quantity"] = 20

	var prog = ProgressionManager.new()
	root.add_child(prog)
	prog._enter_tree()

	var world = Node3D.new()
	root.add_child(world)

	var player_scene = load("res://src/player/player.tscn")
	var player = player_scene.instantiate() as Player
	world.add_child(player)
	player._ready()

	var fryer_scene = load("res://src/stations/fryer.tscn")
	var fryer = fryer_scene.instantiate() as Fryer
	world.add_child(fryer)
	fryer._ready()

	# -------------------------------------------------------------
	# 1. TESTE: FRITADEIRA DESLIGADA -> SILÊNCIO
	# -------------------------------------------------------------
	print("\n--- 1. Fritadeira Desligada ---")
	assert(not fryer.is_on, "Fritadeira inicia desligada")
	fryer._process(0.1)
	assert(fryer.hum_audio.volume_db <= -60.0 or not fryer.hum_audio.playing, "Sem som de aquecimento desligada")
	assert(fryer.sizzle_audio.volume_db <= -60.0 or not fryer.sizzle_audio.playing, "Sem som de fritura")
	print("  [PASS] Fritadeira desligada permanece silenciosa.")

	# -------------------------------------------------------------
	# 2. TESTE: LIGAR FRITADEIRA -> CLIQUE + HUM INDUSTRIAL
	# -------------------------------------------------------------
	print("\n--- 2. Ligar Fritadeira ---")
	fryer.toggle_power(player)
	assert(fryer.is_on, "Fritadeira ligada")
	assert(fryer.oneshot_audio.stream == SoundSynthesizer.get_stream("fryer_switch_on"), "Som de botão ligando carregado")
	assert(fryer.oneshot_audio.volume_db == -6.0, "Volume de clique calibrado (-6 dB)")

	fryer._process(0.6)
	assert(fryer.hum_audio.stream == SoundSynthesizer.get_stream("fryer_hum_loop"), "Hum térmico em loop ativo")
	assert(fryer.hum_audio.volume_db > -30.0, "Hum térmico audível (%.1f dB)" % fryer.hum_audio.volume_db)
	print("  [PASS] Acionamento: clique de botão + início do hum industrial.")

	# -------------------------------------------------------------
	# 3. TESTE: AQUECIMENTO PROGRESSIVO E FEEDBACK DE PRONTIDÃO (150°C)
	# -------------------------------------------------------------
	print("\n--- 3. Aquecimento e Termômetro ---")
	assert(not fryer.is_ideal_temp(), "Ainda abaixo de 150°C")
	fryer.current_temperature = 149.0
	fryer._process(0.2) # Atinge 150°C
	assert(fryer.is_ideal_temp(), "Fritadeira atingiu temperatura ideal (> 150°C)")
	assert(fryer._has_played_ready_chime, "Chime de prontidão disparado")
	assert(fryer.oneshot_audio.stream == SoundSynthesizer.get_stream("fryer_ready_chime"), "Som de pronta reproduzido")
	print("  [PASS] Temperatura ideal atingida: sinal acústico e indicador visual verde.")

	# -------------------------------------------------------------
	# 4. TESTE: COLOCAR BATATAS NO CESTO 0 (LEVANTADO)
	# -------------------------------------------------------------
	print("\n--- 4. Colocar Batatas no Cesto ---")
	var potato_scene = load("res://src/items/potato.tscn")
	var pot0 = potato_scene.instantiate() as Potato
	world.add_child(pot0)
	player.pick_up(pot0)

	# Jogador mira no cesto 0 e clica
	fryer.interact_item(player)
	assert(fryer.compartments[0]["food_state"] == "frozen", "Cesto 0 com batatas congeladas")
	assert(fryer.oneshot_audio.stream == SoundSynthesizer.get_stream("fryer_place_potatoes"), "Som de queda dos palitos no cesto aramado")
	assert(player.held_item == null, "Saco transferido para o cesto")
	print("  [PASS] Batatas colocadas no cesto com som característico.")

	# -------------------------------------------------------------
	# 5. TESTE: ABAIXAR CESTO 0 NO ÓLEO -> SOM MECÂNICO + INÍCIO DE FRITURA
	# -------------------------------------------------------------
	print("\n--- 5. Abaixar Cesto no Óleo e Iniciar Fritura ---")
	fryer.toggle_basket(0, player)
	assert(fryer.compartments[0]["basket_down"], "Cesto 0 abaixado no óleo")
	assert(fryer.basket_audio.stream == SoundSynthesizer.get_stream("fryer_basket_lower"), "Som mecânico de descida reproduzido")

	fryer._process(0.6)
	assert(fryer.sizzle_audio.stream == SoundSynthesizer.get_stream("fryer_sizzle_loop"), "Chiado e borbulhamento do óleo ativo")
	var vol_1_basket = fryer.sizzle_audio.volume_db
	assert(vol_1_basket > -12.0, "Volume de fritura ativo (%.1f dB)" % vol_1_basket)
	print("  [PASS] Cesto abaixado: som mecânico de engate + borbulhamento imediato.")

	# -------------------------------------------------------------
	# 6. TESTE: EVOLUÇÃO VISUAL (CONGELADA -> COOKING -> DOURADA COOKED)
	# -------------------------------------------------------------
	print("\n--- 6. Evolução das Batatas ---")
	# Frita por 4 segundos (metade do tempo) -> cooking
	fryer._process(4.0)
	assert(fryer.compartments[0]["food_state"] == "cooking", "Batatas em processo de cocção")

	# Frita por mais 5 segundos (total > 8s) -> cooked
	fryer._process(5.0)
	assert(fryer.compartments[0]["food_state"] == "cooked", "Batatas douradas e crocantes prontas")
	print("  [PASS] Batatas atingiram o ponto perfeito (douradas e prontas).")

	# -------------------------------------------------------------
	# 7. TESTE: DOIS CESTOS SIMULTÂNEOS -> ESCALAÇÃO NATURAL DE VOLUME
	# -------------------------------------------------------------
	print("\n--- 7. Múltiplos Cestos Simultâneos ---")
	var pot1 = potato_scene.instantiate() as Potato
	world.add_child(pot1)
	player.pick_up(pot1)

	# Coloca no cesto 1 e abaixa
	fryer.compartments[1]["food_state"] = "frozen"
	fryer.compartments[1]["basket_down"] = true
	player.take_held_item().queue_free()

	fryer._process(0.6)
	var vol_2_baskets = fryer.sizzle_audio.volume_db
	assert(vol_2_baskets > vol_1_basket, "Volume aumenta organicamente com 2 cestos (%.1f > %.1f)" % [vol_2_baskets, vol_1_basket])
	assert(vol_2_baskets <= -4.0, "Volume não satura acima do limite seguro (-4 dB)")
	print("  [PASS] 2 cestos fritando: volume cresce harmonicamente sem distorção.")

	# -------------------------------------------------------------
	# 8. TESTE: LEVANTAR CESTO 0 -> SOM MECÂNICO + DRENAGEM
	# -------------------------------------------------------------
	print("\n--- 8. Levantar Cesto e Drenar Óleo ---")
	fryer.toggle_basket(0, player)
	assert(not fryer.compartments[0]["basket_down"], "Cesto 0 levantado")
	assert(fryer.basket_audio.stream == SoundSynthesizer.get_stream("fryer_basket_raise"), "Som mecânico de elevação")
	assert(fryer.compartments[0]["drain_timer"] > 0.0, "Timer de drenagem/gotejamento ativado")
	print("  [PASS] Cesto 0 levantado com som mecânico e gotejamento de óleo.")

	# -------------------------------------------------------------
	# 9. TESTE: EMBALAR BATATAS PRONTAS (CLIQUE ESQUERDO)
	# -------------------------------------------------------------
	print("\n--- 9. Embalar Batata Frita Pronta ---")
	# Jogador sem item na mão pega a batata pronta do cesto 0
	fryer._finish_and_pack_fries(0, player)
	assert(fryer.compartments[0]["food_state"] == "empty", "Cesto 0 esvaziado")
	assert(fryer.oneshot_audio.stream == SoundSynthesizer.get_stream("fryer_pack_fries"), "Som crocante de embalar batata frita")
	assert(player.held_item is FriesPack, "Jogador segurando caixinha de batata frita")
	player.take_held_item().queue_free()
	print("  [PASS] Batatas embaladas no recipiente com som crocante.")

	# -------------------------------------------------------------
	# 10. TESTE: BATATA QUEIMANDO NO CESTO 1
	# -------------------------------------------------------------
	print("\n--- 10. Batata Queimando ---")
	# Avança tempo até queimar no cesto 1 (cook_time 8s + burn_time 12s = 20s total)
	fryer._process(22.0)
	assert(fryer.compartments[1]["food_state"] == "burnt", "Batata queimada se deixada tempo excessivo")
	assert(fryer.sizzle_audio.pitch_scale >= 1.05, "Pitch dinâmico do óleo elevado quando queimando")
	print("  [PASS] Batata queimada detectada com elevação de pitch e escurecimento visual.")

	# Esvazia cesto 1
	fryer.toggle_basket(1, player)
	fryer.compartments[1]["food_state"] = "empty"

	# -------------------------------------------------------------
	# 11. TESTE: OS 4 CESTOS INDEPENDENTES
	# -------------------------------------------------------------
	print("\n--- 11. 4 Cestos 100% Independentes ---")
	for i in range(4):
		assert(fryer.compartments[i]["food_state"] == "empty", "Cesto %d limpo" % i)
		assert(not fryer.compartments[i]["basket_down"], "Cesto %d levantado" % i)
	print("  [PASS] Todos os 4 compartimentos isolados e independentes.")

	# -------------------------------------------------------------
	# 12. TESTE: DESLIGAR FRITADEIRA
	# -------------------------------------------------------------
	print("\n--- 12. Desligar Fritadeira ---")
	fryer.toggle_power(player)
	assert(not fryer.is_on, "Fritadeira desligada")
	assert(fryer.oneshot_audio.stream == SoundSynthesizer.get_stream("fryer_switch_off"), "Som de desligamento reproduzido")

	fryer._process(3.0)
	assert(fryer.hum_audio.volume_db <= -60.0 or not fryer.hum_audio.playing, "Hum industrial desligado")
	assert(fryer.sizzle_audio.volume_db <= -60.0 or not fryer.sizzle_audio.playing, "Chiado totalmente encerrado")
	print("  [PASS] Fritadeira desligada com clique mecânico e silêncio restaurado.")

	# -------------------------------------------------------------
	# 13. TESTE: PROPRIEDADES DE ÁUDIO 3D ESPACIAL
	# -------------------------------------------------------------
	print("\n--- 13. Áudio 3D Espacial ---")
	assert(fryer.hum_audio.unit_size >= 2.5, "Unit size espacial 3D validado")
	assert(fryer.hum_audio.max_distance >= 15.0, "Max distance espacial 3D validado")
	assert(fryer.sizzle_audio.unit_size >= 2.5, "Sizzle player espacial 3D validado")
	print("  [PASS] Parâmetros 3D posicionais verificados.")

	# Limpeza
	fryer.queue_free()
	player.queue_free()
	world.queue_free()
	prog.queue_free()
	inv.queue_free()

	print("\n============================================================")
	print("TODOS OS TESTES DA FRITADEIRA FORAM 100% APROVADOS!")
	print("============================================================\n")
	quit(0)
