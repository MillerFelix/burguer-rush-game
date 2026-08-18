class_name CustomerExperience
extends RefCounted

# =============================================================================
# BURGER RUSH - TELEMETRIA E GERAÇÃO DE AVALIAÇÕES CONTEXTUAIS
# =============================================================================

const CustomerReview = preload("res://src/customers/customer_review.gd")
const MenuPricingManager = preload("res://src/recipes/menu_pricing_manager.gd")
const DailyEventManager = preload("res://src/core/daily_event_manager.gd")
const WeatherManager = preload("res://src/environment/weather_manager.gd")
const PowerManager = preload("res://src/core/power_manager.gd")
const CalendarManager = preload("res://src/core/calendar_manager.gd")
const AirConditioner = preload("res://src/stations/air_conditioner.gd")

var customer_id: int = 1
var customer_name: String = "Cliente Anônimo"
var customer_type: String = "Padrão" # Padrão, Apressado, Tranquilo, Crítico, Criança, Idoso, VIP, Drive-Thru, Delivery

# Origem: DINE_IN (Salão), DRIVE_THRU (Drive-thru), DELIVERY (Delivery)
var channel_type: String = "DINE_IN"

var initial_mood: float = 100.0
var final_mood: float = 100.0

var wait_time_to_order: float = 0.0
var wait_time_for_food: float = 0.0
var wait_time_checkout: float = 0.0
var wait_time_in_line: float = 0.0
var total_time_in_restaurant: float = 0.0

# Métricas específicas para Delivery
var delivery_prep_time: float = 0.0
var delivery_window_wait_time: float = 0.0

# Economia e Preço
var primary_product_id: String = ""
var charged_price: float = 0.0

var order_correct: bool = true
var food_quality: float = 1.0          # 0.0 a 1.0
var table_cleanliness: float = 1.0     # 1.0 = limpa, 0.0 = suja
var restaurant_cleanliness: float = 1.0 # 1.0 = limpo

enum AbandonType {
	NONE,
	TIMEOUT,
	WRONG_ORDER
}

var abandon_type: AbandonType = AbandonType.NONE
var abandoned: bool = false
var abandon_reason: String = ""
var order_summary: String = ""

const CUSTOMER_NAMES = [
	"Maria Silva", "João Pedro", "Lucas Santos", "Beatriz Oliveira",
	"Carlos Henrique", "Camila Ferreira", "Felipe Souza", "Juliana Lima",
	"Thiago Ribeiro", "Larissa Martins", "Bruno Pereira", "Fernanda Rocha",
	"Matheus Carvalho", "Amanda Barbosa", "Rafael Gomes", "Carolina Dias",
	"Leonardo Castro", "Natália Mendes", "Gustavo Ramos", "Letícia Vieira",
	"Eduardo Moreira", "Vanessa Cardoso", "Diego Nunes", "Patrícia Teixeira",
	"Renato Silveira", "Tatiane Ramos", "André Albuquerque", "Isabela Duarte"
]

const AVATAR_PALETTE = [
	Color(0.85, 0.25, 0.25, 1.0), # Vermelho
	Color(0.95, 0.65, 0.15, 1.0), # Amarelo/Ouro
	Color(0.20, 0.65, 0.85, 1.0), # Ciano
	Color(0.30, 0.75, 0.40, 1.0), # Verde
	Color(0.65, 0.35, 0.85, 1.0), # Roxo
	Color(0.95, 0.45, 0.30, 1.0), # Laranja
	Color(0.40, 0.50, 0.70, 1.0)  # Azul ardósia
]

func _init(p_id: int = 1, p_type: String = "Padrão", p_initial_mood: float = 100.0, p_channel: String = "DINE_IN") -> void:
	customer_id = p_id
	customer_type = p_type
	initial_mood = p_initial_mood
	final_mood = p_initial_mood
	channel_type = p_channel
	customer_name = CUSTOMER_NAMES[abs(customer_id) % CUSTOMER_NAMES.size()]

func is_drive_thru() -> bool:
	return channel_type == "DRIVE_THRU" or customer_type == "Drive-Thru" or "drive" in customer_type.to_lower()

func is_delivery() -> bool:
	return channel_type == "DELIVERY" or customer_type == "Delivery" or "delivery" in customer_type.to_lower()

