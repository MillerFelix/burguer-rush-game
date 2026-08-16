class_name SyrupCanister
extends Item

# ================================================================
# RECIPIENTE / BARRIL DE INSUMO PARA MÁQUINA DE BEBIDAS
# Com indicador visual de nível de xarope integrado
# ================================================================

@export var flavor_type: String = "soda_cola":
	set(val):
		flavor_type = val
		_setup_flavor_properties()

@export var current_amount: float = 25.0:
	set(val):
		current_amount = clampf(val, 0.0, max_amount)
		_update_gauge()

@export var max_amount: float = 25.0

@onready var body_mesh: MeshInstance3D = get_node_or_null("Model/Body")
@onready var color_band: MeshInstance3D = get_node_or_null("Model/ColorBand")
@onready var valve_mesh: MeshInstance3D = get_node_or_null("Model/Valve")
@onready var level_indicator: MeshInstance3D = get_node_or_null("Model/Gauge/LevelIndicator")

var _band_color: Color = Color(0.85, 0.12, 0.12, 1.0)

func _ready() -> void:
	item_type = "ingredient"
	_setup_flavor_properties()
	_update_gauge()

func _setup_flavor_properties() -> void:
	match flavor_type:
		"soda_cola", "cola":
			item_id = "syrup_cola"
			display_name = "Barril de Cola"
			_band_color = Color(0.85, 0.12, 0.12, 1.0) # Vermelho Cola
		"soda_cola_zero", "cola_zero", "zero":
			item_id = "syrup_cola_zero"
			display_name = "Barril de Zero"
			_band_color = Color(0.18, 0.18, 0.22, 1.0) # Preto/Prata Zero
		"soda_lime", "soda", "soda_sprite", "sprite", "lemon", "limao":
			item_id = "syrup_lemon"
			display_name = "Barril de Soda"
			_band_color = Color(0.18, 0.75, 0.18, 1.0) # Verde Soda
		"soda_citrus", "citrus", "soda_citrix", "citrix", "juice_orange", "orange", "laranja", "orangy":
			item_id = "syrup_orange"
			display_name = "Barril de Citrus"
			_band_color = Color(0.95, 0.50, 0.08, 1.0) # Laranja Citrus
		_:
			item_id = "syrup_soda"
			display_name = "Barril de Xarope de Bebida"
			_band_color = Color(0.6, 0.6, 0.6, 1.0)

	_set_band_color(_band_color)
	prompt_text = "🖱️ [Clique Esquerdo] Pegar %s" % display_name

func _set_band_color(col: Color) -> void:
	if not color_band:
		color_band = get_node_or_null("Model/ColorBand")
	if color_band:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = col
		mat.roughness = 0.35
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 0.3
		color_band.material_override = mat

func _update_gauge() -> void:
	if not level_indicator:
		level_indicator = get_node_or_null("Model/Gauge/LevelIndicator")
	if level_indicator:
		var fraction = clampf(current_amount / max_amount, 0.0, 1.0)
		var mat = StandardMaterial3D.new()
		if fraction <= 0.001:
			mat.albedo_color = Color(0.15, 0.15, 0.15, 1.0) # Apagado / Vazio
			mat.emission_enabled = false
			level_indicator.scale.y = 0.02
		else:
			var gauge_color = _band_color
			if fraction <= 0.25:
				gauge_color = Color(0.95, 0.2, 0.1, 1.0) # Alerta quase vazio
			mat.albedo_color = gauge_color
			mat.emission_enabled = true
			mat.emission = gauge_color
			mat.emission_energy_multiplier = 0.8
			level_indicator.scale.y = maxf(0.04, fraction)

		level_indicator.material_override = mat
		level_indicator.position.y = 0.08 * (fraction - 1.0)

func is_empty() -> bool:
	return current_amount <= 0.001

func consume(amount: float) -> float:
	var actual = minf(current_amount, amount)
	current_amount = maxf(0.0, current_amount - actual)
	return actual

func refill() -> void:
	current_amount = max_amount

func get_ingredient_key() -> String:
	return item_id
