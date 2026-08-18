class_name CustomerExperience
extends RefCounted

# Telemetria Completa da Jornada do Cliente no Restaurante / Drive-Thru
var customer_id: int = 1
var customer_name: String = "Cliente Anônimo"
var customer_type: String = "Padrão" # Padrão, Apressado, Tranquilo, Crítico, Criança, Idoso, VIP, Drive-Thru

var initial_mood: float = 100.0
var final_mood: float = 100.0

var wait_time_to_order: float = 0.0
var wait_time_for_food: float = 0.0
var wait_time_checkout: float = 0.0
var wait_time_in_line: float = 0.0
var total_time_in_restaurant: float = 0.0

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
	"Lucas Silva", "Mariana Costa", "Gabriel Santos", "Beatriz Oliveira",
	"Rodrigo Almeida", "Camila Ferreira", "Felipe Souza", "Juliana Lima",
	"Thiago Ribeiro", "Larissa Martins", "Bruno Pereira", "Fernanda Rocha",
	"Matheus Carvalho", "Amanda Barbosa", "Rafael Gomes", "Carolina Dias",
	"Leonardo Castro", "Natália Mendes", "Gustavo Ramos", "Letícia Vieira",
	"Eduardo Moreira", "Vanessa Cardoso", "Diego Nunes", "Patrícia Teixeira"
]

func _init(p_id: int = 1, p_type: String = "Padrão", p_initial_mood: float = 100.0) -> void:
	customer_id = p_id
	customer_type = p_type
	initial_mood = p_initial_mood
	final_mood = p_initial_mood
	customer_name = CUSTOMER_NAMES[abs(customer_id) % CUSTOMER_NAMES.size()]

func is_drive_thru() -> bool:
	return customer_type == "Drive-Thru" or "drive" in customer_type.to_lower()

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

	var is_dt = is_drive_thru()

	# 1. Avaliação do Atendimento / Tempos de Espera (Com limites generosos e saudáveis)
	var service_score: float = 5.0
	if abandoned:
		service_score = 1.0
	else:
		if is_dt:
			# Limites equilibrados para Drive-Thru:
			# Espera no interfone/janela para pedir
			if wait_time_to_order > 60.0:
				service_score -= 2.0
			elif wait_time_to_order > 35.0:
				service_score -= 0.8

			# Espera pela entrega dos pacotes no carro
			if wait_time_for_food > 90.0:
				service_score -= 2.0
			elif wait_time_for_food > 55.0:
				service_score -= 0.8
		else:
			# Limites saudáveis para Salão de Mesas:
			# Espera para fazer pedido
			if wait_time_to_order > 70.0:
				service_score -= 2.5
			elif wait_time_to_order > 45.0:
				service_score -= 1.0
			elif wait_time_to_order > 25.0:
				service_score -= 0.3

			# Espera para receber comida na mesa
			if wait_time_for_food > 105.0:
				service_score -= 2.5
			elif wait_time_for_food > 70.0:
				service_score -= 1.0
			elif wait_time_for_food > 40.0:
				service_score -= 0.4

			# Espera na fila do caixa
			if wait_time_checkout > 55.0:
				service_score -= 1.5
			elif wait_time_checkout > 30.0:
				service_score -= 0.5

	review.service_stars = clampf(service_score, 1.0, 5.0)

	# 2. Avaliação da Comida
	var food_score: float = 5.0 * food_quality
	if not order_correct:
		food_score = minf(food_score, 1.5)
	if abandoned:
		food_score = 1.0
	review.food_stars = clampf(food_score, 1.0, 5.0)

	# 3. Avaliação de Limpeza (Drive-Thru não avalia mesa)
	if is_dt:
		review.cleanliness_stars = 5.0
	else:
		var cleanliness_score: float = (table_cleanliness * 4.0) + (restaurant_cleanliness * 1.0)
		if table_cleanliness <= 0.3:
			cleanliness_score = minf(cleanliness_score, 1.8)
		review.cleanliness_stars = clampf(cleanliness_score, 1.0, 5.0)

	# 4. Avaliação Global Ponderada
	if abandoned:
		review.stars = 1.0
	else:
		var mood_factor = (final_mood / 100.0) * 5.0
		var weighted: float = 5.0
		if is_dt:
			# Drive-Thru foca em Agilidade (50%) + Comida (40%) + Humor (10%)
			weighted = (review.service_stars * 0.50) + (review.food_stars * 0.40) + (mood_factor * 0.10)
		else:
			# Salão: Serviço (35%) + Comida (35%) + Limpeza (15%) + Humor (15%)
			weighted = (review.service_stars * 0.35) + (review.food_stars * 0.35) + (review.cleanliness_stars * 0.15) + (mood_factor * 0.15)
		review.stars = clampf(snappedf(weighted, 0.1), 1.0, 5.0)

	# 5. Geração de Tags de Feedback
	_generate_tags(review)

	# 6. Geração de Comentário Realista e Contextualizado
	review.comment = _generate_comment(review)

	return review

