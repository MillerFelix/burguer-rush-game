extends SceneTree

# =============================================================================
# BURGER RUSH - TEST SUITE: AJUSTES DO SISTEMA DE ENERGIA E ELETRÔNICOS
# Quadro Geral, 3x Consumo Portas Abertas, AC Reposicionado & LEDs Físicos TV/AC
# =============================================================================

const PowerManager = preload("res://src/core/power_manager.gd")
const MainPowerPanel = preload("res://src/stations/main_power_panel.gd")
const AirConditioner = preload("res://src/stations/air_conditioner.gd")
const KitchenOrderTV = preload("res://src/stations/kitchen_order_tv.gd")
const IngredientRefrigerator = preload("res://src/stations/ingredient_refrigerator.gd")
const CommercialRefrigerator = preload("res://src/stations/commercial_refrigerator.gd")
const CommercialChestFreezer = preload("res://src/stations/commercial_chest_freezer.gd")

var pass_count: int = 0
var fail_count: int = 0

func _init() -> void:
	print("\n" + "=".repeat(75))
	print("TESTE: AJUSTES DO SISTEMA DE ENERGIA (3X PORTAS ABERTAS, AC NA ENTRADA, LEDS)")
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
		print("ERRO: main.tscn não encontrado")
		quit(1)
		return

	var root_node = main_scene.instantiate()
	root.add_child(root_node)
	await create_timer(0.2).timeout

	var player = root_node.get_node_or_null("Player")
	assert_test(player != null, "Player ativo no mundo")

	var pm = PowerManager.get_instance()
	assert_test(pm != null, "PowerManager central ativo")

	var breaker_panel: MainPowerPanel = root_node.get_node_or_null("MainPowerPanel")
	assert_test(breaker_panel != null, "Quadro Geral de Energia na parede externa")

	var ac_unit: AirConditioner = root_node.get_node_or_null("AirConditioner")
	assert_test(ac_unit != null, "Ar-Condicionado presente")

	var tv: KitchenOrderTV = root_node.get_node_or_null("KitchenOrderTV")
	assert_test(tv != null, "TV de Pedidos presente")

	var veg_fridge: IngredientRefrigerator = root_node.get_node_or_null("IngredientRefrigerator")
	var meat_fridge: CommercialRefrigerator = root_node.get_node_or_null("CommercialRefrigerator")
	var chest_freezer: CommercialChestFreezer = root_node.get_node_or_null("CommercialChestFreezer")

	print("\n--- ETAPA 1: Estado Inicial e Posicionamento do Ar-Condicionado ---")
	assert_test(pm.is_main_power_on == false, "Energia geral começa DESLIGADA no início do dia")
	assert_test(pm.get_current_power_consumption_kw() == 0.0, "Consumo ativo da rede é 0.0 kW com o quadro desligado")

	# Quadro Geral posicionado na parede branca externa ao lado da porta do armazém
	assert_test(breaker_panel.global_position.x < -9.0 and is_equal_approx(breaker_panel.global_position.y, 1.55) and breaker_panel.global_position.z < -4.5, "Quadro Geral instalado na parede branca externa ao lado da saída do armazém (X = %.2fm, Y = %.2fm, Z = %.2fm)" % [breaker_panel.global_position.x, breaker_panel.global_position.y, breaker_panel.global_position.z])

	# AC perfeitamente centralizado acima da porta principal (X = 0.0m, Y = 2.88m, Z = 8.70m)
	assert_test(is_equal_approx(ac_unit.global_position.x, 0.0), "Ar-Condicionado perfeitamente centralizado horizontalmente na porta principal (X = %.2fm)" % ac_unit.global_position.x)
	assert_test(ac_unit.global_position.y >= 2.80 and ac_unit.global_position.y <= 3.00, "Ar-Condicionado no alto da parede com distância adequada do teto (Y = %.2fm)" % ac_unit.global_position.y)
	assert_test(ac_unit.audio_player != null and ac_unit.audio_player.volume_db <= -20.0, "Volume do Ar-Condicionado ajustado para nível suave e discreto (%.1f dB)" % ac_unit.audio_player.volume_db)

	# LED do AC desligado é VERMELHO
	var ac_led_mat = ac_unit.led_status.get_surface_override_material(0) if ac_unit.led_status else null
	assert_test(ac_led_mat != null and ac_led_mat.albedo_color.r > 0.8, "LED do Ar-Condicionado em VERMELHO quando desligado")

	# TV completamente desligada (sem pedidos, sem textos de cabeçalho, LED vermelho)
	assert_test(tv.screen_label.text == "", "Tela da TV sem pedidos quando desligada")
	assert_test(tv.header_label.text == "", "Tela da TV sem cabeçalho/textos/letras quando desligada")
	var tv_led_mat = tv.power_led.get_surface_override_material(0) if tv.power_led else null
	assert_test(tv_led_mat != null and tv_led_mat.albedo_color.r > 0.8, "LED da TV de Pedidos em VERMELHO quando sem energia")

	print("\n--- ETAPA 2: Ligar Quadro Geral de Energia ---")
	breaker_panel.interact_equipment(player)
	await create_timer(0.3).timeout

	assert_test(pm.is_main_power_on == true, "Quadro Geral acionado -> Rede elétrica ativa")
	assert_test(breaker_panel.lever_pivot.rotation_degrees.z > 0.0, "Alavanca do quadro na posição ligada (para cima)")

	# TV liga automaticamente com a energia geral
	assert_test(tv.header_label.text != "", "TV exibe cabeçalho após ligar o quadro")
	assert_test(tv.screen_label.text != "", "TV exibe informações após ligar o quadro")
	tv_led_mat = tv.power_led.get_surface_override_material(0)
	assert_test(tv_led_mat != null and tv_led_mat.albedo_color.g > 0.8, "LED da TV de Pedidos em VERDE após receber energia")

	print("\n--- ETAPA 3: Ar-Condicionado (Funcionamento, Som e LED Verde/Vermelho) ---")
	ac_unit.interact_equipment(player)
	await create_timer(0.3).timeout

	assert_test(ac_unit.is_running, "Ar-Condicionado em funcionamento")
	ac_led_mat = ac_unit.led_status.get_surface_override_material(0)
	assert_test(ac_led_mat != null and ac_led_mat.albedo_color.g > 0.8, "LED do Ar-Condicionado em VERDE quando ligado")
	assert_test(ac_unit.audio_player != null and ac_unit.audio_player.playing, "Som suave de ventilação do AC ativo")
	assert_test(ac_unit.vent_particles != null and ac_unit.vent_particles.emitting, "Efeito de ar sutil do AC ativo")

	# Desliga o AC
	ac_unit.interact_equipment(player)
	await create_timer(0.3).timeout
	assert_test(not ac_unit.is_running, "Ar-Condicionado desligado")
	ac_led_mat = ac_unit.led_status.get_surface_override_material(0)
	assert_test(ac_led_mat != null and ac_led_mat.albedo_color.r > 0.8, "LED do Ar-Condicionado voltou para VERMELHO após desligar")
	assert_test(ac_unit.audio_player != null and not ac_unit.audio_player.playing, "Som de ventilação do AC parou imediatamente")
	assert_test(ac_unit.vent_particles != null and not ac_unit.vent_particles.emitting, "Efeito de ventilação do AC parou")

	print("\n--- ETAPA 4: Portas Abertas — Consumo Triplicado (3x) em Geladeiras e Freezers ---")
	if veg_fridge:
		var veg_data = pm.get_appliance_data(veg_fridge)
		var base_kw = veg_data.get("base_kw", 1.0)
		assert_test(is_equal_approx(veg_data.get("multiplier", 1.0), 1.0), "Geladeira de hortifrúti fechada -> Multiplicador normal (1.0x)")

		# Abre porta da geladeira
		veg_fridge.open_door(player)
		await create_timer(0.5).timeout
		veg_data = pm.get_appliance_data(veg_fridge)
		assert_test(veg_fridge.is_door_open(), "Porta da geladeira de hortifrúti aberta")
		assert_test(is_equal_approx(veg_data.get("multiplier", 1.0), 3.0), "Porta da geladeira aberta -> Consumo TRIPLICADO (3.0x = %.2f kW)" % (base_kw * 3.0))

		# Fecha porta da geladeira
		veg_fridge.close_door(player)
		await create_timer(0.5).timeout
		veg_data = pm.get_appliance_data(veg_fridge)
		assert_test(not veg_fridge.is_door_open(), "Porta da geladeira fechada")
		assert_test(is_equal_approx(veg_data.get("multiplier", 1.0), 1.0), "Porta fechada -> Consumo retorna para 1.0x imediatamente")

	if meat_fridge:
		meat_fridge.open_door(player)
		await create_timer(0.5).timeout
		var meat_data = pm.get_appliance_data(meat_fridge)
		assert_test(is_equal_approx(meat_data.get("multiplier", 1.0), 3.0), "Geladeira de carnes aberta -> Consumo TRIPLICADO (3.0x)")
		meat_fridge.close_door(player)
		await create_timer(0.5).timeout
		meat_data = pm.get_appliance_data(meat_fridge)
		assert_test(is_equal_approx(meat_data.get("multiplier", 1.0), 1.0), "Geladeira de carnes fechada -> Consumo volta para 1.0x")

	if chest_freezer:
		chest_freezer.open_freezer(player)
		await create_timer(0.5).timeout
		var freezer_data = pm.get_appliance_data(chest_freezer)
		assert_test(is_equal_approx(freezer_data.get("multiplier", 1.0), 3.0), "Freezer de queijos aberto -> Consumo TRIPLICADO (3.0x)")
		chest_freezer.close_freezer(player)
		await create_timer(0.5).timeout
		freezer_data = pm.get_appliance_data(chest_freezer)
		assert_test(is_equal_approx(freezer_data.get("multiplier", 1.0), 1.0), "Freezer de queijos fechado -> Consumo volta para 1.0x")

	print("\n--- ETAPA 5: Desligamento Manual da TV (Tela Apagada e LED Vermelho) ---")
	tv.interact_equipment(player)
	await create_timer(0.2).timeout

	assert_test(not tv.is_turned_on, "TV desligada no botão próprio")
	assert_test(tv.screen_label.text == "", "Tela da TV sem pedidos quando desligada")
	assert_test(tv.header_label.text == "", "Tela da TV sem cabeçalho/letras quando desligada")
	tv_led_mat = tv.power_led.get_surface_override_material(0)
	assert_test(tv_led_mat != null and tv_led_mat.albedo_color.r > 0.8, "LED da TV em VERMELHO quando desligada manualmente")

	# Religa a TV
	tv.interact_equipment(player)
	await create_timer(0.2).timeout
	assert_test(tv.is_turned_on, "TV religada no botão próprio")
	assert_test(tv.header_label.text != "" and tv.screen_label.text != "", "Informações e pedidos voltam a aparecer na tela")
	tv_led_mat = tv.power_led.get_surface_override_material(0)
	assert_test(tv_led_mat != null and tv_led_mat.albedo_color.g > 0.8, "LED da TV volta para VERDE")

	print("\n--- ETAPA 6: Desligamento e Restauração Geral da Energia ---")
	breaker_panel.interact_equipment(player)
	await create_timer(0.3).timeout

	assert_test(pm.is_main_power_on == false, "Quadro Geral desligado -> Rede sem energia")
	assert_test(pm.get_current_power_consumption_kw() == 0.0, "Consumo total de energia zerado (0.0 kW)")
	assert_test(tv.screen_label.text == "" and tv.header_label.text == "", "Tela da TV apagada sem energia")
	tv_led_mat = tv.power_led.get_surface_override_material(0)
	assert_test(tv_led_mat != null and tv_led_mat.albedo_color.r > 0.8, "LED da TV em VERMELHO sem energia")

	# Restaura energia
	breaker_panel.interact_equipment(player)
	await create_timer(0.3).timeout

	assert_test(pm.is_main_power_on == true, "Quadro Geral religado -> Rede restaurada")
	assert_test(tv.screen_label.text != "", "TV volta a funcionar normalmente após restauração")
	assert_test(pm.get_current_power_consumption_kw() > 0.0, "Equipamentos voltam a consumir energia")

	print("\n" + "=".repeat(75))
	print("RESULTADO FINAL: %d PASSOU | %d FALHOU" % [pass_count, fail_count])
	print("=".repeat(75) + "\n")

	if fail_count == 0:
		print(">>> TODOS OS TESTES DOS AJUSTES DE ENERGIA PASSARAM COM 100% DE SUCESSO! <<<")
		quit(0)
	else:
		print(">>> ALGUNS TESTES FALHARAM! <<<")
		quit(1)
