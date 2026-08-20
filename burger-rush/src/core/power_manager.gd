class_name PowerManager
extends Node

# =============================================================================
# BURGER RUSH - SISTEMA CENTRAL DE ENERGIA (POWER MANAGER)
#
# Gerencia a rede elétrica geral do restaurante, estado do disjuntor principal,
# registro de todos os equipamentos elétricos conectados, monitoramento de
# consumo em tempo real (kW) e acúmulo de consumo diário (kWh).
#
# Preparado para integração futura com clima, conta de luz e eventos elétricos.
# =============================================================================

signal power_state_changed(is_on: bool)
signal appliance_registered(appliance: Node)
signal appliance_unregistered(appliance: Node)

static var instance = null

## Estado da chave geral de energia do restaurante (Inicia desligada a cada novo dia)
@export var is_main_power_on: bool = false

## Registro de aparelhos elétricos conectados
## Chave: instance_id (int) -> Valor: Dictionary com metadados e métricas
var registered_appliances: Dictionary = {}

## Consumo total acumulado no dia em kWh
var total_energy_kwh: float = 0.0

func _init() -> void:
	instance = self

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
	# Notifica o estado inicial (desligado por padrão)
	call_deferred("_broadcast_power_state")

func _process(delta: float) -> void:
	if not is_main_power_on:
		return

	# Acumula o consumo energético de cada aparelho em funcionamento ativo
	var active_kw_total: float = 0.0
	var dead_ids: Array = []
	for id in registered_appliances:
		var app = registered_appliances[id]
		var node = app.get("node")
		if node and is_instance_valid(node):
			if app.get("is_turned_on", false):
				var mult: float = app.get("multiplier", 1.0)
				var kw: float = app.get("base_kw", 0.0) * mult
				app["active_seconds"] = app.get("active_seconds", 0.0) + delta
				var energy_step: float = (kw * delta) / 3600.0
				app["total_kwh"] = app.get("total_kwh", 0.0) + energy_step
				active_kw_total += kw
		else:
			dead_ids.append(id)

	for id in dead_ids:
		registered_appliances.erase(id)

	total_energy_kwh += (active_kw_total * delta) / 3600.0

## Liga ou desliga a chave geral do restaurante
func set_main_power(is_on: bool) -> void:
	if is_main_power_on == is_on:
		return

	is_main_power_on = is_on
	_broadcast_power_state()

func toggle_main_power() -> void:
	set_main_power(not is_main_power_on)

func _broadcast_power_state() -> void:
	power_state_changed.emit(is_main_power_on)
	for id in registered_appliances:
		var app = registered_appliances[id]
		var node = app.get("node")
		if node and is_instance_valid(node):
			if node.has_method("on_power_state_changed"):
				node.on_power_state_changed(is_main_power_on)

## Registra um novo equipamento elétrico na rede
func register_appliance(node: Node, appliance_id: String, display_name: String, base_kw: float, is_on_default: bool = true) -> void:
	if not node:
		return

	var id: int = node.get_instance_id()
	registered_appliances[id] = {
		"node": node,
		"appliance_id": appliance_id,
		"display_name": display_name,
		"base_kw": base_kw,
		"multiplier": 1.0,
		"is_turned_on": is_on_default,
		"active_seconds": 0.0,
		"total_kwh": 0.0
	}

	appliance_registered.emit(node)

	# Atualiza o equipamento com o estado atual da rede
	if node.has_method("on_power_state_changed"):
		node.on_power_state_changed(is_main_power_on)

## Desregistra um equipamento elétrico
func unregister_appliance(node: Node) -> void:
	if not node:
		return
	var id: int = node.get_instance_id()
	if registered_appliances.has(id):
		registered_appliances.erase(id)
		appliance_unregistered.emit(node)

## Atualiza se o equipamento específico está ligado em operação pelo seu próprio botão
func set_appliance_state(node: Node, is_turned_on: bool) -> void:
	if not node:
		return
	var id: int = node.get_instance_id()
	if registered_appliances.has(id):
		registered_appliances[id]["is_turned_on"] = is_turned_on

## Atualiza o multiplicador de consumo dinâmico (ex: 3.0x quando porta de geladeira/freezer aberta)
func set_appliance_multiplier(node: Node, multiplier: float) -> void:
	if not node:
		return
	var id: int = node.get_instance_id()
	if registered_appliances.has(id):
		registered_appliances[id]["multiplier"] = maxf(0.0, multiplier)

## Retorna a potência ativa instantânea sendo consumida pela rede em kW
func get_current_power_consumption_kw() -> float:
	if not is_main_power_on:
		return 0.0

	var total_kw: float = 0.0
	for id in registered_appliances.keys():
		var app = registered_appliances[id]
		if app.get("is_turned_on", false):
			var mult: float = app.get("multiplier", 1.0)
			total_kw += app.get("base_kw", 0.0) * mult
	return total_kw

## Retorna o consumo total de energia acumulado no dia em kWh
func get_daily_energy_consumption_kwh() -> float:
	return total_energy_kwh

## Retorna dados detalhados de um aparelho específico
func get_appliance_data(node: Node) -> Dictionary:
	if not node:
		return {}
	var id: int = node.get_instance_id()
	return registered_appliances.get(id, {})

## Retorna o custo financeiro estimado da energia consumida no dia (R$), considerando a tarifa base e modificadores de eventos
func get_daily_electricity_cost() -> float:
	var base_rate = 0.85 # R$ 0,85 por kWh base
	var event_mult = 1.0
	if is_inside_tree() and get_tree() and get_tree().root:
		var dem = get_tree().root.find_child("DailyEventManager", true, false)
		if dem and dem.has_method("get_electricity_cost_multiplier"):
			event_mult = dem.get_electricity_cost_multiplier()
	return total_energy_kwh * base_rate * event_mult

## Reseta o contador diário de energia (usado na virada do dia)
func reset_daily_consumption() -> void:
	total_energy_kwh = 0.0
	for id in registered_appliances.keys():
		registered_appliances[id]["active_seconds"] = 0.0
		registered_appliances[id]["total_kwh"] = 0.0

func start_new_day() -> void:
	reset_daily_consumption()
