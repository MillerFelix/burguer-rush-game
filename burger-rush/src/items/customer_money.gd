class_name CustomerMoney
extends Item

@export var amount: float = 25.0
var customer_ref: Node = null
var is_customer_deposit_money: bool = true

func _ready() -> void:
	item_id = "customer_money"
	display_name = "Dinheiro do Cliente"
	item_type = "currency"
	prompt_text = "Pegar Pagamento (R$ %.2f)" % amount

func setup(p_amount: float, p_customer: Node = null) -> void:
	amount = p_amount
	customer_ref = p_customer
	display_name = "Dinheiro do Cliente (R$ %.2f)" % amount
	prompt_text = "Pegar Pagamento (R$ %.2f)" % amount

func get_display_name() -> String:
	return "Dinheiro do Cliente (R$ %.2f)" % amount
