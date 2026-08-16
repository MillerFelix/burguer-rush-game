class_name CookingOil
extends Item

@onready var mesh_model: Node3D = get_node_or_null("MeshInstance3D")

func _ready() -> void:
	item_id = "cooking_oil"
	display_name = "Galão de Óleo de Cozinha"
	item_type = "ingredient"
	prompt_text = "🖱️ [Clique] Pegar Galão de Óleo"

func play_pour_animation(duration: float = 1.2) -> void:
	if not mesh_model:
		mesh_model = get_node_or_null("MeshInstance3D")
	if not mesh_model:
		return

	var tween = create_tween()
	tween.tween_property(mesh_model, "rotation:z", deg_to_rad(-65.0), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(duration)
	tween.tween_property(mesh_model, "rotation:z", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