func generate_review(clock_day: int = 1, clock_time: String = "12:00") -> CustomerReview:
	var review = CustomerReview.new()
	review.customer_id = customer_id
	review.customer_name = customer_name
	review.customer_type = customer_type
	review.day = clock_day
	review.time_string = clock_time
	review.order_summary = order_summary
	review.abandoned = abandoned
	review.abandon_reason = abandon_reason

	var cal = CalendarManager.get_instance()
	if cal and cal.has_method("get_formatted_date"):
		review.date_string = cal.get_formatted_date()
	else:
		review.date_string = "Dia %d" % clock_day

	review.avatar_color = AVATAR_PALETTE[abs(customer_id) % AVATAR_PALETTE.size()]

	# Configura Origem do Canal
	if is_delivery():
		review.channel_type = "DELIVERY"
		review.channel_name = "Delivery"
	elif is_drive_thru():
		review.channel_type = "DRIVE_THRU"
		review.channel_name = "Drive-thru"
	else:
		review.channel_type = "DINE_IN"
		review.channel_name = "Restaurante"

	var is_dt = (review.channel_type == "DRIVE_THRU")
	var is_deliv = (review.channel_type == "DELIVERY")

	# Identifica Clima e Conforto Real (Ar-Condicionado / Calor / Chuva)
	var is_heatwave = false
	var is_rainy = false
	var is_power_out = false

	var event_mgr = DailyEventManager.get_instance()
	if event_mgr:
		if event_mgr.current_event == DailyEventManager.EventType.EXTREME_HEAT:
			is_heatwave = true
		elif event_mgr.current_event == DailyEventManager.EventType.RAINY_DAY or event_mgr.current_event == DailyEventManager.EventType.STORM_DAY:
			is_rainy = true
		elif event_mgr.current_event == DailyEventManager.EventType.NETWORK_MAINTENANCE:
			is_power_out = true

	var wm = WeatherManager.get_instance()
	if wm:
		if wm.current_weather == WeatherManager.WeatherType.RAINY:
			is_rainy = true

	var pm = PowerManager.get_instance()
	if pm and not pm.is_main_power_on:
		is_power_out = true

	var is_ac_active = AirConditioner.is_ac_running()

	# Tolerância bônus em dias de chuva no salão (clientes compreendem atrasos leves)
	var rain_time_tolerance = 18.0 if is_rainy else 0.0

	# 1. Avaliação do Atendimento e Tempos de Espera
	var service_score: float = 5.0
	if abandoned:
		service_score = 1.0
	elif is_deliv:
		# Delivery: Tempo de preparo na cozinha + tempo de espera pela moto
		var total_deliv_wait = delivery_prep_time + delivery_window_wait_time
		if total_deliv_wait > 220.0:
			service_score -= 2.5
		elif total_deliv_wait > 130.0:
			service_score -= 1.0
		elif total_deliv_wait > 80.0:
			service_score -= 0.3
	elif is_dt:
		# Drive-thru: Espera para pedir + espera de entrega no carro
		if wait_time_to_order > 65.0:
			service_score -= 2.0
		elif wait_time_to_order > 38.0:
			service_score -= 0.8

		if wait_time_for_food > 95.0:
			service_score -= 2.0
		elif wait_time_for_food > 58.0:
			service_score -= 0.8
	else:
		# Salão Presencial: Espera para ser atendido na mesa
		if wait_time_to_order > (75.0 + rain_time_tolerance):
			service_score -= 2.5
		elif wait_time_to_order > (45.0 + rain_time_tolerance * 0.5):
			service_score -= 1.0
		elif wait_time_to_order > 25.0:
			service_score -= 0.3

		# Espera pela comida na mesa
		if wait_time_for_food > (110.0 + rain_time_tolerance):
			service_score -= 2.5
		elif wait_time_for_food > (70.0 + rain_time_tolerance * 0.5):
			service_score -= 1.0
		elif wait_time_for_food > 40.0:
			service_score -= 0.4

		# Espera na fila do caixa
		if wait_time_checkout > 60.0:
			service_score -= 1.5
		elif wait_time_checkout > 32.0:
			service_score -= 0.5

	review.service_stars = clampf(service_score, 1.0, 5.0)

	# 2. Avaliação da Comida / Acerto do Pedido
	var food_score: float = 5.0 * food_quality
	if not order_correct:
		food_score = minf(food_score, 1.2)
	if abandoned:
		food_score = 1.0
	review.food_stars = clampf(food_score, 1.0, 5.0)

	# 3. Avaliação de Limpeza
	if is_dt or is_deliv:
		review.cleanliness_stars = 5.0
	else:
		var cleanliness_score: float = (table_cleanliness * 4.0) + (restaurant_cleanliness * 1.0)
		if table_cleanliness <= 0.3:
			cleanliness_score = minf(cleanliness_score, 1.8)
		review.cleanliness_stars = clampf(cleanliness_score, 1.0, 5.0)

	# 4. Avaliação de Preço / Custo-Benefício
	var price_score: float = 5.0
	if primary_product_id != "" and charged_price > 0.0:
		var price_eval = MenuPricingManager.evaluate_price_perception(primary_product_id, charged_price)
		price_score = price_eval.get("score", 4.5)
	review.price_stars = clampf(price_score, 1.0, 5.0)

	# 5. Avaliação de Clima e Conforto Térmico (Salão)
	var climate_score: float = 5.0
	if not is_dt and not is_deliv:
		if is_heatwave:
			if is_ac_active:
				climate_score = 5.0 # Salão bem refrigerado
			else:
				climate_score = 2.0 # Muito quente lá dentro
		elif is_power_out:
			climate_score = 2.5 # Queda de energia prejudicou o ambiente
	review.climate_stars = clampf(climate_score, 1.0, 5.0)

	# 6. Cálculo da Nota Final Ponderada (1 a 5 estrelas)
	if abandoned:
		review.stars = 1.0
	elif not order_correct:
		review.stars = clampf(minf(1.8, (review.service_stars * 0.3) + 1.0), 1.0, 2.0)
	else:
		var mood_factor = (final_mood / 100.0) * 5.0
		var weighted: float = 5.0

		if is_deliv:
			# Delivery: Comida/Acerto (45%) + Tempo/Entrega (40%) + Preço (15%)
			weighted = (review.food_stars * 0.45) + (review.service_stars * 0.40) + (review.price_stars * 0.15)
		elif is_dt:
			# Drive-Thru: Agilidade (40%) + Comida/Acerto (40%) + Preço (10%) + Humor (10%)
			weighted = (review.service_stars * 0.40) + (review.food_stars * 0.40) + (review.price_stars * 0.10) + (mood_factor * 0.10)
		else:
			# Salão: Serviço (30%) + Comida (30%) + Limpeza (15%) + Conforto Térmico (10%) + Preço (10%) + Humor (5%)
			weighted = (review.service_stars * 0.30) + (review.food_stars * 0.30) + (review.cleanliness_stars * 0.15) + (review.climate_stars * 0.10) + (review.price_stars * 0.10) + (mood_factor * 0.05)

		review.stars = clampf(snappedf(weighted, 0.1), 1.0, 5.0)

	# 7. Geração de Tags Contextuais
	_generate_tags(review, is_heatwave, is_ac_active, is_rainy)

	# 8. Geração de Comentário Realista e Contextualizado
	review.comment = _generate_comment(review, is_heatwave, is_ac_active, is_rainy, is_power_out)

	return review

