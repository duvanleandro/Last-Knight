extends CanvasLayer

@onready var label_nivel: Label = $VBoxContainer/LabelNivel
@onready var barra_xp: ProgressBar = $VBoxContainer/BarraXP

func _process(delta: float) -> void:
	if not is_instance_valid(label_nivel) or not is_instance_valid(barra_xp):
		return
	label_nivel.text = "Nivel " + str(EstadoJuego.nivel_jugador)
	barra_xp.max_value = EstadoJuego.xp_para_siguiente_nivel
	barra_xp.value = EstadoJuego.xp_jugador
