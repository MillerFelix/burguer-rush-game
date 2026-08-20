class_name CalendarManager
extends Node

# =============================================================================
# BURGER RUSH - SISTEMA DE CALENDÁRIO CENTRAL & HISTÓRICO VIVO
#
# Gerencia a data cronológica real do jogo a partir de 01/01/2026 (Quinta-feira, Dia 1).
# O restaurante opera todos os 7 dias da semana sem folgas semanais.
# Fornece persistência e agregação do histórico diário de cada dia da partida:
# - Finanças (Receita, Despesas, Lucro Líquido, Contas, Salários);
# - Pedidos (Salão, Drive-thru, Delivery, Corretos/Incorretos, Histórico);
# - Reputação & Avaliações dos Clientes;
# - Eventos do Dia & Condições Climáticas;
# - Notícias e Fatos Noticiosos.
# =============================================================================

signal day_advanced(day_number: int, formatted_date: String, full_date_string: String)

static var instance: CalendarManager = null

const START_YEAR: int = 2026
const START_MONTH: int = 1
const START_DAY: int = 1
const START_DAY_OF_WEEK: int = 4 # 1 = Segunda, 2 = Terça, 3 = Quarta, 4 = Quinta, 5 = Sexta, 6 = Sábado, 7 = Domingo

var day_number: int = 1
var current_day: int = 1
var current_month: int = 1
var current_year: int = 2026
var day_of_week: int = 4

## Armazenamento persistente de registros de cada dia encerrado
var daily_records: Dictionary = {}

const WEEKDAY_NAMES: Array[String] = [
	"Segunda-feira",
	"Terça-feira",
	"Quarta-feira",
	"Quinta-feira",
	"Sexta-feira",
	"Sábado",
	"Domingo"
]

const MONTH_NAMES: Array[String] = [
	"janeiro", "fevereiro", "março", "abril", "maio", "junho",
	"julho", "agosto", "setembro", "outubro", "novembro", "dezembro"
]

const DAYS_PER_MONTH: Array[int] = [
	31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
]

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

static func get_instance() -> CalendarManager:
	if instance and is_instance_valid(instance):
		return instance
	var ml = Engine.get_main_loop()
	if ml and ml is SceneTree:
		var tree = ml as SceneTree
		if tree.root:
			var found = tree.root.find_child("CalendarManager", true, false)
			if found:
				instance = found
				return instance
	return null

func _ready() -> void:
	reset_calendar()

## Reinicializa o calendário para o Dia 1 (01/01/2026 - Quinta-feira)
func reset_calendar() -> void:
	day_number = 1
	current_day = START_DAY
	current_month = START_MONTH
	current_year = START_YEAR
	day_of_week = START_DAY_OF_WEEK
	daily_records.clear()

## Avança um dia no calendário
func advance_day() -> void:
	day_number += 1
	day_of_week = ((day_of_week % 7) + 1)
	current_day += 1

	var max_days = _get_days_in_month(current_month, current_year)
	if current_day > max_days:
		current_day = 1
		current_month += 1
		if current_month > 12:
			current_month = 1
			current_year += 1

	day_advanced.emit(day_number, get_formatted_date(), get_full_date_string())

func _get_days_in_month(month: int, year: int) -> int:
	if month == 2 and _is_leap_year(year):
		return 29
	var idx = clamp(month - 1, 0, 11)
	return DAYS_PER_MONTH[idx]

func _is_leap_year(year: int) -> bool:
	return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)

## Retorna se o dia atual é fim de semana (Sábado ou Domingo)
func is_weekend() -> bool:
	return day_of_week == 6 or day_of_week == 7

## Retorna o nome do dia da semana (ex: "Quinta-feira")
func get_weekday_name() -> String:
	var idx = clamp(day_of_week - 1, 0, 6)
	return WEEKDAY_NAMES[idx]

## Retorna o nome do mês (ex: "janeiro")
func get_month_name() -> String:
	var idx = clamp(current_month - 1, 0, 11)
	return MONTH_NAMES[idx]

## Retorna a data no formato DD/MM/AAAA (ex: "01/01/2026")
func get_formatted_date() -> String:
	return "%02d/%02d/%04d" % [current_day, current_month, current_year]

## Retorna a data por extenso (ex: "Quinta-feira, 1 de janeiro de 2026")
func get_full_date_string() -> String:
	return "%s, %d de %s de %d" % [get_weekday_name(), current_day, get_month_name(), current_year]

## Retorna o título formatado para o HUD/Avisos (ex: "DIA 1 — Quinta-feira, 1 de janeiro de 2026")
func get_day_title() -> String:
	return "DIA %d — %s" % [day_number, get_full_date_string()]

