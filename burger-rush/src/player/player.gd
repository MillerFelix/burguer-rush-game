class_name Player
extends CharacterBody3D

# ================================================================
# CONTROLADOR DO JOGADOR — SISTEMA DE MOVIMENTAÇÃO E FERRAMENTAS
#
# Ferramentas:
#  - Tecla 1: Espátula de Grelha (virar / retirar alimentos)
#  - Tecla 2: Bucha de Limpeza
#  - Tecla 3: Mão Livre (pegar ingredientes e manipular objetos)
# ================================================================

enum ToolSlot {
	SPATULA = 1,
	SPONGE = 2,
	HANDS = 3
}

@export var walk_speed: float = 4.0
@export var sprint_speed: float = 7.0
@export var acceleration: float = 12.0
@export var mouse_sensitivity: float = 0.002
@export var jump_velocity: float = 4.5

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var hold_position: Node3D = $Head/Camera3D/HoldPosition
@onready var tool_holder: Node3D = get_node_or_null("Head/Camera3D/ToolHolder")
@onready var hud = $HUD

# Áudio do Jogador (Passos, Ferramentas, Itens)
var footstep_audio: AudioStreamPlayer3D = null
var tool_audio: AudioStreamPlayer3D = null
var item_audio: AudioStreamPlayer3D = null
const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

var _step_timer: float = 0.0

var held_item: Node3D = null
var active_tool_slot: int = ToolSlot.HANDS
@export var sponge_is_dirty: bool = false

# ================================================================
# SISTEMA DE SLOTS RÁPIDOS DE INGREDIENTES (SLOTS 4, 5, 6)
# ================================================================
var quick_slots: Array[Dictionary] = [{}, {}, {}] # 3 Slots rápidos
var active_quick_slot: int = -1 # -1 = Nenhum slot rápido ativo, 0 = Slot 4, 1 = Slot 5, 2 = Slot 6
var quick_slot_visual: Node3D = null

var SCENE_SPATULA = load("res://src/tools/spatula.tscn")
var SCENE_SPONGE = load("res://src/tools/sponge.tscn")

func _enter_tree() -> void:
	_setup_audio()

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_ensure_audio_listener()
	_setup_audio()
	select_tool_slot(ToolSlot.HANDS, false)
	_notify_hud_quick_slots()
	_update_interaction_detection()

func _ensure_audio_listener() -> void:
	var listener = get_node_or_null("Head/Camera3D/AudioListener3D") as AudioListener3D
	if not listener and camera:
		listener = AudioListener3D.new()
		listener.name = "AudioListener3D"
		camera.add_child(listener)
	if listener:
		listener.make_current()

func _setup_audio() -> void:
	if not footstep_audio:
		footstep_audio = AudioStreamPlayer3D.new()
		footstep_audio.name = "FootstepAudioPlayer"
		footstep_audio.unit_size = 4.5
		footstep_audio.max_distance = 22.0
		footstep_audio.volume_db = -11.0
		add_child(footstep_audio)

	if not tool_audio:
		tool_audio = AudioStreamPlayer3D.new()
		tool_audio.name = "ToolAudioPlayer"
		tool_audio.unit_size = 4.0
		tool_audio.max_distance = 20.0
		tool_audio.volume_db = -4.0
		add_child(tool_audio)

	if not item_audio:
		item_audio = AudioStreamPlayer3D.new()
		item_audio.name = "ItemAudioPlayer"
		item_audio.unit_size = 4.0
		item_audio.max_distance = 20.0
		item_audio.volume_db = -4.0
		add_child(item_audio)

func _play_sound(audio_player: AudioStreamPlayer3D, sound_id: String, vol_db: float = -8.0, pitch_var: float = 0.0) -> void:
	if not audio_player:
		return
	audio_player.stream = SoundSynthesizer.get_stream(sound_id)
	audio_player.volume_db = vol_db
	if pitch_var > 0.0:
		audio_player.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
	else:
		audio_player.pitch_scale = 1.0
	if audio_player.is_inside_tree():
		audio_player.play()

