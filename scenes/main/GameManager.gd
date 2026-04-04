extends Node

@export var escena_enemigo: PackedScene
var tiempo_entre_spawns: float = 2.0
var timer_spawn: float = 0.0
var direccion_jugador: Vector2 = Vector2.ZERO
var posicion_anterior: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	_actualizar_direccion_jugador()
	timer_spawn += delta
	if timer_spawn >= tiempo_entre_spawns:
		timer_spawn = 0.0
		_spawnear_enemigo()

func _actualizar_direccion_jugador() -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return
	var movimiento = jugador.global_position - posicion_anterior
	if movimiento.length() > 1.0:
		direccion_jugador = movimiento.normalized()
	posicion_anterior = jugador.global_position

func _spawnear_enemigo() -> void:
	if escena_enemigo == null:
		return
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return

	var tamano_pantalla = get_viewport().get_visible_rect().size
	var mitad_w = tamano_pantalla.x / 2.0 + 80.0
	var mitad_h = tamano_pantalla.y / 2.0 + 80.0

	# 70% de probabilidad de spawnear hacia donde se mueve el jugador
	var angulo_base: float
	if direccion_jugador.length() > 0.1 and randf() < 0.7:
		angulo_base = direccion_jugador.angle()
		angulo_base += randf_range(-0.6, 0.6) # pequeña variación
	else:
		angulo_base = randf() * TAU # dirección completamente aleatoria

	var lado = _angulo_a_lado(angulo_base)
	var pos = Vector2.ZERO

	match lado:
		0: # arriba
			pos = Vector2(randf_range(-mitad_w, mitad_w), -mitad_h)
		1: # abajo
			pos = Vector2(randf_range(-mitad_w, mitad_w), mitad_h)
		2: # izquierda
			pos = Vector2(-mitad_w, randf_range(-mitad_h, mitad_h))
		3: # derecha
			pos = Vector2(mitad_w, randf_range(-mitad_h, mitad_h))

	var enemigo = escena_enemigo.instantiate()
	enemigo.global_position = jugador.global_position + pos
	get_tree().current_scene.add_child(enemigo)

func _angulo_a_lado(angulo: float) -> int:
	# Convierte un ángulo a uno de los 4 lados (0=arriba,1=abajo,2=izq,3=der)
	var grados = fmod(rad_to_deg(angulo) + 360.0, 360.0)
	if grados < 45 or grados >= 315:
		return 3 # derecha
	elif grados < 135:
		return 1 # abajo
	elif grados < 225:
		return 2 # izquierda
	else:
		return 0 # arriba
