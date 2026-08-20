class_name DailyEventManager
extends Node

# =============================================================================
# BURGER RUSH - GERENCIADOR CENTRAL DE EVENTOS DIÁRIOS E OCORRÊNCIAS
#
# Escolhe e gerencia no máximo 1 evento principal aleatório por dia (ou nenhum).
# Centraliza modificadores de demanda de clientes, tipos de pedidos, abastecimento de água,
# clima e consumo elétrico.
#
# Totalmente preparado para consultas futuras pelo PC (Notícias, Finanças, Conta de Luz).
# =============================================================================

const CalendarManager = preload("res://src/core/calendar_manager.gd")
const PowerManager = preload("res://src/core/power_manager.gd")

signal event_started(event_type: EventType, event_data: Dictionary)
signal event_ended(event_type: EventType)
signal power_outage_occurred(reason: String)
signal water_supply_state_changed(is_active: bool)

enum EventType {
	NONE,
	NETWORK_MAINTENANCE,     # Manutenção na rede elétrica (quedas de energia durante o expediente)
	NETWORK_REGULATION,      # Ajustes tarifários na rede (+30% no custo da energia do dia)
	WATER_SUPPLY_PROBLEM,    # Interrupção temporária no fornecimento de água por 2 horas
	RAINY_DAY,               # Dia de chuva (menos clientes presenciais, mais drive-thru)
	STORM_DAY,               # Tempestade intensa (vento/chuva forte, possível queda de luz)
	EXTREME_HEAT,            # Onda de calor extremo (alta demanda por bebidas)
	GAME_DAY,                # Dia de jogo no estádio (pico de clientes à noite)
	TRANSPORT_DISRUPTION     # Problemas nas estradas / paralisações (+25% no tempo de entrega)
}

## Evento ativo no dia
var current_event: EventType = EventType.NONE

## Dados descritivos do evento do dia
var event_title: String = ""
var event_headline: String = ""
var event_body: String = ""

## Modificadores Centrais de Demanda e Operação
@export var weekend_customer_multiplier: float = 1.25
var customer_demand_multiplier: float = 1.0
var dine_in_multiplier: float = 1.0
var drive_thru_multiplier: float = 1.0
var beverage_demand_multiplier: float = 1.0
var electricity_cost_multiplier: float = 1.0
var delivery_time_multiplier: float = 1.0

## Controle de Água
var is_water_supply_active: bool = true
var water_outage_start_hour: float = 13.0
var water_outage_end_hour: float = 15.0

## Controle de Quedas de Energia Programadas
var power_cut_hours: Array[float] = [14.0, 16.5]
var power_cuts_triggered: Array[bool] = [false, false]

## Controle de Horário de Pico do Dia de Jogo
var game_peak_start_hour: float = 18.5
var game_peak_end_hour: float = 21.0

## Histórico de Eventos Diários (para PC / Estatísticas)
var event_history: Array[Dictionary] = []

static var instance = null

func _init() -> void:
	instance = self

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

static func get_instance() -> DailyEventManager:
	if instance and is_instance_valid(instance):
		return instance
	var ml = Engine.get_main_loop()
	if ml and ml is SceneTree:
		var tree = ml as SceneTree
		if tree.root:
			var found = tree.root.find_child("DailyEventManager", true, false)
			if found and found is DailyEventManager:
				instance = found
	return instance

func _ready() -> void:
	var clock = _get_game_clock()
	if clock:
		if not clock.day_started.is_connected(_on_day_started):
			clock.day_started.connect(_on_day_started)
		if not clock.time_tick.is_connected(_on_time_tick):
			clock.time_tick.connect(_on_time_tick)
		if not clock.day_ended.is_connected(_on_day_ended):
			clock.day_ended.connect(_on_day_ended)

func _get_game_clock() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.find_child("GameClock", true, false)
	return null

func _on_day_started(_day_number: int) -> void:
	roll_daily_event()

func _on_day_ended(_summary = null) -> void:
	end_day_event()

func _on_time_tick(hour: int, minute: int) -> void:
	var time_f: float = hour + (minute / 60.0)
	_process_timed_event_effects(time_f)

## Sorteia e aplica o evento do dia no início de cada jornada
func roll_daily_event(forced_event: EventType = EventType.NONE, force_roll: bool = false) -> void:
	_reset_modifiers()

	if force_roll or forced_event != EventType.NONE:
		current_event = forced_event
	else:
		# Sorteio com probabilidade balanceada:
		# 40% Sem evento especial, 60% Distribuído entre os eventos disponíveis
		var rand_val = randf()
		if rand_val < 0.40:
			current_event = EventType.NONE
		else:
			var event_pool = [
				EventType.NETWORK_MAINTENANCE,
				EventType.NETWORK_REGULATION,
				EventType.WATER_SUPPLY_PROBLEM,
				EventType.RAINY_DAY,
				EventType.STORM_DAY,
				EventType.EXTREME_HEAT,
				EventType.GAME_DAY,
				EventType.TRANSPORT_DISRUPTION
			]
			current_event = event_pool[randi() % event_pool.size()]

	_apply_event_rules()

	var nm = null
	if is_inside_tree() and get_tree() and get_tree().root:
		nm = get_tree().root.find_child("NewsManager", true, false)
	if not nm:
		var nm_class = load("res://src/news/news_manager.gd")
		if nm_class and nm_class.has_method("get_instance"):
			nm = nm_class.get_instance()
	if nm and nm.has_method("generate_daily_news"):
		nm.generate_daily_news()

