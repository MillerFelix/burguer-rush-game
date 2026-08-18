class_name FloorDirtSpot
extends StaticBody3D

# ================================================================
# MANCHA / SUJEIRA NO CHÃO (SISTEMA DE LIMPEZA DO RESTAURANTE)
#
# Marcas de refrigerante derramado, gotas de suco ou gordura.
# Limpeza com a bucha no mesmo fluxo unificado.
# ================================================================

@export var spot_type: String = "soda" # "soda", "sauce", "grease"
@export var dirt_amount: float = 1.0:
	set(val):
		dirt_amount = clampf(val, 0.0, 1.0)
		_update_visuals()

@onready var model: Node3D = get_node_or_null("Model")

func _ready() -> void:
	add_to_group("floor_dirt_spots")
	_update_visuals()

func _update_visuals() -> void:
	if not model:
		model = get_node_or_null("Model")
	if model:
		var sc = lerpf(0.20, 1.0, dirt_amount) if dirt_amount > 0.001 else 0.0
		model.scale = Vector3(sc, 1.0, sc)
		model.visible = (dirt_amount > 0.001)
		for child in model.get_children():
			if child is MeshInstance3D:
				var mat = child.get_active_material(0)
				if mat is StandardMaterial3D and mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					mat.albedo_color.a = clampf(dirt_amount * 0.95, 0.0, 0.95)

func is_dirty() -> bool:
	return dirt_amount > 0.01

func get_dirt_level() -> float:
	return dirt_amount

func clean_progress(delta: float, player: Node3D = null) -> bool:
	if dirt_amount <= 0.0:
		queue_free()
		return true

	dirt_amount = maxf(0.0, dirt_amount - (delta / 0.85))

	if dirt_amount <= 0.0:
		if player:
			var hud = player.get_node_or_null("HUD")
			if hud and hud.has_method("show_temporary_feedback"):
				hud.show_temporary_feedback("✨ Chão limpo com sucesso!")
		queue_free()
		return true

	return false

func get_interaction_prompt(player: Node = null) -> String:
	if not is_dirty():
		return ""

	var tool_holder = player.get_node_or_null("Head/Camera3D/ToolHolder") if player else null
	var sponge = tool_holder.get_node_or_null("Sponge") if tool_holder else null
	if sponge:
		if sponge.is_dirty:
			return "⚠️ Bucha suja! Lave na pia antes de limpar o chão"
		else:
			return "🖱️ [Segurar Clique Esquerdo] Limpar Mancha no Chão"
	else:
		return "Mancha no chão (Equipe a Bucha [2] para limpar)"
