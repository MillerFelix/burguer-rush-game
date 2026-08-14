class_name InventoryItem
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var quantity: int = 10
@export var max_capacity: int = 50
@export var unit_cost: float = 2.0
@export var min_stock_alert: int = 5
@export var quality: String = "BASIC" # BASIC, GOOD, PREMIUM, ARTISAN
@export var quality_multiplier: float = 1.0
@export var scene: PackedScene

func is_low_stock() -> bool:
	return quantity <= min_stock_alert

func is_empty() -> bool:
	return quantity <= 0

func is_full() -> bool:
	return quantity >= max_capacity

func get_available_space() -> int:
	return maxi(0, max_capacity - quantity)
