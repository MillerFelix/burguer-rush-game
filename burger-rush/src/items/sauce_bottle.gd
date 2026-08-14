class_name SauceBottle
extends Item

@export var sauce_type: String = "sauce" # "sauce" (ketchup), "mustard", "mayo", "green_sauce", "special_sauce"
@export var max_charges: int = 50
@export var current_charges: int = 50

@onready var label_3d: Label3D = $Label3D
@onready var bottle_body: MeshInstance3D = $Model/BottleBody
@onready var sauce_band: MeshInstance3D = $Model/SauceBand
@onready var bottle_neck: MeshInstance3D = $Model/BottleNeck
@onready var nozzle_tip: MeshInstance3D = $Model/NozzleTip

func _ready() -> void:
	item_id = sauce_type
	item_type = "sauce_bottle"
	_apply_visual_theme()
	_update_sauce_metadata()

func _apply_visual_theme() -> void:
	if not sauce_band or not nozzle_tip:
		return

	var sauce_color: Color
	var cap_color: Color

	match sauce_type:
		"sauce", "ketchup":
			sauce_color = Color(0.82, 0.14, 0.12, 1.0) # Vermelho natural tomate
			cap_color = Color(0.72, 0.10, 0.08, 1.0)
		"mustard":
			sauce_color = Color(0.88, 0.72, 0.14, 1.0) # Amarelo mostarda Dijon
			cap_color = Color(0.82, 0.65, 0.10, 1.0)
		"mayo":
			sauce_color = Color(0.96, 0.94, 0.88, 1.0) # Creme maionese suave
			cap_color = Color(0.18, 0.38, 0.68, 1.0) # Tampa azul clássica de maionese
		"green_sauce", "herbs":
			sauce_color = Color(0.22, 0.62, 0.28, 1.0) # Verde ervas frescas
			cap_color = Color(0.18, 0.50, 0.22, 1.0)
		"special_sauce", "barbecue":
			sauce_color = Color(0.85, 0.42, 0.12, 1.0) # Âmbar barbecue / molho especial
			cap_color = Color(0.78, 0.35, 0.08, 1.0)
		_:
			sauce_color = Color(0.82, 0.14, 0.12, 1.0)
			cap_color = Color(0.72, 0.10, 0.08, 1.0)

	var mat_sauce = StandardMaterial3D.new()
	mat_sauce.albedo_color = sauce_color
	mat_sauce.roughness = 0.45
	sauce_band.material_override = mat_sauce

	var mat_cap = StandardMaterial3D.new()
	mat_cap.albedo_color = cap_color
	mat_cap.roughness = 0.4
	if bottle_neck:
		bottle_neck.material_override = mat_cap
	nozzle_tip.material_override = mat_cap

func _update_sauce_metadata() -> void:
	match sauce_type:
		"sauce", "ketchup":
			display_name = "Bisnaga de Ketchup"
			prompt_text = "E — Pegar Bisnaga de Ketchup (%d/%d)" % [current_charges, max_charges]
		"mustard":
			display_name = "Bisnaga de Mostarda"
			prompt_text = "E — Pegar Bisnaga de Mostarda (%d/%d)" % [current_charges, max_charges]
		"mayo":
			display_name = "Bisnaga de Maionese"
			prompt_text = "E — Pegar Bisnaga de Maionese (%d/%d)" % [current_charges, max_charges]
		"green_sauce", "herbs":
			display_name = "Bisnaga de Molho Verde"
			prompt_text = "E — Pegar Bisnaga de Molho Verde (%d/%d)" % [current_charges, max_charges]
		"special_sauce", "barbecue":
			display_name = "Bisnaga de Molho Especial"
			prompt_text = "E — Pegar Bisnaga de Molho Especial (%d/%d)" % [current_charges, max_charges]
		_:
			display_name = "Bisnaga de Molho"
			prompt_text = "E — Pegar Bisnaga de Molho (%d/%d)" % [current_charges, max_charges]

	if label_3d:
		if current_charges > 0:
			label_3d.text = "%s\n(%d/%d doses)" % [display_name, current_charges, max_charges]
			label_3d.modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			label_3d.text = "%s\n🔴 VAZIA (Recarregar)" % display_name
			label_3d.modulate = Color(1.0, 0.3, 0.3, 1.0)

func is_empty() -> bool:
	return current_charges <= 0

func can_apply() -> bool:
	if current_charges > 0:
		return true
	# Verifica se há estoque no inventário para recarga automática
	var inv = InventoryManager.get_instance()
	if inv and inv.has_stock("sauce", 1):
		return true
	return false

func consume_dose() -> bool:
	if current_charges > 0:
		current_charges -= 1
		# Consome do estoque se necessário
		var inv = InventoryManager.get_instance()
		if inv and inv.has_stock("sauce", 1):
			inv.consume_stock("sauce", 1)
		_update_sauce_metadata()
		return true
	elif can_apply():
		refill()
		current_charges -= 1
		var inv = InventoryManager.get_instance()
		if inv and inv.has_stock("sauce", 1):
			inv.consume_stock("sauce", 1)
		_update_sauce_metadata()
		return true
	return false

func refill() -> void:
	current_charges = max_charges
	_update_sauce_metadata()

func get_ingredient_key() -> String:
	return "sauce"
