extends Area2D

var velocidad: float = 400.0
var danio: float = 25.0
var direccion: Vector2 = Vector2.ZERO
var penetracion: int = 0
var reduccion_danio: float = 0.5
var enemigos_golpeados: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func inicializar(pos: Vector2, dir: Vector2, dmg: float, pen: int = 0, red: float = 0.5) -> void:
	global_position = pos
	direccion = dir.normalized()
	danio = dmg
	penetracion = pen
	reduccion_danio = red

func _physics_process(delta: float) -> void:
	global_position += direccion * velocidad * delta
	# Destruir si sale muy lejos
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador and global_position.distance_to(jugador.global_position) > 800.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemigos") and not body in enemigos_golpeados:
		enemigos_golpeados.append(body)
		body.recibir_danio(danio)
		if penetracion <= 0:
			queue_free()
		else:
			penetracion -= 1
			danio *= reduccion_danio
