class_name PulpStorageTable
extends StaticBody3D

# ================================================================
# MESA DE ARMAZENAMENTO DE POLPAS CONGELADAS NO ARMAZÉM
# Cesto de armazenamento aberto com 30 pedras físicas de polpa
# (10 Laranja, 10 Uva, 10 Morango)
# ================================================================

const JUICE_PULP_SCENE = preload("res://src/items/juice_pulp.tscn")

@export var stock_orange: int = 10:
	set(val):
		stock_orange = clamp(val, 0, 10)
		_update_pulp_visuals(0)

@export var stock_grape: int = 10:
	set(val):
		stock_grape = clamp(val, 0, 10)
		_update_pulp_visuals(1)

@export var stock_strawberry: int = 10:
	set(val):
		stock_strawberry = clamp(val, 0, 10)
		_update_pulp_visuals(2)

const FLAVORS = [
	{ "id": "orange", "name": "Laranja", "color": Color(0.98, 0.52, 0.05, 1.0) },
	{ "id": "grape", "name": "Uva", "color": Color(0.48, 0.12, 0.65, 1.0) },
	{ "id": "strawberry", "name": "Morango", "color": Color(0.92, 0.12, 0.28, 1.0) }
]

func _ready() -> void:
	_update_all_visuals()

func _get_aimed_flavor_index(player: Node3D) -> int:
	if not player:
		return 0
	var ray = player.get_node_or_null("Head/Camera3D/RayCast3D")
	if ray and ray is RayCast3D and ray.is_colliding():
		var col_pt = to_local(ray.get_collision_point())
		if col_pt.x < -0.16:
			return 0 # Laranja (Esquerda)
		elif col_pt.x > 0.16:
			return 2 # Morango (Direita)
		else:
			return 1 # Uva (Centro)
	return 0

func get_stock(idx: int) -> int:
	match idx:
		0: return stock_orange
		1: return stock_grape
		2: return stock_strawberry
	return 0

func set_stock(idx: int, val: int) -> void:
	match idx:
		0: stock_orange = val
		1: stock_grape = val
		2: stock_strawberry = val

func get_interaction_prompt(player: Node = null) -> String:
	if not player:
		return ""
	var idx = _get_aimed_flavor_index(player as Node3D)
	var count = get_stock(idx)
	var f_name = FLAVORS[idx].name
	if count <= 0:
		return "🔴 Cesto de Polpa de %s Vazio" % f_name
	return "🖱️ [Clique Esquerdo] Pegar Polpa de %s" % f_name

# Regra Burger Rush: E é estritamente para máquinas, portas e gavetas.
func interact(player: Node3D) -> void:
	# Não pega pelo E — instrui o jogador a usar o botão esquerdo
	var idx = _get_aimed_flavor_index(player)
	_show_feedback(player, "🖱️ Use [Clique Esquerdo] para pegar a pedra de polpa de %s." % FLAVORS[idx].name)

# Clique Esquerdo: pega o item manipulável
func interact_item(player: Node3D) -> void:
	take_pulp(player)

func take_pulp(player: Node3D, target_flavor_idx: int = -1) -> JuicePulp:
	if not player:
		return null
	if player.get("held_item") != null:
		_show_feedback(player, "⚠️ Suas mãos estão ocupadas!")
		return null

	var idx = target_flavor_idx if (target_flavor_idx >= 0 and target_flavor_idx < 3) else _get_aimed_flavor_index(player)
	var count = get_stock(idx)
	if count <= 0:
		_show_feedback(player, "🔴 Polpa de %s esgotada no cesto!" % FLAVORS[idx].name)
		return null

	# Reduz o estoque fisicamente contabilizado (ex: 10 -> 9)
	set_stock(idx, count - 1)

	# Instancia a pedra de polpa física na mão do jogador
	var pulp = JUICE_PULP_SCENE.instantiate() as JuicePulp
	if get_parent():
		get_parent().add_child(pulp)
	elif is_inside_tree() and get_tree() and get_tree().root:
		get_tree().root.add_child(pulp)

	pulp.fruit_type = FLAVORS[idx].id
	pulp._setup_pulp_properties()

	if player.has_method("pick_up"):
		player.pick_up(pulp)

	_show_feedback(player, "🧊 Polpa de %s retirada" % FLAVORS[idx].name)
	return pulp

func _update_all_visuals() -> void:
	for i in range(3):
		_update_pulp_visuals(i)

func _update_pulp_visuals(idx: int) -> void:
	var stock = get_stock(idx)
	# 10 pedras físicas por sabor (índices 0 a 9)
	for slot in range(10):
		var node = get_node_or_null("Model/Crate/Pulp_%d_%d" % [idx, slot])
		if node and node is MeshInstance3D:
			node.visible = (slot < stock)

func _show_feedback(player: Node3D, message: String) -> void:
	if player and player.has_node("HUD"):
		var hud = player.get_node("HUD")
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback(message)
