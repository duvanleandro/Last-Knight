extends CharacterBody2D

var VELOCIDAD = 200.0
var vida: float = 100.0
var vida_maxima: float = 100.0
var danio_ataque: float = 25.0
var cadencia: float = 0.5
var timer_ataque: float = 0.0
var penetracion_completos: int = 0
var penetracion_parcial: float = 0.0

# Escudo
var escudo_nivel: int = 0
var escudo_golpes_max: int = 0
var escudo_golpes_actual: int = 0
var escudo_timer: float = 0.0
var escudo_roto: bool = false
var escudo_radio_empuje: float = 150.0
var escudo_danio_ruptura: float = 60.0
var knockback_velocidad: Vector2 = Vector2.ZERO
var knockback_fuerza: float = 800.0

@export var escena_proyectil: PackedScene
@onready var barra_vida = $BarraVida

func _ready() -> void:
	add_to_group("jugador")

func _physics_process(delta: float) -> void:
	_mover(delta)
	_atacar(delta)
	_actualizar_escudo(delta)

func _mover(delta: float) -> void:
	var direccion = Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direccion.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direccion.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direccion.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direccion.y -= 1
	if direccion != Vector2.ZERO:
		direccion = direccion.normalized()
	if knockback_velocidad.length() > 1.0:
		knockback_velocidad *= 0.85
		velocity = knockback_velocidad + (direccion * VELOCIDAD * 0.3)
	else:
		knockback_velocidad = Vector2.ZERO
		velocity = direccion * VELOCIDAD
	move_and_slide()

func _atacar(delta: float) -> void:
	timer_ataque += delta
	if timer_ataque < cadencia:
		return
	if not Input.is_action_pressed("click_izquierdo"):
		return
	if escena_proyectil == null:
		return
	var pos_mouse = get_global_mouse_position()
	var direccion = (pos_mouse - global_position).normalized()
	var proyectil = escena_proyectil.instantiate()
	get_tree().current_scene.add_child(proyectil)
	proyectil.inicializar(global_position, direccion, danio_ataque, penetracion_completos, penetracion_parcial)
	timer_ataque = 0.0

func aplicar_knockback(origen: Vector2) -> void:
	knockback_velocidad = (global_position - origen).normalized() * knockback_fuerza

func recibir_danio(cantidad: float, origen: Vector2 = Vector2.ZERO) -> void:
	if escudo_absorber_golpe():
		return
	vida -= cantidad
	if origen != Vector2.ZERO:
		knockback_velocidad = (global_position - origen).normalized() * knockback_fuerza
	barra_vida.actualizar(vida, vida_maxima)
	if vida <= 0:
		queue_free()

func agregar_xp(cantidad: float) -> void:
	EstadoJuego.agregar_xp(cantidad)

func _actualizar_escudo(delta: float) -> void:
	if escudo_nivel == 0:
		return
	if escudo_golpes_actual >= escudo_golpes_max:
		return
	escudo_timer -= delta
	if escudo_timer <= 0.0:
		escudo_golpes_actual = escudo_golpes_max
		escudo_roto = false

func escudo_absorber_golpe() -> bool:
	if escudo_nivel == 0 or escudo_golpes_actual <= 0:
		return false

	escudo_golpes_actual -= 1

	# Efecto de empuje en Nv.2+
	if escudo_nivel >= 2:
		_escudo_empujar_enemigos(false)

	if escudo_golpes_actual <= 0:
		escudo_roto = true
		escudo_timer = 30.0
		# Efecto de ruptura en Nv.3+
		if escudo_nivel >= 3:
			_escudo_empujar_enemigos(true)
	else:
		escudo_timer = 15.0

	return true

func _escudo_empujar_enemigos(ruptura: bool) -> void:
	var enemigos = get_tree().get_nodes_in_group("enemigos")
	for enemigo in enemigos:
		var distancia = global_position.distance_to(enemigo.global_position)
		if distancia <= escudo_radio_empuje:
			var direccion = (enemigo.global_position - global_position).normalized()
			if ruptura:
				enemigo.recibir_danio(escudo_danio_ruptura)
			# Aplicar knockback al enemigo
			if enemigo.has_method("recibir_empuje"):
				enemigo.recibir_empuje(direccion * 500.0)
