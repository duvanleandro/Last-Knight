extends Node

@export var escena_enemigo_basico: PackedScene
@export var escena_enemigo_rapido: PackedScene
@export var escena_enemigo_tanque: PackedScene
@export var escena_enemigo_especial: PackedScene

var tiempo_entre_spawns: float = 2.0
var timer_spawn: float = 0.0
var direccion_jugador: Vector2 = Vector2.ZERO
var posicion_anterior: Vector2 = Vector2.ZERO

@onready var pantalla_preguntas = $PantallaPreguntas
@onready var pantalla_poderes = $PantallaSeleccionPoder
@onready var menu_pausa = $MenuPausa

var ventajas = [
	{"nombre": "⚔️ Daño+", "descripcion": "+25% daño", "tipo": "danio", "valor": 0.25},
	{"nombre": "💨 Velocidad+", "descripcion": "+20% velocidad", "tipo": "velocidad", "valor": 0.20},
	{"nombre": "🔥 Cadencia+", "descripcion": "-20% tiempo entre ataques", "tipo": "cadencia", "valor": -0.20},
	{"nombre": "❤️ Vida+", "descripcion": "+30 vida máxima", "tipo": "vida", "valor": 30.0},
	{"nombre": "🔱 Penetración+", "descripcion": "", "tipo": "penetracion", "valor": 1},
	{"nombre": "🛡️ Escudo+", "descripcion": "", "tipo": "escudo", "valor": 1},
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
	if OS.is_debug_build() and Input.is_action_just_pressed("ui_page_down"):
		EstadoJuego.tiempo_transcurrido += 300.0
	_actualizar_direccion_jugador()
	_actualizar_dificultad()
	timer_spawn += delta
	if timer_spawn >= tiempo_entre_spawns:
		timer_spawn = 0.0
		_spawnear_enemigo()

func _actualizar_dificultad() -> void:
	var fase = EstadoJuego.get_fase_actual()
	match fase:
		1: tiempo_entre_spawns = 1.5
		2: tiempo_entre_spawns = 1.4
		3: tiempo_entre_spawns = 0.9
		4: tiempo_entre_spawns = 0.5

func _elegir_escena_enemigo() -> PackedScene:
	var fase = EstadoJuego.get_fase_actual()
	var opciones: Array = []
	match fase:
		1:
			opciones = [
				escena_enemigo_basico, escena_enemigo_basico, escena_enemigo_basico
			]
		2:
			opciones = [
				escena_enemigo_basico, escena_enemigo_basico,
				escena_enemigo_rapido, escena_enemigo_tanque
			]
		3:
			opciones = [
				escena_enemigo_basico, escena_enemigo_rapido,
				escena_enemigo_tanque, escena_enemigo_especial
			]
		4:
			opciones = [
				escena_enemigo_rapido, escena_enemigo_rapido,
				escena_enemigo_tanque, escena_enemigo_especial,
				escena_enemigo_especial
			]
	return opciones[randi() % opciones.size()]

func _on_jugador_subio_nivel() -> void:
	var fase = EstadoJuego.get_fase_actual()
	var pregunta = GestorPreguntas.obtener_pregunta(fase)
	if pregunta.is_empty():
		return
	pantalla_preguntas.mostrar_pregunta(pregunta)

func _on_pregunta_respondida(correcta: bool) -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador:
		var siguiente = jugador.penetracion_parcial + 0.25
		var porcentaje: int
		if siguiente >= 1.0:
			porcentaje = 100
		else:
			porcentaje = int(siguiente * 100)
		var num_enemigo = jugador.penetracion_completos + 2
		for poder in ventajas:
			if poder.tipo == "penetracion":
				poder.descripcion = "Daño al %dº enemigo: %d%%" % [num_enemigo, porcentaje]
			elif poder.tipo == "escudo":
				var nv = jugador.escudo_nivel
				if nv == 0:
					poder.descripcion = "Absorbe 1 golpe, se regenera"
				elif nv == 1:
					poder.descripcion = "Sube a 2 golpes + empuje al recibir"
				elif nv == 2:
					poder.descripcion = "Sube a 3 golpes + daño al romperse"
				else:
					poder.descripcion = "Regeneracion mas rapida"
	var pool = ventajas if correcta else desventajas
	pool.shuffle()
	var seleccion = pool.slice(0, 3)
	pantalla_poderes.mostrar_poderes(seleccion, correcta)

func _on_poder_elegido(poder: Dictionary) -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return
	EstadoJuego.poderes_activos.append(poder.nombre)
	match poder.tipo:
		"danio":
			jugador.danio_ataque *= (1.0 + poder.valor)
		"velocidad":
			jugador.VELOCIDAD *= (1.0 + poder.valor)
		"cadencia":
			jugador.cadencia *= (1.0 + poder.valor)
		"vida":
			jugador.vida_maxima += poder.valor
			jugador.vida = min(jugador.vida + poder.valor, jugador.vida_maxima)
		"escudo":
			jugador.escudo_nivel += 1
			jugador.escudo_golpes_max = jugador.escudo_nivel
			jugador.escudo_golpes_actual = jugador.escudo_golpes_max
			jugador.escudo_roto = false
			jugador.escudo_timer = 0.0
			if jugador.escudo_nivel >= 4:
				var reduccion = (jugador.escudo_nivel - 3) * 3
				jugador.escudo_danio_ruptura += 20.0
		"penetracion":
			if jugador.penetracion_completos == 0 and jugador.penetracion_parcial == 0.0:
				# Primer upgrade: activa penetracion, 1 completo + 25% al siguiente
				jugador.penetracion_completos = 1
				jugador.penetracion_parcial = 0.25
			else:
				jugador.penetracion_parcial += 0.25
				if jugador.penetracion_parcial >= 1.0:
					# El parcial llego al 100%, se convierte en completo
					jugador.penetracion_completos += 1
					jugador.penetracion_parcial = 0.25

func _actualizar_direccion_jugador() -> void:
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador == null:
		return
	var movimiento = jugador.global_position - posicion_anterior
	if movimiento.length() > 1.0:
		direccion_jugador = movimiento.normalized()
	posicion_anterior = jugador.global_position

func _spawnear_enemigo() -> void:
	var escena = _elegir_escena_enemigo()
	if escena == null:
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
	var enemigo = escena.instantiate()
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
