class_name ServingTrayStack
extends StaticBody3D

# ================================================================
# PILHA DE BANDEJAS DE SERVIÇO NO BALCÃO PRINCIPAL
#
# Pilha física de 8 bandejas empilhadas.
# Regra global: Clique Esquerdo pega / devolve a bandeja.
# Limite rígido: Máximo de 8 bandejas disponíveis no jogo.
# Sem textos flutuantes / sem números no ar.
# ================================================================

const MAX_TRAYS: int = 8
const SERVING_TRAY_SCENE = preload("res://src/items/serving_tray.tscn")

@export var current_tray_count: int = 8

@onready var tray_nodes: Array[Node3D] = [
	$Model/Trays/Tray1,
	$Model/Trays/Tray2,
	$Model/Trays/Tray3,
	$Model/Trays/Tray4,
	$Model/Trays/Tray5,
	$Model/Trays/Tray6,
	$Model/Trays/Tray7,
	$Model/Trays/Tray8
]

func _ready() -> void:
	current_tray_count = clampi(current_tray_count, 0, MAX_TRAYS)
	_update_stack_visuals()

func _update_stack_visuals() -> void:
	for i in range(MAX_TRAYS):
		if i < tray_nodes.size() and is_instance_valid(tray_nodes[i]):
			tray_nodes[i].visible = (i < current_tray_count)

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""

	var held = player.get("held_item")
	if held != null:
		if (held is ServingTray or held is OrderTray) and held.get("carried_items") != null and held.carried_items.is_empty():
			if current_tray_count < MAX_TRAYS:
				return "🍽️ 🖱️ Devolver Bandeja à Pilha"
		return ""

	if current_tray_count > 0:
		return "🍽️ 🖱️ Pegar Bandeja"
	return "🔴 Pilha Vazia"

# Clique Esquerdo — Regra global de manipulação de itens
func interact_item(player: Node3D) -> void:
	if not player:
		return

	var held = player.get("held_item")

	# Se o jogador estiver de mãos livres: PEGA 1 BANDEJA
	if held == null:
		if current_tray_count <= 0:
			_show_feedback(player, "Não há mais bandejas disponíveis na pilha!")
			return

		current_tray_count -= 1
		_update_stack_visuals()

		var new_tray = SERVING_TRAY_SCENE.instantiate() as ServingTray
		get_tree().root.add_child(new_tray)
		player.pick_up(new_tray)
		_show_feedback(player, "🍽️ Pegou uma Bandeja de Serviço")
		return

	# Se o jogador estiver segurando uma bandeja vazia/limpa: DEVOLVE À PILHA
	if (held is ServingTray or held is OrderTray) and held.get("carried_items") != null and held.carried_items.is_empty():
		if current_tray_count >= MAX_TRAYS:
			_show_feedback(player, "A pilha de bandejas já está completa (8/8)!")
			return

		var returned_tray = player.take_held_item()
		if returned_tray:
			returned_tray.queue_free()
			current_tray_count += 1
			_update_stack_visuals()
			_show_feedback(player, "🍽️ Bandeja devolvida à pilha")
		return

	_show_feedback(player, "Mãos ocupadas!")

# Tecla E — Ações de ambiente / orientação
func interact(player: Node3D) -> void:
	var held = player.get("held_item")
	if held == null:
		_show_feedback(player, "ℹ️ Use o [Clique Esquerdo] para pegar uma bandeja.")
	elif (held is ServingTray or held is OrderTray) and held.carried_items.is_empty():
		_show_feedback(player, "ℹ️ Use o [Clique Esquerdo] para devolver a bandeja à pilha.")
	else:
		_show_feedback(player, "ℹ️ Desocupe as mãos para pegar uma bandeja.")

func _show_feedback(player: Node3D, message: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback(message)
