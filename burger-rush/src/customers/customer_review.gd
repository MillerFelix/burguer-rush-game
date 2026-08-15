class_name CustomerReview
extends RefCounted

# Modelo de Dados Estruturado de Avaliação de Restaurante
var customer_id: int = 1
var customer_name: String = "Cliente Anônimo"
var customer_type: String = "Padrão"

var stars: float = 5.0              # Nota geral de 1.0 a 5.0
var service_stars: float = 5.0      # Atendimento e tempo de espera
var food_stars: float = 5.0         # Qualidade e acerto do pedido
var cleanliness_stars: float = 5.0  # Limpeza da mesa e salão

var comment: String = ""
var order_summary: String = ""
var time_string: String = "12:00"
var day: int = 1

var abandoned: bool = false
var abandon_reason: String = ""
var tags: Array[String] = []

func get_formatted_stars() -> String:
	var filled = int(round(stars))
	var text = ""
	for i in range(5):
		text += "★" if i < filled else "☆"
	return text

func to_dict() -> Dictionary:
	return {
		"customer_id": customer_id,
		"customer_name": customer_name,
		"customer_type": customer_type,
		"stars": stars,
		"service_stars": service_stars,
		"food_stars": food_stars,
		"cleanliness_stars": cleanliness_stars,
		"comment": comment,
		"order_summary": order_summary,
		"time_string": time_string,
		"day": day,
		"abandoned": abandoned,
		"abandon_reason": abandon_reason,
		"tags": tags
	}