## Força a definição de um evento específico (útil para testes ou cenários programados)
func force_event(event_type: EventType) -> void:
	roll_daily_event(event_type, true)

func _reset_modifiers() -> void:
	customer_demand_multiplier = 1.0
	dine_in_multiplier = 1.0
	drive_thru_multiplier = 1.0
	beverage_demand_multiplier = 1.0
	electricity_cost_multiplier = 1.0
	delivery_time_multiplier = 1.0
	is_water_supply_active = true
	power_cuts_triggered = [false, false]
	event_title = ""
	event_headline = ""
	event_body = ""

func _apply_event_rules() -> void:
	match current_event:
		EventType.NONE:
			event_title = ""
			event_headline = ""
			event_body = ""

		EventType.NETWORK_MAINTENANCE:
			event_title = "MANUTENÇÃO PROGRAMADA"
			event_headline = "Interrupções no Fornecimento de Energia"
			event_body = "A concessionária de energia elétrica informou que realizará manutenções na rede local hoje. Interrupções temporárias de energia poderão ocorrer durante o expediente."
			power_cuts_triggered = [false, false]

		EventType.NETWORK_REGULATION:
			event_title = "REGULAGEM DA REDE"
			event_headline = "Ajuste Temporário na Tarifa de Energia"
			event_body = "A operadora elétrica realizará ajustes e calibrações na infraestrutura regional. O custo por kWh consumido hoje sofrerá um acréscimo temporário de 30%."
			electricity_cost_multiplier = 1.30

		EventType.WATER_SUPPLY_PROBLEM:
			event_title = "PROBLEMA NO ABASTECIMENTO"
			event_headline = "Interrupção Temporária no Fornecimento de Água"
			event_body = "A companhia de saneamento notificou reparos na tubulação do bairro. O fornecimento de água será interrompido temporariamente por cerca de 2 horas no início da tarde."
			water_outage_start_hour = 13.0
			water_outage_end_hour = 15.0

		EventType.RAINY_DAY:
			event_title = "PREVISÃO DO TEMPO"
			event_headline = "Chuva Persistente ao Longo do Dia"
			event_body = "Previsão de chuva constante na região. Espera-se menor circulação de pedestres no salão e maior procura pelo atendimento rápido via Drive-Thru."
			dine_in_multiplier = 0.75
			drive_thru_multiplier = 1.35
			_sync_weather(WeatherManager.WeatherType.RAINY)

		EventType.STORM_DAY:
			event_title = "ALERTA METEOROLÓGICO"
			event_headline = "Tempestade com Rajadas de Vento e Chuva Forte"
			event_body = "Forte tempestade prevista para hoje com ventos intensos e raios. Há risco moderado de instabilidade e queda de energia na rede elétrica."
			dine_in_multiplier = 0.60
			drive_thru_multiplier = 1.50
			_sync_weather(WeatherManager.WeatherType.RAINY)

		EventType.EXTREME_HEAT:
			event_title = "ONDA DE CALOR"
			event_headline = "Temperaturas Excepcionalmente Altas"
			event_body = "Uma intensa onda de calor atinge a cidade hoje. A procura por bebidas geladas, sucos e refrigerantes registrará um aumento expressivo."
			beverage_demand_multiplier = 2.0
			_sync_weather(WeatherManager.WeatherType.SUNNY)

		EventType.GAME_DAY:
			event_title = "DIA DE JOGO NO ESTÁDIO"
			event_headline = "Grande Movimento Esperado Pós-Partida"
			event_body = "O estádio da região sediará uma importante partida de futebol hoje. Um pico expressivo de torcedores e clientes é esperado no restaurante a partir das 18h30."
			game_peak_start_hour = 18.5
			game_peak_end_hour = 21.0

		EventType.TRANSPORT_DISRUPTION:
			event_title = "PROBLEMAS NO TRANSPORTE"
			event_headline = "Atrasos nas Entregas e Paralisações nas Estradas"
			event_body = "Devido a problemas nas rodovias e paralisações no setor de transportes, as entregas de insumos poderão sofrer atrasos hoje (+25%)."
			delivery_time_multiplier = 1.25

	event_started.emit(current_event, get_current_event_data())

func _sync_weather(wtype: WeatherManager.WeatherType) -> void:
	var wm = WeatherManager.get_instance()
	if wm:
		wm.target_weather = wtype
		wm.current_weather = wtype

