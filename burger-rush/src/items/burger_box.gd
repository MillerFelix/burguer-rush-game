class_name BurgerBox
extends Item

# ================================================================
# CAIXA DE HAMBÚRGUER (EMBALAGEM VAZIA)
# Usada pelo jogador para embalar lanches prontos na bancada
# ================================================================

func _ready() -> void:
	item_id = "burger_box"
	display_name = "Caixa de Hambúrguer"
	item_type = "packaging"
	prompt_text = "🖱️ Pegar Caixa de Hambúrguer"

func get_display_name() -> String:
	return "Caixa de Hambúrguer"

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD:
		return ""
	if player and player.get("held_item") != null:
		return ""
	return "🖱️ Pegar Caixa de Hambúrguer"
