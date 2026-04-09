extends CanvasLayer

@onready var label_nivel: Label = $VBoxContainer/LabelNivel
@onready var barra_xp: ProgressBar = $VBoxContainer/BarraXP
@onready var label_tiempo: Label = $VBoxContainer/LabelTiempo
@onready var label_fase: Label = $VBoxContainer/LabelFase

var nombres_fases = {
	1: "⚔️ Fase 1 — Inicio",
	2: "🔥 Fase 2 — Desarrollo",
	3: "💀 Fase 3 — Intensidad",
	4: "👹 Fase 4 — Finalización"
}

func _process(delta: float) -> void:
	if not is_instance_valid(label_nivel) or not is_instance_valid(barra_xp):
		return
	
	# Nivel y XP
	label_nivel.text = "Nivel " + str(EstadoJuego.nivel_jugador)
	barra_xp.max_value = EstadoJuego.xp_para_siguiente_nivel
	barra_xp.value = EstadoJuego.xp_jugador
	
	# Cronómetro
	var segundos_totales = int(EstadoJuego.tiempo_transcurrido)
	var minutos = segundos_totales / 60
	var segundos = segundos_totales % 60
	label_tiempo.text = "⏱ %02d:%02d" % [minutos, segundos]
	
	# Fase actual
	var fase = EstadoJuego.get_fase_actual()
	label_fase.text = nombres_fases[fase]
