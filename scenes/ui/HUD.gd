extends CanvasLayer

@onready var label_nivel: Label = $VBoxContainer/LabelNivel
@onready var barra_xp: ProgressBar = $VBoxContainer/BarraXP
@onready var label_tiempo: Label = $VBoxContainer/LabelTiempo
@onready var label_fase: Label = $VBoxContainer/LabelFase
@onready var escudo_hud: Control = $EscudoHUD
@onready var arco_recarga: TextureProgressBar = $EscudoHUD/ArcoRecarga
@onready var label_golpes: Label = $EscudoHUD/LabelGolpes

var nombres_fases = {
	1: "⚔️ Fase 1 — Inicio",
	2: "🔥 Fase 2 — Desarrollo",
	3: "💀 Fase 3 — Intensidad",
	4: "👹 Fase 4 — Finalización"
}

# Colores por golpe restante
var colores_escudo = [
	Color(1.0, 0.2, 0.2),   # rojo  — último golpe
	Color(1.0, 0.85, 0.0),  # amarillo — golpe intermedio
	Color(0.2, 1.0, 0.3),   # verde — golpe lleno
]

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

	# Escudo
	_actualizar_escudo_hud()

func _actualizar_escudo_hud() -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null or jugador.escudo_nivel == 0:
		escudo_hud.visible = false
		return

	escudo_hud.visible = true
	var golpes_max = jugador.escudo_golpes_max
	var golpes_actual = jugador.escudo_golpes_actual
	var timer = jugador.escudo_timer
	var duracion = 30.0 if jugador.escudo_roto else 15.0

	# Color según golpes restantes
	var idx = clamp(golpes_actual - 1, 0, colores_escudo.size() - 1)
	if golpes_actual == 0:
		# Roto — mostrar recarga en gris
		arco_recarga.modulate = Color(0.5, 0.5, 0.5)
	else:
		arco_recarga.modulate = colores_escudo[idx]

	# Arco de recarga
	if golpes_actual >= golpes_max:
		# Escudo completo — arco lleno
		arco_recarga.value = 100.0
	else:
		# Mostrando recarga — arco se llena conforme pasa el tiempo
		var progreso = 1.0 - (timer / duracion)
		arco_recarga.value = progreso * 100.0

	# Etiqueta central
	if golpes_actual == 0:
		var segundos_restantes = int(ceil(timer))
		label_golpes.text = str(segundos_restantes)
	else:
		label_golpes.text = "🛡" if golpes_actual == golpes_max else "🛡 %d" % golpes_actual