func _generate_tags(review: CustomerReview, is_heatwave: bool, is_ac_active: bool, is_rainy: bool) -> void:
	review.tags.clear()
	var is_dt = (review.channel_type == "DRIVE_THRU")
	var is_deliv = (review.channel_type == "DELIVERY")

	if abandoned:
		review.tags.append("Abandono")
		if abandon_type == AbandonType.WRONG_ORDER or "errad" in abandon_reason.to_lower() or "incorret" in abandon_reason.to_lower():
			review.tags.append("Pedido Incorreto")
		else:
			review.tags.append("Espera Excessiva")
		if is_dt: review.tags.append("Drive-Thru")
		elif is_deliv: review.tags.append("Delivery")
		return

	if not order_correct:
		review.tags.append("Pedido Incorreto")

	var total_wait = wait_time_to_order + wait_time_for_food
	if is_deliv:
		total_wait = delivery_prep_time + delivery_window_wait_time

	var fast_threshold = 45.0 if is_dt else (80.0 if is_deliv else 55.0)
	var slow_threshold = 100.0 if is_dt else (170.0 if is_deliv else 120.0)

	if total_wait <= fast_threshold:
		review.tags.append("Atendimento Rápido" if not is_deliv else "Entrega Rápida")
	elif total_wait >= slow_threshold:
		review.tags.append("Demora")

	if order_correct and food_quality >= 0.9:
		review.tags.append("Comida Excelente")

	if review.price_stars <= 2.5:
		review.tags.append("Preço Alto")
	elif review.price_stars >= 4.8:
		review.tags.append("Bom Preço")

	if not is_dt and not is_deliv:
		if is_heatwave:
			if is_ac_active:
				review.tags.append("Ambiente Agradável")
			else:
				review.tags.append("Restaurante Quente")
		if table_cleanliness >= 0.9:
			review.tags.append("Mesa Limpa")
		elif table_cleanliness <= 0.4:
			review.tags.append("Mesa Suja")

	if is_rainy:
		review.tags.append("Dia Chuvoso")