## Calcula os dados cronológicos exatos para qualquer número de dia da partida
func get_date_for_day_number(target_day: int) -> Dictionary:
	var d = START_DAY
	var m = START_MONTH
	var y = START_YEAR
	var dow = START_DAY_OF_WEEK

	for _i in range(1, target_day):
		dow = ((dow % 7) + 1)
		d += 1
		var max_d = _get_days_in_month(m, y)
		if d > max_d:
			d = 1
			m += 1
			if m > 12:
				m = 1
				y += 1

	var w_name = WEEKDAY_NAMES[clamp(dow - 1, 0, 6)]
	var m_name = MONTH_NAMES[clamp(m - 1, 0, 11)]
	var f_date = "%02d/%02d/%04d" % [d, m, y]
	var full_str = "%s, %d de %s de %d" % [w_name, d, m_name, y]

	return {
		"day_number": target_day,
		"day": d,
		"month": m,
		"year": y,
		"day_of_week": dow,
		"weekday_name": w_name,
		"month_name": m_name,
		"formatted_date": f_date,
		"full_date_string": full_str,
		"is_weekend": (dow == 6 or dow == 7)
	}

## Retorna o número do dia da partida (1, 2, 3...) a partir da data de calendário
func get_day_number_from_date(day: int, month: int, year: int) -> int:
	var cur_d = START_DAY
	var cur_m = START_MONTH
	var cur_y = START_YEAR
	var count = 1

	while true:
		if cur_d == day and cur_m == month and cur_y == year:
			return count
		cur_d += 1
		var max_d = _get_days_in_month(cur_m, cur_y)
		if cur_d > max_d:
			cur_d = 1
			cur_m += 1
			if cur_m > 12:
				cur_m = 1
				cur_y += 1
		count += 1
		if count > 2000: # Proteção contra loop infinito
			break
	return count

## Retorna a matriz de semanas para exibição visual do mês no Calendário (Segunda=0 a Domingo=6)
func get_month_matrix(year: int, month: int) -> Array:
	var total_days = _get_days_in_month(month, year)
	var first_day_info = get_date_for_day_number(get_day_number_from_date(1, month, year))
	var start_weekday = first_day_info.get("day_of_week", 1) # 1=Segunda, 7=Domingo
	var start_col = start_weekday - 1 # 0=Segunda, 6=Domingo

	var matrix: Array = []
	var current_week: Array = []

	# Preenche dias vazios antes do dia 1
	for _i in range(start_col):
		current_week.append({"day": 0, "day_number": 0, "is_current_month": false})

	for d in range(1, total_days + 1):
		var d_num = get_day_number_from_date(d, month, year)
		current_week.append({
			"day": d,
			"day_number": d_num,
			"is_current_month": true,
			"is_past": d_num < day_number,
			"is_today": d_num == day_number,
			"is_future": d_num > day_number
		})

		if current_week.size() == 7:
			matrix.append(current_week)
			current_week = []

	# Preenche o restante da última semana
	if not current_week.is_empty():
		while current_week.size() < 7:
			current_week.append({"day": 0, "day_number": 0, "is_current_month": false})
		matrix.append(current_week)

	return matrix

## Arquiva o registro consolidado ao final de um dia
func archive_day_record(day_num: int, record: Dictionary) -> void:
	daily_records[day_num] = record

## Retorna os dados consolidados de qualquer dia (ao vivo se for hoje, ou do histórico arquivado)
func get_day_record(target_day: int) -> Dictionary:
	if daily_records.has(target_day):
		return daily_records[target_day]

	# Se for o dia atual em andamento ou dia sem registro prévio, gera a agregação ao vivo
	return _build_live_day_record(target_day)

