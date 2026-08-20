class_name NewsManager
extends Node

# =============================================================================
# BURGER RUSH - SISTEMA CENTRAL DE NOTÍCIAS & JORNAL DA CIDADE
#
# Gerencia as notícias e boletins informativos conectados diretamente aos eventos:
# - Eventos reais do DailyEventManager (manutenção elétrica, água, calor, jogos);
# - Previsão e alertas meteorológicos com impacto prático no gameplay;
# - Quando não há eventos relevantes, não cria notícias artificiais/fictícias;
# - Quando há notícias, detalha claramente as Influências no dia a dia do restaurante.
# =============================================================================

signal news_updated(today_articles: Array)
signal breaking_news_alert(article: Dictionary)

static var instance = null

const CalendarManager = preload("res://src/core/calendar_manager.gd")
const DailyEventManager = preload("res://src/core/daily_event_manager.gd")

## Histórico de notícias arquivadas por dia: { day_number: Array[Dictionary] }
var news_history: Dictionary = {}

## Notícias do dia atual
var today_articles: Array = []

func _enter_tree() -> void:
	instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

static func get_instance() -> NewsManager:
	if instance and is_instance_valid(instance):
		return instance
	var ml = Engine.get_main_loop()
	if ml and ml is SceneTree:
		var tree = ml as SceneTree
		if tree.root:
			var found = tree.root.find_child("NewsManager", true, false)
			if found:
				instance = found
	return instance

func _ready() -> void:
	instance = self
	generate_daily_news()

## Gera o pacote de notícias do dia com base nos sistemas reais do jogo
func generate_daily_news(forced_day: int = -1, forced_event: int = -1) -> Array:
	var cal = CalendarManager.get_instance()
	if not cal and is_inside_tree() and get_tree() and get_tree().root:
		cal = get_tree().root.find_child("CalendarManager", true, false)

	var current_day_num = cal.day_number if cal else 1
	var is_current_day = (forced_day <= 0 or forced_day == current_day_num)
	var day_num = current_day_num if is_current_day else forced_day
	var date_str = cal.get_formatted_date() if (cal and is_current_day) else "01/01/2026"
	if not is_current_day and cal:
		date_str = cal.get_date_for_day_number(forced_day).get("formatted_date", "01/01/2026")

	var dem = DailyEventManager.get_instance()
	if not dem and is_inside_tree() and get_tree() and get_tree().root:
		dem = get_tree().root.find_child("DailyEventManager", true, false)

	var event_type = DailyEventManager.EventType.NONE
	if forced_event >= 0:
		event_type = forced_event
	elif is_current_day and dem:
		event_type = dem.current_event
	elif dem and not is_current_day:
		for h in dem.event_history:
			if h.get("day_number") == day_num:
				event_type = h.get("event_type", DailyEventManager.EventType.NONE)
				break

	var articles: Array = []
	if event_type != DailyEventManager.EventType.NONE:
		var main_article = _build_main_event_article(day_num, date_str, event_type)
		articles.append(main_article)
	else:
		var normal_bulletin = _build_normal_day_bulletin(day_num, date_str)
		articles.append(normal_bulletin)

	var sec_news = _build_secondary_local_news(day_num)
	for s in sec_news:
		articles.append(s)

	news_history[day_num] = articles.duplicate(true)

	if is_current_day:
		today_articles = articles.duplicate(true)
		news_updated.emit(today_articles)

	return articles

func _build_normal_day_bulletin(day_num: int, date_str: String) -> Dictionary:
	var impacts: Array[String] = [
		"Todos os canais de atendimento operando com normalidade (Salão, Drive-Thru e Delivery).",
		"Nenhuma alteração climática brusca ou interrupção de serviços prevista."
	]
	return {
		"id": "normal_%d" % day_num,
		"day_number": day_num,
		"date": date_str,
		"published_time": "08:00",
		"source": "Gazeta Metropolitana",
		"category": "INFORMATIVO MUNICIPAL",
		"icon": "📰",
		"title": "Boletim da Cidade — Dia tranquilo na região",
		"subtitle": "Atividades comerciais e serviços públicos seguem sem alterações previstas.",
		"body": "Nenhum acontecimento relevante foi registrado para hoje. O comércio local funciona normalmente e os estabelecimentos seguem suas atividades com fluxo regular de clientes e transporte normalizado.",
		"impact": " ".join(impacts),
		"impacts": impacts,
		"status_badge": "✅ OPERAÇÃO REGULAR",
		"is_main": true,
		"occurred": false,
		"event_type": 0
	}