func _generate_comment(review: CustomerReview, is_heatwave: bool, is_ac_active: bool, is_rainy: bool, is_power_out: bool) -> String:
	var is_dt = (review.channel_type == "DRIVE_THRU")
	var is_deliv = (review.channel_type == "DELIVERY")
	var rating = review.stars
	var is_wrong = (not order_correct or abandon_type == AbandonType.WRONG_ORDER or "errad" in abandon_reason.to_lower() or "incorret" in abandon_reason.to_lower())

	# CASO 1: Abandono ou Pedido Incorreto
	if abandoned or is_wrong:
		if is_deliv:
			if is_wrong:
				var deliv_wrong_msgs = [
					"O motoboy entregou o lanche completamente errado! Veio outro item, péssima experiência.",
					"Pedido veio incorreto na entrega do delivery! Não foi o que solicitei pelo app.",
					"Entregaram o pedido errado no delivery e não recebi o que paguei."
				]
				return deliv_wrong_msgs[customer_id % deliv_wrong_msgs.size()]
			else:
				return "O pedido de delivery demorou tanto que tive que cancelar. Muito lento!"
		elif is_dt:
			if is_wrong:
				var dt_wrong_msgs = [
					"Entregaram o pedido errado no drive-thru! Não foi o que pedi, fui embora.",
					"Pedido veio incorreto na janela do drive-thru! Péssima atenção, não paguei e saí.",
					"Deram o pedido trocado no drive-thru. Inadmissível!"
				]
				return dt_wrong_msgs[customer_id % dt_wrong_msgs.size()]
			else:
				return "Desisti de esperar na fila do drive-thru e fui embora! Demora excessiva."
		else:
			if is_wrong:
				var dine_wrong_msgs = [
					"Esse não foi o meu pedido! Serviram itens errados na mesa, me recusei a pagar e fui embora.",
					"Pedido completamente errado. Pedi uma coisa e trouxeram outra. Fui embora!",
					"Erraram meu pedido na mesa. Atendimento desatento, cancelei e saí."
				]
				return dine_wrong_msgs[customer_id % dine_wrong_msgs.size()]
			elif "atendimento" in abandon_reason.to_lower():
				return "Desisti de esperar pelo atendimento e fui embora! Ninguém veio anotar meu pedido."
			else:
				return "Esperei demais pela comida e nada de chegar. Cancelei e fui comer em outro lugar!"

	# CASO 2: Delivery
	if is_deliv:
		if rating >= 4.8:
			var msgs = [
				"O lanche estava muito bom e chegou rapidinho! O motoboy foi super atencioso. Voltarei com certeza!",
				"Entrega super veloz, hambúrguer quentinho e embalagem impecável. Recomendo demais!",
				"Melhor delivery da região! Pedido perfeito, crocante e chegou antes do prazo."
			]
			return msgs[customer_id % msgs.size()]
		elif rating >= 3.8:
			if "Preço Alto" in review.tags:
				return "O lanche é muito gostoso e a entrega foi boa, mas achei o preço um pouco salgado."
			elif "Demora" in review.tags:
				return "O burger é saboroso, porém o delivery demorou um pouco mais que o esperado."
			return "Muito bom! Pedido de delivery correto e lanche quentinho."
		elif rating >= 2.8:
			return "Comida razoável, mas a entrega demorou bastante para chegar."
		else:
			return "Demora excessiva na entrega e o lanche chegou morno. Decepcionante."

	# CASO 3: Drive-Thru
	if is_dt:
		if rating >= 4.8:
			var msgs = [
				"Drive-thru super rápido e o lanche veio quentinho e perfeito!",
				"Atendimento muito ágil na janela do drive-thru! Pedido entregue no carro sem demora.",
				"Excelente drive-thru, praticidade e burger delicioso!"
			]
			return msgs[customer_id % msgs.size()]
		elif rating >= 3.8:
			if "Preço Alto" in review.tags:
				return "Atendimento no drive-thru foi ótimo, mas os preços subiram um pouco."
			elif "Demora" in review.tags:
				return "O lanche estava bom, mas fiquei muito tempo esperando no drive-thru."
			return "Muito bom! Pedido correto e entrega no carro sem complicação."
		elif rating >= 2.8:
			return "Comida boa, porém a fila do drive-thru estava bem lenta hoje."
		else:
			return "Péssima experiência no drive-thru, tempo de espera inaceitável."

	# CASO 4: Salão Presencial
	# Específico para Onda de Calor / Ar-Condicionado
	if is_heatwave:
		if not is_ac_active:
			if rating >= 3.5:
				return "O lanche estava ótimo e o atendimento foi bom, mas estava muito quente lá dentro."
			else:
				return "Demorou muito para me atender e o restaurante estava muito quente sem ar-condicionado."
		else:
			if rating >= 4.5:
				return "Lanche perfeito e ambiente super fresco com ar-condicionado! Refúgio nesse calor."

	# Específico para Preço Alto
	if "Preço Alto" in review.tags:
		if rating >= 3.8:
			return "Preço um pouco alto, mas o atendimento foi excelente e o lanche delicioso."
		else:
			return "Achei o lanche muito caro pelo tamanho e a demora no atendimento."

	# Específico para Dia de Chuva
	if is_rainy and rating >= 4.5:
		return "Ótimo refúgio em um dia chuvoso! Atendimento caloroso e burger excelente."

	# Comentários Gerais de Salão por Faixa de Estrelas
	if rating >= 4.8:
		var msgs = [
			"Atendimento rápido, lanche excelente e restaurante muito bem cuidado!",
			"Esperei pouco e o pedido veio perfeito! O melhor burger da cidade.",
			"Experiência sensacional! Comida fresca, mesa impecável e equipe muito atenciosa.",
			"Tudo perfeito! O atendimento foi super ágil e o lanche estava delicioso."
		]
		return msgs[customer_id % msgs.size()]
	elif rating >= 3.8:
		if "Demora" in review.tags:
			return "O lanche estava muito bom, mas demorou bastante para ficar pronto."
		elif "Mesa Suja" in review.tags:
			return "Comida saborosa e atendimento ágil, mas a mesa poderia estar mais limpa."
		else:
			var msgs = [
				"Muito bom! Hambúrguer saboroso e ambiente agradável.",
				"Ótima experiência no geral, recomendo para ir com a família.",
				"Lanche de boa qualidade e atendimento prestativo."
			]
			return msgs[customer_id % msgs.size()]
	elif rating >= 2.8:
		if "Demora" in review.tags and "Mesa Suja" in review.tags:
			return "Comida boa, porém demorou bastante e a mesa estava meio suja."
		elif "Demora" in review.tags:
			return "O hambúrguer estava ok, mas esperei bastante tempo pelo atendimento."
		else:
			return "Experiência mediana. O lanche é bom, mas o serviço pode melhorar."
	elif rating >= 1.8:
		if "Mesa Suja" in review.tags:
			return "Demorou demais, a mesa estava suja e o atendimento foi confuso."
		else:
			return "Muito lento e desorganizado. Fiquei decepcionado com o tempo de espera."
	else:
		return "Péssima experiência! Atendimento extremamente demorado e comida decepcionante."