func _generate_tags(review: CustomerReview) -> void:
	review.tags.clear()
	var is_dt = is_drive_thru()

	if abandoned:
		review.tags.append("Abandono")
		if abandon_type == AbandonType.WRONG_ORDER or "errad" in abandon_reason.to_lower() or "incorret" in abandon_reason.to_lower():
			review.tags.append("Pedido Incorreto")
		else:
			review.tags.append("Espera Excessiva")
		if is_dt:
			review.tags.append("Drive-Thru")
		return

	var total_wait = wait_time_to_order + wait_time_for_food
	var fast_threshold = 45.0 if is_dt else 55.0
	var slow_threshold = 100.0 if is_dt else 120.0

	if total_wait <= fast_threshold:
		review.tags.append("Atendimento Rápido")
	elif total_wait >= slow_threshold:
		review.tags.append("Demora")

	if order_correct and food_quality >= 0.9:
		review.tags.append("Comida Excelente")
	elif not order_correct:
		review.tags.append("Pedido Incorreto")

	if is_dt:
		review.tags.append("Drive-Thru")
	else:
		if table_cleanliness >= 0.9:
			review.tags.append("Mesa Limpa")
		elif table_cleanliness <= 0.4:
			review.tags.append("Mesa Suja")

func _generate_comment(review: CustomerReview) -> String:
	var is_dt = is_drive_thru()

	# Casos de Abandono por Frustração
	if abandoned:
		var is_wrong = (abandon_type == AbandonType.WRONG_ORDER or "errad" in abandon_reason.to_lower() or "incorret" in abandon_reason.to_lower())
		if is_dt:
			if is_wrong:
				var dt_wrong_msgs = [
					"Entregaram o pedido errado no drive-thru! Não foi o que pedi, fui embora.",
					"Pedido veio incorreto na janela do drive-thru! Péssima atenção, não paguei e saí.",
					"Deram o pedido trocado no drive-thru. Inadmissível!"
				]
				return dt_wrong_msgs[customer_id % dt_wrong_msgs.size()]
			else:
				var dt_abandon_msgs = [
					"Desisti de esperar na fila do drive-thru e fui embora!",
					"Fiquei preso na fila do drive-thru sem atendimento. Demora excessiva!",
					"Cancelei meu pedido no drive-thru, muito lento hoje."
				]
				return dt_abandon_msgs[customer_id % dt_abandon_msgs.size()]
		else:
			if is_wrong:
				var dine_wrong_msgs = [
					"Esse não foi o meu pedido! Serviram itens errados na mesa, me recusei a pagar e fui embora.",
					"Pedido completamente errado. Pedi uma coisa e trouxeram outra. Fui embora!",
					"Erraram meu pedido na mesa. Atendimento desatento, cancelei e saí."
				]
				return dine_wrong_msgs[customer_id % dine_wrong_msgs.size()]
			elif "atendimento" in abandon_reason.to_lower():
				var msgs = [
					"Desisti de esperar pelo atendimento e fui embora! Ninguém veio anotar meu pedido.",
					"Fiquei esperando uma eternidade na mesa e ninguém me atendeu. Falta de consideração!",
					"Cancelei minha visita. O restaurante estava super lento e ninguém me atendeu."
				]
				return msgs[customer_id % msgs.size()]
			else:
				var msgs = [
					"Esperei demais pela comida e nada de chegar. Cancelei e fui comer em outro lugar!",
					"Demora absurda na cozinha! Esperei muito tempo pelo hambúrguer e fui embora.",
					"Fiquei com fome esperando o pedido. Não recomendo para quem tem pressa!"
				]
				return msgs[customer_id % msgs.size()]

	var rating = review.stars

	# Comentários de Drive-Thru
	if is_dt:
		if rating >= 4.8:
			var msgs = [
				"Drive-thru super rápido e o lanche veio quentinho e perfeito!",
				"Atendimento muito ágil na janela! Pedido entregue sem demora.",
				"Excelente drive-thru, praticidade e burger delicioso."
			]
			return msgs[customer_id % msgs.size()]
		elif rating >= 3.8:
			if "Demora" in review.tags:
				return "O lanche estava ótimo, mas a fila do drive-thru demorou um pouco."
			return "Muito bom! Pedido correto e entrega no carro sem complicação."
		elif rating >= 2.8:
			return "Comida boa, porém o drive-thru estava um pouco lento."
		elif rating >= 1.8:
			return "Demorou bastante na janela de entrega e o atendimento foi confuso."
		else:
			return "Péssima experiência no drive-thru, tempo de espera inaceitável."

	# Comentários de Salão
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
			return "O lanche estava muito bom, mas o pedido demorou um pouco para chegar."
		elif "Mesa Suja" in review.tags:
			return "Comida saborosa e atendimento rápido, mas a mesa poderia estar mais limpa."
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
		if not order_correct:
			return "Esperei bastante pelo pedido e quando chegou estava com o item errado!"
		elif "Mesa Suja" in review.tags:
			return "Demorou demais, a mesa estava suja e o atendimento foi confuso."
		else:
			return "Muito lento e desorganizado. Fiquei decepcionado com o tempo de espera."
	else:
		return "Péssima experiência! Atendimento extremamente demorado, mesa suja e comida fria."
