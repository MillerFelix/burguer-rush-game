class_name CalendarManager
extends Node

# =============================================================================
# BURGER RUSH - SISTEMA DE CALENDÁRIO CENTRAL
#
# Gerencia a data cronológica real do jogo a partir de 01/01/2026 (Quinta-feira, Dia 1).
# O restaurante opera todos os 7 dias da semana sem folgas semanais.
# Fornece identificação de finais de semana e formatações de data em português.
# Preparado para integração com PC (Notícias, Finanças, Conta de Energia).
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
	return instance

func _ready() -> void:
	reset_calendar()

## Reinicializa o calendário para o Dia 1 (01/01/2026 - Quinta-feira)
func reset_calendar() -> void:
	day_number = 1
	current_day = START_DAY
	current_month = START_MONTH
	current_year = START_YEAR
	day_of_week = START_DAY_OF_WEEK

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
