class_name CustomerReview
extends RefCounted

# =============================================================================
# BURGER RUSH - MODELO DE DADOS ESTRUTURADO DE AVALIAÇÃO DE CLIENTES
# =============================================================================

var customer_id: int = 1
var customer_name: String = "Cliente Anônimo"
var customer_type: String = "Padrão"

# Origem do Atendimento: DINE_IN (Restaurante), DRIVE_THRU (Drive-thru), DELIVERY (Delivery)
var channel_type: String = "DINE_IN"
var channel_name: String = "Restaurante"

var stars: float = 5.0              # Nota geral de 1.0 a 5.0
var service_stars: float = 5.0      # Atendimento, tempo de espera e preparo
var food_stars: float = 5.0         # Sabor, qualidade e acerto do pedido
var cleanliness_stars: float = 5.0  # Limpeza do salão e mesa
var price_stars: float = 5.0        # Custo-benefício e percepção de valor
var climate_stars: float = 5.0      # Conforto térmico e ambiente (AC / Clima)

var comment: String = ""
var order_summary: String = ""
var time_string: String = "12:00"
var date_string: String = "Dia 1"
var day: int = 1

var abandoned: bool = false
var abandon_reason: String = ""
var tags: Array[String] = []
var avatar_color: Color = Color(0.9, 0.45, 0.2, 1.0)

func get_formatted_stars() -> String:
	var filled = int(clamp(round(stars), 1, 5))
	var text = ""
	for i in range(5):
		text += "★" if i < filled else "☆"
	return text

func get_channel_icon() -> String:
	match channel_type:
		"DRIVE_THRU": return "🚗"
		"DELIVERY": return "🛵"
		_: return "🍽️"

func get_channel_badge_text() -> String:
	match channel_type:
		"DRIVE_THRU": return "🚗 Drive-thru"
		"DELIVERY": return "🛵 Delivery"
		_: return "🍽️ Restaurante"

func to_dict() -> Dictionary:
	return {
		"customer_id": customer_id,
		"customer_name": customer_name,
		"customer_type": customer_type,
		"channel_type": channel_type,
		"channel_name": channel_name,
		"stars": stars,
		"service_stars": service_stars,
		"food_stars": food_stars,
		"cleanliness_stars": cleanliness_stars,
		"price_stars": price_stars,
		"climate_stars": climate_stars,
		"comment": comment,
		"order_summary": order_summary,
		"time_string": time_string,
		"date_string": date_string,
		"day": day,
		"abandoned": abandoned,
		"abandon_reason": abandon_reason,
		"tags": tags,
		"avatar_color": avatar_color.to_html()
	}
