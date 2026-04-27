extends CharacterBody2D

var velocidad: float = 0.0
var danio: float = 0.0
var vida: float = 0.0
var vida_maxima: float = 0.0
var xp_al_morir: float = 0.0
var jugador: Node2D = null
var timer_danio: float = 0.0
var cadencia_danio: float = 1.5

@onready var barra_vida = $BarraVida

func _ready() -> void:
	add_to_group("enemigos")
	var fase = EstadoJuego.get_fase_actual()
	var nivel = EstadoJuego.nivel_jugador
	var escala = 1.0 + (fase - 1) * 0.4 + nivel * 0.07
	velocidad = 35.0 * escala
	danio = 25.0 * escala
	vida = 150.0 * escala
	vida_maxima = vida
	xp_al_morir = 25.0 * escala

func _physics_process(delta: float) -> void:
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
		return
	var direccion = (jugador.global_position - global_position).normalized()
	if empuje.length() > 10.0:
		empuje = empuje.lerp(Vector2.ZERO, 0.15)
		velocity = empuje
	else:
		empuje = Vector2.ZERO
		velocity = direccion * velocidad
	move_and_slide()
	var distancia = global_position.distance_to(jugador.global_position)
	if distancia < 40.0:
		jugador.aplicar_knockback(global_position)
	timer_danio += delta
	if timer_danio >= cadencia_danio:
		if distancia < 40.0:
			jugador.recibir_danio(danio, global_position)
			timer_danio = 0.0

var empuje: Vector2 = Vector2.ZERO

func recibir_empuje(fuerza: Vector2) -> void:
	empuje = fuerza

func recibir_danio(cantidad: float) -> void:
	vida -= cantidad
	barra_vida.actualizar(vida, vida_maxima)
	if vida <= 0:
		_morir()

func _morir() -> void:
	var j = get_tree().get_first_node_in_group("jugador")
	if j:
		j.agregar_xp(xp_al_morir)
	queue_free()
