class_name TrashBin
extends StaticBody3D

# ================================================================
# LIXEIRA DO RESTAURANTE (DESCARTE SIMPLES COM SOM NATURAL)
#
# Objeto físico do cenário para descarte direto de itens.
# Sem cálculos de prejuízo, multas ou valores financeiros.
# ================================================================

const SoundSynthesizer = preload("res://src/audio/sound_synthesizer.gd")

@onready var audio_player: AudioStreamPlayer3D = get_node_or_null("AudioPlayer")

func _ready() -> void:
	if not audio_player:
		audio_player = AudioStreamPlayer3D.new()
		audio_player.name = "AudioPlayer"
		audio_player.unit_size = 4.0
		audio_player.max_distance = 18.0
		audio_player.volume_db = -5.0
		add_child(audio_player)

func get_interaction_prompt(player: Node = null) -> String:
	if player:
		if player.get("held_item") != null:
			var held = player.get("held_item")
			var name_str = held.get_display_name() if held.has_method("get_display_name") else "Item"
			return "E — Descartar %s" % name_str
		elif player.has_method("has_active_ingredient") and player.has_active_ingredient():
			var act = player.get_active_ingredient()
			var name_str = act.get("display_name", "Ingrediente")
			return "E — Descartar %s" % name_str
	return ""

func interact(player: Node3D) -> void:
	if not player:
		return

	if player.get("held_item") != null and player.has_method("take_held_item"):
		var held = player.take_held_item()
		if not held:
			return

		var item_name = held.get_display_name() if held.has_method("get_display_name") else "Item"

		# Reproduz som natural e discreto de descarte na lixeira
		_play_dispose_sound()

		# Descarte direto e simples do item
		held.queue_free()
		_show_feedback(player, "🗑️ %s descartado." % item_name)
	elif player.has_method("has_active_ingredient") and player.has_active_ingredient() and player.has_method("consume_active_ingredient"):
		var act = player.get_active_ingredient()
		var item_name = act.get("display_name", "Ingrediente")
		var node = player.consume_active_ingredient()
		if node:
			node.queue_free()
		_play_dispose_sound()
		_show_feedback(player, "🗑️ %s descartado." % item_name)

func _play_dispose_sound() -> void:
	if not audio_player:
		audio_player = get_node_or_null("AudioPlayer")
	if audio_player:
		audio_player.stream = SoundSynthesizer.get_stream("trash_dispose")
		audio_player.pitch_scale = randf_range(0.96, 1.04)
		audio_player.play()

func _show_feedback(player: Node3D, message: String) -> void:
	var hud = player.get_node_or_null("HUD")
	if hud and hud.has_method("show_temporary_feedback"):
		hud.show_temporary_feedback(message)
