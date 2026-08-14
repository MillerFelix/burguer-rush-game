class_name Transaction
extends RefCounted

enum Type {
	SALE,
	PURCHASE
}

var type: Type = Type.SALE
var amount: float = 0.0
var description: String = ""
var day: int = 1
var time_string: String = "08:00"

func _init(p_type: Type = Type.SALE, p_amount: float = 0.0, p_desc: String = "", p_day: int = 1, p_time: String = "08:00") -> void:
	type = p_type
	amount = p_amount
	description = p_desc
	day = p_day
	time_string = p_time

func get_type_string() -> String:
	match type:
		Type.SALE:
			return "VENDA"
		Type.PURCHASE:
			return "COMPRA"
		_:
			return "OUTRO"