func _build_secondary_local_news(day_num: int) -> Array:
	var pool = [
		{
			"source": "Diário Comercial",
			"category": "COMÉRCIO LOCAL",
			"icon": "🍔",
			"title": "Movimento nos restaurantes da região segue em ritmo constante",
			"body": "Comerciantes do centro gastronômico destacam a boa saída de lanches artesanais, porções crocantes e bebidas durante os horários de pico.",
			"time": "09:15"
		},
		{
			"source": "Voz da Cidade",
			"category": "TRÂNSITO & VIAS",
			"icon": "🚗",
			"title": "Tráfego flui sem retenções nos acessos e avenidas comerciais",
			"body": "Agentes municipais de trânsito relatam vias desobstruídas e rotas livres para motoboys e clientes acessando o drive-thru.",
			"time": "10:30"
		},
		{
			"source": "Tribuna Regional",
			"category": "ABASTECIMENTO",
			"icon": "📦",
			"title": "Distribuição de insumos e atacados opera com estoque regular",
			"body": "Fornecedores regionais garantem disponibilidade de carnes selecionadas, pães frescos e refis para o setor de alimentação.",
			"time": "11:15"
		},
		{
			"source": "Gazeta Metropolitana",
			"category": "COTIDIANO",
			"icon": "☀️",
			"title": "Dia agradável movimenta comércio e praças do bairro",
			"body": "Consumidores aproveitam o clima ameno para circular pelas calçadas comerciais e conhecer os estabelecimentos gastronômicos.",
			"time": "12:00"
		}
	]
	var idx1 = (day_num * 2) % pool.size()
	var idx2 = (day_num * 2 + 1) % pool.size()
	return [pool[idx1], pool[idx2]]

## Atualiza a manchete principal quando um evento ocorre em tempo real
func mark_event_occurred(event_type: int) -> void:
	if today_articles.is_empty():
		return

	var main_art = today_articles[0]
	if main_art.get("is_main", false) and not main_art.get("occurred", false):
		main_art["occurred"] = true
		main_art["status_badge"] = "🔴 URGENTE / CONFIRMADO"
		main_art["title"] = _get_occurred_title(event_type)
		main_art["body"] = _get_occurred_body(event_type)
		main_art["published_time"] = "Agora há pouco"

		var cal = CalendarManager.get_instance()
		var d_num = cal.day_number if cal else 1
		news_history[d_num] = today_articles.duplicate(true)

		news_updated.emit(today_articles)
		breaking_news_alert.emit(main_art)

