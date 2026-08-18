class_name WaterManager
extends Node

# =============================================================================
# BURGER RUSH - GERENCIADOR CENTRAL DE CONSUMO DE ÁGUA (WATER MANAGER)
#
# Monitora o consumo de água das atividades do restaurante:
#  - Pia industrial (lavagem de bucha, higienização das mãos)
#  - Máquina de refrigerante (refrigeração / diluição / operação)
#  - Máquina de suco (mistura de polpa / diluição)
#  - Limpeza e outras atividades operacionais
#
# Totalmente integrado com DailyEventManager (interrupções no fornecimento)
# e FinanceManager (geração de fatura de água).
# =============================================================================

signal water_consumed(liters: float, source: String)
signal water_supply_state_changed(is_available: bool)

static var instance = null

## Tarifa de água por litro (R$ 20,00 / m³ = R$ 0,02 / Litro)
@export var water_tariff_per_liter: float = 0.02

## Consumo acumulado no dia em Litros
var daily_water_liters: float = 0.0

## Detalhamento por fonte de consumo
var consumption_by_source: Dictionary = {
	"sink": 0.0,
	"drink_machine": 0.0,
	"juice_machine": 0.0,
	"cleaning": 0.0,
	"other": 0.0
}

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

static func get_instance():
	if instance and is_instance_valid(instance):
		return instance
	return null

func _ready() -> void:
	var clock = _get_game_clock()
	if clock and not clock.day_started.is_connected(_on_day_started):
		clock.day_started.connect(_on_day_started)

func _get_game_clock() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.find_child("GameClock", true, false)
	return null

func _on_day_started(_day_number: int) -> void:
	start_new_day()

func start_new_day() -> void:
	daily_water_liters = 0.0
	for k in consumption_by_source.keys():
		consumption_by_source[k] = 0.0

## Registra consumo de água (em litros). Retorna false se o abastecimento estiver cortado.
func consume_water(liters: float, source: String = "sink") -> bool:
	if liters <= 0.0:
		return true

	# Verifica se há água disponível no momento
	if not is_water_available():
		return false

	daily_water_liters += liters
	consumption_by_source[source] = consumption_by_source.get(source, 0.0) + liters
	water_consumed.emit(liters, source)
	return true

## Verifica se o abastecimento está ativo na rede pública
func is_water_available() -> bool:
	var dem = _get_daily_event_manager()
	if dem:
		return dem.is_water_available()
	return true

func _get_daily_event_manager() -> Node:
	if is_inside_tree() and get_tree() and get_tree().root:
		return get_tree().root.find_child("DailyEventManager", true, false)
	return null

## Retorna o total de litros consumidos no dia
func get_daily_consumption_liters() -> float:
	return daily_water_liters

## Retorna o custo monetário da água consumida no dia
func get_daily_water_cost() -> float:
	return daily_water_liters * water_tariff_per_liter

## Retorna o dicionário com consumo detalhado por categoria/fonte
func get_consumption_breakdown() -> Dictionary:
	return consumption_by_source.duplicate()