func _unhandled_input(event: InputEvent) -> void:
	if is_inside_tree() and get_tree().paused:
		return

	var hud_node = hud
	if not hud_node and is_inside_tree() and get_tree() and get_tree().root:
		hud_node = get_tree().root.find_child("HUD", true, false)
	if hud_node:
		if hud_node.get("report_modal") and hud_node.report_modal.visible:
			return
		if hud_node.get("day1_welcome_modal") and hud_node.day1_welcome_modal.visible:
			return
		if hud_node.get("daily_notice_modal") and hud_node.daily_notice_modal.visible:
			return

	var comp_ui = get_tree().root.find_child("ComputerUI", true, false) if (is_inside_tree() and get_tree() and get_tree().root) else null
	if comp_ui and comp_ui.visible:
		return

	var pause_menu_node = get_tree().root.find_child("PauseMenu", true, false) if (is_inside_tree() and get_tree() and get_tree().root) else null
	if pause_menu_node and pause_menu_node.visible:
		return

	# Clique do mouse recaptura o controle se o cursor estiver livre durante gameplay
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or DisplayServer.get_name() == "headless":
			rotate_y(-event.relative.x * mouse_sensitivity)
			head.rotate_x(-event.relative.y * mouse_sensitivity)
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	# Seleção de ferramentas (1, 2, 3) e Slots Rápidos de Ingredientes (4, 5, 6)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1, KEY_KP_1:
				select_tool_slot(ToolSlot.SPATULA)
			KEY_2, KEY_KP_2:
				select_tool_slot(ToolSlot.SPONGE)
			KEY_3, KEY_KP_3:
				select_tool_slot(ToolSlot.HANDS)
			KEY_4, KEY_KP_4:
				select_quick_slot(0)
			KEY_5, KEY_KP_5:
				select_quick_slot(1)
			KEY_6, KEY_KP_6:
				select_quick_slot(2)

	# Troca de slots rápidos através do Scroll do Mouse
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cycle_quick_slot(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cycle_quick_slot(1)

	# Tecla E — Interagir com equipamentos / portas / máquinas
	if event.is_action_pressed("interact"):
		_try_interact_equipment()

	# Clique Esquerdo — Manipulação de itens, ferramentas e ingredientes (Pegar / Colocar)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_try_interact_item()

	# Clique Direito — Devolver item para armazenamento (Return to Storage) / Ação Secundária
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		_try_return_to_storage()

	if InputMap.has_action("secondary_interact") and event.is_action_pressed("secondary_interact"):
		_try_secondary_interact()

	if event.is_action_pressed("ui_cancel"):
		var pm = get_tree().root.find_child("PauseMenu", true, false) if (is_inside_tree() and get_tree() and get_tree().root) else null
		if pm and pm.has_method("pause_game") and not pm.visible:
			pm.pause_game()

func get_spatula() -> Node3D:
	if active_tool_slot == ToolSlot.SPATULA and tool_holder and tool_holder.get_child_count() > 0:
		var sp = tool_holder.get_child(0)
		if sp is Spatula or sp.has_method("has_patty"):
			return sp
	return null

func get_spatula_held_patty() -> Node3D:
	var sp = get_spatula()
	if sp and sp.has_method("get_held_patty"):
		return sp.get_held_patty()
	return null

func take_spatula_held_patty() -> Node3D:
	var sp = get_spatula()
	if sp and sp.has_method("detach_patty"):
		return sp.detach_patty()
	return null

func select_tool_slot(slot: int, show_feedback: bool = true) -> void:
	if active_tool_slot == ToolSlot.SPATULA and slot != ToolSlot.SPATULA and get_spatula_held_patty() != null:
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback("⚠️ Deposite o hambúrguer da espátula antes de trocar de ferramenta!")
		return

	if held_item != null and (held_item.get("is_customer_deposit_money") == true or str(held_item.get("item_id")) == "customer_money"):
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback("⚠️ Deposite o dinheiro no caixa antes de trocar de ferramenta!")
		return

	var transferring_item: Node3D = held_item
	if transferring_item and is_instance_valid(transferring_item) and transferring_item.get_meta("is_quick_slot_visual", false):
		if transferring_item.get_parent():
			transferring_item.get_parent().remove_child(transferring_item)
		transferring_item.queue_free()
		transferring_item = null
		held_item = null
	elif transferring_item and transferring_item.get_parent():
		transferring_item.get_parent().remove_child(transferring_item)

	active_tool_slot = slot
	if slot == ToolSlot.HANDS:
		active_quick_slot = -1

	if not tool_holder:
		tool_holder = get_node_or_null("Head/Camera3D/ToolHolder")

	if tool_holder:
		for child in tool_holder.get_children():
			tool_holder.remove_child(child)
			child.queue_free()

	match active_tool_slot:
		ToolSlot.SPATULA:
			if tool_holder:
				var spatula = SCENE_SPATULA.instantiate()
				tool_holder.add_child(spatula)
			if show_feedback:
				_play_sound(tool_audio, "tool_spatula_equip", -8.0, 0.05)
				if hud and hud.has_method("show_temporary_feedback"):
					hud.show_temporary_feedback("🍳 Espátula equipada [1]")

		ToolSlot.SPONGE:
			if tool_holder:
				var sponge = SCENE_SPONGE.instantiate()
				sponge.name = "Sponge"
				sponge.is_dirty = sponge_is_dirty
				tool_holder.add_child(sponge)
			if show_feedback:
				_play_sound(tool_audio, "tool_sponge_equip", -8.0, 0.05)
				if hud and hud.has_method("show_temporary_feedback"):
					hud.show_temporary_feedback("🧽 Bucha de limpeza equipada [2]")

		ToolSlot.HANDS:
			if show_feedback:
				_play_sound(tool_audio, "tool_hands_equip", -8.0, 0.05)
				if hud and hud.has_method("show_temporary_feedback"):
					hud.show_temporary_feedback("✋ Mão livre [3]")

	# Reanexa o item segurado ao ponto correto (BladeRestPoint da espátula ou HoldPosition da mão)
	if transferring_item:
		if active_tool_slot == ToolSlot.SPATULA and tool_holder and tool_holder.get_child_count() > 0:
			var spatula = tool_holder.get_child(0)
			var rest_pt = spatula.get_node_or_null("Model/BladeRestPoint")
			if rest_pt:
				rest_pt.add_child(transferring_item)
				transferring_item.position = Vector3.ZERO
				transferring_item.rotation = Vector3.ZERO
			else:
				hold_position.add_child(transferring_item)
				transferring_item.position = Vector3.ZERO
				transferring_item.rotation = Vector3.ZERO
		elif hold_position:
			hold_position.add_child(transferring_item)
			transferring_item.position = Vector3.ZERO
			transferring_item.rotation = Vector3.ZERO

	_notify_hud_quick_slots()
	_update_interaction_detection()
	_update_quick_slot_visual()

func _try_interact_equipment() -> void:
	if raycast and raycast.is_colliding():
		var raw_collider = raycast.get_collider()
		if raw_collider:
			var collider = _get_target_interactable(raw_collider)
			if collider:
				if held_item != null or has_active_ingredient():
					# Proteção estrita: Dinheiro em processo de depósito só pode interagir com a Caixa Registradora
					if held_item != null and (held_item.get("is_customer_deposit_money") == true or str(held_item.get("item_id")) == "customer_money"):
						if collider is CashRegister or (collider.get_parent() and collider.get_parent() is CashRegister):
							var cr = collider if collider is CashRegister else collider.get_parent()
							cr.interact(self)
							return
						else:
							if hud and hud.has_method("show_temporary_feedback"):
								hud.show_temporary_feedback("⚠️ O dinheiro do cliente só pode ser depositado na caixa registradora!")
							return

					if collider is TrashBin or (collider.get_parent() and collider.get_parent() is TrashBin):
						var tb = collider if collider is TrashBin else collider.get_parent()
						tb.interact(self)
						return
					elif collider is DeliveryStation or (collider.get_parent() and collider.get_parent() is DeliveryStation):
						var ds = collider if collider is DeliveryStation else collider.get_parent()
						ds.interact(self)
						return
					elif collider is DeliveryCar or (collider.get_parent() and collider.get_parent() is DeliveryCar):
						var dc = collider if collider is DeliveryCar else collider.get_parent()
						dc.interact(self)
						return
					elif collider is RestaurantTable or (collider is Customer and collider.assigned_table != null):
						var tbl = collider if collider is RestaurantTable else collider.assigned_table
						tbl.interact(self)
						return
					elif collider is IngredientDispenser:
						if held_item != null and (held_item.get("ingredient_id") == collider.get("ingredient_id") or str(held_item.get("item_type")) == "crate"):
							collider.interact(self)
							return
					elif collider.has_method("interact_equipment"):
						collider.interact_equipment(self)
						return
					elif collider.has_method("interact"):
						# Se for uma superfície física (bancada, mesa, chão, ilha), solta o item no ponto
						if collider is StaticBody3D or collider is CSGShape3D:
							if held_item != null or has_active_ingredient():
								drop_item()
							return
						collider.interact(self)
						return
					else:
						if held_item != null or has_active_ingredient():
							drop_item()
						return
				else:
					if collider is Customer:
						collider.interact(self)
						return
					elif collider is RestaurantTable:
						collider.interact(self)
						return
					elif collider.has_method("interact_equipment"):
						collider.interact_equipment(self)
						return
					elif collider.has_method("interact"):
						collider.interact(self)
						return

	if held_item != null or (has_active_ingredient() and active_tool_slot == ToolSlot.HANDS):
		# Pressionar E solta o item segurado ou ingrediente livremente na superfície física
		drop_item()
		return

func _get_target_interactable(collider: Object) -> Object:
	if not collider:
		return null
	if collider is BreadBottom:
		return collider
	if collider.has_meta("burger_base"):
		var base = collider.get_meta("burger_base")
		if base and is_instance_valid(base):
			return base
	if collider.get_parent() is BurgerAssembly:
		var ass = collider.get_parent() as BurgerAssembly
		if ass.base_bun and is_instance_valid(ass.base_bun):
			return ass.base_bun
	if collider.get_parent() is BreadBottom:
		return collider.get_parent()

	# Se for um item manipulável (ex: copo, barril, bisnaga, ingrediente): retorna o próprio item
	# Mas se estiver conectado em uma estação (SodaRefillRack ou DrinkMachine), redireciona a interação para a estação!
	if collider is Item:
		var p = collider.get_parent()
		while p != null:
			if p is SodaRefillRack or p.has_method("insert_canister"):
				return p
			p = p.get_parent()
		return collider

	# Se o colisor for filho de um Item (ex: CollisionShape3D, Model, etc.):
	var item_anc = collider.get_parent() if collider is Node else null
	while item_anc != null:
		if item_anc is Item:
			if item_anc is ServingTray:
				break
			var p = item_anc.get_parent()
			var redirect_to_station = false
			while p != null:
				if p is SodaRefillRack or p.has_method("insert_canister"):
					redirect_to_station = true
					break
				p = p.get_parent()
			if not redirect_to_station:
				return item_anc
		item_anc = item_anc.get_parent()

	if collider is Customer:
		return collider

	# Se o colisor for parte de uma estação / equipamento (ex: Grill, Sink, DrinkMachine, RestaurantTable, etc.):
	var curr = collider
	while curr != null:
		if curr is Node and (curr is RestaurantTable or curr is Customer or curr is CashRegister or curr is DeliveryStation or curr is DeliveryCar or curr is TrashBin or curr is Grill or curr is Fryer or curr is CommercialSink or curr is PrepIsland or curr is StorageRack or curr is MainPowerPanel or curr is ComputerStation or curr is DrinkMachine or curr is JuiceMachine or curr is PackagingStation or curr is OpenSign or curr.has_method("clean_progress")):
			return curr
		if curr is Node and curr.has_method("get_interaction_prompt") and (curr.has_method("interact") or curr.has_method("interact_item")):
			return curr
		curr = curr.get_parent() if curr is Node else null

	return collider

func can_be_picked_with_spatula(obj: Object) -> bool:
	if not obj or not is_instance_valid(obj):
		return false
	if obj is Patty or obj is Cheese or obj is Bacon or obj is Egg:
		return true
	if obj.has_method("is_cookable_on_grill") and obj.is_cookable_on_grill():
		return true
	if obj.get("is_grillable") == true:
		return true
	return false

func _try_interact_item() -> void:
	if active_tool_slot == ToolSlot.SPONGE:
		# Com a bucha de limpeza ativa, o clique/segurar é reservado exclusivamente para limpeza contínua e lavagem na pia
		if raycast and raycast.is_colliding():
			var raw_c = raycast.get_collider()
			var c = _get_target_interactable(raw_c)
			if c is CommercialSink or (c and c.get_parent() is CommercialSink):
				var sink = c if c is CommercialSink else c.get_parent()
				sink.wash_or_sanitize(self)
				return
			if (c and (c is Grill or c is RestaurantTable or c.has_method("clean_progress"))) or (raw_c and raw_c.has_method("clean_progress")):
				return
		return

	if held_item != null and (held_item is SauceBottle or str(held_item.get("item_type")) == "sauce_bottle"):
		return

	if raycast and raycast.is_colliding():
		var raw_collider = raycast.get_collider()
		if not raw_collider or not is_instance_valid(raw_collider):
			return

		if raw_collider == held_item or (held_item != null and is_instance_valid(held_item) and held_item.is_ancestor_of(raw_collider)):
			return

		var collider = _get_target_interactable(raw_collider)
		if not collider or not is_instance_valid(collider):
			return

		# Se mirou na bandeja, verifica se o ponto atingido pelo RayCast mira um item contido na bandeja
		if collider is ServingTray:
			var tray_col = collider as ServingTray
			var hit_pos = raycast.get_collision_point()
			var best_item: Item = null
			var best_dist: float = 0.25
			for p_item in tray_col.carried_items:
				if p_item and is_instance_valid(p_item) and p_item is Item:
					var d = hit_pos.distance_to(p_item.global_position)
					if d < best_dist:
						best_dist = d
						best_item = p_item as Item
			if best_item != null:
				collider = best_item

		# ESTADO 1: O jogador está com item na mão (ou ingrediente ativo)
		if held_item != null or has_active_ingredient():
			if collider is ServingTray:
				if hud and hud.has_method("show_temporary_feedback"):
					hud.show_temporary_feedback("ℹ️ Use o [Botão Direito] para colocar o item na bandeja.")
				return

			# 1. Se mirou em uma montagem de lanche (BreadBottom): SEMPRE aciona interact_item para adicionar ingrediente ou embalar!
			if collider is BreadBottom:
				collider.interact_item(self)
				return

			# Se mirou em outro item no mundo -> Tenta pegar se houver espaço; avisa se cheio
			if collider is Item:
				if is_quick_slot_compatible(collider):
					if has_empty_quick_slot():
						if active_tool_slot == ToolSlot.SPONGE:
							select_tool_slot(ToolSlot.HANDS, false)
						pick_up(collider as Item)
						return
					else:
						if hud and hud.has_method("show_temporary_feedback"):
							hud.show_temporary_feedback("⚠️ Slots rápidos cheios (3/3)! Use os ingredientes atuais antes de pegar outros.")
						return
				else:
					if hud and hud.has_method("show_temporary_feedback"):
						hud.show_temporary_feedback("⚠️ Mãos ocupadas! Solte o item atual antes de pegar outro.")
					return

			# Se mirou em uma estação / receptor ativo / dispenser / geladeira / lixeira / chapa
			var is_station = collider is PulpStorageTable or collider is StorageRack or collider is BaconEggStation or collider is OilRack or collider is IngredientRefrigerator or collider is CommercialChestFreezer or collider is MeatRefrigerator or collider is DrinkMachine or collider is SodaRefillRack or collider is TrashBin or collider is DeliveryStation
			var is_surface = not is_station and (collider is StaticBody3D or collider is CSGShape3D) and (
				collider is PrepIsland or collider is PrepTable or
				collider.name.to_lower().contains("table") or
				collider.name.to_lower().contains("counter") or
				collider.name.to_lower().contains("island") or
				collider.name.to_lower().contains("floor") or
				collider.name.to_lower().contains("wall")
			)

			if collider.has_method("interact_item") and not is_surface:
				if active_tool_slot == ToolSlot.SPONGE:
					select_tool_slot(ToolSlot.HANDS, false)
				collider.interact_item(self)
				return
			elif collider.has_method("interact") and not is_surface:
				if active_tool_slot == ToolSlot.SPONGE:
					select_tool_slot(ToolSlot.HANDS, false)
				collider.interact(self)
				return
			else:
				# QUALQUER SUPERFÍCIE FÍSICA MIRADA (Ilha, bancadas, mesas, chão, etc.) -> Coloca no ponto atingido pelo RayCast3D
				drop_item()
				return

		# ESTADO 2: Mãos livres (held_item == null) -> PEGAR ITENS DO MUNDO
		else:
			# Se a ESPÁTULA estiver carregando um hambúrguer
			if active_tool_slot == ToolSlot.SPATULA and get_spatula_held_patty() != null:
				if collider is BreadBottom or collider.get_parent() is BurgerAssembly or collider.has_meta("burger_assembly") or collider.has_meta("burger_base"):
					collider.interact_item(self)
					return
				elif collider is TrashBin:
					collider.interact(self)
					return
				elif collider is ServingTray:
					var p_tray = take_spatula_held_patty()
					if p_tray:
						collider.add_product(p_tray)
						if hud and hud.has_method("show_temporary_feedback"):
							hud.show_temporary_feedback("🍱 %s colocado na bandeja!" % p_tray.get_display_name())
					return
				elif collider is PrepIsland or collider is PrepTable:
					if collider.has_method("interact_item"):
						collider.interact_item(self)
						return
				elif collider is Grill:
					if hud and hud.has_method("show_temporary_feedback"):
						hud.show_temporary_feedback("⚠️ A espátula já está carregando um hambúrguer! Deposite-o antes de pegar outro.")
					return
				else:
					# Superfície física (bancada, balcão, mesa): deposita no ponto clicado
					var p_surf = take_spatula_held_patty()
					if p_surf:
						var hit_pos = raycast.get_collision_point()
						if is_inside_tree():
							get_tree().current_scene.add_child(p_surf)
						p_surf.global_position = hit_pos + Vector3(0, 0.03, 0)
						p_surf.rotation = Vector3(0, rotation.y, 0)
						if "location" in p_surf:
							p_surf.location = Item.ItemLocation.WORLD
						if "is_held" in p_surf:
							p_surf.is_held = false
						if hud and hud.has_method("show_temporary_feedback"):
							hud.show_temporary_feedback("🍳 %s depositado na bancada." % p_surf.get_display_name())
					return

			if collider is Item:
				if "is_held" in collider and collider.is_held:
					return

				# Se for a própria bandeja, não pega com LMB (pegar bandeja é com a tecla E)
				if collider is ServingTray:
					if hud and hud.has_method("show_temporary_feedback"):
						hud.show_temporary_feedback("ℹ️ Pressione [E] para pegar a bandeja.")
					return

				# 1. Bucha de limpeza nunca pega itens -> Troca automaticamente para a Mão Livre
				if active_tool_slot == ToolSlot.SPONGE:
					select_tool_slot(ToolSlot.HANDS, false)
					pick_up(collider as Item)
					return

				# 2. Espátula: manipula itens válidos para grelha; para os demais, troca para Mão Livre
				if active_tool_slot == ToolSlot.SPATULA:
					if can_be_picked_with_spatula(collider):
						var p_grill = collider.get_parent()
						while p_grill != null:
							if p_grill is Grill:
								p_grill.interact_item(self)
								return
							p_grill = p_grill.get_parent()
						pick_up(collider as Item)
						return
					else:
						select_tool_slot(ToolSlot.HANDS, false)
						pick_up(collider as Item)
						return

				# 3. Mão Livre (Slot 3): PROTEÇÃO CONTRA PEGAR HAMBÚRGUER QUENTE DA CHAPA
				if active_tool_slot == ToolSlot.HANDS:
					var p_grill = collider.get_parent()
					var on_grill = false
					while p_grill != null:
						if p_grill is Grill:
							on_grill = true
							break
						p_grill = p_grill.get_parent()

					if on_grill and collider is Patty:
						if hud and hud.has_method("show_temporary_feedback"):
							hud.show_temporary_feedback("⚠️ Alimento quente na chapa! Equipe a Espátula [Tecla 1] para retirar.")
						return

					if on_grill:
						var gr = p_grill as Grill
						if gr:
							gr.interact_item(self)
							return

					pick_up(collider as Item)
					return

			elif collider.has_method("interact_item"):
				collider.interact_item(self)
				return
	else:
		if held_item != null:
			drop_item()
			return

func _try_return_to_storage() -> void:
	if not raycast or not raycast.is_colliding():
		return

	var raw_collider = raycast.get_collider()
	if not raw_collider or not is_instance_valid(raw_collider):
		return

	# 1. Se mirou em uma bandeja (ServingTray ou item dentro de ServingTray)
	var tray_target: ServingTray = null
	if raw_collider is ServingTray:
		tray_target = raw_collider as ServingTray
	else:
		var p = raw_collider.get_parent() if raw_collider is Node else null
		while p != null:
			if p is ServingTray:
				tray_target = p as ServingTray
				break
			p = p.get_parent()

	if tray_target != null:
		if held_item != null and held_item != tray_target and is_instance_valid(held_item):
			if tray_target.carried_items.size() < tray_target.max_capacity:
				var item_to_add = take_held_item()
				if item_to_add:
					tray_target.add_product(item_to_add)
					if hud and hud.has_method("show_temporary_feedback"):
						var d_name = item_to_add.get_display_name() if item_to_add.has_method("get_display_name") else item_to_add.name
						hud.show_temporary_feedback("🍱 %s colocado na bandeja" % d_name)
			else:
				if hud and hud.has_method("show_temporary_feedback"):
					hud.show_temporary_feedback("⚠️ Bandeja cheia!")
			return
		elif has_active_ingredient():
			if tray_target.carried_items.size() < tray_target.max_capacity:
				var node = consume_active_ingredient()
				if node:
					tray_target.add_product(node)
					if hud and hud.has_method("show_temporary_feedback"):
						var d_name = node.get_display_name() if node.has_method("get_display_name") else node.name
						hud.show_temporary_feedback("🍱 %s colocado na bandeja" % d_name)
			else:
				if hud and hud.has_method("show_temporary_feedback"):
					hud.show_temporary_feedback("⚠️ Bandeja cheia!")
			return
		else:
			if hud and hud.has_method("show_temporary_feedback"):
				hud.show_temporary_feedback("⚠️ Segure um produto/embalagem para colocar na bandeja com o Botão Direito.")
			return

	var collider = _get_target_interactable(raw_collider)
	if not collider or not is_instance_valid(collider):
		return

	# 2. Se o colisor possui manipulador específico de devolução
	if collider.has_method("interact_return"):
		collider.interact_return(self)
		return
	elif collider.has_method("return_item"):
		collider.return_item(self)
		return
	elif collider is IngredientDispenser:
		collider.interact_return(self)
		return
	elif collider.has_method("cycle_flavor"):
		collider.cycle_flavor(self)
		return
	elif collider.has_method("secondary_interact"):
		collider.secondary_interact(self)
		return

func has_matching_ingredient(target_id: String) -> bool:
	if held_item != null:
		var held_id = str(held_item.get("item_id")) if held_item.get("item_id") != null else ""
		if _matches_ingredient_id(held_id, target_id):
			return true
		var held_ing_id = str(held_item.get("ingredient_id")) if held_item.get("ingredient_id") != null else ""
		if _matches_ingredient_id(held_ing_id, target_id):
			return true
		if held_item is Patty:
			var p = held_item as Patty
			if (target_id == "patty_beef" and p.meat_type == Patty.MeatType.BEEF) or (target_id == "patty_chicken" and p.meat_type == Patty.MeatType.CHICKEN):
				return true
		if held_item is Cheese and target_id in ["cheese", "cheese_cheddar", "cheese_prato", "cheese_mozzarella"]:
			return true
		if held_item is Onion:
			var o = held_item as Onion
			if o.onion_type == Onion.OnionType.RED and target_id == "red_onion":
				return true
			elif o.onion_type != Onion.OnionType.RED and target_id in ["onion", "white_onion"]:
				return true
		if held_item is Potato and target_id in ["potato_raw", "potato", "potato_box"]:
			return true
		if held_item is JuicePulp:
			var jp = held_item as JuicePulp
			if target_id == ("pulp_" + str(jp.fruit_type)) or target_id == str(jp.fruit_type):
				return true
		if held_item is Bacon and target_id == "bacon":
			return true
		if held_item is Egg and target_id == "egg":
			return true
		if held_item is CookingOil and target_id == "cooking_oil":
			return true
		if str(held_item.get("item_type")) in ["crate", "storage_box", "delivery_box"]:
			var box_item_id = str(held_item.get("contained_item_id"))
			if _matches_ingredient_id(box_item_id, target_id):
				return true
		var s_path = held_item.scene_file_path if held_item.scene_file_path else ""
		if s_path.contains("bread_top") and target_id in ["bread_top", "bread"]:
			return true
		if s_path.contains("bread_bottom") and target_id in ["bread_bottom", "bread"]:
			return true
		if s_path.contains("tomato") and target_id == "tomato":
			return true
		if s_path.contains("lettuce") and target_id == "lettuce":
			return true
		if s_path.contains("pickle") and target_id == "pickle":
			return true

	for slot in quick_slots:
		if not slot.is_empty():
			var slot_id = str(slot.get("item_id", ""))
			if _matches_ingredient_id(slot_id, target_id):
				return true
	return false

func _matches_ingredient_id(item_id: String, target_id: String) -> bool:
	if item_id == target_id:
		return true
	if target_id == "patty_beef" and item_id in ["patty_beef", "patty", "patty_raw"]:
		return true
	if target_id == "patty_chicken" and item_id == "patty_chicken":
		return true
	if target_id == "cheese" and item_id in ["cheese", "cheese_cheddar", "cheese_prato", "cheese_mozzarella"]:
		return true
	if item_id == "cheese" and target_id in ["cheese", "cheese_cheddar", "cheese_prato", "cheese_mozzarella"]:
		return true
	if target_id in ["potato_raw", "potato", "potato_box"] and item_id in ["potato_raw", "potato", "potato_box"]:
		return true
	if target_id in ["onion_rings_raw", "onion_bag"] and item_id in ["onion_rings_raw", "onion_bag"]:
		return true
	if target_id in ["onion", "white_onion"] and item_id in ["onion", "white_onion"]:
		return true
	if target_id == "bread" and item_id in ["bread", "bread_top", "bread_bottom"]:
		return true
	if item_id == "bread" and target_id in ["bread", "bread_top", "bread_bottom"]:
		return true
	if target_id.begins_with("pulp_") and (item_id == target_id or ("pulp_" + item_id) == target_id):
		return true
	return false

func return_one_matching_ingredient(target_id: String) -> bool:
	# 1. Se o active_quick_slot corresponder ao target_id, remove primeiro
	if active_quick_slot >= 0 and active_quick_slot < quick_slots.size() and not quick_slots[active_quick_slot].is_empty():
		var act_id = str(quick_slots[active_quick_slot].get("item_id", ""))
		if _matches_ingredient_id(act_id, target_id):
			var taken = take_held_item()
			if taken:
				taken.queue_free()
			else:
				quick_slots[active_quick_slot] = {}
				active_quick_slot = -1
				_notify_hud_quick_slots()
				_update_quick_slot_visual()
			return true

	# 2. Se o item físico segurado na mão (mão principal ou caixa) for compatível
	if held_item != null:
		var held_id = str(held_item.get("item_id")) if held_item.get("item_id") != null else ""
		var is_match = _matches_ingredient_id(held_id, target_id)
		if not is_match and held_item is Patty:
			var p = held_item as Patty
			if (target_id == "patty_beef" and p.meat_type == Patty.MeatType.BEEF) or (target_id == "patty_chicken" and p.meat_type == Patty.MeatType.CHICKEN):
				is_match = true
		if is_match:
			var taken = take_held_item()
			if taken:
				taken.queue_free()
			return true

	# 3. Procura nos outros slots rápidos
	for i in range(quick_slots.size()):
		if not quick_slots[i].is_empty():
			var s_id = str(quick_slots[i].get("item_id", ""))
			if _matches_ingredient_id(s_id, target_id):
				quick_slots[i] = {}
				if active_quick_slot == i:
					active_quick_slot = -1
				_notify_hud_quick_slots()
				_update_quick_slot_visual()
				return true

	return false

func _try_secondary_interact() -> void:
	if raycast and raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider:
			if collider.has_method("cycle_flavor"):
				collider.cycle_flavor(self)
			elif collider.has_method("secondary_interact"):
				collider.secondary_interact(self)

var _cached_hud_node: Node = null
var _cached_pause_menu: Node = null

func _get_hud_node() -> Node:
	if _cached_hud_node and is_instance_valid(_cached_hud_node):
		return _cached_hud_node
	if hud and is_instance_valid(hud):
		_cached_hud_node = hud
		return _cached_hud_node
	if is_inside_tree() and get_tree() and get_tree().root:
		_cached_hud_node = get_tree().root.find_child("HUD", true, false)
	return _cached_hud_node

func _get_pause_menu_node() -> Node:
	if _cached_pause_menu and is_instance_valid(_cached_pause_menu):
		return _cached_pause_menu
	if is_inside_tree() and get_tree() and get_tree().root:
		_cached_pause_menu = get_tree().root.find_child("PauseMenu", true, false)
	return _cached_pause_menu

func _physics_process(delta: float) -> void:
	if is_inside_tree() and get_tree().paused:
		velocity = Vector3.ZERO
		return

	var hud_node = _get_hud_node()
	if hud_node and hud_node.get("report_modal") and hud_node.report_modal.visible:
		velocity = Vector3.ZERO
		return

	if held_item != null and held_item is SauceBottle:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			held_item.start_squeezing(raycast)
		else:
			held_item.stop_squeezing()

	# Processamento de Limpeza Contínua com a Bucha (Slot 2)
	if active_tool_slot == ToolSlot.SPONGE:
		_process_sponge_cleaning(delta)
	else:
		_stop_scrubbing_audio()

	var pause_menu = _get_pause_menu_node()
	if pause_menu and pause_menu.visible:
		velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var speed: float = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if direction:
		velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
	elif DisplayServer.get_name() != "headless":
		velocity.x = lerp(velocity.x, 0.0, acceleration * delta)
		velocity.z = lerp(velocity.z, 0.0, acceleration * delta)

	var move_speed_h = Vector2(velocity.x, velocity.z).length()
	move_and_slide()
	_process_footsteps(delta, maxf(move_speed_h, Vector2(velocity.x, velocity.z).length()))
	_update_interaction_detection()

func _process_footsteps(delta: float, speed_h: float = -1.0) -> void:
	var horizontal_speed = speed_h if speed_h >= 0.0 else Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.4:
		var step_interval = 0.38 if not Input.is_action_pressed("sprint") else 0.26
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = step_interval
			_play_sound(footstep_audio, "player_footstep", -11.0, 0.08)
	else:
		_step_timer = 0.05

func _update_interaction_detection() -> void:
	if not hud:
		return

	if raycast and raycast.is_colliding():
		var raw_collider = raycast.get_collider()
		if raw_collider and raw_collider != held_item and (held_item == null or not held_item.is_ancestor_of(raw_collider)):
			var collider = _get_target_interactable(raw_collider)

			# Se mirou na bandeja com mãos livres, verifica se mira proximidade de um item dentro da bandeja
			if collider is ServingTray and (held_item == null and not has_active_ingredient()):
				var tray_col = collider as ServingTray
				var hit_pos = raycast.get_collision_point()
				var best_item: Item = null
				var best_dist: float = 0.25
				for p_item in tray_col.carried_items:
					if p_item and is_instance_valid(p_item) and p_item is Item:
						var d = hit_pos.distance_to(p_item.global_position)
						if d < best_dist:
							best_dist = d
							best_item = p_item as Item
				if best_item != null:
					collider = best_item

			if collider and collider.has_method("get_interaction_prompt"):
				var prompt: String = collider.get_interaction_prompt(self)
				if prompt != "":
					hud.show_prompt(prompt)
					return
			elif collider is Item and not is_holding_large_item():
				var parent_ass = collider.get_parent()
				if parent_ass and parent_ass != held_item and parent_ass.has_method("get_interaction_prompt"):
					var prompt: String = parent_ass.get_interaction_prompt(self)
					if prompt != "":
						hud.show_prompt(prompt)
						return
				elif not collider.has_method("get_interaction_prompt"):
					var c_name = collider.get_display_name() if collider.has_method("get_display_name") else collider.name
					hud.show_prompt("🖱️ Pegar %s" % c_name)
					return

	if held_item != null:
		if held_item.get("is_customer_deposit_money") == true or str(held_item.get("item_id")) == "customer_money":
			hud.show_prompt("💵 Dinheiro em processo de depósito (Leve até a Caixa Registradora)")
			return
		elif held_item is SauceBottle:
			hud.show_prompt("🖱️ (Segurar) Aplicar %s  │  [E] Soltar" % held_item.display_name)
		else:
			var d_name = held_item.get_display_name() if held_item.has_method("get_display_name") else held_item.name
			hud.show_prompt("🖱️ / [E] Colocar %s" % d_name)
		return
	elif has_active_ingredient() and active_tool_slot == ToolSlot.HANDS:
		var act = get_active_ingredient()
		var d_name = act.get("display_name", "Ingrediente")
		hud.show_prompt("🖱️ / [E] Colocar %s" % d_name)
		return

	if hud and hud.has_method("hide_prompt"):
		hud.hide_prompt()

# ================================================================
# MÉTODOS DE CONTROLE DOS SLOTS RÁPIDOS (4, 5, 6)
# ================================================================

func is_quick_slot_compatible(item: Node3D) -> bool:
	if item == null:
		return false
	# Objetos grandes e únicos — NUNCA entram em slots rápidos
	if item is ServingTray or item is OrderTray: return false
	if item is DeliveryBag or item is DeliveryBox or item is BurgerBox or item is PackagedBurger: return false
	if item is DrinkCup or item is SyrupCanister or item is SodaSyrupBottle or item is CookingOil or item is SauceBottle: return false
	if item is DirtyDishes or item is PotatoBoxItem: return false
	if item.get("is_customer_deposit_money") == true or str(item.get("item_id")) == "customer_money": return false
	if item is BreadBottom and item.has_ingredients(): return false # Hambúrguer montado não entra em quick slot!

	# Ingredientes e sacos compatíveis com slots rápidos
	if item is Patty or item is Cheese or item is Pickle or item is Tomato or item is Lettuce: return true
	if item is Onion or item is Bacon or item is Egg or item is JuicePulp or item is Potato: return true
	if item is OnionBag or item.name.begins_with("OnionBag") or (item.scene_file_path and item.scene_file_path.contains("onion_bag")): return true
	if item is Bread or (item is BreadBottom and not item.has_ingredients()) or (item.scene_file_path and item.scene_file_path.contains("bread")): return true
	if "item_type" in item and item.item_type == "ingredient": return true

	return false

func is_holding_large_item() -> bool:
	if held_item != null and is_instance_valid(held_item):
		return not held_item.get_meta("is_quick_slot_visual", false)
	return false

func is_hand_free() -> bool:
	return not is_holding_large_item()

func can_manipulate_ingredients() -> bool:
	return not is_holding_large_item()

func has_active_ingredient() -> bool:
	return active_quick_slot >= 0 and active_quick_slot < quick_slots.size() and not quick_slots[active_quick_slot].is_empty()

func get_active_ingredient() -> Dictionary:
	if has_active_ingredient():
		return quick_slots[active_quick_slot]
	return {}

func has_empty_quick_slot() -> bool:
	for slot in quick_slots:
		if slot.is_empty():
			return true
	return false

func can_take_ingredient(_ing_id: String = "") -> bool:
	if is_holding_large_item():
		return false
	return has_empty_quick_slot()

func select_quick_slot(slot_idx: int, show_feedback: bool = true) -> void:
	if slot_idx < 0 or slot_idx >= quick_slots.size():
		return

	active_quick_slot = slot_idx

	if quick_slots[slot_idx].is_empty():
		if show_feedback and hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback("Slot [%d] vazio" % (slot_idx + 4))
	else:
		var s_data = quick_slots[slot_idx]
		if active_tool_slot == ToolSlot.SPONGE:
			select_tool_slot(ToolSlot.HANDS, false)

		if show_feedback:
			_play_sound(tool_audio, "tool_hands_equip", -8.0, 0.05)
			if hud and hud.has_method("show_temporary_feedback"):
				hud.show_temporary_feedback("%s %s [%d] selecionado" % [
					s_data.get("icon", "📦"), s_data.get("display_name", "Item"), slot_idx + 4
				])

	_notify_hud_quick_slots()
	_update_interaction_detection()
	_update_quick_slot_visual()

func _update_quick_slot_visual() -> void:
	if not hold_position:
		hold_position = get_node_or_null("Head/Camera3D/HoldPosition")

	# Se a ferramenta ativa não for Mãos (Slot 3) ou não houver ingrediente ativo nos slots rápidos
	if active_tool_slot != ToolSlot.HANDS or not has_active_ingredient():
		if held_item != null and is_instance_valid(held_item) and held_item.get_meta("is_quick_slot_visual", false):
			if raycast and held_item is CollisionObject3D:
				raycast.remove_exception(held_item)
			if held_item.get_parent():
				held_item.get_parent().remove_child(held_item)
			held_item.queue_free()
			held_item = null
		quick_slot_visual = null

		# Limpeza estrita de qualquer nó visual órfão remanescente em HoldPosition
		if hold_position and is_instance_valid(hold_position):
			for child in hold_position.get_children():
				if child != held_item or not is_instance_valid(held_item) or held_item == null:
					if raycast and child is CollisionObject3D:
						raycast.remove_exception(child)
					child.queue_free()
		return

	# Caso haja ingrediente ativo nos slots rápidos:
	var slot = quick_slots[active_quick_slot]

	# Se já está segurando exatamente o visual do slot ativo atual, valida e limpa duplicatas
	if held_item != null and is_instance_valid(held_item) and held_item.get_meta("is_quick_slot_visual", false):
		if held_item.get_meta("quick_slot_index", -1) == active_quick_slot:
			quick_slot_visual = held_item
			if hold_position and is_instance_valid(hold_position):
				for child in hold_position.get_children():
					if child != held_item:
						child.queue_free()
			return

		# Se mudou de slot rápido, remove o visual do slot anterior
		if raycast and held_item is CollisionObject3D:
			raycast.remove_exception(held_item)
		if held_item.get_parent():
			held_item.get_parent().remove_child(held_item)
		held_item.queue_free()
		held_item = null

	# Limpa qualquer resíduo anterior em HoldPosition antes de instanciar o novo visual
	if hold_position and is_instance_valid(hold_position):
		for child in hold_position.get_children():
			if child != held_item or not is_instance_valid(held_item) or held_item == null:
				child.queue_free()

	# Instancia o novo nó 3D representativo do ingrediente na mão
	var node = _instantiate_from_slot_data(slot)
	if node:
		node.set_meta("is_quick_slot_visual", true)
		node.set_meta("quick_slot_index", active_quick_slot)
		held_item = node
		quick_slot_visual = node
		if hold_position:
			hold_position.add_child(node)
			node.position = Vector3.ZERO
			node.rotation = Vector3.ZERO
		if node.has_method("on_picked_up"):
			node.on_picked_up()
		elif node is CollisionObject3D:
			node.collision_layer = 0
			node.collision_mask = 0
		if raycast and node is CollisionObject3D:
			raycast.add_exception(node)

func cycle_quick_slot(direction: int) -> void:
	var occupied: Array[int] = []
	for i in range(quick_slots.size()):
		if not quick_slots[i].is_empty():
			occupied.append(i)

	if occupied.is_empty():
		# Se nenhum estiver ocupado, apenas cicla entre os 3 índices 0, 1, 2
		var next_slot = (active_quick_slot + direction) % quick_slots.size()
		if next_slot < 0:
			next_slot = quick_slots.size() - 1
		select_quick_slot(next_slot, true)
		return

	if occupied.size() == 1:
		if active_quick_slot != occupied[0]:
			select_quick_slot(occupied[0], true)
		return

	var current_idx_in_occupied = occupied.find(active_quick_slot)
	var next_idx_in_occupied = 0
	if current_idx_in_occupied != -1:
		next_idx_in_occupied = (current_idx_in_occupied + direction) % occupied.size()
		if next_idx_in_occupied < 0:
			next_idx_in_occupied = occupied.size() - 1
	else:
		next_idx_in_occupied = 0 if direction > 0 else occupied.size() - 1

	select_quick_slot(occupied[next_idx_in_occupied], true)

func _find_first_occupied_quick_slot() -> int:
	for i in range(quick_slots.size()):
		if not quick_slots[i].is_empty():
			return i
	return -1

func consume_active_ingredient() -> Node3D:
	if not has_active_ingredient():
		return null

	var slot = quick_slots[active_quick_slot]
	var node = _instantiate_from_slot_data(slot)
	quick_slots[active_quick_slot] = {}

	var next_slot = _find_first_occupied_quick_slot()
	active_quick_slot = next_slot

	_notify_hud_quick_slots()
	_update_interaction_detection()
	_update_quick_slot_visual()
	return node

func consume_ingredient_from_slot(slot_idx: int) -> Node3D:
	if slot_idx < 0 or slot_idx >= quick_slots.size() or quick_slots[slot_idx].is_empty():
		return null

	var slot = quick_slots[slot_idx]
	var node = _instantiate_from_slot_data(slot)
	quick_slots[slot_idx] = {}

	if active_quick_slot == slot_idx:
		active_quick_slot = _find_first_occupied_quick_slot()

	_notify_hud_quick_slots()
	_update_interaction_detection()
	_update_quick_slot_visual()
	return node

func _instantiate_from_slot_data(slot: Dictionary) -> Node3D:
	var item_id: String = slot.get("item_id", "")
	var scene_path: String = slot.get("scene_path", "")
	var data: Dictionary = slot.get("data", {})
	var node: Node3D = null

	if scene_path != "" and ResourceLoader.exists(scene_path):
		var sc = load(scene_path)
		if sc:
			node = sc.instantiate()

	if node == null:
		node = _create_fallback_ingredient_node(item_id)

	if node is Patty:
		if data.has("meat_type"):
			node.meat_type = data["meat_type"]
		elif item_id == "patty_chicken":
			node.meat_type = Patty.MeatType.CHICKEN
		else:
			node.meat_type = Patty.MeatType.BEEF

		if data.has("state"):
			node.state = data["state"]
		if data.has("side_a_cooked"):
			node.side_a_cooked = data["side_a_cooked"]
		if data.has("side_b_cooked"):
			node.side_b_cooked = data["side_b_cooked"]
		if data.has("current_side_cooking"):
			node.current_side_cooking = data["current_side_cooking"]
		if data.has("is_flipped"):
			node.is_flipped = data["is_flipped"]
		if node.has_method("_update_visuals"):
			node._update_visuals()
	elif node is Bacon:
		if data.has("state"):
			node.state = data["state"]
		if data.has("cooking_progress"):
			node.cooking_progress = data["cooking_progress"]
		if node.has_method("_update_visuals"):
			node._update_visuals()
	elif node is Egg:
		if data.has("state"):
			node.state = data["state"]
		if data.has("cooking_progress"):
			node.cooking_progress = data["cooking_progress"]
		if node.has_method("_update_visuals"):
			node._update_visuals()
	elif node is Cheese:
		if data.has("cheese_type"):
			node.cheese_type = data["cheese_type"]
		elif item_id == "cheese_mozzarella":
			node.cheese_type = Cheese.CheeseType.MOZZARELLA
		elif item_id == "cheese_prato":
			node.cheese_type = Cheese.CheeseType.PRATO
		else:
			node.cheese_type = Cheese.CheeseType.CHEDDAR
		if data.has("state"):
			node.state = data["state"]
		if data.has("cook_progress"):
			node.cook_progress = data["cook_progress"]
		if node.has_method("_update_visuals"):
			node._update_visuals()
	elif node is Onion:
		if data.has("onion_type"):
			node.onion_type = data["onion_type"]
		elif item_id == "red_onion":
			node.onion_type = Onion.OnionType.RED
		else:
			node.onion_type = Onion.OnionType.NORMAL
	elif node is Potato:
		node.state = data.get("state", Potato.State.RAW)
	elif node is JuicePulp:
		if data.has("fruit_type"):
			node.fruit_type = data["fruit_type"]
		elif item_id.begins_with("pulp_"):
			node.fruit_type = item_id.replace("pulp_", "")
		elif item_id.begins_with("juice_pulp_"):
			node.fruit_type = item_id.replace("juice_pulp_", "")

	return node

func _create_fallback_ingredient_node(item_id: String) -> Node3D:
	var path = _get_default_scene_path(item_id)
	if path != "" and ResourceLoader.exists(path):
		var sc = load(path)
		if sc:
			return sc.instantiate()
	var fallback_item = load("res://src/items/item.tscn").instantiate()
	fallback_item.item_id = item_id
	return fallback_item

func _get_default_scene_path(item_id: String) -> String:
	match item_id:
		"patty_beef", "patty_chicken", "patty_raw", "patty": return "res://src/items/patty.tscn"
		"cheese", "cheese_cheddar", "cheese_mozzarella", "cheese_prato": return "res://src/items/cheese.tscn"
		"pickle": return "res://src/items/pickle.tscn"
		"tomato": return "res://src/items/tomato.tscn"
		"lettuce": return "res://src/items/lettuce.tscn"
		"onion", "white_onion", "red_onion": return "res://src/items/onion.tscn"
		"onion_rings_raw", "onion_bag": return "res://src/items/onion_bag.tscn"
		"bacon": return "res://src/items/bacon.tscn"
		"egg": return "res://src/items/egg.tscn"
		"bread", "bread_bottom": return "res://src/items/bread_bottom.tscn"
		"bread_top": return "res://src/items/bread_top.tscn"
		"potato_raw", "potato": return "res://src/items/potato.tscn"
		_:
			if item_id.begins_with("pulp_") or item_id.begins_with("juice_pulp"):
				return "res://src/items/juice_pulp.tscn"
			return "res://src/items/item.tscn"

func _get_item_canonical_id(item: Node3D) -> String:
	if item is Patty:
		return "patty_chicken" if item.meat_type == Patty.MeatType.CHICKEN else "patty_beef"
	if item is Cheese:
		if "cheese_type" in item:
			match item.cheese_type:
				Cheese.CheeseType.MOZZARELLA: return "cheese_mozzarella"
				Cheese.CheeseType.CHEDDAR: return "cheese_cheddar"
				Cheese.CheeseType.PRATO: return "cheese_prato"
		return "cheese_cheddar"
	if item is Pickle: return "pickle"
	if item is Tomato: return "tomato"
	if item is Lettuce: return "lettuce"
	if item is Onion:
		if item.onion_type == Onion.OnionType.RED:
			return "red_onion"
		return "onion"
	if item is Bacon: return "bacon"
	if item is Egg: return "egg"
	if item is Potato: return "potato_raw"
	if item is JuicePulp:
		match item.fruit_type:
			"orange", "laranja", "pulp_orange": return "pulp_orange"
			"strawberry", "morango", "pulp_strawberry": return "pulp_strawberry"
			"grape", "uva", "pulp_grape": return "pulp_grape"
			"lemon", "limao", "pulp_lemon": return "pulp_lemon"
		return "pulp_orange"
	if item is OnionBag or item.name.begins_with("OnionBag") or (item.scene_file_path and item.scene_file_path.contains("onion_bag")):
		return "onion_rings_raw"
	if item.scene_file_path and item.scene_file_path.contains("bread_top"):
		return "bread_top"
	if item.scene_file_path and item.scene_file_path.contains("bread_bottom"):
		return "bread_bottom"
	if item is Bread or item is BreadBottom: return "bread_bottom"
	if "item_id" in item and item.item_id != "" and item.item_id != "generic":
		return item.item_id
	return item.name.to_lower()

func _get_item_icon(item: Node3D) -> String:
	if item is Patty: return "🍗" if item.meat_type == Patty.MeatType.CHICKEN else "🥩"
	if item is Cheese: return "🧀"
	if item is Pickle: return "🥒"
	if item is Tomato: return "🍅"
	if item is Lettuce: return "🥬"
	if item is Onion: return "🧅"
	if item is Bacon: return "🥓"
	if item is Egg: return "🍳"
	if item is Potato: return "🥔"
	if item is JuicePulp:
		match item.fruit_type:
			"orange", "laranja", "pulp_orange": return "🍊"
			"strawberry", "morango", "pulp_strawberry": return "🍓"
			"grape", "uva", "pulp_grape": return "🍇"
			"lemon", "limao", "pulp_lemon": return "🍋"
		return "🧃"
	if item is Bread or item is BreadBottom: return "🍞"
	if item is ServingTray or item is OrderTray: return "🍱"
	if item is DeliveryBag: return "🛍️"
	if item is DrinkCup: return "🥤"
	if item is BurgerBox or item is DeliveryBox or item is PackagedBurger: return "📦"
	if item is CustomerMoney: return "💵"
	return "📦"

func _extract_item_data(item: Node3D) -> Dictionary:
	var data = {}
	if item is Patty:
		data["meat_type"] = item.meat_type
		data["state"] = item.state if ("state" in item) else 0
		data["side_a_cooked"] = item.side_a_cooked if ("side_a_cooked" in item) else 0.0
		data["side_b_cooked"] = item.side_b_cooked if ("side_b_cooked" in item) else 0.0
		data["current_side_cooking"] = item.current_side_cooking if ("current_side_cooking" in item) else 1
		data["is_flipped"] = item.is_flipped if ("is_flipped" in item) else false
	elif item is Bacon:
		data["state"] = item.state if ("state" in item) else 0
		data["cooking_progress"] = item.cooking_progress if ("cooking_progress" in item) else 0.0
	elif item is Egg:
		data["state"] = item.state if ("state" in item) else 0
		data["cooking_progress"] = item.cooking_progress if ("cooking_progress" in item) else 0.0
	elif item is Cheese:
		if "cheese_type" in item: data["cheese_type"] = item.cheese_type
		if "state" in item: data["state"] = item.state
		if "cook_progress" in item: data["cook_progress"] = item.cook_progress
	elif item is JuicePulp:
		data["fruit_type"] = item.fruit_type
	elif item is Potato:
		data["state"] = item.state if ("state" in item) else 0
	return data

func _notify_hud_quick_slots() -> void:
	if hud and hud.has_method("update_quick_slots_display"):
		hud.update_quick_slots_display(quick_slots, active_quick_slot, get_active_item_info(), active_tool_slot)

func get_active_item_info() -> Dictionary:
	if is_holding_large_item():
		var d_name = held_item.get_display_name() if held_item.has_method("get_display_name") else held_item.name
		return {
			"name": d_name,
			"icon": _get_item_icon(held_item),
			"count": 1,
			"is_large_item": true,
			"slot": -1
		}
	elif has_active_ingredient():
		var slot = quick_slots[active_quick_slot]
		return {
			"name": slot.get("display_name", ""),
			"icon": slot.get("icon", "📦"),
			"count": slot.get("count", 1),
			"is_large_item": false,
			"slot": active_quick_slot
		}
	return {}

func get_quick_slots_info() -> Array:
	return quick_slots.duplicate(true)

# ================================================================
# MANIPULAÇÃO DE ITENS (PICK UP / TAKE / DROP)
# ================================================================

func pick_up(item: Node3D) -> void:
	if item == null:
		return
	if "is_held" in item and item.is_held:
		return

	if active_tool_slot == ToolSlot.SPATULA and get_spatula_held_patty() != null:
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback("⚠️ Espátula ocupada com um hambúrguer! Deposite-o antes de pegar outro item.")
		return

	if active_tool_slot == ToolSlot.HANDS and item is Patty:
		var p_grill = item.get_parent()
		while p_grill != null:
			if p_grill is Grill:
				if hud and hud.has_method("show_temporary_feedback"):
					hud.show_temporary_feedback("⚠️ Alimento quente na chapa! Equipe a Espátula [Tecla 1] para retirar.")
				return
			p_grill = p_grill.get_parent()

	# 1. Se for compatível com Slots Rápidos de Ingredientes (4, 5, 6)
	if is_quick_slot_compatible(item):
		if is_holding_large_item() and not (held_item != null and held_item.get_meta("is_quick_slot_visual", false)):
			if hud and hud.has_method("show_temporary_feedback"):
				var h_name = held_item.get_display_name() if held_item.has_method("get_display_name") else held_item.name
				hud.show_temporary_feedback("⚠️ Mãos ocupadas com %s! Solte antes de pegar ingredientes." % h_name)
			return

		var ing_id = _get_item_canonical_id(item)
		var ing_name = item.get_display_name() if item.has_method("get_display_name") else item.name
		var ing_icon = _get_item_icon(item)
		var scene_path = item.scene_file_path if item.scene_file_path != "" else _get_default_scene_path(ing_id)

		# Busca o primeiro slot vazio (1 unidade física por slot)
		var target_slot = -1
		for i in range(quick_slots.size()):
			if quick_slots[i].is_empty():
				target_slot = i
				break

		# Se todos os 3 slots rápidos estão ocupados
		if target_slot == -1:
			if hud and hud.has_method("show_temporary_feedback"):
				hud.show_temporary_feedback("⚠️ Slots rápidos cheios (3/3)! Guarde ou use os ingredientes atuais.")
			return

		# Se a ferramenta atual for Bucha ou Espátula, muda para Mão Livre
		if active_tool_slot != ToolSlot.HANDS:
			select_tool_slot(ToolSlot.HANDS, false)

		# Armazena exatamente 1 unidade física no slot
		quick_slots[target_slot] = {
			"item_id": ing_id,
			"display_name": ing_name,
			"icon": ing_icon,
			"count": 1,
			"scene_path": scene_path,
			"data": _extract_item_data(item)
		}

		# Se estava dentro de uma bandeja, remove da lista da bandeja
		var tray_parent_qs: ServingTray = null
		var p_check_qs = item.get_parent()
		while p_check_qs != null:
			if p_check_qs is ServingTray:
				tray_parent_qs = p_check_qs as ServingTray
				break
			p_check_qs = p_check_qs.get_parent()
		if tray_parent_qs:
			tray_parent_qs.remove_product(item)

		# Remove o item do pai anterior
		if item.get_parent():
			item.get_parent().remove_child(item)

		# Ativa o slot e anexa este item à HandPosition
		active_quick_slot = target_slot
		if not hold_position:
			hold_position = get_node_or_null("Head/Camera3D/HoldPosition")

		# Se já existia um visual de outro quick slot na mão, remove-o
		if held_item != null and is_instance_valid(held_item) and held_item.get_meta("is_quick_slot_visual", false):
			if raycast and held_item is CollisionObject3D:
				raycast.remove_exception(held_item)
			if held_item.get_parent():
				held_item.get_parent().remove_child(held_item)
			held_item.queue_free()
			held_item = null

		item.set_meta("is_quick_slot_visual", true)
		item.set_meta("quick_slot_index", target_slot)
		held_item = item
		if hold_position:
			hold_position.add_child(item)
			item.position = Vector3.ZERO
			item.rotation = Vector3.ZERO
		if item.has_method("on_picked_up"):
			item.on_picked_up()
		elif item is CollisionObject3D:
			item.collision_layer = 0
			item.collision_mask = 0
		if raycast and item is CollisionObject3D:
			raycast.add_exception(item)

		_play_sound(item_audio, "item_pickup", -7.5, 0.05)
		_notify_hud_quick_slots()
		_update_interaction_detection()
		return

	# 2. Caso contrário: Objeto Grande / Único na Mão Principal
	if held_item != null and not held_item.get_meta("is_quick_slot_visual", false):
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback("⚠️ Mãos ocupadas!")
		return

	if held_item != null and is_instance_valid(held_item) and held_item.get_meta("is_quick_slot_visual", false):
		if raycast and held_item is CollisionObject3D:
			raycast.remove_exception(held_item)
		if held_item.get_parent():
			held_item.get_parent().remove_child(held_item)
		held_item.queue_free()
		held_item = null
		quick_slot_visual = null

	# Se estava dentro de uma bandeja, remove da lista da bandeja
	var tray_parent: ServingTray = null
	var p_check = item.get_parent()
	while p_check != null:
		if p_check is ServingTray:
			tray_parent = p_check as ServingTray
			break
		p_check = p_check.get_parent()
	if tray_parent:
		tray_parent.remove_product(item)

	# Se estava servido em uma mesa, remove da lista de itens servidos da mesa
	var table_parent: RestaurantTable = null
	var p_tbl = item.get_parent()
	while p_tbl != null:
		if p_tbl is RestaurantTable:
			table_parent = p_tbl as RestaurantTable
			break
		p_tbl = p_tbl.get_parent()
	if table_parent:
		table_parent.served_items.erase(item)

	# Se a ferramenta atual for Bucha, troca automaticamente para a Mão Livre
	if active_tool_slot == ToolSlot.SPONGE:
		select_tool_slot(ToolSlot.HANDS, false)
	elif active_tool_slot == ToolSlot.SPATULA and not can_be_picked_with_spatula(item):
		select_tool_slot(ToolSlot.HANDS, false)

	held_item = item
	if raycast and item is CollisionObject3D:
		raycast.add_exception(item)

	var previous_parent = item.get_parent()
	if previous_parent:
		item.owner = null
		previous_parent.remove_child(item)

	if not hold_position:
		hold_position = get_node_or_null("Head/Camera3D/HoldPosition")

	# Se estiver com a Espátula (Slot 1), assenta o item sobre a lâmina
	if active_tool_slot == ToolSlot.SPATULA and tool_holder and tool_holder.get_child_count() > 0:
		var spatula = tool_holder.get_child(0)
		var rest_pt = spatula.get_node_or_null("Model/BladeRestPoint")
		if rest_pt:
			rest_pt.add_child(item)
			item.position = Vector3.ZERO
			item.rotation = Vector3.ZERO
		elif hold_position:
			hold_position.add_child(item)
			item.position = Vector3.ZERO
			item.rotation = Vector3.ZERO
		else:
			add_child(item)
			item.position = Vector3.ZERO
			item.rotation = Vector3.ZERO
	elif hold_position:
		hold_position.add_child(item)
		item.position = Vector3.ZERO
		item.rotation = Vector3.ZERO
	else:
		add_child(item)
		item.position = Vector3.ZERO
		item.rotation = Vector3.ZERO

	_play_sound(item_audio, "item_pickup", -7.5, 0.05)

	if item.has_method("on_picked_up"):
		item.on_picked_up()
	elif item is CollisionObject3D:
		item.collision_layer = 0
		item.collision_mask = 0

	_notify_hud_quick_slots()
	_update_interaction_detection()

func take_held_item() -> Node3D:
	if has_active_ingredient():
		return consume_active_ingredient()

	if held_item != null:
		var item := held_item
		held_item = null
		quick_slot_visual = null
		if raycast and item is CollisionObject3D:
			raycast.remove_exception(item)

		if item.get_parent():
			item.get_parent().remove_child(item)

		if item.has_meta("is_quick_slot_visual"):
			item.remove_meta("is_quick_slot_visual")
		if item.has_meta("quick_slot_index"):
			item.remove_meta("quick_slot_index")

		if hold_position and is_instance_valid(hold_position):
			for child in hold_position.get_children():
				if child == item:
					continue
				child.queue_free()

		_notify_hud_quick_slots()
		_update_interaction_detection()
		_update_quick_slot_visual()
		return item

	return null

func drop_item() -> void:
	if held_item == null and not has_active_ingredient():
		return

	# Proteção estrita: Não pode soltar dinheiro de pagamento no chão ou mesas
	if held_item != null and (held_item.get("is_customer_deposit_money") == true or str(held_item.get("item_id")) == "customer_money"):
		if hud and hud.has_method("show_temporary_feedback"):
			hud.show_temporary_feedback("⚠️ O dinheiro do cliente deve ser depositado na caixa registradora!")
		return

	var item: Node3D = null
	if has_active_ingredient():
		item = consume_active_ingredient()
	elif held_item != null:
		item = held_item
		held_item = null
		quick_slot_visual = null

	if not item:
		return

	if raycast and item is CollisionObject3D:
		raycast.remove_exception(item)

	if item.has_meta("is_quick_slot_visual"):
		item.remove_meta("is_quick_slot_visual")
	if item.has_meta("quick_slot_index"):
		item.remove_meta("quick_slot_index")

	var current_item_world_pos: Vector3
	if item.is_inside_tree():
		current_item_world_pos = item.global_position
	elif hold_position and hold_position.is_inside_tree():
		current_item_world_pos = hold_position.global_position
	elif is_inside_tree():
		var forward_dir = -camera.global_transform.basis.z if (camera and camera.is_inside_tree()) else -transform.basis.z
		current_item_world_pos = global_position + forward_dir * 0.5 + Vector3.UP * 0.8
	else:
		current_item_world_pos = position + Vector3(0, 0.8, -0.5)

	# Encontra a superfície física para o drop: mira direta do RayCast3D
	var drop_pos = current_item_world_pos
	if is_inside_tree():
		if raycast and raycast.is_colliding():
			var col_pt = raycast.get_collision_point()
			var col_norm = raycast.get_collision_normal()
			if col_norm.y >= 0.15:
				drop_pos = col_pt + Vector3(0, 0.003, 0)
			else:
				drop_pos = col_pt + col_norm * 0.05
		else:
			# Fallback: raycast vertical para baixo a partir da posição da câmera/mão
			var world_3d = get_world_3d()
			if world_3d:
				var space_state = world_3d.direct_space_state
				var cam_pos = camera.global_position if (camera and camera.is_inside_tree()) else global_position
				var forward = -camera.global_transform.basis.z if (camera and camera.is_inside_tree()) else -transform.basis.z
				var ray_start = cam_pos + forward * 0.8
				var query = PhysicsRayQueryParameters3D.create(
					ray_start,
					ray_start + Vector3.DOWN * 4.0
				)
				if item is CollisionObject3D:
					query.exclude = [get_rid(), item.get_rid()]
				else:
					query.exclude = [get_rid()]
				var result = space_state.intersect_ray(query)
				if result:
					drop_pos = Vector3(ray_start.x, result.position.y + 0.003, ray_start.z)

	if item is DrinkCup:
		# Verifica se o drop foi em direção a uma máquina de bebidas para snap automático
		if raycast and raycast.is_colliding():
			var col_target = raycast.get_collider()
			if col_target:
				var mach = null
				if col_target.has_method("try_snap_cup"):
					mach = col_target
				elif col_target.get_parent() and col_target.get_parent().has_method("try_snap_cup"):
					mach = col_target.get_parent()
				elif col_target.get_parent() and col_target.get_parent().get_parent() and col_target.get_parent().get_parent().has_method("try_snap_cup"):
					mach = col_target.get_parent().get_parent()
				if mach and mach.try_snap_cup(item as DrinkCup, drop_pos):
					if active_quick_slot >= 0 and active_quick_slot < quick_slots.size():
						quick_slots[active_quick_slot] = {}
						active_quick_slot = -1
					_update_interaction_detection()
					_update_quick_slot_visual()
					return

	var drop_rot_y = rotation.y

	if item.get_parent():
		item.owner = null
		item.get_parent().remove_child(item)

	var world: Node = get_parent()
	if not world and is_inside_tree():
		world = get_tree().current_scene
	if not world and is_inside_tree():
		world = get_tree().root

	if world:
		world.add_child(item)
		if item.is_inside_tree():
			item.global_position = drop_pos
		else:
			item.position = drop_pos
		item.rotation = Vector3(0, drop_rot_y, 0)

	if item.has_method("on_dropped"):
		item.on_dropped()
	elif item.get("collision_shape") != null and item.collision_shape:
		item.collision_shape.disabled = false

	if "location" in item:
		item.location = Item.ItemLocation.WORLD

	_play_sound(item_audio, "item_drop", -8.0, 0.05)
	_notify_hud_quick_slots()
	_update_interaction_detection()
	_update_quick_slot_visual()

# ================================================================
# PROCESSAMENTO DE LIMPEZA CONTÍNUA (BUCHA DE LIMPEZA)
# ================================================================
var _is_scrubbing_audio_playing: bool = false

func _process_sponge_cleaning(delta: float) -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_stop_scrubbing_audio()
		return

	if not raycast or not raycast.is_colliding():
		_stop_scrubbing_audio()
		return

	var raw_collider = raycast.get_collider()
	var collider = _get_target_interactable(raw_collider) if raw_collider else null
	if not collider:
		_stop_scrubbing_audio()
		return

	var sponge: Sponge = null
	if tool_holder and tool_holder.get_child_count() > 0:
		sponge = tool_holder.get_child(0) as Sponge

	# 1. Se estiver na Pia (CommercialSink): lava a bucha
	if collider is CommercialSink or (collider.get_parent() and collider.get_parent() is CommercialSink):
		var sink = collider if collider is CommercialSink else collider.get_parent()
		sink.wash_or_sanitize(self)
		_stop_scrubbing_audio()
		return

	# 2. Resolução de alvos limpáveis (Mesas, Grelha, Poças, Chão, Bancada, Fritadeira)
	var cleanable_target = null
	if collider and collider.has_method("clean_progress"):
		cleanable_target = collider
	elif raw_collider and raw_collider.has_method("clean_progress"):
		cleanable_target = raw_collider
	else:
		var curr = raw_collider
		while curr != null:
			if curr is Node and curr.has_method("clean_progress"):
				cleanable_target = curr
				break
			curr = curr.get_parent() if curr is Node else null

	if cleanable_target:
		var is_target_dirty = false
		if cleanable_target.has_method("is_dirty") and cleanable_target.is_dirty():
			is_target_dirty = true
		elif cleanable_target.has_method("get_dirt_level") and cleanable_target.get_dirt_level() > 0.001:
			is_target_dirty = true

		if cleanable_target is RestaurantTable and cleanable_target.has_tray_on_table():
			is_target_dirty = false

		if is_target_dirty:
			if sponge:
				if sponge.is_dirty:
					if hud and hud.has_method("show_temporary_feedback"):
						hud.show_temporary_feedback("⚠️ Bucha suja! Lave-a na pia da cozinha antes de limpar.")
					_stop_scrubbing_audio()
					return

				# Bucha limpa executando a limpeza
				_play_scrubbing_audio()
				sponge.play_scrub_animation()
				var is_finished = cleanable_target.clean_progress(delta, self)
				if is_finished:
					sponge.set_dirty()
					_stop_scrubbing_audio()
					if hud and hud.has_method("show_temporary_feedback"):
						hud.show_temporary_feedback("✨ Limpeza concluída! A bucha ficou suja.")
			return
		else:
			_stop_scrubbing_audio()
			return

	_stop_scrubbing_audio()

func _play_scrubbing_audio() -> void:
	if not _is_scrubbing_audio_playing:
		_is_scrubbing_audio_playing = true
		if tool_audio:
			tool_audio.stream = SoundSynthesizer.get_stream("sponge_scrub_loop")
			tool_audio.volume_db = -6.0
			tool_audio.play()

func _stop_scrubbing_audio() -> void:
	if _is_scrubbing_audio_playing:
		_is_scrubbing_audio_playing = false
		if tool_audio and tool_audio.playing:
			tool_audio.stop()

	var tool_holder = get_node_or_null("Head/Camera3D/ToolHolder")
	if tool_holder and tool_holder.get_child_count() > 0:
		var sp = tool_holder.get_child(0)
		if sp and sp.has_method("stop_scrub_continuous"):
			sp.stop_scrub_continuous()

	_update_interaction_detection()
