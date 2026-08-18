class_name FloorPuddle
extends StaticBody3D

# ================================================================
# POÇA D'ÁGUA NO CHÃO (SISTEMA DE LIMPEZA E CONDENSAÇÃO)
#
# Formada por geladeiras/freezers abertos por muito tempo ou
# derramamento de líquidos.
#
# Limpeza:
#  - Equipar Bucha Limpa (tecla 2)
#  - Segurar Clique Esquerdo sobre a poça
#  - Poça encolhe e seca progressivamente
#  - Bucha torna-se SUJA ao término da limpeza
# ================================================================

@export var puddle_size: float = 1.0:
	set(val):
		puddle_size = clampf(val, 0.0, 1.0)
		_update_visuals()

@onready var model: Node3D = get_node_or_null("Model")
@onready var main_puddle: MeshInstance3D = get_node_or_null("Model/MainPuddle")

func _ready() -> void:
	add_to_group("floor_puddles")
	_update_visuals()

func _update_visuals() -> void:
	if not model:
		model = get_node_or_null("Model")
	if model:
		var sc = lerpf(0.20, 1.0, puddle_size) if puddle_size > 0.001 else 0.0
		model.scale = Vector3(sc, 1.0, sc)
		model.visible = (puddle_size > 0.001)
		for child in model.get_children():
			if child is MeshInstance3D:
				var mat = child.get_active_material(0)
				if mat is StandardMaterial3D and mat.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					mat.albedo_color.a = clampf(puddle_size * 0.70, 0.0, 0.70)

func is_dirty() -> bool:
	return puddle_size > 0.01

func get_dirt_level() -> float:
	return puddle_size

func clean_progress(delta: float, player: Node3D = null) -> bool:
	if puddle_size <= 0.0:
		queue_free()
		return true

	puddle_size = maxf(0.0, puddle_size - (delta / 1.0))

	if puddle_size <= 0.0:
		if player:
			var hud = player.get_node_or_null("HUD")
			if hud and hud.has_method("show_temporary_feedback"):
				hud.show_temporary_feedback("✨ Poça d'água seca e limpa!")
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
			return "⚠️ Bucha suja! Lave na pia antes de secar a poça"
		else:
			return "🖱️ [Segurar Clique Esquerdo] Secar Poça d'Água com a Bucha"
	else:
		return "Poça d'água no chão (Equipe a Bucha [2] para secar)"