func _build_main_event_article(day_num: int, date_str: String, event_type: int) -> Dictionary:
	var source = "Portal Central"
	var category = "CIDADE"
	var title = ""
	var subtitle = ""
	var body = ""
	var impacts: Array[String] = []
	var icon = "📰"
	var status_badge = "📢 ALERTA MATINAL"
	var time_str = "08:30"

	match event_type:
		DailyEventManager.EventType.NETWORK_MAINTENANCE:
			source = "Portal Central"
			category = "INFRAESTRUTURA"
			icon = "⚡"
			title = "Manutenção programada na rede elétrica"
			subtitle = "A concessionária realizará manutenção preventiva na região comercial."
			body = "Equipes técnicas atuarão nos transformadores e cabos subterrâneos ao longo do dia para reparos na rede."
			impacts = [
				"Possíveis interrupções temporárias de energia.",
				"O jogador deverá religar o quadro de disjuntores caso a energia seja interrompida."
			]

		DailyEventManager.EventType.NETWORK_REGULATION:
			source = "Mercado & Negócios"
			category = "ECONOMIA"
			icon = "📈"
			title = "Reajuste temporário na tarifa de energia comercial"
			subtitle = "Variação na bandeira tarifária entra em vigor para o comércio local."
			body = "O órgão regulador autorizou uma adequação temporária na cobrança por kilowatt-hora para o setor de alimentação."
			impacts = [
				"Custo de consumo elétrico por kWh temporariamente mais alto (+30%).",
				"A conta de luz ao final do dia refletirá o acréscimo tarifário."
			]

		DailyEventManager.EventType.WATER_SUPPLY_PROBLEM:
			source = "Diário Regional"
			category = "SERVIÇOS"
			icon = "💧"
			title = "Obras no sistema de distribuição de água"
			subtitle = "Companhia municipal programa manutenção de registros na avenida."
			body = "O abastecimento na região comercial sofrerá oscilações de pressão durante o período da tarde até a conclusão dos reparos."
			impacts = [
				"Possível interrupção no fornecimento de água nas torneiras e pias.",
				"A pia da cozinha pode ficar inoperante durante o período da manutenção."
			]

		DailyEventManager.EventType.RAINY_DAY:
			source = "Clima Agora"
			category = "METEOROLOGIA"
			icon = "🌧️"
			title = "Chuva intensa atinge a cidade"
			subtitle = "Chuvas fortes cobrem a região durante grande parte do expediente."
			body = "A previsão meteorológica indica precipitação contínua e ruas molhadas ao longo de todo o dia."
			impacts = [
				"Maior movimento no drive-thru e pedidos de entrega (delivery).",
				"Menor preferência dos clientes por atendimento presencial no salão."
			]

		DailyEventManager.EventType.STORM_DAY:
			source = "Portal Central"
			category = "ALERTA TEMPESTADE"
			icon = "⛈️"
			title = "Tempestade severa com ventos fortes"
			subtitle = "Defesa Civil emite alerta para temporais e rajadas de vento na região."
			body = "Instabilidade climática severa com ventania coloca as redes de distribuição e o comércio em estado de alerta."
			impacts = [
				"Risco elevado de queda no disjuntor principal de energia.",
				"O jogador deverá religar o quadro caso a energia seja interrompida.",
				"Maior fluxo de pedidos no drive-thru e delivery."
			]

		DailyEventManager.EventType.EXTREME_HEAT:
			source = "Clima Agora"
			category = "CLIMA"
			icon = "☀️"
			title = "Onda de calor extremo atinge a região"
			subtitle = "Temperaturas superam 35°C e causam sensação térmica elevada."
			body = "Massa de ar seco e quente predomina em todo o município, aumentando a busca por hidratação e locais climatizados."
			impacts = [
				"Aumento expressivo na saída de bebidas geladas e refrigerantes.",
				"Clientes exigirão ar-condicionado ligado para manterem o humor e a satisfação."
			]

		DailyEventManager.EventType.GAME_DAY:
			source = "Jornal da Cidade"
			category = "ESPORTES & CIDADE"
			icon = "⚽"
			title = "Grande clássico de futebol no estádio municipal"
			subtitle = "Partida decisiva promete lotar os arredores e avenidas próximas."
			body = "Mais de 40 mil torcedores acompanharão o clássico, movimentando intensamente bares e restaurantes no encerramento do jogo."
			impacts = [
				"Forte pico de clientes no salão e balcão durante o horário noturno (18h30 às 21h00).",
				"Agilidade no preparo dos pedidos será essencial para evitar atrasos e desistências."
			]

		DailyEventManager.EventType.TRANSPORT_DISRUPTION:
			source = "Notícias do Bairro"
			category = "LOGÍSTICA"
			icon = "🚚"
			title = "Paralisação e lentidão no tráfego de transportadoras"
			subtitle = "Bloqueios parciais e obras nas rodovias atrasam cronograma de carga."
			body = "Distribuidores de insumos e atacados informaram que prazos de entrega de mercadorias podem sofrer pequenos atrasos."
			impacts = [
				"Entregas de pedidos na Central de Compras podem levar mais tempo para chegar.",
				"Recomenda-se antecipar reposições de carnes, pães e insumos críticos."
			]

		_:
			impacts = []

	return {
		"id": "main_%d" % day_num,
		"day_number": day_num,
		"date": date_str,
		"published_time": time_str,
		"source": source,
		"category": category,
		"icon": icon,
		"title": title,
		"subtitle": subtitle,
		"body": body,
		"impact": " ".join(impacts),
		"impacts": impacts,
		"status_badge": status_badge,
		"is_main": true,
		"occurred": false,
		"event_type": event_type
	}

func _get_occurred_title(event_type: int) -> String:
	match event_type:
		DailyEventManager.EventType.NETWORK_MAINTENANCE, DailyEventManager.EventType.STORM_DAY:
			return "Queda de energia elétrica confirmada na região"
		DailyEventManager.EventType.WATER_SUPPLY_PROBLEM:
			return "Interrupção temporária no fornecimento de água confirmada"
		DailyEventManager.EventType.GAME_DAY:
			return "Torcedores chegam em grande número ao restaurante após a partida"
		_:
			return "Atualização: Evento do dia em andamento"

func _get_occurred_body(event_type: int) -> String:
	match event_type:
		DailyEventManager.EventType.NETWORK_MAINTENANCE, DailyEventManager.EventType.STORM_DAY:
			return "Interrupções no fornecimento elétrico foram registradas. Caso a luz do restaurante caia, verifique e religue o quadro de disjuntores."
		DailyEventManager.EventType.WATER_SUPPLY_PROBLEM:
			return "O corte temporário no fornecimento de água afeta torneiras e pias. A previsão de normalização é para as próximas horas."
		DailyEventManager.EventType.GAME_DAY:
			return "Com o término do jogo, torcedores tomam o balcão e as mesas do restaurante. Atenda os pedidos com agilidade."
		_:
			return "Acompanhe as orientações operacionais para manter o restaurante funcionando perfeitamente."

## Retorna todas as notícias do dia atual
func get_today_news() -> Array:
	return today_articles

## Retorna as notícias arquivadas de qualquer dia específico da partida
func get_news_for_day(day_num: int) -> Array:
	if news_history.has(day_num):
		return news_history[day_num]
	return generate_daily_news(day_num)
