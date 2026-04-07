extends Node

@export var escena_enemigo: PackedScene
var tiempo_entre_spawns: float = 2.0
var timer_spawn: float = 0.0
var direccion_jugador: Vector2 = Vector2.ZERO
var posicion_anterior: Vector2 = Vector2.ZERO

@onready var pantalla_preguntas = $PantallaPreguntas
@onready var pantalla_poderes = $PantallaSeleccionPoder

# Poderes disponibles
var ventajas = [
	{"nombre": "⚔️ Daño+", "descripcion": "+25% daño", "tipo": "danio", "valor": 0.25},
	{"nombre": "💨 Velocidad+", "descripcion": "+20% velocidad", "tipo": "velocidad", "valor": 0.20},
	{"nombre": "🔥 Cadencia+", "descripcion": "-20% tiempo entre ataques", "tipo": "cadencia", "valor": -0.20},
	{"nombre": "❤️ Vida+", "descripcion": "+30 vida máxima", "tipo": "vida", "valor": 30.0},
	{"nombre": "🎯 Rango+", "descripcion": "+100 rango de ataque", "tipo": "rango", "valor": 100.0},
]

var desventajas = [
	{"nombre": "🐢 Lento", "descripcion": "-20% velocidad", "tipo": "velocidad", "valor": -0.20},
	{"nombre": "💔 Daño-", "descripcion": "-25% daño", "tipo": "danio", "valor": -0.25},
	{"nombre": "🐌 Cadencia-", "descripcion": "+30% tiempo entre ataques", "tipo": "cadencia", "valor": 0.30},
]

func _ready() -> void:
	EventBus.jugador_subio_nivel.connect(_on_jugador_subio_nivel)
	pantalla_preguntas.pregunta_respondida.connect(_on_pregunta_respondida)
	pantalla_poderes.poder_elegido.connect(_on_poder_elegido)

func _process(delta: float) -> void:
	_actualizar_direccion_jugador()
	timer_spawn += delta
	if timer_spawn >= tiempo_entre_spawns:
		timer_spawn = 0.0
		_spawnear_enemigo()

func _on_jugador_subio_nivel() -> void:
	var fase = EstadoJuego.get_fase_actual()
	var pregunta = GestorPreguntas.obtener_pregunta(fase)
	if pregunta.is_empty():
		return
	pantalla_preguntas.mostrar_pregunta(pregunta)

func _on_pregunta_respondida(correcta: bool) -> void:
	var pool = ventajas if correcta else desventajas
	pool.shuffle()
	var seleccion = pool.slice(0, 3)
	pantalla_poderes.mostrar_poderes(seleccion, correcta)

func _on_poder_elegido(poder: Dictionary) -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return
	match poder.tipo:
		"danio":
			jugador.danio_ataque *= (1.0 + poder.valor)
		"velocidad":
			jugador.VELOCIDAD *= (1.0 + poder.valor) # Nota: cambiar VELOCIDAD a var
		"cadencia":
			jugador.cadencia *= (1.0 + poder.valor)
		"vida":
			jugador.vida_maxima += poder.valor
			jugador.vida = min(jugador.vida + poder.valor, jugador.vida_maxima)
		"rango":
			jugador.rango_ataque += poder.valor

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
	var angulo_base: float
	if direccion_jugador.length() > 0.1 and randf() < 0.7:
		angulo_base = direccion_jugador.angle()
		angulo_base += randf_range(-0.6, 0.6)
	else:
		angulo_base = randf() * TAU
	var lado = _angulo_a_lado(angulo_base)
	var pos = Vector2.ZERO
	match lado:
		0: pos = Vector2(randf_range(-mitad_w, mitad_w), -mitad_h)
		1: pos = Vector2(randf_range(-mitad_w, mitad_w), mitad_h)
		2: pos = Vector2(-mitad_w, randf_range(-mitad_h, mitad_h))
		3: pos = Vector2(mitad_w, randf_range(-mitad_h, mitad_h))
	var enemigo = escena_enemigo.instantiate()
	enemigo.global_position = jugador.global_position + pos
	get_tree().current_scene.add_child(enemigo)

func _angulo_a_lado(angulo: float) -> int:
	var grados = fmod(rad_to_deg(angulo) + 360.0, 360.0)
	if grados < 45 or grados >= 315:
		return 3
	elif grados < 135:
		return 1
	elif grados < 225:
		return 2
	else:
		return 0