func _build_live_day_record(target_day: int) -> Dictionary:
	var date_info = get_date_for_day_number(target_day)

	# 1. Finanças
	var fin = null
	var fin_script = load("res://src/economy/finance_manager.gd")
	if fin_script and fin_script.has_method("get_instance"):
		fin = fin_script.get_instance()
	if not fin and is_inside_tree() and get_tree() and get_tree().root:
		fin = get_tree().root.find_child("FinanceManager", true, false)

	var revenue = 0.0
	var expenses = 0.0
	var profit = 0.0
	var channel_sales = {"dine_in": 0.0, "drive_thru": 0.0, "delivery": 0.0}

	if fin:
		var f_data = fin.get_financial_data()
		revenue = f_data.get("daily_revenue", 0.0)
		expenses = f_data.get("daily_expenses", 0.0)
		profit = f_data.get("daily_profit", 0.0)
		channel_sales = f_data.get("daily_channels", channel_sales)

	# 2. Pedidos
	var om = null
	var om_script = load("res://src/orders/order_manager.gd")
	if om_script and om_script.has_method("get_instance"):
		om = om_script.get_instance()
	if not om and is_inside_tree() and get_tree() and get_tree().root:
		om = get_tree().root.find_child("OrderManager", true, false)

	var total_orders = 0
	var dine_in_orders = 0
	var drive_thru_orders = 0
	var delivery_orders = 0
	var correct_orders = 0
	var wrong_orders = 0
	var orders_history: Array = []

	if om:
		var history = om.get_daily_history()
		for ord in history:
			total_orders += 1
			var st = ord.get("source_type", "DINE_IN")
			match st:
				"DRIVE_THRU": drive_thru_orders += 1
				"DELIVERY": delivery_orders += 1
				_: dine_in_orders += 1

			if ord.get("is_wrong", false):
				wrong_orders += 1
			else:
				correct_orders += 1
			orders_history.append(ord)

	# 3. Avaliações
	var rep = null
	var rep_script = load("res://src/customers/reputation_manager.gd")
	if rep_script and rep_script.has_method("get_instance"):
		rep = rep_script.get_instance()
	if not rep and is_inside_tree() and get_tree() and get_tree().root:
		rep = get_tree().root.find_child("ReputationManager", true, false)

	var avg_rating = 5.0
	var day_reviews: Array = []
	if rep:
		avg_rating = rep.get_average_rating()
		day_reviews = rep.get_today_reviews(target_day)

	# 4. Eventos e Clima
	var dem = null
	var wm = null
	var dem_script = load("res://src/core/daily_event_manager.gd")
	if dem_script and dem_script.has_method("get_instance"):
		dem = dem_script.get_instance()
	if not dem and is_inside_tree() and get_tree() and get_tree().root:
		dem = get_tree().root.find_child("DailyEventManager", true, false)

	var wm_script = load("res://src/environment/weather_manager.gd")
	if wm_script and wm_script.has_method("get_instance"):
		wm = wm_script.get_instance()
	if not wm and is_inside_tree() and get_tree() and get_tree().root:
		wm = get_tree().root.find_child("WeatherManager", true, false)

	var event_title = "Operação Normal"
	var event_headline = "Nenhum incidente registrado na região."
	var event_type_val = 0
	if dem:
		var edata = dem.get_current_event_data()
		event_title = edata.get("title", "Operação Normal")
		event_headline = edata.get("headline", "Sem eventos especiais")
		event_type_val = edata.get("event_type", 0)

	var weather_name = "Ensolarado"
	var weather_icon = "☀️"
	if wm:
		match wm.current_weather:
			0:
				weather_name = "Ensolarado"
				weather_icon = "☀️"
			1:
				weather_name = "Nublado"
				weather_icon = "☁️"
			2:
				weather_name = "Chuvoso"
				weather_icon = "🌧️"

	# 5. Notícias do Dia
	var news_articles: Array = []
	var news_mgr = null
	var nm_script = load("res://src/news/news_manager.gd")
	if nm_script and nm_script.has_method("get_instance"):
		news_mgr = nm_script.get_instance()
	if not news_mgr and is_inside_tree() and get_tree() and get_tree().root:
		news_mgr = get_tree().root.find_child("NewsManager", true, false)
	if news_mgr and news_mgr.has_method("get_news_for_day"):
		news_articles = news_mgr.get_news_for_day(target_day)

	var rec = {
		"day_number": target_day,
		"date": date_info.get("formatted_date", ""),
		"full_date_string": date_info.get("full_date_string", ""),
		"weekday_name": date_info.get("weekday_name", ""),
		"financial": {
			"revenue": revenue,
			"expenses": expenses,
			"profit": profit,
			"channels": channel_sales
		},
		"orders": {
			"total": total_orders,
			"dine_in": dine_in_orders,
			"drive_thru": drive_thru_orders,
			"delivery": delivery_orders,
			"correct": correct_orders,
			"wrong": wrong_orders,
			"history": orders_history
		},
		"reputation": {
			"average_rating": avg_rating,
			"reviews_count": day_reviews.size(),
			"reviews": day_reviews
		},
		"event": {
			"type": event_type_val,
			"title": event_title,
			"headline": event_headline
		},
		"weather": {
			"name": weather_name,
			"icon": weather_icon
		},
		"news": news_articles
	}

	return rec

## Retorna um dicionário com todos os dados cronológicos atuais para o PC e Estatísticas
func get_calendar_data() -> Dictionary:
	return {
		"day_number": day_number,
		"day": current_day,
		"month": current_month,
		"year": current_year,
		"day_of_week": day_of_week,
		"weekday_name": get_weekday_name(),
		"month_name": get_month_name(),
		"formatted_date": get_formatted_date(),
		"full_date_string": get_full_date_string(),
		"is_weekend": is_weekend()
	}
