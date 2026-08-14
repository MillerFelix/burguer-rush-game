class_name CustomerReview
extends RefCounted

var customer_id: int = 1
var stars: float = 5.0
var service_stars: float = 5.0
var food_stars: float = 5.0
var cleanliness_stars: float = 5.0
var comment: String = ""
var order_summary: String = ""
var time_string: String = ""
var day: int = 1

func get_formatted_stars() -> String:
	var filled = int(round(stars))
	var text = ""
	for i in range(5):
		if i < filled:
			text += "★"
		else:
			text += "☆"
	return text