func _process_timed_event_effects(time_f: float) -> void:
	# 1. Interrupção de Água (WATER_SUPPLY_PROBLEM)
	if current_event == EventType.WATER_SUPPLY_PROBLEM:
		var should_be_active = not (time_f >= water_outage_start_hour and time_f < water_outage_end_hour)
		if is_water_supply_active != should_be_active:
			is_water_supply_active = should_be_active
			water_supply_state_changed.emit(is_water_supply_active)
	else:
		if not is_water_supply_active:
			is_water_supply_active = true
			water_supply_state_changed.emit(true)

	# 2. Quedas de Energia Programadas (NETWORK_MAINTENANCE)
	if current_event == EventType.NETWORK_MAINTENANCE:
		for i in range(power_cut_hours.size()):
			var cut_h = power_cut_hours[i]
			if time_f >= cut_h and time_f < (cut_h + 0.35) and not power_cuts_triggered[i]:
				power_cuts_triggered[i] = true
				_trigger_power_cut("Manutenção na rede elétrica")

	# 3. Queda de Energia por Tempestade (STORM_DAY)
	if current_event == EventType.STORM_DAY:
		if time_f >= 15.5 and time_f < 16.0 and not power_cuts_triggered[0]:
			power_cuts_triggered[0] = true
			_trigger_power_cut("Queda de raio na rede durante a tempestade")

	# 4. Pico Noturno do Dia de Jogo (GAME_DAY)
	if current_event == EventType.GAME_DAY:
		if time_f >= game_peak_start_hour and time_f <= game_peak_end_hour:
			customer_demand_multiplier = 1.65
		else:
			customer_demand_multiplier = 1.0

func _trigger_power_cut(reason: String) -> void:
	var pm = PowerManager.get_instance()
	if pm and pm.is_main_power_on:
		pm.set_main_power(false)
		power_outage_occurred.emit(reason)

	var nm = null
	if is_inside_tree() and get_tree() and get_tree().root:
		nm = get_tree().root.find_child("NewsManager", true, false)
	if nm and nm.has_method("mark_event_occurred"):
		nm.mark_event_occurred(current_event)

## Finaliza o evento ao encerramento do dia e arquiva no histórico
func end_day_event() -> void:
	var cal = CalendarManager.get_instance()
	var day_num = cal.day_number if cal else 1
	var date_str = cal.get_formatted_date() if cal else ""

	event_history.append({
		"day_number": day_num,
		"date": date_str,
		"event_type": current_event,
		"event_title": event_title,
		"event_headline": event_headline,
		"electricity_cost_multiplier": electricity_cost_multiplier
	})

	var finished_event = current_event
	_reset_modifiers()
	current_event = EventType.NONE
	event_ended.emit(finished_event)

# ─── Consultas de Modificadores para Clientes e Economia ────────────────────────

## Multiplicador geral de fluxo de clientes (inclui Fim de Semana e Picos de Evento)
func get_customer_demand_multiplier(time_h: float = 12.0) -> float:
	var mult = customer_demand_multiplier

	# Modificador automático de Fim de Semana (Sábado/Domingo)
	var cal = CalendarManager.get_instance()
	if cal and cal.is_weekend():
		mult *= weekend_customer_multiplier

	# Modificador de pico do dia de jogo
	if current_event == EventType.GAME_DAY:
		if time_h >= game_peak_start_hour and time_h <= game_peak_end_hour:
			mult *= 1.65

	return mult

## Multiplicador de preferência por clientes presenciais (Salão)
func get_dine_in_multiplier() -> float:
	return dine_in_multiplier

## Multiplicador de preferência pelo Drive-thru
func get_drive_thru_multiplier() -> float:
	return drive_thru_multiplier

## Multiplicador de demanda por bebidas
func get_beverage_demand_multiplier() -> float:
	return beverage_demand_multiplier

## Multiplicador da tarifa de energia do dia (ex: 1.30 na regulagem de rede)
func get_electricity_cost_multiplier() -> float:
	return electricity_cost_multiplier

## Retorna se o fornecimento de água está disponível no momento
func is_water_available() -> bool:
	return is_water_supply_active

## Multiplicador de prazo de entrega de suprimentos (ex: 1.25 em greves/bloqueios)
func get_delivery_time_multiplier() -> float:
	return delivery_time_multiplier

## Retorna dados completos do evento atual para exibição no HUD e futuro PC
func get_current_event_data() -> Dictionary:
	return {
		"has_event": current_event != EventType.NONE,
		"event_type": current_event,
		"event_name": EventType.keys()[current_event],
		"title": event_title,
		"headline": event_headline,
		"body": event_body,
		"electricity_multiplier": electricity_cost_multiplier,
		"demand_multiplier": customer_demand_multiplier,
		"dine_in_multiplier": dine_in_multiplier,
		"drive_thru_multiplier": drive_thru_multiplier,
		"beverage_multiplier": beverage_demand_multiplier,
		"is_water_active": is_water_supply_active
	}
