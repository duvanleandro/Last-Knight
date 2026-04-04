extends CharacterBody2D

var velocidad: float = 60.0
var danio: float = 10.0
var vida: float = 30.0
var vida_maxima: float = 30.0
var xp_al_morir: float = 10.0
var jugador: Node2D = null
var timer_danio: float = 0.0
var cadencia_danio: float = 1.0

@onready var barra_vida = $BarraVida

func _ready() -> void:
	add_to_group("enemigos")

func _physics_process(delta: float) -> void:
	if jugador == null:
		jugador = get_tree().get_first_node_in_group("jugador")
		return
	var direccion = (jugador.global_position - global_position).normalized()
	velocity = direccion * velocidad
	move_and_slide()

	# Hacer daño al jugador si está cerca
	timer_danio += delta
	if timer_danio >= cadencia_danio:
		var distancia = global_position.distance_to(jugador.global_position)
		if distancia < 32.0:
			jugador.recibir_danio(danio)
			timer_danio = 0.0

func recibir_danio(cantidad: float) -> void:
	vida -= cantidad
	barra_vida.actualizar(vida, vida_maxima)
	if vida <= 0:
		_morir()

func _morir() -> void:
	var jugador_node = get_tree().get_first_node_in_group("jugador")
	if jugador_node:
		jugador_node.agregar_xp(xp_al_morir)
	queue_free()
