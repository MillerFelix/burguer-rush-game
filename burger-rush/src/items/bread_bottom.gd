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

func has_ingredients() -> bool:
	_ensure_assembly()
	if assembly:
		return assembly.ingredients.size() > 0 or assembly.state != BurgerAssembly.State.EMPTY
	return false

func get_interaction_prompt(player: Node = null) -> String:
	if location != ItemLocation.WORLD or is_held:
		return ""

	_ensure_assembly()
	if assembly:
		return assembly.get_interaction_prompt(player)

	return "🖱️ Pegar Base do Pão"

# [Clique Esquerdo] — Manipulação do lanche / adição de ingredientes / embalar
func interact_item(player: Node3D) -> void:
	if not player or location != ItemLocation.WORLD or is_held:
		return

	var held = player.get("held_item")
	if held == self:
		return

	_ensure_assembly()
	if assembly:
		assembly.interact_item(player)
		return

	if player.has_method("pick_up"):
		player.pick_up(self)

# [E] — Pegar o lanche inteiro (completo ou incompleto) para a mão principal
func interact(player: Node3D) -> void:
	if not player or location != ItemLocation.WORLD or is_held:
		return
	if player.get("held_item") == self:
		player.drop_item()
		return
	if player.has_method("is_holding_large_item") and player.is_holding_large_item():
		if player.get_node_or_null("HUD"):
			player.get_node_or_null("HUD").show_temporary_feedback("⚠️ Mãos ocupadas! Solte o item atual antes de pegar o lanche.")
		return
	if player.has_method("pick_up"):
		player.pick_up(self)
