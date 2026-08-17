class_name BreadBottom
extends Item

# ================================================================
# BASE DO PÃO (BREAD BOTTOM) — BASE FÍSICA E RAIZ DO BURGER
#
# Contém a montagem unificada (BurgerAssembly).
# Todos os ingredientes e molhos empilhados são filhos da montagem.
# Ao clicar no lanche (pão ou ingredientes), o jogador pega o lanche inteiro.
# ================================================================

var assembly: BurgerAssembly = null
const BURGER_ASSEMBLY_SCENE = preload("res://src/recipes/burger_assembly.tscn")

func _ready() -> void:
	item_id = "bread_bottom"
	display_name = "Base do Pão"
	item_type = "ingredient"
	prompt_text = "🖱️ Pegar Base do Pão"
	_ensure_assembly()

func _ensure_assembly() -> void:
	if not assembly or not is_instance_valid(assembly):
		assembly = get_node_or_null("BurgerAssembly")
		if not assembly:
			assembly = BURGER_ASSEMBLY_SCENE.instantiate() as BurgerAssembly
			add_child(assembly)
			assembly.position = Vector3.ZERO
			assembly.base_bun = self

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD or is_held:
		return ""

	_ensure_assembly()
	if player and player.get("held_item") != null:
		var held = player.get("held_item")
		if held != self:
			return assembly.get_interaction_prompt(player)

	if assembly:
		if assembly.state == BurgerAssembly.State.CLOSED:
			var b_name = assembly.matched_recipe.display_name if assembly.matched_recipe else "Burger"
			return "🍔 %s — [Clique] Pegar Lanche" % b_name
		elif assembly.state == BurgerAssembly.State.ASSEMBLING:
			return "🥪 [Clique] Pegar Lanche"

	return "🖱️ Pegar Base do Pão"

# [Clique Esquerdo] — Manipulação do lanche / adição de ingredientes / pegar conjunto
func interact_item(player: Node3D) -> void:
	if not player or location != ItemLocation.WORLD or is_held:
		return

	var held = player.get("held_item")
	if held == self:
		return

	_ensure_assembly()

	# Se o jogador está segurando outro item (ingrediente, caixa, etc.), encaminha para a montagem
	if held != null:
		assembly.interact_item(player)
		return

	# Se está de mãos livres, pega o lanche inteiro
	if player.has_method("pick_up"):
		player.pick_up(self)
