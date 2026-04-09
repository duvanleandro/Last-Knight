extends CharacterBody2D

var VELOCIDAD = 200.0
var vida: float = 100.0
var vida_maxima: float = 100.0
var danio_ataque: float = 25.0
var cadencia: float = 0.5
var timer_ataque: float = 0.0
var penetracion: int = 0
var reduccion_danio_penetracion: float = 0.5
var knockback_velocidad: Vector2 = Vector2.ZERO
var knockback_fuerza: float = 800.0

@export var escena_proyectil: PackedScene
@onready var barra_vida = $BarraVida

func _ready() -> void:
	add_to_group("jugador")

func _physics_process(delta: float) -> void:
	_mover(delta)
	_atacar(delta)

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
	proyectil.inicializar(global_position, direccion, danio_ataque, penetracion, reduccion_danio_penetracion)
	timer_ataque = 0.0

func aplicar_knockback(origen: Vector2) -> void:
	knockback_velocidad = (global_position - origen).normalized() * knockback_fuerza

func recibir_danio(cantidad: float, origen: Vector2 = Vector2.ZERO) -> void:
	vida -= cantidad
	if origen != Vector2.ZERO:
		knockback_velocidad = (global_position - origen).normalized() * knockback_fuerza
	barra_vida.actualizar(vida, vida_maxima)
	if vida <= 0:
		queue_free()

func agregar_xp(cantidad: float) -> void:
	EstadoJuego.agregar_xp(cantidad)
