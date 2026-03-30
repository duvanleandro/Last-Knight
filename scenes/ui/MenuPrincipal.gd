extends Control

func _ready() -> void:
	# Asegura que el cursor sea visible en el menú
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_boton_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/Main.tscn")

func _on_boton_salir_pressed() -> void:
	get_tree().quit()
