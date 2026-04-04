extends Area2D

var velocidad: float = 400.0
var danio: float = 25.0
var direccion: Vector2 = Vector2.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func inicializar(pos: Vector2, dir: Vector2, dmg: float) -> void:
	global_position = pos
	direccion = dir.normalized()
	danio = dmg

func _physics_process(delta: float) -> void:
	global_position += direccion * velocidad * delta
	# Destruir si sale muy lejos
	var jugador = get_tree().get_first_node_in_group("jugador")
	if jugador and global_position.distance_to(jugador.global_position) > 800.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemigos"):
		body.recibir_danio(danio)
		queue_free()
