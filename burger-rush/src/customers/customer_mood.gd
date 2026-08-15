class_name CustomerMood
extends RefCounted

# Sistema de Humor Reativo e Dinâmico do Cliente
enum MoodState {
	VERY_HAPPY,            # 85 - 100
	HAPPY,                 # 70 - 84
	SATISFIED,             # 55 - 69
	NEUTRAL,               # 40 - 54
	IMPATIENT,             # 25 - 39
	ANGRY,                 # 15 - 24
	VERY_ANGRY,            # 5 - 14
	EXTREMELY_FRUSTRATED   # 0 - 4
}

var current_mood: float = 100.0
var decay_multiplier: float = 1.0
var initial_mood: float = 100.0

func _init(p_initial_mood: float = 100.0, p_decay_multiplier: float = 1.0) -> void:
	current_mood = clampf(p_initial_mood, 0.0, 100.0)
	initial_mood = current_mood
	decay_multiplier = p_decay_multiplier

func get_state() -> MoodState:
	if current_mood >= 85.0:
		return MoodState.VERY_HAPPY
	elif current_mood >= 70.0:
		return MoodState.HAPPY
	elif current_mood >= 55.0:
		return MoodState.SATISFIED
	elif current_mood >= 40.0:
		return MoodState.NEUTRAL
	elif current_mood >= 25.0:
		return MoodState.IMPATIENT
	elif current_mood >= 15.0:
		return MoodState.ANGRY
	elif current_mood >= 5.0:
		return MoodState.VERY_ANGRY
	else:
		return MoodState.EXTREMELY_FRUSTRATED

func get_label() -> String:
	match get_state():
		MoodState.VERY_HAPPY:
			return "Muito Feliz"
		MoodState.HAPPY:
			return "Feliz"
		MoodState.SATISFIED:
			return "Satisfeito"
		MoodState.NEUTRAL:
			return "Neutro"
		MoodState.IMPATIENT:
			return "Impaciente"
		MoodState.ANGRY:
			return "Irritado"
		MoodState.VERY_ANGRY:
			return "Muito Irritado"
		MoodState.EXTREMELY_FRUSTRATED:
			return "Extremamente Frustrado"
	return "Neutro"

func get_emoji() -> String:
	match get_state():
		MoodState.VERY_HAPPY:
			return "😄"
		MoodState.HAPPY:
			return "😊"
		MoodState.SATISFIED:
			return "🙂"
		MoodState.NEUTRAL:
			return "😐"
		MoodState.IMPATIENT:
			return "😒"
		MoodState.ANGRY:
			return "😠"
		MoodState.VERY_ANGRY:
			return "😡"
		MoodState.EXTREMELY_FRUSTRATED:
			return "🤬"
	return "🙂"

func get_color() -> Color:
	match get_state():
		MoodState.VERY_HAPPY:
			return Color(0.2, 0.9, 0.4) # Verde brilhante
		MoodState.HAPPY:
			return Color(0.4, 0.85, 0.4)
		MoodState.SATISFIED:
			return Color(0.7, 0.85, 0.3)
		MoodState.NEUTRAL:
			return Color(0.95, 0.85, 0.2) # Amarelo
		MoodState.IMPATIENT:
			return Color(0.95, 0.65, 0.2) # Laranja claro
		MoodState.ANGRY:
			return Color(0.95, 0.45, 0.2) # Laranja escuro
		MoodState.VERY_ANGRY:
			return Color(0.95, 0.25, 0.2) # Vermelho
		MoodState.EXTREMELY_FRUSTRATED:
			return Color(0.85, 0.10, 0.10) # Vermelho escuro
	return Color(1, 1, 1)

func decay(amount: float) -> void:
	current_mood = maxf(0.0, current_mood - (amount * decay_multiplier))

# Decaimento progressivo em fases com carência inicial permissiva:
# Fase 1 (0% a 35%): Tolerância total (decaimento quase nulo)
# Fase 2 (35% a 65%): Espera normal (decaimento suave)
# Fase 3 (65% a 85%): Impaciência (decaimento moderado)
# Fase 4 (85% a 95%): Irritação (decaimento acentuado)
# Fase 5 (95%+): Limite crítico / Abandono
func decay_progressively(elapsed_time: float, tolerance_time: float, delta: float) -> void:
	if tolerance_time <= 0.0:
		decay(delta * 10.0)
		return

	var progress = elapsed_time / tolerance_time
	var base_rate = (100.0 / tolerance_time) * delta

	var phase_factor = 1.0
	if progress < 0.35:
		phase_factor = 0.08 # Fase 1: Carência inicial permissiva
	elif progress < 0.65:
		phase_factor = 0.60 # Fase 2: Espera aceitável
	elif progress < 0.85:
		phase_factor = 1.40 # Fase 3: Impaciência perceptível
	elif progress < 0.95:
		phase_factor = 2.20 # Fase 4: Irritação clara
	else:
		phase_factor = 3.50 # Fase 5: Limite crítico

	decay(base_rate * phase_factor)

func boost(amount: float) -> void:
	current_mood = minf(100.0, current_mood + amount)

func is_critical() -> bool:
	return current_mood <= 20.0

func is_exhausted() -> bool:
	return current_mood <= 0.0
